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
import 'package:dive_travel_app/core/data/operation_review_policy.dart';
import 'package:dive_travel_app/core/data/refund_policy.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/i18n/translation_engine.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/dive_log.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/core/models/dive_star_assessment.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/review_detail_options.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/gallery_upload.dart';
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
        'member_grade': MemberGrade.silver.firestoreValue,
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
      payload['member_grade'] = MemberGrade.silver.firestoreValue;
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

  @override
  Future<void> setFavoriteShop({
    required String uid,
    required String shopId,
    required bool favorite,
  }) {
    final trimmed = shopId.trim();
    if (trimmed.isEmpty) {
      return Future.value();
    }
    return _userDoc(uid).set({
      'favorite_shop_ids': favorite
          ? FieldValue.arrayUnion([trimmed])
          : FieldValue.arrayRemove([trimmed]),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      paymentStatus: PaymentStatus.parse(data['payment_status']),
      productId: data['product_id'] as String? ?? '',
      optionId: data['option_id'] as String? ?? '',
      optionName: data['option_name'] as String? ?? '',
      listingKind: data.containsKey('listing_kind')
          ? ProductListingKind.parse(data['listing_kind'])
          : ProductListingKind.exploreOnly,
      fromFlag: data['from_flag'] == true,
      partySize: (data['party_size'] as num?)?.toInt() ?? 0,
      divers: (data['divers'] as num?)?.toInt() ?? 0,
      nondivers: (data['nondivers'] as num?)?.toInt() ?? 0,
      children: (data['children'] as num?)?.toInt() ?? 0,
      infants: (data['infants'] as num?)?.toInt() ?? 0,
      quoteLines: BookingLine.listFrom(data['quote_lines']),
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
      'payment_status': booking.paymentStatus.firestoreValue,
      'product_id': booking.productId,
      'option_id': booking.optionId,
      'option_name': booking.optionName,
      'listing_kind': booking.listingKind.firestoreValue,
      'from_flag': booking.fromFlag,
      'party_size': booking.partySize,
      'divers': booking.divers,
      'nondivers': booking.nondivers,
      'children': booking.children,
      'infants': booking.infants,
      if (booking.quoteLines.isNotEmpty)
        'quote_lines': [
          for (final line in booking.quoteLines) line.toMap(),
        ],
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
  Future<bool> createBooking({
    required String uid,
    required String shopId,
    required String shopName,
    required String productName,
    required int price,
    DateTime? tourDate,
    String? productId,
    int partySize = 0,
    String optionId = '',
    String optionName = '',
    String seatOptionId = '',
    ProductListingKind listingKind = ProductListingKind.exploreOnly,
    bool fromFlag = false,
    int divers = 0,
    int nondivers = 0,
    int children = 0,
    int infants = 0,
    List<BookingLine> quoteLines = const [],
    BookingStatus status = BookingStatus.requested,
    PaymentStatus paymentStatus = PaymentStatus.unpaid,
  }) async {
    final hullId = shopId.split('--').first;
    final held = await _holdOpenSeats(
      hullId,
      productId,
      partySize,
      optionId: seatOptionId,
      uid: uid,
    );
    if (!held) {
      return false;
    }
    final id = _bookings(uid).doc().id;
    final booking = TourBooking(
      id: id,
      uid: uid,
      shopId: hullId,
      shopName: shopName,
      productName: productName,
      productId: productId ?? '',
      optionId: optionId,
      optionName: optionName,
      listingKind: listingKind,
      fromFlag: fromFlag,
      price: price,
      createdAt: DateTime.now(),
      tourDate: tourDate ?? DateTime.now().add(const Duration(days: 7)),
      status: status,
      paymentStatus: paymentStatus,
      commissionRate: RefundPolicy.defaultCommissionRate,
      partySize: partySize,
      divers: divers,
      nondivers: nondivers,
      children: children,
      infants: infants,
      quoteLines: quoteLines,
    );
    final payload = _bookingPayload(booking);
    payload['created_at'] = FieldValue.serverTimestamp();
    await _bookings(uid).doc(id).set(payload);
    await _shopBookings(booking.shopId).doc(id).set(payload);
    return true;
  }

  Future<bool> _holdOpenSeats(
    String shopId,
    String? productId,
    int partySize, {
    String optionId = '',
    String uid = '',
  }) async {
    if (productId == null || productId.isEmpty || partySize <= 0) {
      return true;
    }
    final ref = _shops.doc(shopId);
    final snap = await ref.get();
    final current = ShopProduct.listFrom(shopId, snap.data()?['products']);
    ShopProduct? target;
    for (final item in current) {
      if (item.id == productId) {
        target = item;
        break;
      }
    }
    if (target == null) {
      return false;
    }
    var opens = target.openEmptySeats;
    if (optionId.isNotEmpty) {
      opens = false;
      for (final option in target.options) {
        if (option.id == optionId) {
          opens = option.openEmptySeats;
          break;
        }
      }
    }
    if (!opens) {
      return true;
    }
    final before = target.bookedSeatsFor(optionId);
    final captured = target.capturePayment(
      partySize,
      DateTime.now(),
      uid: uid,
      optionId: optionId,
    );
    if (captured.bookedSeatsFor(optionId) <= before) {
      return false;
    }
    await ref.set({
      'products': [
        for (final item in current)
          if (item.id == productId) captured.toMap() else item.toMap(),
      ],
    }, SetOptions(merge: true));
    return true;
  }

  @override
  Future<void> plantSeatFlag({
    required String shopId,
    required String productId,
    required int partySize,
    required DateTime now,
    String optionId = '',
    String uid = '',
  }) async {
    final hull = shopId.split('--').first;
    final ref = _shops.doc(hull);
    final snap = await ref.get();
    final current = ShopProduct.listFrom(hull, snap.data()?['products']);
    final next = [
      for (final item in current)
        if (item.id == productId)
          item.plantFlag(
            partySize: partySize,
            now: now,
            optionId: optionId,
            uid: uid,
          )
        else
          item,
    ];
    await ref.set({
      'products': [for (final item in next) item.toMap()],
    }, SetOptions(merge: true));
  }

  @override
  Future<OperationReviewOutcome> submitOperationReview({
    required String uid,
    required String shopId,
    required int safety,
    required int guide,
    required int boat,
    String? bookingId,
    String? logId,
    String? productId,
    String? optionId,
    String? comment,
    String? authorDisplayName,
    ReviewDetails? details,
  }) async {
    final resolvedBookingId = bookingId?.trim() ?? '';
    if (resolvedBookingId.isEmpty) {
      throw const ReviewValidationException(ReviewValidationCode.bookingRequired);
    }
    final safeSafety = OperationReviewPolicy.clampStars(safety);
    final safeGuide = OperationReviewPolicy.clampStars(guide);
    final safeBoat = OperationReviewPolicy.clampStars(boat);
    OperationReviewPolicy.assertStarsInRange(safeSafety, safeGuide, safeBoat);
    final safeComment = OperationReviewPolicy.normalizeComment(comment);
    final safeDetails = OperationReviewPolicy.normalizeDetails(details);

    final shop = DiveShopCatalog.byId(shopId);
    final shopRef = _shops.doc(shopId);
    final reviewRef = shopRef.collection('reviews').doc();
    final userReviewRef = _userDoc(uid).collection('reviews').doc(reviewRef.id);
    final bookingRef = _bookings(uid).doc(resolvedBookingId);
    final passedProductId = productId?.trim() ?? '';
    final passedOptionId = optionId?.trim() ?? '';
    final publicName = authorDisplayName?.trim();

    late OperationReviewOutcome outcome;
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(shopRef);
      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) {
        throw const ReviewValidationException(
          ReviewValidationCode.bookingNotFound,
        );
      }
      final booking = _toBooking(bookingSnap.id, bookingSnap.data() ?? {});
      OperationReviewPolicy.requireEligibleBooking(
        bookingId: resolvedBookingId,
        bookings: [booking],
        uid: uid,
        shopId: shopId,
      );

      final data = snapshot.data() ?? {};
      final count = (data['review_count'] as num?)?.toInt() ?? 0;
      final nextCount = count + 1;
      final sumSafety =
          ((data['sum_safety'] as num?)?.toDouble() ?? 0) + safeSafety;
      final sumGuide =
          ((data['sum_guide'] as num?)?.toDouble() ?? 0) + safeGuide;
      final sumBoat = ((data['sum_boat'] as num?)?.toDouble() ?? 0) + safeBoat;
      final avgSafety = sumSafety / nextCount;
      final avgGuide = sumGuide / nextCount;
      final avgBoat = sumBoat / nextCount;
      final avgOverall = DiveStar.overall(
        safety: avgSafety,
        guide: avgGuide,
        boat: avgBoat,
      );
      final guestStars =
          ((safeSafety + safeGuide + safeBoat) / 3).round().clamp(1, 5);
      final productKey = passedProductId.isNotEmpty
          ? passedProductId
          : (booking.productId.isNotEmpty ? booking.productId : '');
      final optionKey = passedOptionId.isNotEmpty
          ? passedOptionId
          : booking.optionId.trim();

      List<Map<String, dynamic>>? nextProducts;
      var link = ReviewProductLinkStatus.missingProductId;
      if (productKey.isEmpty) {
        link = ReviewProductLinkStatus.missingProductId;
      } else {
        final products = ShopProduct.listFrom(shopId, data['products']);
        var found = false;
        nextProducts = [
          for (final item in products)
            if (item.id == productKey)
              () {
                found = true;
                return item
                    .withGuestStarReview(guestStars, optionId: optionKey)
                    .toMap();
              }()
            else
              item.toMap(),
        ];
        link = found
            ? ReviewProductLinkStatus.linked
            : ReviewProductLinkStatus.productNotFound;
      }
      outcome = OperationReviewOutcome(
        productLink: link,
        productId: productKey,
      );

      final review = <String, dynamic>{
        'uid': uid,
        'shop_id': shopId,
        'safety': safeSafety,
        'guide': safeGuide,
        'boat': safeBoat,
        'overall': (safeSafety + safeGuide + safeBoat) / 3,
        'comment': ?safeComment,
        'booking_id': resolvedBookingId,
        'log_id': ?logId,
        if (productKey.isNotEmpty) 'product_id': productKey,
        if (optionKey.isNotEmpty) 'option_id': optionKey,
        if (publicName != null && publicName.isNotEmpty)
          'author_display_name': publicName,
        ...safeDetails.toFirestoreFields(),
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
        // Do not write dive_star / dive_star_grade here — admin assigns grade.
        'safety_pass': avgSafety >= DiveStar.safetyPassThreshold,
        'products': ?nextProducts,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.set(bookingRef, {
        'reviewed': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    await _bumpActivityAndMaybeUpgrade(uid: uid, reviewDelta: 1);
    return outcome;
  }

  @override
  Future<GuestReviewsPage> fetchShopReviewsPage({
    required String shopId,
    int limit = 10,
    Object? cursor,
  }) async {
    final pageSize = limit < 1 ? 10 : limit;
    Query<Map<String, dynamic>> query = _shops
        .doc(shopId)
        .collection('reviews')
        .orderBy('created_at', descending: true)
        .limit(pageSize + 1);
    if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }
    final snap = await query.get();
    final docs = snap.docs;
    final hasMore = docs.length > pageSize;
    final pageDocs = hasMore ? docs.sublist(0, pageSize) : docs;
    return GuestReviewsPage(
      reviews: [
        for (final doc in pageDocs) GuestReview.fromMap(doc.id, doc.data()),
      ],
      hasMore: hasMore,
      cursor: pageDocs.isEmpty ? null : pageDocs.last,
    );
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
    for (final comment in CommunityPostCatalog.seedComments) {
      batch.delete(
        _posts.doc(comment.postId).collection('comments').doc(comment.id),
      );
      writes += 1;
    }
    for (final post in CommunityPostCatalog.seeds) {
      batch.delete(_posts.doc(post.id));
      writes += 1;
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
    final owned = (data['owned_shop_id'] as String?)?.trim() ??
        (data['ownedShopId'] as String?)?.trim() ??
        '';
    final business = data['is_business'] == true ||
        data['isBusiness'] == true ||
        owned.isNotEmpty;
    DateTime? createdAt;
    final createdRaw = data['created_at'];
    if (createdRaw is Timestamp) {
      createdAt = createdRaw.toDate();
    }
    DateTime? lastSeenAt;
    final seenRaw = data['last_seen_at'];
    if (seenRaw is Timestamp) {
      lastSeenAt = seenRaw.toDate();
    }
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
      isBusiness: business,
      ownedShopId: owned,
      paidPurchaseCount: (data['paid_purchase_count'] as num?)?.toInt() ?? 0,
      reviewCount: (data['review_count'] as num?)?.toInt() ?? 0,
      gradeLocked: data['member_grade_locked'] == true,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt,
    );
  }

  Future<void> _bumpActivityAndMaybeUpgrade({
    required String uid,
    int purchaseDelta = 0,
    int reviewDelta = 0,
  }) async {
    if (uid.isEmpty || (purchaseDelta == 0 && reviewDelta == 0)) {
      return;
    }
    final ref = _userDoc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final purchases =
          ((data['paid_purchase_count'] as num?)?.toInt() ?? 0) +
          purchaseDelta;
      final reviews =
          ((data['review_count'] as num?)?.toInt() ?? 0) + reviewDelta;
      final locked = data['member_grade_locked'] == true;
      final current = MemberGrade.parse(
        data['member_grade'] ?? data['memberGrade'],
      );
      final earned = MemberGrade.fromActivity(
        paidPurchases: purchases,
        reviews: reviews,
      );
      final patch = <String, dynamic>{
        'paid_purchase_count': purchases,
        'review_count': reviews,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (!locked && earned.rank > current.rank) {
        patch['member_grade'] = earned.firestoreValue;
        patch['grade_celebration_pending'] = true;
        patch['grade_celebration_to'] = earned.firestoreValue;
      }
      tx.set(ref, patch, SetOptions(merge: true));
    });
  }

  @override
  Stream<List<MemberAccount>> watchMembers() {
    return _users.snapshots().map((snapshot) {
      final members = [for (final doc in snapshot.docs) _toMemberAccount(doc)];
      members.sort((a, b) => a.displayName.compareTo(b.displayName));
      return members;
    });
  }

  @override
  Future<void> setMemberGrade({
    required String uid,
    required MemberGrade grade,
  }) async {
    final snap = await _userDoc(uid).get();
    final current = MemberGrade.parse(
      snap.data()?['member_grade'] ?? snap.data()?['memberGrade'],
    );
    final patch = <String, dynamic>{
      'member_grade': grade.firestoreValue,
      'member_grade_locked': true,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (grade.rank > current.rank) {
      patch['grade_celebration_pending'] = true;
      patch['grade_celebration_to'] = grade.firestoreValue;
    }
    await _userDoc(uid).set(patch, SetOptions(merge: true));
  }

  @override
  Future<void> unlockMemberGrade(String uid) {
    return _userDoc(uid).set({
      'member_grade_locked': false,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> touchLastSeen(String uid) {
    if (uid.isEmpty) {
      return Future.value();
    }
    return _userDoc(uid).set({
      'last_seen_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> clearGradeCelebration(String uid) {
    return _userDoc(uid).set({
      'grade_celebration_pending': false,
      'grade_celebration_to': FieldValue.delete(),
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
  Future<void> setInternalScore({
    required String shopId,
    required int score,
  }) {
    final clamped = score.clamp(0, 100);
    final shop = DiveShopCatalog.byId(shopId);
    return _shops.doc(shopId).set({
      'name': shop?.name ?? shopId,
      'location': shop?.location,
      'internal_score': clamped,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setDiveStarGrade({
    required String shopId,
    required int grade,
    required DateTime reviewedAt,
    required DateTime expiresAt,
  }) {
    final clamped = DiveStar.clampGrade(grade);
    final shop = DiveShopCatalog.byId(shopId);
    return _shops.doc(shopId).set({
      'name': shop?.name ?? shopId,
      'location': shop?.location,
      'dive_star_grade': clamped,
      'dive_star_reviewed_at': Timestamp.fromDate(reviewedAt.toUtc()),
      'dive_star_expires_at': Timestamp.fromDate(expiresAt.toUtc()),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  CollectionReference<Map<String, dynamic>> get _diveStarForms =>
      _db.collection('dive_star_forms');

  CollectionReference<Map<String, dynamic>> _diveStarAssessments(String shopId) =>
      _shops.doc(shopId).collection('dive_star_assessments');

  @override
  Future<DiveStarForm> ensureActiveDiveStarForm() async {
    final active = await _diveStarForms
        .where('active', isEqualTo: true)
        .limit(1)
        .get();
    if (active.docs.isNotEmpty) {
      final doc = active.docs.first;
      return DiveStarForm.fromDocument(doc.id, doc.data());
    }
    final v1Ref = _diveStarForms.doc('v1');
    final existing = await v1Ref.get();
    if (existing.exists && existing.data() != null) {
      return DiveStarForm.fromDocument(existing.id, existing.data()!);
    }
    final seed = DiveStarForm.v1();
    await v1Ref.set(seed.toMap());
    return seed;
  }

  @override
  Future<DiveStarForm?> getDiveStarForm(String version) async {
    final id = version.trim();
    if (id.isEmpty) {
      return null;
    }
    final snap = await _diveStarForms.doc(id).get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      return null;
    }
    return DiveStarForm.fromDocument(snap.id, data);
  }

  @override
  Future<List<DiveStarForm>> listDiveStarForms() async {
    final snap = await _diveStarForms.get();
    final list = [
      for (final doc in snap.docs)
        DiveStarForm.fromDocument(doc.id, doc.data()),
    ];
    list.sort((a, b) => a.version.compareTo(b.version));
    return list;
  }

  @override
  Future<DiveStarForm> importDiveStarFormDraft(DiveStarForm form) async {
    final id = form.version.trim();
    if (id.isEmpty) {
      throw StateError('Form version is required');
    }
    final ref = _diveStarForms.doc(id);
    final existing = await ref.get();
    if (existing.exists) {
      throw StateError('Form version already exists: $id');
    }
    final draft = DiveStarForm(
      version: id,
      active: false,
      status: DiveStarFormStatus.draft,
      rules: form.rules,
      gates: form.gates,
      areas: form.areas,
      items: form.items,
      thresholds: form.thresholds,
    );
    await ref.set({
      ...draft.toMap(),
      'updated_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });
    return draft;
  }

  Map<String, int> _clampScores(DiveStarForm form, Map<String, int> scores) {
    return {
      for (final area in form.areas)
        area.id: (scores[area.id] ?? 0).clamp(0, area.maxPoints),
    };
  }

  @override
  Future<List<DiveStarAssessment>> listDiveStarAssessments(String shopId) async {
    final snap = await _diveStarAssessments(shopId)
        .orderBy('reviewed_at', descending: true)
        .get();
    return [
      for (final doc in snap.docs)
        DiveStarAssessment.fromDocument(doc.id, shopId, doc.data()),
    ];
  }

  @override
  Future<DiveStarAssessment> saveDiveStarAssessment({
    required String shopId,
    String? assessmentId,
    required DiveStarAssessmentType type,
    required DateTime reviewedAt,
    required Map<String, bool> gates,
    required Map<String, int> scores,
    required Map<String, String> comments,
  }) async {
    final form = await ensureActiveDiveStarForm();
    final clampedScores = _clampScores(form, scores);
    final gateMap = {
      for (final gate in form.gates) gate.id: gates[gate.id] == true,
    };
    final result = DiveStarScoring.evaluate(
      form: form,
      gates: gateMap,
      scores: clampedScores,
    );
    final updating = assessmentId != null && assessmentId.isNotEmpty;
    final ref = updating
        ? _diveStarAssessments(shopId).doc(assessmentId)
        : _diveStarAssessments(shopId).doc();
    if (updating) {
      final existing = await ref.get();
      if (!existing.exists || existing.data() == null) {
        throw StateError('Assessment not found: $assessmentId');
      }
      if (existing.data()!['confirmed'] == true) {
        throw StateError('Confirmed assessments cannot be edited');
      }
    }
    final payload = <String, dynamic>{
      'form_version': form.version,
      'type': type.firestoreValue,
      'reviewed_at': Timestamp.fromDate(reviewedAt.toUtc()),
      'gates': gateMap,
      'scores': clampedScores,
      'comments': {
        for (final entry in comments.entries)
          if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
      },
      'total_score': result.totalScore,
      'candidate_grade': result.candidateGrade,
      'gates_passed': result.gatesPassed,
      'confirmed': false,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (!updating) {
      payload['created_at'] = FieldValue.serverTimestamp();
    }
    await ref.set(payload, SetOptions(merge: true));
    final saved = await ref.get();
    return DiveStarAssessment.fromDocument(
      ref.id,
      shopId,
      saved.data() ?? payload,
    );
  }

  @override
  Future<DiveStarAssessment> confirmDiveStarAssessment({
    required String shopId,
    required String assessmentId,
    DateTime? expiresAt,
  }) async {
    final ref = _diveStarAssessments(shopId).doc(assessmentId);
    final snap = await ref.get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      throw StateError('Assessment not found: $assessmentId');
    }
    final assessment = DiveStarAssessment.fromDocument(assessmentId, shopId, data);
    if (assessment.confirmed) {
      throw StateError('Assessment already confirmed');
    }
    final expires = expiresAt ??
        assessment.reviewedAt.toUtc().add(const Duration(days: 365));
    await setDiveStarGrade(
      shopId: shopId,
      grade: assessment.candidateGrade,
      reviewedAt: assessment.reviewedAt,
      expiresAt: expires,
    );
    final confirmedAt = DateTime.now().toUtc();
    await ref.set({
      'confirmed': true,
      'confirmed_at': Timestamp.fromDate(confirmedAt),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return assessment.copyWith(confirmed: true, confirmedAt: confirmedAt);
  }

  @override
  Future<void> deleteDiveStarAssessment({
    required String shopId,
    required String assessmentId,
  }) async {
    final ref = _diveStarAssessments(shopId).doc(assessmentId);
    final snap = await ref.get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      throw StateError('Assessment not found: $assessmentId');
    }
    if (data['confirmed'] == true) {
      throw StateError('Confirmed assessments cannot be deleted');
    }
    await ref.delete();
  }

  CollectionReference<Map<String, dynamic>> get _partnerDocuments =>
      _db.collection('partner_documents');

  CollectionReference<Map<String, dynamic>> get _documentShares =>
      _db.collection('document_shares');

  DocumentReference<Map<String, dynamic>> get _partnerDocConfig =>
      _db.collection('partner_doc_config').doc('default');

  @override
  Future<List<PartnerDocument>> ensurePartnerDocumentsSeeded() async {
    final existing = await _partnerDocuments.limit(20).get();
    if (existing.docs.isEmpty) {
      final batch = _db.batch();
      for (final seed in PartnerDocument.phase1Seeds()) {
        batch.set(_partnerDocuments.doc(seed.id), {
          ...seed.toMap(),
          'updated_at': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
    final snap = await _partnerDocuments.get();
    final list = [
      for (final doc in snap.docs)
        PartnerDocument.fromDocument(doc.id, doc.data()),
    ];
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  @override
  Future<List<PartnerDocument>> listApprovedPublicPartnerDocuments() async {
    final snap = await _partnerDocuments
        .where('audience', isEqualTo: 'public')
        .where('status', isEqualTo: 'approved')
        .get();
    final list = [
      for (final doc in snap.docs)
        PartnerDocument.fromDocument(doc.id, doc.data()),
    ];
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  @override
  Future<PartnerDocConfig> ensurePartnerDocConfig() async {
    final snap = await _partnerDocConfig.get();
    if (!snap.exists || snap.data() == null) {
      final seed = PartnerDocConfig.defaultConfig;
      await _partnerDocConfig.set({
        ...seed.toMap(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return seed;
    }
    return PartnerDocConfig.fromDocument(snap.data()!);
  }

  @override
  Future<void> savePartnerDocConfig(PartnerDocConfig config) {
    return _partnerDocConfig.set({
      ...config.toMap(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updatePartnerDocumentStatus({
    required String documentId,
    required PartnerDocStatus status,
  }) {
    return _partnerDocuments.doc(documentId).set({
      'status': status.firestoreValue,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<DocumentShareRecord>> listDocumentShares({int limit = 50}) async {
    final snap = await _documentShares
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in snap.docs)
        DocumentShareRecord.fromDocument(doc.id, doc.data()),
    ];
  }

  @override
  Future<DocumentShareRecord> recordDocumentShare({
    required String documentId,
    required String documentTitle,
    required String shopId,
    required String shopName,
    required PartnerDocShareMethod method,
    required String adminUid,
  }) async {
    final ref = _documentShares.doc();
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'document_id': documentId,
      'document_title': documentTitle,
      'shop_id': shopId,
      'shop_name': shopName,
      'method': method.firestoreValue,
      'admin_uid': adminUid,
      'created_at': Timestamp.fromDate(now),
    };
    await ref.set(payload);
    return DocumentShareRecord.fromDocument(ref.id, {
      ...payload,
      'created_at': now.toIso8601String(),
    });
  }

  CollectionReference<Map<String, dynamic>> get _diveStarApplications =>
      _db.collection('dive_star_applications');

  CollectionReference<Map<String, dynamic>> get _partnerEmailOutbox =>
      _db.collection('partner_email_outbox');

  @override
  Future<DiveStarApplication> submitDiveStarApplication({
    required String shopId,
    required String shopName,
    required String partnerUid,
    required String companyName,
    required String contactName,
    required String contactEmail,
    required String contactPhone,
    required String country,
    required String notes,
    required String signaturePngBase64,
  }) async {
    final ref = _diveStarApplications.doc();
    final now = DateTime.now().toUtc();
    final reminder = now.add(const Duration(days: 14));
    final payload = <String, dynamic>{
      'shop_id': shopId,
      'shop_name': shopName,
      'partner_uid': partnerUid,
      'company_name': companyName.trim(),
      'contact_name': contactName.trim(),
      'contact_email': contactEmail.trim(),
      'contact_phone': contactPhone.trim(),
      'country': country.trim(),
      'notes': notes.trim(),
      'signature_png_base64': signaturePngBase64,
      'pipeline_status': DiveStarPipelineStatus.loiReceived.firestoreValue,
      'submitted_at': Timestamp.fromDate(now),
      'reminder_due_at': Timestamp.fromDate(reminder),
      'updated_at': FieldValue.serverTimestamp(),
    };
    await ref.set(payload);
    return DiveStarApplication.fromDocument(ref.id, {
      ...payload,
      'submitted_at': now.toIso8601String(),
      'reminder_due_at': reminder.toIso8601String(),
    });
  }

  @override
  Future<List<DiveStarApplication>> listDiveStarApplications({
    String? shopId,
    String? partnerUid,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _diveStarApplications;
    if (partnerUid != null && partnerUid.isNotEmpty) {
      query = query.where('partner_uid', isEqualTo: partnerUid);
    } else if (shopId != null && shopId.isNotEmpty) {
      query = query.where('shop_id', isEqualTo: shopId);
    }
    final snap =
        await query.orderBy('submitted_at', descending: true).limit(limit).get();
    return [
      for (final doc in snap.docs)
        DiveStarApplication.fromDocument(doc.id, doc.data()),
    ];
  }

  @override
  Future<DiveStarApplication> updateDiveStarApplicationPipeline({
    required String applicationId,
    required DiveStarPipelineStatus status,
    DateTime? reminderDueAt,
    bool clearReminder = false,
  }) async {
    final ref = _diveStarApplications.doc(applicationId);
    final payload = <String, dynamic>{
      'pipeline_status': status.firestoreValue,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (clearReminder) {
      payload['reminder_due_at'] = FieldValue.delete();
    } else if (reminderDueAt != null) {
      payload['reminder_due_at'] = Timestamp.fromDate(reminderDueAt.toUtc());
    }
    await ref.set(payload, SetOptions(merge: true));
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) {
      throw StateError('Application not found: $applicationId');
    }
    return DiveStarApplication.fromDocument(applicationId, data);
  }

  @override
  Future<PartnerEmailOutboxItem> queuePartnerEmail({
    required String toEmail,
    required String subject,
    required String body,
    String applicationId = '',
    String shopId = '',
  }) async {
    final ref = _partnerEmailOutbox.doc();
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'to_email': toEmail.trim(),
      'subject': subject.trim(),
      'body': body.trim(),
      'status': 'pending',
      'created_at': Timestamp.fromDate(now),
      'application_id': applicationId,
      'shop_id': shopId,
    };
    await ref.set(payload);
    return PartnerEmailOutboxItem.fromDocument(ref.id, {
      ...payload,
      'created_at': now.toIso8601String(),
    });
  }

  @override
  Future<List<PartnerEmailOutboxItem>> listPartnerEmailOutbox({
    int limit = 30,
  }) async {
    final snap = await _partnerEmailOutbox
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in snap.docs)
        PartnerEmailOutboxItem.fromDocument(doc.id, doc.data()),
    ];
  }

  @override
  Future<void> markPartnerEmailOutboxSent(String outboxId) {
    return _partnerEmailOutbox.doc(outboxId).set({
      'status': 'sent',
      'sent_at': FieldValue.serverTimestamp(),
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
    String? country,
    String? continent,
    bool? curated,
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
      galleryUrls = await uploadGallerySlots(
        gallery: gallery,
        keyPrefix: 'shops/$shopId/gallery',
        upload: _photos.upload,
      );
      coverUrl = galleryUrls.isEmpty ? null : galleryUrls.first;
    } else if (coverBytes != null && coverBytes.isNotEmpty) {
      final extension = _photoExtension(coverFileName);
      coverUrl = await _photos.upload(
        objectKey: 'shops/$shopId/cover$extension',
        bytes: coverBytes,
        contentType: coverContentType ?? 'image/jpeg',
        requirePublicUrl: true,
      );
    }

    final ref = _shops.doc(shopId);
    final existing = await ref.get();
    final currentProducts = ShopProduct.listFrom(
      shopId,
      existing.data()?['products'],
    );
    // Keep listing cards in sync: desk price edits used to update only the
    // shop doc while Explore/Home still read the stale products[] prices.
    final syncedProducts = currentProducts.isEmpty
        ? currentProducts
        : [
            for (var i = 0; i < currentProducts.length; i++)
              i == 0
                  ? currentProducts[i].copyWith(
                      name: productName.trim().isEmpty
                          ? currentProducts[i].name
                          : productName.trim(),
                      consumerPrice: consumerPrice,
                      professionalPrice: professionalPrice,
                    )
                  : currentProducts[i],
          ];

    await ref.set({
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
      'country': (country ?? catalog?.country)?.trim(),
      'continent': (continent ?? catalog?.continent)?.trim(),
      if (curated != null) 'curated': curated,
      if (syncedProducts.isNotEmpty)
        'products': [for (final item in syncedProducts) item.toMap()],
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
    List<ShopGallerySlot>? gallery,
  }) async {
    var saved = product;
    // Upload first so we never persist a product that looks saved without a
    // durable cover URL (local memory cache used to fake success briefly).
    if (gallery != null) {
      final urls = await uploadGallerySlots(
        gallery: gallery,
        keyPrefix: 'shops/$shopId/products/${product.id}/gallery',
        upload: _photos.upload,
      );
      saved = product.copyWith(
        photoUrls: urls,
        coverUrl: urls.isEmpty ? '' : urls.first,
      );
    } else if (photoBytes != null && photoBytes.isNotEmpty) {
      final extension = _photoExtension(photoFileName);
      final url = await _photos.upload(
        objectKey: 'shops/$shopId/products/${product.id}$extension',
        bytes: photoBytes,
        contentType: photoContentType ?? 'image/jpeg',
        requirePublicUrl: true,
      );
      saved = product.copyWith(coverUrl: url);
    }
    final ref = _shops.doc(shopId);
    final snap = await ref.get();
    final current = <String, ShopProduct>{
      for (final parsed in ShopProduct.listFrom(
        shopId,
        snap.data()?['products'],
      ))
        parsed.id: parsed,
    };
    // Keep an existing cover if the edit omitted bytes/url (avoids wiping R2).
    // An explicit gallery, even an empty one, is the new photo list.
    final previous = current[saved.id];
    if (gallery == null &&
        saved.coverUrl.isEmpty &&
        previous != null &&
        previous.coverUrl.isNotEmpty) {
      saved = saved.copyWith(coverUrl: previous.coverUrl);
    }
    current[saved.id] = saved;
    final next = current.values.toList();
    final coverForShop = saved.coverUrl.isNotEmpty
        ? saved.coverUrl
        : (snap.data()?['cover_url'] as String? ?? '');
    await ref.set({
      'products': [for (final item in next) item.toMap()],
      'product_name': saved.name,
      'consumer_price': saved.consumerPrice,
      'professional_price': saved.professionalPrice,
      // Always mirror a durable product cover onto the shop so Explore/Home
      // cards keep a photo even when nested product maps fail to parse.
      if (coverForShop.isNotEmpty &&
          (useAsResortCover ||
              photoBytes != null ||
              (snap.data()?['cover_url'] as String?)?.isNotEmpty != true)) ...{
        'cover_url': coverForShop,
        'gallery_urls': [
          coverForShop,
          for (final item
              in (snap.data()?['gallery_urls'] as List<dynamic>? ?? const []))
            if (item is String &&
                item.trim().isNotEmpty &&
                item.trim() != coverForShop)
              item.trim(),
        ],
      },
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteShopProduct({
    required String shopId,
    required String productId,
  }) async {
    final ref = _shops.doc(shopId);
    final snap = await ref.get();
    final current = ShopProduct.listFrom(shopId, snap.data()?['products']);
    final next = [
      for (final item in current)
        if (item.id != productId) item,
    ];
    await ref.set({
      'products': [for (final item in next) item.toMap()],
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setShopProductPublishStatus({
    required String shopId,
    required String productId,
    required ProductPublishStatus status,
    String reviewNote = '',
  }) async {
    final ref = _shops.doc(shopId);
    final snap = await ref.get();
    final current = ShopProduct.listFrom(shopId, snap.data()?['products']);
    final next = [
      for (final item in current)
        if (item.id == productId)
          item.copyWith(
            publishStatus: status,
            active: status == ProductPublishStatus.approved,
            reviewedAt: DateTime.now(),
            reviewNote: reviewNote,
          )
        else
          item,
    ];
    await ref.set({
      'products': [for (final item in next) item.toMap()],
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setShopProductListingKind({
    required String shopId,
    required String productId,
    required ProductListingKind listingKind,
  }) async {
    final ref = _shops.doc(shopId);
    final snap = await ref.get();
    final current = ShopProduct.listFrom(shopId, snap.data()?['products']);
    final now = DateTime.now();
    final next = [
      for (final item in current)
        if (item.id == productId)
          item.copyWith(
            listingKind: listingKind,
            featuredAt: listingKind.isHomeShelf ? now : null,
          )
        else
          item,
    ];
    await ref.set({
      'products': [for (final item in next) item.toMap()],
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
    final nextPayment = !booking.isPaid
        ? PaymentStatus.unpaid
        : (quote.percent > 0 ? PaymentStatus.refunded : PaymentStatus.captured);
    final patch = {
      'status': BookingStatus.cancelled.firestoreValue,
      'refund_percent': quote.percent,
      'refund_amount': quote.amountFor(booking.price),
      'payment_status': nextPayment.firestoreValue,
      'cancelled_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    await userRef.set(patch, SetOptions(merge: true));
    await _shopBookings(booking.shopId)
        .doc(bookingId)
        .set(patch, SetOptions(merge: true));
  }

  @override
  Future<bool> confirmShopBooking({
    required String shopId,
    required String bookingId,
  }) async {
    final shopRef = _shopBookings(shopId).doc(bookingId);
    final snap = await shopRef.get();
    if (!snap.exists) {
      return false;
    }
    final booking = _toBooking(snap.id, snap.data() ?? {});
    if (!booking.awaitsShopConfirm) {
      return false;
    }
    final patch = {
      'status': BookingStatus.confirmed.firestoreValue,
      'payment_status': PaymentStatus.captured.firestoreValue,
      'confirmed_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    await shopRef.set(patch, SetOptions(merge: true));
    if (booking.uid.isNotEmpty) {
      await _bookings(booking.uid)
          .doc(bookingId)
          .set(patch, SetOptions(merge: true));
      await _bumpActivityAndMaybeUpgrade(
        uid: booking.uid,
        purchaseDelta: 1,
      );
    }
    return true;
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
        'payment_status': booking.isPaid
            ? PaymentStatus.refunded.firestoreValue
            : PaymentStatus.unpaid.firestoreValue,
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
