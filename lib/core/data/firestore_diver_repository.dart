import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_repository.dart';
import 'package:dive_travel_app/core/data/diver_snapshot.dart';
import 'package:dive_travel_app/core/data/refund_policy.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/i18n/translation_engine.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/core/models/dive_log.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/r2_photo_storage.dart';

class FirestoreDiverRepository implements DiverRepository {
  FirestoreDiverRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    R2PhotoStorage? photoStorage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance,
       _photos = photoStorage ?? const R2PhotoStorage();

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final R2PhotoStorage _photos;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _users.doc(uid);

  CollectionReference<Map<String, dynamic>> _logs(String uid) =>
      _userDoc(uid).collection('logs');

  AppUser _toAppUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  @override
  Stream<AppUser?> authState() {
    return _auth.authStateChanges().map((user) {
      return user == null ? null : _toAppUser(user);
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await ensureUserDocument(_toAppUser(user));
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return;
      }
      await _finishNewUser(user, email: email, displayName: displayName);
    } on FirebaseAuthException catch (error) {
      // 이메일 열거 보호가 켜져 있으면, 이미 가입된 주소로 회원가입할 때
      // email-already-in-use 대신 invalid-credential이 온다.
      if (error.code == 'email-already-in-use' ||
          error.code == 'invalid-credential') {
        await signIn(email: email, password: password);
        return;
      }
      rethrow;
    }
  }

  Future<void> _finishNewUser(
    User user, {
    required String email,
    required String? displayName,
  }) async {
    final name = AppOwner.resolveDisplayName(
      email: user.email ?? email,
      displayName: displayName,
    );
    await user.updateDisplayName(name);
    await user.reload();
    final refreshed = _auth.currentUser ?? user;
    await ensureUserDocument(
      AppUser(uid: refreshed.uid, email: refreshed.email, displayName: name),
    );
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> ensureUserDocument(AppUser user) async {
    final ref = _userDoc(user.uid);
    final snapshot = await ref.get().timeout(const Duration(seconds: 8));
    final existingName = snapshot.data()?['display_name'] as String?;
    final displayName = (existingName != null && existingName.trim().isNotEmpty)
        ? existingName.trim()
        : AppOwner.resolveDisplayName(
            email: user.email,
            displayName: user.displayName,
          );
    final payload = <String, dynamic>{
      'email': user.email,
      'display_name': displayName,
      'updated_at': FieldValue.serverTimestamp(),
    };
    final grantAdmin =
        AppOwner.isOwnerEmail(user.email) ||
        AppConstants.grantAdminToCurrentSession;
    final grantBusiness =
        AppOwner.isOwnerEmail(user.email) ||
        AppConstants.grantBusinessToCurrentSession;
    if (grantAdmin) {
      payload['is_admin'] = true;
      payload['user_role'] = 'admin';
    }
    if (grantBusiness) {
      payload['is_business'] = true;
      payload['owned_shop_id'] =
          snapshot.data()?['owned_shop_id'] as String? ??
          AppConstants.defaultPartnerShopId;
      payload['user_role'] = grantAdmin ? 'admin' : 'business';
    }
    if (!snapshot.exists) {
      payload.addAll({
        if (!grantAdmin) 'user_role': 'diver',
        'member_grade': MemberGrade.member.firestoreValue,
        'is_instructor': false,
        'is_verified_pro': false,
        'c_card_agency': '',
        'c_card_photo_url': '',
        'total_log_count': 0,
        'unique_regions_count': 0,
        'visited_regions': <String>[],
        'region_log_counts': <String, int>{},
        'created_at': FieldValue.serverTimestamp(),
      });
    } else if (snapshot.data()?['member_grade'] == null &&
        snapshot.data()?['memberGrade'] == null) {
      final instructor = snapshot.data()?['is_instructor'] == true;
      payload['member_grade'] = instructor
          ? MemberGrade.instructor.firestoreValue
          : MemberGrade.member.firestoreValue;
    }
    await ref.set(payload, SetOptions(merge: true));
  }

  @override
  Stream<DiverSnapshot> watchDiver(String uid) {
    return Stream<DiverSnapshot>.multi((controller) {
      DocumentSnapshot<Map<String, dynamic>>? userSnap;
      QuerySnapshot<Map<String, dynamic>>? logsSnap;
      late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      userSub;
      late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      logsSub;

      void emit() {
        final user = userSnap;
        if (user == null || controller.isClosed) {
          return;
        }
        controller.add(_toSnapshot(user, logsSnap));
      }

      controller.onCancel = () async {
        await userSub.cancel();
        await logsSub.cancel();
      };

      userSub = _userDoc(uid).snapshots().listen((snapshot) {
        userSnap = snapshot;
        emit();
      }, onError: controller.addError);
      logsSub = _logs(uid)
          .orderBy('dived_at', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              logsSnap = snapshot;
              emit();
            },
            onError: (Object error, StackTrace stackTrace) {
              developer.log(
                'logs snapshots 실패: $error',
                name: 'FirestoreDiverRepository',
                stackTrace: stackTrace,
              );
              emit();
            },
          );
    });
  }

  DiverSnapshot _toSnapshot(
    DocumentSnapshot<Map<String, dynamic>> userSnap,
    QuerySnapshot<Map<String, dynamic>>? logsSnap,
  ) {
    if (!userSnap.exists) {
      return DiverSnapshot.empty();
    }
    final logDocs =
        logsSnap?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final logs = [
      for (final doc in logDocs)
        DiveLog(
          id: doc.id,
          siteName: doc.data()['site_name'] as String? ?? '',
          divedAt: _readDate(doc.data()['dived_at']),
          memo: doc.data()['memo'] as String? ?? '',
          regionId: doc.data()['region_id'] as String?,
          photoUrl: doc.data()['photo_url'] as String?,
          profile: DiveProfile.tryParse(doc.data()),
          createdAt: doc.data()['created_at'] == null
              ? null
              : _readDate(doc.data()['created_at']),
        ),
    ];

    return DiverSnapshot.fromUserDocument(
      data: userSnap.data() ?? {},
      logs: logs,
    );
  }

  DateTime _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return DateTime.now();
  }

  @override
  Future<void> addLog({
    required String uid,
    required String siteName,
    required DateTime divedAt,
    required String memo,
    Uint8List? photoBytes,
    String? photoFileName,
    String? photoContentType,
    DiveProfile? profile,
  }) async {
    final trimmed = siteName.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final resolved = RegionCatalog.resolve(trimmed, 1);
    final userRef = _userDoc(uid);
    final logRef = _logs(uid).doc();

    String? photoUrl;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      final extension = _photoExtension(photoFileName);
      photoUrl = await _photos.upload(
        objectKey: 'logs/$uid/${logRef.id}$extension',
        bytes: photoBytes,
        contentType: photoContentType ?? 'image/jpeg',
      );
    }

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() ?? {};
      final visited = List<String>.from(data['visited_regions'] ?? const []);
      final counts = Map<String, dynamic>.from(
        data['region_log_counts'] ?? const {},
      );
      final regionName = resolved.name;
      counts[regionName] = ((counts[regionName] as num?)?.toInt() ?? 0) + 1;
      if (!visited.contains(regionName)) {
        visited.add(regionName);
      }
      transaction.set(userRef, {
        'total_log_count':
            ((data['total_log_count'] as num?)?.toInt() ?? 0) + 1,
        'visited_regions': visited,
        'unique_regions_count': visited.length,
        'region_log_counts': counts,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(logRef, {
        'site_name': trimmed,
        'dived_at': Timestamp.fromDate(divedAt),
        'memo': memo.trim(),
        'region_id': resolved.id,
        'photo_url': ?photoUrl,
        'created_at': FieldValue.serverTimestamp(),
        'self_registered': true,
        ...?profile?.toMap(),
      });
    });
  }

  @override
  Future<void> updateLog({
    required String uid,
    required String logId,
    required String siteName,
    required DateTime divedAt,
    required String memo,
    Uint8List? photoBytes,
    String? photoFileName,
    String? photoContentType,
    DiveProfile? profile,
    bool removePhoto = false,
  }) async {
    final trimmed = siteName.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final resolved = RegionCatalog.resolve(trimmed, 1);
    final userRef = _userDoc(uid);
    final logRef = _logs(uid).doc(logId);

    String? photoUrl;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      final extension = _photoExtension(photoFileName);
      photoUrl = await _photos.upload(
        objectKey: 'logs/$uid/${logRef.id}$extension',
        bytes: photoBytes,
        contentType: photoContentType ?? 'image/jpeg',
      );
    }

    await _db.runTransaction((transaction) async {
      final logSnap = await transaction.get(logRef);
      final userSnap = await transaction.get(userRef);
      if (!logSnap.exists) {
        return;
      }
      final oldSite = (logSnap.data()?['site_name'] as String? ?? '').trim();
      final data = userSnap.data() ?? {};
      final visited = List<String>.from(data['visited_regions'] ?? const []);
      final counts = Map<String, dynamic>.from(
        data['region_log_counts'] ?? const {},
      );
      if (oldSite.isNotEmpty && oldSite != trimmed) {
        final oldName = RegionCatalog.resolve(oldSite, 1).name;
        _nudgeRegion(counts, visited, oldName, -1);
        _nudgeRegion(counts, visited, resolved.name, 1);
        transaction.set(userRef, {
          'visited_regions': visited,
          'unique_regions_count': visited.length,
          'region_log_counts': counts,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      final payload = <String, dynamic>{
        'site_name': trimmed,
        'dived_at': Timestamp.fromDate(divedAt),
        'memo': memo.trim(),
        'region_id': resolved.id,
        'self_registered': true,
        'updated_at': FieldValue.serverTimestamp(),
        'photo_url': ?photoUrl,
        if (removePhoto && photoUrl == null) 'photo_url': FieldValue.delete(),
      };
      const profileKeys = [
        'max_depth_m',
        'avg_depth_m',
        'minutes',
        'start_bar',
        'end_bar',
        'tank_liters',
        'temp_c',
        'o2_mix',
      ];
      if (profile == null) {
        for (final key in profileKeys) {
          payload[key] = FieldValue.delete();
        }
      } else {
        payload.addAll(profile.toMap());
      }
      transaction.set(logRef, payload, SetOptions(merge: true));
    });
  }

  void _nudgeRegion(
    Map<String, dynamic> counts,
    List<String> visited,
    String name,
    int delta,
  ) {
    final next = ((counts[name] as num?)?.toInt() ?? 0) + delta;
    if (next <= 0) {
      counts.remove(name);
      visited.remove(name);
    } else {
      counts[name] = next;
      if (!visited.contains(name)) {
        visited.add(name);
      }
    }
  }

  String _photoExtension(String? fileName) {
    final name = (fileName ?? '').toLowerCase();
    if (name.endsWith('.png')) {
      return '.png';
    }
    if (name.endsWith('.webp')) {
      return '.webp';
    }
    if (name.endsWith('.gif')) {
      return '.gif';
    }
    if (name.endsWith('.heic') || name.endsWith('.heif')) {
      return '.heic';
    }
    return '.jpg';
  }

  CollectionReference<Map<String, dynamic>> get _shops =>
      _db.collection('shops');

  CollectionReference<Map<String, dynamic>> _bookings(String uid) =>
      _userDoc(uid).collection('bookings');

  @override
  Stream<List<ShopLiveStats>> watchShopStats() {
    return _shops.snapshots().map((snapshot) {
      return [
        for (final doc in snapshot.docs)
          ShopLiveStats.fromDocument(doc.id, doc.data()),
      ];
    });
  }

  CollectionReference<Map<String, dynamic>> _shopBookings(String shopId) =>
      _shops.doc(shopId).collection('bookings');

  TourBooking _toBooking(String id, Map<String, dynamic> data) {
    return TourBooking(
      id: id,
      uid: data['uid'] as String? ?? '',
      shopId: data['shop_id'] as String? ?? '',
      shopName: data['shop_name'] as String? ?? '',
      productName: data['product_name'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      createdAt: _readDate(data['created_at']),
      tourDate: data['tour_date'] == null ? null : _readDate(data['tour_date']),
      reviewed: data['reviewed'] == true,
      status: BookingStatus.parse(data['status']),
      refundPercent: (data['refund_percent'] as num?)?.toInt() ?? 0,
      refundAmount: (data['refund_amount'] as num?)?.toInt() ?? 0,
      refundNoticeSeen: data['refund_notice_seen'] == true,
      commissionRate:
          (data['commission_rate'] as num?)?.toDouble() ??
          RefundPolicy.defaultCommissionRate,
      paymentStatus: data['payment_status'] as String? ?? 'captured',
    );
  }

  Map<String, dynamic> _bookingPayload(TourBooking booking) {
    return {
      'uid': booking.uid,
      'shop_id': booking.shopId,
      'shop_name': booking.shopName,
      'product_name': booking.productName,
      'price': booking.price,
      'reviewed': booking.reviewed,
      'status': booking.status.firestoreValue,
      'refund_percent': booking.refundPercent,
      'refund_amount': booking.refundAmount,
      'refund_notice_seen': booking.refundNoticeSeen,
      'commission_rate': booking.commissionRate,
      'payment_status': booking.paymentStatus,
      'tour_date': Timestamp.fromDate(booking.scheduledFor),
      'created_at': Timestamp.fromDate(booking.createdAt),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  @override
  Stream<List<TourBooking>> watchBookings(String uid) {
    return _bookings(uid).snapshots().map((snapshot) {
      final bookings = [
        for (final doc in snapshot.docs) _toBooking(doc.id, doc.data()),
      ];
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  @override
  Future<void> createBooking({
    required String uid,
    required String shopId,
    required String shopName,
    required String productName,
    required int price,
    DateTime? tourDate,
  }) async {
    final id = _bookings(uid).doc().id;
    final booking = TourBooking(
      id: id,
      uid: uid,
      shopId: shopId.split('--').first,
      shopName: shopName,
      productName: productName,
      price: price,
      createdAt: DateTime.now(),
      tourDate: tourDate ?? DateTime.now().add(const Duration(days: 7)),
      commissionRate: RefundPolicy.defaultCommissionRate,
    );
    final payload = _bookingPayload(booking);
    payload['created_at'] = FieldValue.serverTimestamp();
    await _bookings(uid).doc(id).set(payload);
    await _shopBookings(booking.shopId).doc(id).set(payload);
  }

  @override
  Future<void> submitOperationReview({
    required String uid,
    required String shopId,
    required int safety,
    required int guide,
    required int boat,
    String? bookingId,
    String? logId,
    String? comment,
  }) async {
    final shop = DiveShopCatalog.byId(shopId);
    final shopRef = _shops.doc(shopId);
    final reviewRef = shopRef.collection('reviews').doc();
    final userReviewRef = _userDoc(uid).collection('reviews').doc(reviewRef.id);
    final bookingRef = bookingId == null || bookingId.isEmpty
        ? null
        : _bookings(uid).doc(bookingId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(shopRef);
      if (bookingRef != null) {
        await transaction.get(bookingRef);
      }
      final data = snapshot.data() ?? {};
      final count = (data['review_count'] as num?)?.toInt() ?? 0;
      final nextCount = count + 1;
      final sumSafety =
          ((data['sum_safety'] as num?)?.toDouble() ?? 0) + safety;
      final sumGuide = ((data['sum_guide'] as num?)?.toDouble() ?? 0) + guide;
      final sumBoat = ((data['sum_boat'] as num?)?.toDouble() ?? 0) + boat;
      final avgSafety = sumSafety / nextCount;
      final avgGuide = sumGuide / nextCount;
      final avgBoat = sumBoat / nextCount;
      final avgOverall = DiveStar.overall(
        safety: avgSafety,
        guide: avgGuide,
        boat: avgBoat,
      );
      final diveStar = DiveStar.fromAverages(
        safety: avgSafety,
        guide: avgGuide,
        boat: avgBoat,
        reviewCount: nextCount,
      );
      final review = <String, dynamic>{
        'uid': uid,
        'shop_id': shopId,
        'safety': safety,
        'guide': guide,
        'boat': boat,
        'overall': (safety + guide + boat) / 3,
        'comment': ?comment,
        'booking_id': ?bookingId,
        'log_id': ?logId,
        'created_at': FieldValue.serverTimestamp(),
      };
      transaction.set(reviewRef, review);
      transaction.set(userReviewRef, review);
      transaction.set(shopRef, {
        'name': shop?.name ?? data['name'] ?? shopId,
        'location': shop?.location ?? data['location'],
        'review_count': nextCount,
        'sum_safety': sumSafety,
        'sum_guide': sumGuide,
        'sum_boat': sumBoat,
        'avg_safety': avgSafety,
        'avg_guide': avgGuide,
        'avg_boat': avgBoat,
        'avg_overall': avgOverall,
        'dive_star': diveStar,
        'safety_pass': avgSafety >= DiveStar.safetyPassThreshold,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (bookingRef != null) {
        transaction.set(bookingRef, {
          'reviewed': true,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  @override
  Future<void> submitProVerification({
    required String uid,
    required String agency,
    required Uint8List photoBytes,
    required String photoFileName,
    required String photoContentType,
  }) async {
    final extension = _photoExtension(photoFileName);
    final photoUrl = await _photos.upload(
      objectKey:
          'ccards/$uid/${DateTime.now().millisecondsSinceEpoch}$extension',
      bytes: photoBytes,
      contentType: photoContentType,
    );
    final existing = await _userDoc(uid).get();
    final alreadyInstructor = existing.data()?['is_instructor'] == true;
    await _userDoc(uid).set({
      'is_verified_pro': ProVerificationStatus.pending.firestoreValue,
      if (!alreadyInstructor) 'is_instructor': false,
      'c_card_agency': agency,
      'c_card_photo_url': photoUrl,
      'c_card_submitted_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  PendingInstructor? _toPendingInstructor(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final status = ProVerificationStatus.parse(data['is_verified_pro']);
    if (status != ProVerificationStatus.pending) {
      return null;
    }
    return PendingInstructor(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName:
          data['display_name'] as String? ??
          (data['email'] as String?)?.split('@').first ??
          '다이버',
      agency: data['c_card_agency'] as String? ?? '',
      photoUrl: data['c_card_photo_url'] as String? ?? '',
    );
  }

  CommunityPost _toCommunityPost(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return CommunityPost(
      id: doc.id,
      type: data['type'] == 'buddy'
          ? CommunityPostType.buddy
          : CommunityPostType.shopTour,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      authorUid: data['author_uid'] as String? ?? '',
      authorName: data['author_name'] as String? ?? '',
      createdAt: _readDate(data['created_at']),
      hidden: data['hidden'] == true,
      language:
          data['language'] as String? ??
          LanguageDetector.detect(
            '${data['title'] ?? ''} ${data['subtitle'] ?? ''}',
          ),
      shopId: data['shop_id'] as String?,
      destination: data['destination'] as String? ?? '',
      windowLabel: data['window_label'] as String? ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 6,
      bookedSeats: (data['booked_seats'] as num?)?.toInt() ?? 0,
      lookingSeats: (data['looking_seats'] as num?)?.toInt() ?? 0,
      soloShare: data['solo_share'] == true,
      kind: TideKind.parse(data['tide_kind']),
    );
  }

  Map<String, dynamic> _postPayload(CommunityPost post) {
    return {
      'type': post.type == CommunityPostType.buddy ? 'buddy' : 'shop_tour',
      'title': post.title,
      'subtitle': post.subtitle,
      'author_uid': post.authorUid,
      'author_name': post.authorName,
      'hidden': post.hidden,
      'language': post.language,
      'shop_id': post.shopId,
      'destination': post.destination,
      'window_label': post.windowLabel,
      'capacity': post.capacity,
      'booked_seats': post.bookedSeats,
      'looking_seats': post.lookingSeats,
      'solo_share': post.soloShare,
      'tide_kind': post.kind.firestoreValue,
      'created_at': Timestamp.fromDate(post.createdAt),
    };
  }

  @override
  Stream<List<PendingInstructor>> watchPendingInstructors() {
    return _users.snapshots().map((snapshot) {
      return [
        for (final doc in snapshot.docs)
          if (_toPendingInstructor(doc) case final pending?) pending,
      ];
    });
  }

  @override
  Stream<List<CommunityPost>> watchCommunityPosts() {
    return _posts.snapshots().map((snapshot) {
      final posts = [for (final doc in snapshot.docs) _toCommunityPost(doc)];
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  @override
  Future<void> ensureSeedPosts() async {
    final batch = _db.batch();
    var writes = 0;
    for (final post in CommunityPostCatalog.seeds) {
      final ref = _posts.doc(post.id);
      final snap = await ref.get();
      if (!snap.exists) {
        batch.set(ref, _postPayload(post));
        writes += 1;
      }
    }
    for (final comment in CommunityPostCatalog.seedComments) {
      final ref = _posts
          .doc(comment.postId)
          .collection('comments')
          .doc(comment.id);
      final snap = await ref.get();
      if (!snap.exists) {
        batch.set(ref, {
          'author_uid': comment.authorUid,
          'author_name': comment.authorName,
          'body': comment.body,
          'language': comment.language,
          'created_at': Timestamp.fromDate(comment.createdAt),
        });
        writes += 1;
      }
    }
    if (writes > 0) {
      await batch.commit();
    }
  }

  @override
  Future<void> approveInstructor(String uid) {
    return _userDoc(uid).set({
      'is_instructor': true,
      'is_verified_pro': ProVerificationStatus.approved.firestoreValue,
      'member_grade': MemberGrade.instructor.firestoreValue,
      'pro_approved_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> rejectInstructor(String uid) {
    return _userDoc(uid).set({
      'is_instructor': false,
      'is_verified_pro': ProVerificationStatus.rejected.firestoreValue,
      'pro_rejected_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  MemberAccount _toMemberAccount(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final instructor = data['is_instructor'] == true;
    return MemberAccount(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName:
          data['display_name'] as String? ??
          (data['email'] as String?)?.split('@').first ??
          '다이버',
      grade: MemberGrade.parse(
        data['member_grade'] ?? data['memberGrade'],
        isInstructor: instructor,
      ),
      totalLogCount: (data['total_log_count'] as num?)?.toInt() ?? 0,
      uniqueRegionsCount: (data['unique_regions_count'] as num?)?.toInt() ?? 0,
      isAdmin: data['is_admin'] == true,
      isInstructor: instructor,
    );
  }

  @override
  Stream<List<MemberAccount>> watchMembers() {
    return _users.snapshots().map((snapshot) {
      final members = [
        for (final doc in snapshot.docs) _toMemberAccount(doc),
      ];
      members.sort((a, b) => a.displayName.compareTo(b.displayName));
      return members;
    });
  }

  @override
  Future<void> setMemberGrade({
    required String uid,
    required MemberGrade grade,
  }) {
    return _userDoc(uid).set({
      'member_grade': grade.firestoreValue,
      if (grade == MemberGrade.instructor) 'is_instructor': true,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setPlaqueStatus({
    required String shopId,
    required PlaqueStatus status,
  }) {
    final shop = DiveShopCatalog.byId(shopId);
    return _shops.doc(shopId).set({
      'name': shop?.name ?? shopId,
      'location': shop?.location,
      'plaque_status': status.firestoreValue,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setPostHidden({required String postId, required bool hidden}) {
    return _posts.doc(postId).set({
      'hidden': hidden,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deletePost(String postId) {
    return _posts.doc(postId).delete();
  }

  @override
  Future<void> saveShopProfile({
    required String shopId,
    required String name,
    required String location,
    required String productName,
    required int consumerPrice,
    required int professionalPrice,
    String? intro,
    String? address,
    List<String>? amenities,
    Uint8List? coverBytes,
    String? coverFileName,
    String? coverContentType,
    bool removeCover = false,
    List<ShopGallerySlot>? gallery,
  }) async {
    final catalog = DiveShopCatalog.byId(shopId);
    String? coverUrl;
    List<String>? galleryUrls;

    if (gallery != null) {
      galleryUrls = <String>[];
      final stamp = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < gallery.length; i++) {
        final slot = gallery[i];
        if (slot.hasBytes) {
          final extension = _photoExtension(slot.fileName);
          final url = await _photos.upload(
            objectKey: 'shops/$shopId/gallery/${stamp}_$i$extension',
            bytes: slot.bytes!,
            contentType: slot.contentType ?? 'image/jpeg',
          );
          galleryUrls.add(url);
        } else if (slot.hasUrl) {
          galleryUrls.add(slot.url!.trim());
        }
      }
      coverUrl = galleryUrls.isEmpty ? null : galleryUrls.first;
    } else if (coverBytes != null && coverBytes.isNotEmpty) {
      final extension = _photoExtension(coverFileName);
      coverUrl = await _photos.upload(
        objectKey: 'shops/$shopId/cover$extension',
        bytes: coverBytes,
        contentType: coverContentType ?? 'image/jpeg',
      );
    }

    return _shops.doc(shopId).set({
      'name': name.trim(),
      'location': location.trim(),
      'product_name': productName.trim(),
      'consumer_price': consumerPrice,
      'professional_price': professionalPrice,
      if (intro != null) 'intro': intro.trim(),
      if (address != null) 'address': address.trim(),
      if (amenities != null) 'amenities': amenities,
      if (galleryUrls != null) 'gallery_urls': galleryUrls,
      if (galleryUrls != null && galleryUrls.isEmpty)
        'cover_url': FieldValue.delete()
      else if (coverUrl != null)
        'cover_url': coverUrl
      else if (removeCover)
        'cover_url': FieldValue.delete(),
      'country': catalog?.country,
      'continent': catalog?.continent,
      'commission_rate': RefundPolicy.defaultCommissionRate,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveShopProduct({
    required String shopId,
    required ShopProduct product,
    Uint8List? photoBytes,
    String? photoFileName,
    String? photoContentType,
    bool useAsResortCover = false,
  }) async {
    var saved = product;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      final extension = _photoExtension(photoFileName);
      final url = await _photos.upload(
        objectKey: 'shops/$shopId/products/${product.id}$extension',
        bytes: photoBytes,
        contentType: photoContentType ?? 'image/jpeg',
      );
      saved = ShopProduct(
        id: product.id,
        shopId: product.shopId,
        name: product.name,
        consumerPrice: product.consumerPrice,
        professionalPrice: product.professionalPrice,
        active: product.active,
        blurb: product.blurb,
        durationLabel: product.durationLabel,
        coverUrl: url,
      );
    }
    final ref = _shops.doc(shopId);
    final snap = await ref.get();
    final current = [
      for (final item
          in (snap.data()?['products'] as List<dynamic>? ?? const []))
        if (item is Map<String, dynamic>) ShopProduct.fromMap(shopId, item),
    ];
    final next = [
      for (final item in current)
        if (item.id != saved.id) item,
      saved,
    ];
    await ref.set({
      'products': [for (final item in next) item.toMap()],
      'product_name': saved.name,
      'consumer_price': saved.consumerPrice,
      'professional_price': saved.professionalPrice,
      if (useAsResortCover && saved.coverUrl.isNotEmpty) ...{
        'cover_url': saved.coverUrl,
        'gallery_urls': [
          saved.coverUrl,
          for (final item
              in (snap.data()?['gallery_urls'] as List<dynamic>? ?? const []))
            if (item is String &&
                item.trim().isNotEmpty &&
                item.trim() != saved.coverUrl)
              item.trim(),
        ],
      },
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<TourBooking>> watchShopBookings(String shopId) {
    return _shopBookings(shopId).snapshots().map((snapshot) {
      final bookings = [
        for (final doc in snapshot.docs) _toBooking(doc.id, doc.data()),
      ];
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  @override
  Future<void> cancelBookingAsGuest({
    required String uid,
    required String bookingId,
  }) async {
    final userRef = _bookings(uid).doc(bookingId);
    final snap = await userRef.get();
    if (!snap.exists) {
      return;
    }
    final booking = _toBooking(snap.id, snap.data() ?? {});
    if (!booking.isActive) {
      return;
    }
    final quote = RefundPolicy.forUserCancel(tourDate: booking.scheduledFor);
    final patch = {
      'status': BookingStatus.cancelled.firestoreValue,
      'refund_percent': quote.percent,
      'refund_amount': quote.amountFor(booking.price),
      'payment_status': quote.percent > 0 ? 'refunded' : 'captured',
      'cancelled_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    await userRef.set(patch, SetOptions(merge: true));
    await _shopBookings(booking.shopId)
        .doc(bookingId)
        .set(patch, SetOptions(merge: true));
  }

  @override
  Future<void> cancelBookingsForWeather({
    required String shopId,
    required DateTime tourDate,
  }) async {
    final day = RefundPolicy.dateOnly(tourDate);
    final snapshot = await _shopBookings(shopId).get();
    final quote = RefundPolicy.weatherCancel();
    for (final doc in snapshot.docs) {
      final booking = _toBooking(doc.id, doc.data());
      if (!booking.isActive) {
        continue;
      }
      if (RefundPolicy.dateOnly(booking.scheduledFor) != day) {
        continue;
      }
      final patch = {
        'status': BookingStatus.weatherCancelled.firestoreValue,
        'refund_percent': 100,
        'refund_amount': quote.amountFor(booking.price),
        'payment_status': 'refunded',
        'refund_notice_seen': false,
        'cancelled_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      await doc.reference.set(patch, SetOptions(merge: true));
      if (booking.uid.isNotEmpty) {
        await _bookings(booking.uid)
            .doc(booking.id)
            .set(patch, SetOptions(merge: true));
      }
    }
  }

  @override
  Future<void> acknowledgeRefundNotice({
    required String uid,
    required String bookingId,
  }) async {
    final userRef = _bookings(uid).doc(bookingId);
    final snap = await userRef.get();
    final shopId = snap.data()?['shop_id'] as String? ?? '';
    final patch = {
      'refund_notice_seen': true,
      'updated_at': FieldValue.serverTimestamp(),
    };
    await userRef.set(patch, SetOptions(merge: true));
    if (shopId.isNotEmpty) {
      await _shopBookings(shopId)
          .doc(bookingId)
          .set(patch, SetOptions(merge: true));
    }
  }

  @override
  Future<void> addCommunityPost({
    required String uid,
    required String authorName,
    required String title,
    required String subtitle,
    required CommunityPostType type,
    required String language,
    String? shopId,
    String destination = '',
    String windowLabel = '',
    int capacity = 6,
    int bookedSeats = 0,
    int lookingSeats = 1,
    bool soloShare = false,
    TideKind kind = TideKind.soloShare,
  }) {
    return _posts.add({
      'type': type == CommunityPostType.buddy ? 'buddy' : 'shop_tour',
      'title': title.trim(),
      'subtitle': subtitle.trim(),
      'author_uid': uid,
      'author_name': authorName,
      'hidden': false,
      'language': language,
      'shop_id': shopId,
      'destination': destination,
      'window_label': windowLabel,
      'capacity': capacity,
      'booked_seats': bookedSeats,
      'looking_seats': lookingSeats,
      'solo_share': soloShare,
      'tide_kind': kind.firestoreValue,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<CommunityComment>> watchComments(String postId) {
    return _posts.doc(postId).collection('comments').snapshots().map((
      snapshot,
    ) {
      final comments = [
        for (final doc in snapshot.docs)
          CommunityComment(
            id: doc.id,
            postId: postId,
            authorUid: doc.data()['author_uid'] as String? ?? '',
            authorName: doc.data()['author_name'] as String? ?? '',
            body: doc.data()['body'] as String? ?? '',
            createdAt: _readDate(doc.data()['created_at']),
            language:
                doc.data()['language'] as String? ??
                LanguageDetector.detect(doc.data()['body'] as String? ?? ''),
          ),
      ];
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return comments;
    });
  }

  @override
  Future<void> addComment({
    required String postId,
    required String uid,
    required String authorName,
    required String body,
    required String language,
  }) {
    return _posts.doc(postId).collection('comments').add({
      'author_uid': uid,
      'author_name': authorName,
      'body': body.trim(),
      'language': language,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  DocumentReference<Map<String, dynamic>> get _pricingDoc =>
      _db.collection('settings').doc('pricing');

  @override
  Stream<InstructorDiscount> watchInstructorDiscount() {
    return _pricingDoc.snapshots().map(
      (snap) => InstructorDiscount.fromMap(snap.data()),
    );
  }

  @override
  Future<void> saveInstructorDiscount(InstructorDiscount discount) {
    return _pricingDoc.set({
      ...discount.toMap(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
