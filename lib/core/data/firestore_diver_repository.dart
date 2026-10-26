import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:dive_travel_app/core/auth/pending_profile.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/constants/nationality.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_repository.dart';
import 'package:dive_travel_app/core/data/member_profile_repair.dart';
import 'package:dive_travel_app/core/data/diver_snapshot.dart';
import 'package:dive_travel_app/core/models/same_boat_alert.dart';
import 'package:dive_travel_app/core/models/seat_demand.dart';
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
import 'package:dive_travel_app/core/models/partner_contract.dart';
import 'package:dive_travel_app/core/models/partner_contract_terms.dart';
import 'package:dive_travel_app/core/models/partner_application.dart';
import 'package:dive_travel_app/core/models/partner_promotion.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/core/models/active_seat_flag.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/review_detail_options.dart';
import 'package:dive_travel_app/core/models/product_publish_guard.dart';
import 'package:dive_travel_app/core/models/product_change.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';
import 'package:dive_travel_app/core/models/shop_day_stats.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/models/trial_data_cleanup.dart';
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
    String? loginId,
    String? nationality,
    String? birthDate,
    String? phone,
    bool termsAccepted = false,
    bool privacyAccepted = false,
    bool marketingOptIn = false,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      return;
    }
    await _finishNewUser(
      user,
      email: email,
      displayName: displayName,
      loginId: loginId,
      nationality: nationality,
      birthDate: birthDate,
      phone: phone,
      termsAccepted: termsAccepted,
      privacyAccepted: privacyAccepted,
      marketingOptIn: marketingOptIn,
    );
  }

  Future<void> _finishNewUser(
    User user, {
    required String email,
    required String? displayName,
    String? loginId,
    String? nationality,
    String? birthDate,
    String? phone,
    bool termsAccepted = false,
    bool privacyAccepted = false,
    bool marketingOptIn = false,
  }) async {
    final name = AppOwner.resolveDisplayName(
      email: user.email ?? email,
      displayName: displayName,
    );
    await user.updateDisplayName(name);
    await user.reload();
    final refreshed = _auth.currentUser ?? user;
    try {
      await ensureUserDocument(
        AppUser(uid: refreshed.uid, email: refreshed.email, displayName: name),
        loginId: loginId,
        nationality: nationality,
        birthDate: birthDate,
        phone: phone,
        termsAccepted: termsAccepted,
        privacyAccepted: privacyAccepted,
        marketingOptIn: marketingOptIn,
      );
    } catch (error) {
      final code = error is FirebaseException ? error.code : 'unknown';
      throw ProfileWriteException(uid: refreshed.uid, code: code);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser?> currentAuthUser() async {
    final user = _auth.currentUser;
    return user == null ? null : _toAppUser(user);
  }

  @override
  Future<bool> isLoginBlocked(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return false;
    final data = snap.data() ?? {};
    return data['account_blocked'] == true || data['withdrawn_at'] != null;
  }

  @override
  Future<void> promoteMemberToPartner({
    required String uid,
    required String shopId,
    required String actorUid,
    required String actorName,
  }) async {
    final shop = shopId.trim();
    if (shop.isEmpty) {
      throw StateError('PARTNER_SHOP_REQUIRED');
    }
    final ref = _userDoc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final alreadyBusiness = data['is_business'] == true ||
          data['isBusiness'] == true ||
          ((data['owned_shop_id'] as String?)?.trim().isNotEmpty ?? false);
      if (alreadyBusiness) {
        throw StateError('ALREADY_PARTNER');
      }
      final history = _appendRoleHistory(
        existing: data['role_history'],
        entry: {
          'at': Timestamp.now(),
          'by_uid': actorUid,
          'by_name': actorName,
          'action': 'promote_partner',
          'from': {
            'is_business': false,
            'user_role': data['user_role'] ?? 'diver',
            'owned_shop_id': data['owned_shop_id'],
          },
          'to': {
            'is_business': true,
            'user_role': 'business',
            'owned_shop_id': shop,
          },
          'shop_id': shop,
        },
      );
      tx.set(
        ref,
        {
          'is_business': true,
          'user_role': 'business',
          'owned_shop_id': shop,
          'role_history': history,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> demoteMemberFromPartner({
    required String uid,
    required String actorUid,
    required String actorName,
  }) async {
    final ref = _userDoc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final wasBusiness = data['is_business'] == true ||
          data['isBusiness'] == true ||
          ((data['owned_shop_id'] as String?)?.trim().isNotEmpty ?? false);
      if (!wasBusiness) {
        throw StateError('NOT_PARTNER');
      }
      final previousShop =
          (data['owned_shop_id'] as String?)?.trim() ??
          (data['ownedShopId'] as String?)?.trim();
      final history = _appendRoleHistory(
        existing: data['role_history'],
        entry: {
          'at': Timestamp.now(),
          'by_uid': actorUid,
          'by_name': actorName,
          'action': 'demote_partner',
          'from': {
            'is_business': true,
            'user_role': data['user_role'] ?? 'business',
            'owned_shop_id': previousShop,
          },
          'to': {
            'is_business': false,
            'user_role': 'diver',
            'owned_shop_id': null,
          },
          'shop_id': previousShop,
        },
      );
      tx.set(
        ref,
        {
          'is_business': false,
          'user_role': 'diver',
          'owned_shop_id': FieldValue.delete(),
          'role_history': history,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<String> createEmptyShop({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw StateError('SHOP_NAME_REQUIRED');
    }
    final slug = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final base = slug.isEmpty ? 'shop' : slug;
    final shopId =
        '$base-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    await _shops.doc(shopId).set({
      'name': trimmed,
      'location': '',
      'product_name': '',
      'consumer_price': 0,
      'professional_price': 0,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return shopId;
  }

  Future<int?> _countQuery(Query<Map<String, dynamic>> query) async {
    try {
      final agg = await query.count().get();
      return agg.count;
    } catch (_) {
      return null;
    }
  }

  Future<JejuOrangeResolve> _resolveJejuOrange() async {
    final snap = await _shops.get();
    final exact = <({String id, String name})>[];
    final similar = <({String id, String name})>[];
    for (final doc in snap.docs) {
      final name = (doc.data()['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) {
        continue;
      }
      if (name == kJejuOrangeShopName) {
        exact.add((id: doc.id, name: name));
      } else if (name.contains('제주') && name.contains('오렌지')) {
        similar.add((id: doc.id, name: name));
      }
    }
    if (exact.length == 1 && similar.isEmpty) {
      return JejuOrangeResolve(
        kind: JejuOrangeResolveKind.exactOne,
        shopId: exact.first.id,
        shopName: exact.first.name,
        candidates: exact,
      );
    }
    if (exact.length == 1 && similar.isNotEmpty) {
      // Exact match wins if only one exact; similar listed for awareness.
      return JejuOrangeResolve(
        kind: JejuOrangeResolveKind.exactOne,
        shopId: exact.first.id,
        shopName: exact.first.name,
        candidates: [...exact, ...similar],
      );
    }
    if (exact.length > 1 || (exact.isEmpty && similar.length > 1)) {
      return JejuOrangeResolve(
        kind: JejuOrangeResolveKind.ambiguous,
        candidates: [...exact, ...similar],
      );
    }
    if (exact.isEmpty && similar.length == 1) {
      // Do not auto-protect similar-only; treat as ambiguous/list for safety.
      return JejuOrangeResolve(
        kind: JejuOrangeResolveKind.ambiguous,
        candidates: similar,
      );
    }
    return const JejuOrangeResolve(kind: JejuOrangeResolveKind.none);
  }

  @override
  Future<TrialDataSnapshot> fetchTrialDataCounts({
    required String actorUid,
    required String actorEmail,
  }) async {
    final jeju = await _resolveJejuOrange();
    final protectedShopId = jeju.protectedShopId;
    final protectedUids = <String>{actorUid};
    final usersSnap = await _users.get();
    for (final doc in usersSnap.docs) {
      final data = doc.data();
      final email = (data['email'] as String?)?.trim().toLowerCase() ?? '';
      final owned = (data['owned_shop_id'] as String?)?.trim() ?? '';
      if (AppOwner.isOwnerEmail(email) ||
          email == actorEmail.trim().toLowerCase() ||
          (protectedShopId != null && owned == protectedShopId)) {
        protectedUids.add(doc.id);
      }
    }

    Future<TrialCountRow> row({
      required TrialDataBucket bucket,
      required String label,
      required String pathHint,
      required Future<int?> Function() count,
      bool deletable = false,
      bool protected = false,
      String? unavailableReason,
      String? detail,
    }) async {
      if (unavailableReason != null) {
        return TrialCountRow(
          bucket: bucket,
          label: label,
          pathHint: pathHint,
          status: TrialCountStatus.unavailable,
          detail: unavailableReason,
          deletable: false,
          protected: protected,
        );
      }
      final value = await count();
      if (value == null) {
        return TrialCountRow(
          bucket: bucket,
          label: label,
          pathHint: pathHint,
          status: TrialCountStatus.error,
          detail: detail ?? 'count 실패',
          deletable: deletable,
          protected: protected,
        );
      }
      return TrialCountRow(
        bucket: bucket,
        label: label,
        pathHint: pathHint,
        status: TrialCountStatus.ok,
        count: value,
        detail: detail,
        deletable: deletable && !protected,
        protected: protected,
      );
    }

    final totalUsers = await _countQuery(_users);
    final adminUsers = await _countQuery(
      _users.where('is_admin', isEqualTo: true),
    );
    final partnerUsers = await _countQuery(
      _users.where('is_business', isEqualTo: true),
    );
    final diverGuess = (totalUsers != null &&
            adminUsers != null &&
            partnerUsers != null)
        ? (totalUsers - adminUsers - partnerUsers).clamp(0, totalUsers)
        : null;

    final rows = <TrialCountRow>[
      await row(
        bucket: TrialDataBucket.usersTotal,
        label: '회원 전체',
        pathHint: 'users',
        count: () async => totalUsers,
        deletable: true,
      ),
      await row(
        bucket: TrialDataBucket.usersAdmin,
        label: '관리자 회원',
        pathHint: 'users where is_admin',
        count: () async => adminUsers,
        protected: true,
      ),
      await row(
        bucket: TrialDataBucket.usersPartner,
        label: '제휴파트너 회원',
        pathHint: 'users where is_business',
        count: () async => partnerUsers,
        deletable: true,
      ),
      await row(
        bucket: TrialDataBucket.usersDiver,
        label: '일반회원(추정)',
        pathHint: 'users − admin − partner',
        count: () async => diverGuess,
        deletable: true,
        detail: '관리자·파트너와 겹칠 수 있음',
      ),
      await row(
        bucket: TrialDataBucket.shops,
        label: '샵',
        pathHint: 'shops',
        count: () => _countQuery(_shops),
        deletable: true,
      ),
      await row(
        bucket: TrialDataBucket.shopProductsEmbedded,
        label: '상품(임베디드)',
        pathHint: 'shops/*/products[]',
        count: () async => null,
        unavailableReason: '샵 문서 배열이라 count() 불가',
        protected: false,
      ),
      await row(
        bucket: TrialDataBucket.shopBookings,
        label: '샵 예약',
        pathHint: 'shops/*/bookings',
        count: () => _countQuery(_db.collectionGroup('bookings')),
        deletable: true,
        detail: 'collectionGroup(bookings) — 유저 예약과 합산될 수 있음',
      ),
      await row(
        bucket: TrialDataBucket.userBookings,
        label: '회원 예약 복사본',
        pathHint: 'users/*/bookings',
        count: () async => null,
        unavailableReason: 'shop bookings와 CG 구분 어려움 — 삭제 시 유저 하위만',
        deletable: true,
      ),
      await row(
        bucket: TrialDataBucket.shopReviews,
        label: '샵 후기',
        pathHint: 'shops/*/reviews',
        count: () => _countQuery(_db.collectionGroup('reviews')),
        deletable: true,
      ),
      await row(
        bucket: TrialDataBucket.userReviews,
        label: '회원 후기 복사본',
        pathHint: 'users/*/reviews',
        count: () async => null,
        unavailableReason: 'shop reviews와 CG 구분 어려움',
        deletable: true,
      ),
      await row(
        bucket: TrialDataBucket.partnerContracts,
        label: '서류함 계약',
        pathHint: 'shops/*/partner_contracts',
        count: () => _countQuery(_db.collectionGroup('partner_contracts')),
        protected: true,
        detail: '규칙상 삭제 불가 — Console 수동',
      ),
      await row(
        bucket: TrialDataBucket.partnerContractEvents,
        label: '서류함 이벤트',
        pathHint: '…/partner_contracts/*/events',
        count: () async => null,
        unavailableReason: '삭제 불가(규칙). Console 수동',
        protected: true,
      ),
      await row(
        bucket: TrialDataBucket.diveStarAssessments,
        label: '다이브스타 평가',
        pathHint: 'shops/*/dive_star_assessments',
        count: () =>
            _countQuery(_db.collectionGroup('dive_star_assessments')),
        deletable: true,
        detail: '미확정만 삭제 가능',
      ),
      await row(
        bucket: TrialDataBucket.posts,
        label: '커뮤니티 글',
        pathHint: 'posts',
        count: () => _countQuery(_posts),
        deletable: true,
      ),
      await row(
        bucket: TrialDataBucket.postComments,
        label: '커뮤니티 댓글',
        pathHint: 'posts/*/comments',
        count: () => _countQuery(_db.collectionGroup('comments')),
        deletable: true,
      ),
      await row(
        bucket: TrialDataBucket.diveStarApplications,
        label: 'LOI 신청',
        pathHint: 'dive_star_applications',
        count: () => _countQuery(_db.collection('dive_star_applications')),
        deletable: true,
      ),
      await row(
        bucket: TrialDataBucket.partnerEmailOutbox,
        label: '파트너 메일 큐',
        pathHint: 'partner_email_outbox',
        count: () => _countQuery(_db.collection('partner_email_outbox')),
        deletable: true,
      ),
      await row(
        bucket: TrialDataBucket.settingsPricing,
        label: 'settings/pricing',
        pathHint: 'settings/pricing',
        count: () async => null,
        unavailableReason: '규칙 match 없음 — 앱에서 확인 불가',
        protected: true,
      ),
      await row(
        bucket: TrialDataBucket.diveStarForms,
        label: '심사 양식',
        pathHint: 'dive_star_forms',
        count: () => _countQuery(_db.collection('dive_star_forms')),
        protected: true,
      ),
      await row(
        bucket: TrialDataBucket.partnerDocuments,
        label: '파트너 문서 메타',
        pathHint: 'partner_documents',
        count: () => _countQuery(_partnerDocuments),
        protected: true,
      ),
      await row(
        bucket: TrialDataBucket.documentShares,
        label: '문서 공유',
        pathHint: 'document_shares',
        count: () => _countQuery(_db.collection('document_shares')),
        protected: true,
      ),
      await row(
        bucket: TrialDataBucket.partnerDocConfig,
        label: '문서 설정',
        pathHint: 'partner_doc_config',
        count: () => _countQuery(_db.collection('partner_doc_config')),
        protected: true,
      ),
    ];

    return TrialDataSnapshot(
      rows: rows,
      jejuOrange: jeju,
      protectedUserUids: protectedUids,
      fetchedAt: DateTime.now(),
    );
  }

  Future<void> _commitDeletes(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    const chunk = 400;
    for (var i = 0; i < refs.length; i += chunk) {
      final batch = _db.batch();
      final end = (i + chunk < refs.length) ? i + chunk : refs.length;
      for (var j = i; j < end; j++) {
        batch.delete(refs[j]);
      }
      await batch.commit();
    }
  }

  Future<List<DocumentReference<Map<String, dynamic>>>> _listAllRefs(
    Query<Map<String, dynamic>> query, {
    bool Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)? keep,
  }) async {
    final out = <DocumentReference<Map<String, dynamic>>>[];
    Query<Map<String, dynamic>> q = query.limit(300);
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      final page = cursor == null
          ? await q.get()
          : await q.startAfterDocument(cursor).get();
      if (page.docs.isEmpty) {
        break;
      }
      for (final doc in page.docs) {
        if (keep == null || keep(doc)) {
          out.add(doc.reference);
        }
      }
      cursor = page.docs.last;
      if (page.docs.length < 300) {
        break;
      }
    }
    return out;
  }

  @override
  Future<TrialDeleteResult> runTrialDataDeletion({
    required TrialDeleteSelection selection,
    required String confirmPhrase,
    required bool backupAcknowledged,
    required String actorUid,
    required String actorName,
    required String actorEmail,
    void Function(TrialDeleteProgress progress)? onProgress,
  }) async {
    if (confirmPhrase.trim() != kTrialDeleteConfirmPhrase) {
      throw StateError('CONFIRM_MISMATCH');
    }
    if (!backupAcknowledged) {
      throw StateError('BACKUP_REQUIRED');
    }
    if (!selection.anySelected) {
      throw StateError('NOTHING_SELECTED');
    }

    final snapshot = await fetchTrialDataCounts(
      actorUid: actorUid,
      actorEmail: actorEmail,
    );
    if (snapshot.jejuOrange.blocksDeletion) {
      throw StateError('JEJU_ORANGE_AMBIGUOUS');
    }
    final protectedShop = snapshot.jejuOrange.protectedShopId;
    final protectedUids = snapshot.protectedUserUids;
    final notes = <String>[];
    final failed = <String>[];
    var success = 0;
    var failure = 0;
    var step = 0;
    const totalSteps = 12;

    void progress(String message) {
      step += 1;
      onProgress?.call(
        TrialDeleteProgress(message: message, done: step, total: totalSteps),
      );
    }

    Future<void> safeDeleteRefs(
      List<DocumentReference<Map<String, dynamic>>> refs,
      String label,
    ) async {
      if (refs.isEmpty) {
        return;
      }
      try {
        await _commitDeletes(refs);
        success += refs.length;
        notes.add('$label ${refs.length}건 삭제');
      } catch (e) {
        failure += refs.length;
        failed.addAll(refs.map((r) => r.path));
        notes.add('$label 실패: $e');
      }
    }

    if (selection.partnerEmailOutbox) {
      progress('메일 큐 삭제');
      final refs = await _listAllRefs(_db.collection('partner_email_outbox'));
      await safeDeleteRefs(refs, 'partner_email_outbox');
    } else {
      progress('메일 큐 건너뜀');
    }

    if (selection.diveStarApplications) {
      progress('LOI 신청 삭제');
      final refs = await _listAllRefs(_db.collection('dive_star_applications'));
      await safeDeleteRefs(refs, 'dive_star_applications');
    } else {
      progress('LOI 건너뜀');
    }

    if (selection.postsAndComments) {
      progress('커뮤니티 댓글·글 삭제');
      final posts = await _posts.get();
      final commentRefs = <DocumentReference<Map<String, dynamic>>>[];
      final postRefs = <DocumentReference<Map<String, dynamic>>>[];
      for (final post in posts.docs) {
        final comments = await post.reference.collection('comments').get();
        commentRefs.addAll(comments.docs.map((d) => d.reference));
        postRefs.add(post.reference);
      }
      await safeDeleteRefs(commentRefs, 'comments');
      await safeDeleteRefs(postRefs, 'posts');
    } else {
      progress('커뮤니티 건너뜀');
    }

    if (selection.reviews) {
      progress('후기 삭제');
      final shopReviewRefs = await _listAllRefs(
        _db.collectionGroup('reviews'),
        keep: (doc) {
          final path = doc.reference.path;
          if (protectedShop != null &&
              path.startsWith('shops/$protectedShop/')) {
            return false;
          }
          return path.contains('/reviews/');
        },
      );
      await safeDeleteRefs(shopReviewRefs, 'reviews');
    } else {
      progress('후기 건너뜀');
    }

    if (selection.userBookings || selection.userLogs || selection.trialUsers) {
      progress('회원 하위 정리');
      final users = await _users.get();
      for (final user in users.docs) {
        if (protectedUids.contains(user.id)) {
          continue;
        }
        if (selection.userBookings || selection.trialUsers) {
          final bookings = await user.reference.collection('bookings').get();
          await safeDeleteRefs(
            bookings.docs.map((d) => d.reference).toList(),
            'users/${user.id}/bookings',
          );
        }
        if (selection.userLogs || selection.trialUsers) {
          final logs = await user.reference.collection('logs').get();
          await safeDeleteRefs(
            logs.docs.map((d) => d.reference).toList(),
            'users/${user.id}/logs',
          );
        }
        if (selection.reviews || selection.trialUsers) {
          final reviews = await user.reference.collection('reviews').get();
          await safeDeleteRefs(
            reviews.docs.map((d) => d.reference).toList(),
            'users/${user.id}/reviews',
          );
        }
      }
    } else {
      progress('회원 하위 건너뜀');
    }

    if (selection.unconfirmedAssessments) {
      progress('미확정 평가 삭제');
      final refs = await _listAllRefs(
        _db.collectionGroup('dive_star_assessments'),
        keep: (doc) {
          if (protectedShop != null &&
              doc.reference.path.startsWith('shops/$protectedShop/')) {
            return false;
          }
          return doc.data()['confirmed'] != true;
        },
      );
      await safeDeleteRefs(refs, 'dive_star_assessments(unconfirmed)');
    } else {
      progress('평가 건너뜀');
    }

    // Trial shops: bookings → clear products / delete shop
    final shopDocs = await _shops.get();
    final trialShops = [
      for (final doc in shopDocs.docs)
        if (protectedShop == null || doc.id != protectedShop) doc,
    ];

    if (selection.trialShopBookings || selection.trialShops) {
      progress('시험 샵 예약 삭제');
      for (final shop in trialShops) {
        final bookings = await shop.reference.collection('bookings').get();
        await safeDeleteRefs(
          bookings.docs.map((d) => d.reference).toList(),
          'shops/${shop.id}/bookings',
        );
      }
    } else {
      progress('샵 예약 건너뜀');
    }

    if (selection.clearTrialShopProducts && !selection.trialShops) {
      progress('시험 샵 상품 비우기');
      for (final shop in trialShops) {
        try {
          await shop.reference.set({
            'products': <Map<String, dynamic>>[],
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          success += 1;
          notes.add('shops/${shop.id} products 비움');
        } catch (e) {
          failure += 1;
          failed.add(shop.reference.path);
          notes.add('products 비우기 실패 ${shop.id}: $e');
        }
      }
    } else {
      progress('상품 비우기 건너뜀');
    }

    if (selection.trialShops) {
      progress('시험 샵 삭제(주인 해제→하위→샵)');
      for (final shop in trialShops) {
        // Demote owners first (unless protected user).
        for (final user in (await _users.get()).docs) {
          if (protectedUids.contains(user.id)) {
            continue;
          }
          final owned =
              (user.data()['owned_shop_id'] as String?)?.trim() ?? '';
          if (owned != shop.id) {
            continue;
          }
          try {
            await demoteMemberFromPartner(
              uid: user.id,
              actorUid: actorUid,
              actorName: actorName,
            );
            success += 1;
            notes.add('파트너 해제 ${user.id} (샵 ${shop.id})');
          } catch (e) {
            failure += 1;
            notes.add('파트너 해제 실패 ${user.id}: $e');
          }
        }
        // Remaining deletable children
        for (final sub in ['reviews', 'bookings', 'dive_star_assessments']) {
          final kids = await shop.reference.collection(sub).get();
          final refs = <DocumentReference<Map<String, dynamic>>>[];
          for (final kid in kids.docs) {
            if (sub == 'dive_star_assessments' &&
                kid.data()['confirmed'] == true) {
              notes.add('확정 평가 남김: ${kid.reference.path}');
              continue;
            }
            refs.add(kid.reference);
          }
          await safeDeleteRefs(refs, 'shops/${shop.id}/$sub');
        }
        final contracts =
            await shop.reference.collection('partner_contracts').get();
        if (contracts.docs.isNotEmpty) {
          notes.add(
            '서류함 ${contracts.docs.length}건 남음(shops/${shop.id}) — Console에서 수동 삭제',
          );
        }
        try {
          await shop.reference.delete();
          success += 1;
          notes.add('샵 삭제 ${shop.id} (임베디드 상품 포함)');
        } catch (e) {
          failure += 1;
          failed.add(shop.reference.path);
          notes.add('샵 삭제 실패 ${shop.id}: $e');
        }
      }
    } else {
      progress('샵 삭제 건너뜀');
    }

    if (selection.trialUsers) {
      progress('시험 회원 문서 삭제');
      final users = await _users.get();
      final refs = <DocumentReference<Map<String, dynamic>>>[];
      for (final user in users.docs) {
        if (protectedUids.contains(user.id)) {
          continue;
        }
        refs.add(user.reference);
      }
      await safeDeleteRefs(refs, 'users(trial)');
      notes.add(
        'Auth 계정은 앱에서 못 지웁니다. Firebase Console → Authentication → Users에서 '
        '지운 뒤, 같은 아이디로 로그인하면 빈 users 문서가 다시 생길 수 있습니다.',
      );
    } else {
      progress('회원 문서 건너뜀');
    }

    notes.add(
      '서류함(partner_contracts)·확정 평가·R2/Storage 파일·Auth는 앱 삭제 범위 밖일 수 있습니다.',
    );

    return TrialDeleteResult(
      successCount: success,
      failureCount: failure,
      notes: notes,
      failedIds: failed,
    );
  }

  List<Map<String, dynamic>> _appendRoleHistory({
    required Object? existing,
    required Map<String, dynamic> entry,
  }) {
    final list = <Map<String, dynamic>>[];
    if (existing is List) {
      for (final item in existing) {
        if (item is Map) {
          list.add(Map<String, dynamic>.from(item));
        }
      }
    }
    list.add(entry);
    const maxEntries = 50;
    if (list.length > maxEntries) {
      return list.sublist(list.length - maxEntries);
    }
    return list;
  }

  @override
  Future<void> ensureUserDocument(
    AppUser user, {
    String? loginId,
    String? nationality,
    String? birthDate,
    String? phone,
    bool? termsAccepted,
    bool? privacyAccepted,
    bool? marketingOptIn,
  }) async {
    final ref = _userDoc(user.uid);
    final snapshot = await ref.get().timeout(const Duration(seconds: 8));
    final existing = snapshot.data();
    if (snapshot.exists &&
        (existing?['account_blocked'] == true ||
            existing?['withdrawn_at'] != null)) {
      return;
    }
    final existingName = existing?['display_name'] as String?;
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
    final id = (loginId ?? '').trim().toLowerCase();
    if (id.isNotEmpty) {
      payload['login_id'] = id;
    }
    final country = normalizeNationalityCode(nationality);
    if (country != null) {
      payload['nationality'] = country;
      payload['nationality_consent_at'] = FieldValue.serverTimestamp();
    }
    final birth = (birthDate ?? '').trim();
    if (birth.isNotEmpty) {
      payload['birth_date'] = birth;
    }
    final contact = (phone ?? '').trim();
    if (contact.isNotEmpty) {
      payload['phone'] = contact;
    }
    if (termsAccepted == true) {
      payload['consent_terms'] = true;
      payload['consent_terms_at'] = FieldValue.serverTimestamp();
    }
    if (privacyAccepted == true) {
      payload['consent_privacy'] = true;
      payload['consent_privacy_at'] = FieldValue.serverTimestamp();
    }
    if (marketingOptIn != null) {
      payload['consent_marketing'] = marketingOptIn;
      payload['consent_marketing_at'] = FieldValue.serverTimestamp();
    }
    // Do not auto-write is_admin / is_business here. Roles come from the
    // Firestore document (and owner-only session overlay for testing).
    if (!snapshot.exists) {
      payload.addAll({
        'user_role': 'diver',
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
    }
    await ref.set(payload, SetOptions(merge: true));
  }

  @override
  Future<void> adminRepairMemberProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final ref = _userDoc(uid);
    final snapshot = await ref.get();
    if (!snapshot.exists) return;
    final data = snapshot.data() ?? <String, dynamic>{};
    final patch = memberProfileRepairPatch(
      gradeMissing: data['member_grade'] == null && data['memberGrade'] == null,
      existingEmail: (data['email'] as String?) ?? '',
      existingName: (data['display_name'] as String?) ?? '',
      email: email,
      displayName: displayName,
      uid: uid,
    );
    if (patch.isEmpty) return;
    patch['updated_at'] = FieldValue.serverTimestamp();
    await ref.set(patch, SetOptions(merge: true));
  }

  @override
  Future<void> setNationality({
    required String uid,
    required String code,
  }) async {
    final country = normalizeNationalityCode(code);
    if (country == null) {
      throw StateError('nationality');
    }
    await _userDoc(uid).set({
      'nationality': country,
      'nationality_consent_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> clearNationality(String uid) {
    return _userDoc(uid).set({
      'nationality': FieldValue.delete(),
      'nationality_consent_at': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveSeatAlerts({
    required String uid,
    required List<SameBoatAlert> alerts,
  }) {
    return _userDoc(uid).set({
      'seat_alerts': [for (final alert in alerts) alert.toMap()],
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<DiverSnapshot> watchDiver(String uid) {
    // Profile only — logs are loaded on demand via [fetchDiveLogs].
    return _userDoc(uid).snapshots().map((snapshot) {
      return _toSnapshot(snapshot, null);
    });
  }

  @override
  Future<DiveLogsPage> fetchDiveLogs(
    String uid, {
    int limit = 50,
    Object? cursor,
  }) async {
    final pageSize = limit < 1 ? 50 : limit;
    Query<Map<String, dynamic>> query = _logs(
      uid,
    ).orderBy('dived_at', descending: true).limit(pageSize + 1);
    if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }
    final snapshot = await query.get();
    final docs = snapshot.docs;
    final hasMore = docs.length > pageSize;
    final pageDocs = hasMore ? docs.sublist(0, pageSize) : docs;
    final logs = [
      for (final doc in pageDocs)
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
    return DiveLogsPage(
      logs: logs,
      nextCursor: pageDocs.isEmpty ? null : pageDocs.last,
      hasMore: hasMore,
    );
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
  Future<List<ShopLiveStats>> fetchShopStats() async {
    final snapshot = await _shops.get();
    return [
      for (final doc in snapshot.docs)
        ShopLiveStats.fromDocument(doc.id, doc.data()),
    ];
  }

  @override
  Future<ShopLiveStats?> fetchShopStat(String shopId) async {
    final id = shopId.trim();
    if (id.isEmpty) {
      return null;
    }
    final doc = await _shops.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return ShopLiveStats.fromDocument(doc.id, doc.data() ?? {});
  }

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
      seatsHeld: (data['seats_held'] as num?)?.toInt() ?? 0,
      seatOptionId: data['seat_option_id'] as String? ?? '',
      guestDisplayName: data['guest_display_name'] as String? ?? '',
      guestBirthDate: data['guest_birth_date'] as String? ?? '',
      guestContact: data['guest_contact'] as String? ?? '',
      partnerAckedAt: data['partner_acked_at'] == null
          ? null
          : _readDate(data['partner_acked_at']),
      cancelledAt: data['cancelled_at'] == null
          ? null
          : _readDate(data['cancelled_at']),
    );
  }

  Map<String, dynamic> _bookingPayload(
    TourBooking booking, {
    bool includeGuestPrivate = false,
  }) {
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
      'seats_held': booking.seatsHeld,
      'seat_option_id': booking.seatOptionId,
      'guest_display_name': booking.guestDisplayName,
      if (includeGuestPrivate && booking.guestBirthDate.isNotEmpty)
        'guest_birth_date': booking.guestBirthDate,
      if (includeGuestPrivate && booking.guestContact.isNotEmpty)
        'guest_contact': booking.guestContact,
      if (booking.quoteLines.isNotEmpty)
        'quote_lines': [
          for (final line in booking.quoteLines) line.toMap(),
        ],
      if (booking.partnerAckedAt != null)
        'partner_acked_at': Timestamp.fromDate(booking.partnerAckedAt!),
      if (booking.cancelledAt != null)
        'cancelled_at': Timestamp.fromDate(booking.cancelledAt!),
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
    String guestDisplayName = '',
    String guestBirthDate = '',
    String guestContact = '',
  }) async {
    final hullId = shopId.split('--').first;
    final now = DateTime.now();
    final id = _bookings(uid).doc().id;
    final userBookingRef = _bookings(uid).doc(id);
    final shopBookingRef = _shopBookings(hullId).doc(id);
    final shopRef = _shops.doc(hullId);
    final userRef = _userDoc(uid);
    final seatKey = seatOptionId;

    try {
      final ok = await _db.runTransaction((transaction) async {
        var seatsHeld = 0;
        List<ShopProduct>? currentProducts;
        ShopProduct? capturedProduct;
        List<ActiveSeatFlag>? nextFlags;

        final needsSeats =
            productId != null && productId.isNotEmpty && partySize > 0;
        if (needsSeats) {
          final shopSnap = await transaction.get(shopRef);
          final userSnap = await transaction.get(userRef);
          currentProducts =
              ShopProduct.listFrom(hullId, shopSnap.data()?['products']);
          ShopProduct? target;
          for (final item in currentProducts) {
            if (item.id == productId) {
              target = item;
              break;
            }
          }
          if (target == null) {
            return false;
          }
          if (target.opensEmptySeatsFor(seatKey)) {
            final before = target.bookedSeatsFor(seatKey);
            final captured = target.capturePayment(
              partySize,
              now,
              uid: uid,
              optionId: seatKey,
            );
            if (captured.bookedSeatsFor(seatKey) <= before) {
              return false;
            }
            seatsHeld = partySize;
            capturedProduct = captured;
            final live = ActiveSeatFlag.liveOnly(
              ActiveSeatFlag.listFrom(
                userSnap.data()?[ActiveSeatFlag.fieldKey],
              ),
              now,
            );
            nextFlags = ActiveSeatFlag.withoutProduct(live, hullId, productId);
          }
        }

        if (capturedProduct != null && currentProducts != null) {
          transaction.set(
            shopRef,
            {
              'products': [
                for (final item in currentProducts)
                  if (item.id == productId)
                    capturedProduct.toMap()
                    else
                      item.toMap(),
              ],
            },
            SetOptions(merge: true),
          );
          if (nextFlags != null) {
            transaction.set(
              userRef,
              {ActiveSeatFlag.fieldKey: ActiveSeatFlag.toMaps(nextFlags)},
              SetOptions(merge: true),
            );
          }
        }

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
          createdAt: now,
          tourDate: tourDate ?? now.add(const Duration(days: 7)),
          status: status,
          paymentStatus: paymentStatus,
          commissionRate: RefundPolicy.defaultCommissionRate,
          partySize: partySize,
          divers: divers,
          nondivers: nondivers,
          children: children,
          infants: infants,
          quoteLines: quoteLines,
          seatsHeld: seatsHeld,
          seatOptionId: seatKey,
          guestDisplayName: guestDisplayName.trim(),
          guestBirthDate: guestBirthDate.trim(),
          guestContact: guestContact.trim(),
        );
        final userPayload = _bookingPayload(
          booking,
          includeGuestPrivate: true,
        );
        final shopPayload = _bookingPayload(booking);
        userPayload['created_at'] = FieldValue.serverTimestamp();
        shopPayload['created_at'] = FieldValue.serverTimestamp();
        // User doc keeps name, birth, and contact. Shop doc keeps the name only.
        transaction.set(userBookingRef, userPayload);
        transaction.set(shopBookingRef, shopPayload);
        return true;
      });
      if (ok &&
          paymentStatus == PaymentStatus.captured &&
          uid.isNotEmpty) {
        await _bumpActivityAndMaybeUpgrade(uid: uid, purchaseDelta: 1);
      }
      return ok;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw StateError(
          'Firestore rules rejected users/{uid}.active_seat_flags write during createBooking. Stopped without changing firestore.rules.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<SeatFlagPlant> plantSeatFlag({
    required String shopId,
    required String productId,
    required int partySize,
    required DateTime now,
    String optionId = '',
    String uid = '',
    int lockedPrice = 0,
  }) async {
    if (uid.isEmpty || partySize <= 0) {
      return SeatFlagPlant.unavailable;
    }
    final hull = shopId.split('--').first;
    final shopRef = _shops.doc(hull);
    final userRef = _userDoc(uid);

    try {
      return await _db.runTransaction((transaction) async {
        final shopSnap = await transaction.get(shopRef);
        final userSnap = await transaction.get(userRef);
        final current =
            ShopProduct.listFrom(hull, shopSnap.data()?['products']);
        ShopProduct? target;
        for (final item in current) {
          if (item.id == productId) {
            target = item.pruneExpiredHolds(now);
            break;
          }
        }
        final liveFlags = ActiveSeatFlag.liveOnly(
          ActiveSeatFlag.listFrom(userSnap.data()?[ActiveSeatFlag.fieldKey]),
          now,
        );
        void writePrunedFlags([List<ActiveSeatFlag>? next]) {
          transaction.set(
            userRef,
            {
              ActiveSeatFlag.fieldKey:
                  ActiveSeatFlag.toMaps(next ?? liveFlags),
            },
            SetOptions(merge: true),
          );
        }

        if (target == null) {
          writePrunedFlags();
          return SeatFlagPlant.unavailable;
        }
        if (!target.opensEmptySeatsFor(optionId) ||
            !target.isBoardLiveFor(optionId)) {
          writePrunedFlags();
          return SeatFlagPlant.unavailable;
        }
        final closeAt = target.flagClosesAtFor(optionId);
        if (ShopProduct.isTooLateToPlant(now, closeAt)) {
          writePrunedFlags();
          return SeatFlagPlant.tooLate;
        }
        if (target.memberHasLiveFlagOnProduct(uid, now)) {
          writePrunedFlags();
          return SeatFlagPlant.alreadyHeld;
        }

        if (liveFlags.length >= ActiveSeatFlag.maxLivePerUser) {
          writePrunedFlags();
          return SeatFlagPlant.limitReached;
        }
        if (target.bookableSeatsFor(uid, now, optionId: optionId) <
            partySize) {
          writePrunedFlags();
          return SeatFlagPlant.taken;
        }

        final planted = target.plantFlag(
          partySize: partySize,
          now: now,
          optionId: optionId,
          uid: uid,
          lockedPrice: lockedPrice,
        );
        if (!planted.memberHasLiveFlag(uid, now, optionId: optionId)) {
          writePrunedFlags();
          return SeatFlagPlant.taken;
        }
        final hold = planted.liveFlagFor(uid, now, optionId: optionId)!;
        final nextFlags = [
          ...liveFlags,
          ActiveSeatFlag(
            shopId: hull,
            productId: productId,
            optionId: optionId,
            expiresAt: hold.expiresAt,
          ),
        ];
        transaction.set(
          shopRef,
          {
            'products': [
              for (final item in current)
                if (item.id == productId)
                  planted.toMap()
                else
                  item.pruneExpiredHolds(now).toMap(),
            ],
          },
          SetOptions(merge: true),
        );
        writePrunedFlags(nextFlags);
        return SeatFlagPlant.planted;
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw StateError(
          'Firestore rules rejected users/{uid}.active_seat_flags write during plantSeatFlag. Stopped without changing firestore.rules.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> cancelSeatFlag({
    required String uid,
    required String shopId,
    required String productId,
    required DateTime now,
    String optionId = '',
  }) async {
    if (uid.isEmpty) {
      return false;
    }
    final hull = shopId.split('--').first;
    final shopRef = _shops.doc(hull);
    final userRef = _userDoc(uid);

    try {
      return await _db.runTransaction((transaction) async {
        final shopSnap = await transaction.get(shopRef);
        final userSnap = await transaction.get(userRef);
        final current =
            ShopProduct.listFrom(hull, shopSnap.data()?['products']);
        ShopProduct? target;
        for (final item in current) {
          if (item.id == productId) {
            target = item;
            break;
          }
        }
        if (target == null || !target.memberHasLiveFlagOnProduct(uid, now)) {
          return false;
        }
        final resolvedOption = optionId.isNotEmpty
            ? optionId
            : target.liveFlagOptionIdFor(uid, now);
        final next = target.removeMemberFlag(
          uid,
          now,
          optionId: resolvedOption,
        );
        final live = ActiveSeatFlag.liveOnly(
          ActiveSeatFlag.listFrom(userSnap.data()?[ActiveSeatFlag.fieldKey]),
          now,
        );
        transaction.set(
          shopRef,
          {
            'products': [
              for (final item in current)
                if (item.id == productId) next.toMap() else item.toMap(),
            ],
          },
          SetOptions(merge: true),
        );
        transaction.set(
          userRef,
          {
            ActiveSeatFlag.fieldKey: ActiveSeatFlag.toMaps(
              ActiveSeatFlag.withoutProduct(live, hull, productId),
            ),
          },
          SetOptions(merge: true),
        );
        return true;
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw StateError(
          'Firestore rules rejected users/{uid}.active_seat_flags write during cancelSeatFlag. Stopped without changing firestore.rules.',
        );
      }
      rethrow;
    }
  }

  Future<void> _restoreSeatsInTxn(
    Transaction transaction,
    TourBooking booking,
  ) async {
    if (booking.seatsHeld <= 0 || booking.productId.isEmpty) {
      return;
    }
    final shopRef = _shops.doc(booking.shopId);
    final shopSnap = await transaction.get(shopRef);
    final current =
        ShopProduct.listFrom(booking.shopId, shopSnap.data()?['products']);
    final seatKey = booking.seatsOptionKey;
    transaction.set(
      shopRef,
      {
        'products': [
          for (final item in current)
            if (item.id == booking.productId)
              item
                  .releaseBookedSeats(booking.seatsHeld, optionId: seatKey)
                  .toMap()
            else
              item.toMap(),
        ],
      },
      SetOptions(merge: true),
    );
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
  Future<List<GuestReview>> listMyReviews(String uid) async {
    final snap = await _userDoc(uid)
        .collection('reviews')
        .orderBy('created_at', descending: true)
        .get();
    return [
      for (final doc in snap.docs) GuestReview.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  Future<void> updateOperationReview({
    required String uid,
    required String shopId,
    required String reviewId,
    required int safety,
    required int guide,
    required int boat,
    String? comment,
    ReviewDetails? details,
  }) async {
    final safeSafety = OperationReviewPolicy.clampStars(safety);
    final safeGuide = OperationReviewPolicy.clampStars(guide);
    final safeBoat = OperationReviewPolicy.clampStars(boat);
    OperationReviewPolicy.assertStarsInRange(safeSafety, safeGuide, safeBoat);
    final safeComment = OperationReviewPolicy.normalizeComment(comment);
    final safeDetails = OperationReviewPolicy.normalizeDetails(details);
    final shopRef = _shops.doc(shopId);
    final reviewRef = shopRef.collection('reviews').doc(reviewId);
    final userReviewRef = _userDoc(uid).collection('reviews').doc(reviewId);

    await _db.runTransaction((transaction) async {
      final reviewSnap = await transaction.get(reviewRef);
      final reviewData = reviewSnap.data();
      if (!reviewSnap.exists || reviewData == null) {
        throw StateError('Review not found');
      }
      if ((reviewData['uid'] as String? ?? '') != uid) {
        throw StateError('Not your review');
      }
      final shopSnap = await transaction.get(shopRef);
      final shopData = shopSnap.data() ?? {};
      final oldSafety = (reviewData['safety'] as num?)?.toInt() ?? 0;
      final oldGuide = (reviewData['guide'] as num?)?.toInt() ?? 0;
      final oldBoat = (reviewData['boat'] as num?)?.toInt() ?? 0;
      final count = (shopData['review_count'] as num?)?.toInt() ?? 0;
      if (count <= 0) {
        throw StateError('Shop has no reviews to update');
      }
      final sumSafety = ((shopData['sum_safety'] as num?)?.toDouble() ?? 0) -
          oldSafety +
          safeSafety;
      final sumGuide = ((shopData['sum_guide'] as num?)?.toDouble() ?? 0) -
          oldGuide +
          safeGuide;
      final sumBoat =
          ((shopData['sum_boat'] as num?)?.toDouble() ?? 0) - oldBoat + safeBoat;
      final avgSafety = sumSafety / count;
      final avgGuide = sumGuide / count;
      final avgBoat = sumBoat / count;
      final avgOverall = DiveStar.overall(
        safety: avgSafety,
        guide: avgGuide,
        boat: avgBoat,
      );
      final oldGuest =
          ((oldSafety + oldGuide + oldBoat) / 3).round().clamp(1, 5);
      final newGuest =
          ((safeSafety + safeGuide + safeBoat) / 3).round().clamp(1, 5);
      final productKey = (reviewData['product_id'] as String? ?? '').trim();
      final optionKey = (reviewData['option_id'] as String? ?? '').trim();

      List<Map<String, dynamic>>? nextProducts;
      if (productKey.isNotEmpty) {
        final products = ShopProduct.listFrom(shopId, shopData['products']);
        nextProducts = [
          for (final item in products)
            if (item.id == productKey)
              item
                  .replaceGuestStarReview(
                    oldGuest,
                    newGuest,
                    optionId: optionKey,
                  )
                  .toMap()
            else
              item.toMap(),
        ];
      }

      final patch = <String, dynamic>{
        'safety': safeSafety,
        'guide': safeGuide,
        'boat': safeBoat,
        'overall': (safeSafety + safeGuide + safeBoat) / 3,
        'comment': ?safeComment,
        ...safeDetails.toFirestoreFields(),
        'edited_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      transaction.set(reviewRef, patch, SetOptions(merge: true));
      transaction.set(userReviewRef, patch, SetOptions(merge: true));
      transaction.set(shopRef, {
        'review_count': count,
        'sum_safety': sumSafety,
        'sum_guide': sumGuide,
        'sum_boat': sumBoat,
        'avg_safety': avgSafety,
        'avg_guide': avgGuide,
        'avg_boat': avgBoat,
        'avg_overall': avgOverall,
        'safety_pass': avgSafety >= DiveStar.safetyPassThreshold,
        'products': ?nextProducts,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> deleteOperationReview({
    required String uid,
    required String shopId,
    required String reviewId,
  }) async {
    final shopRef = _shops.doc(shopId);
    final reviewRef = shopRef.collection('reviews').doc(reviewId);
    final userReviewRef = _userDoc(uid).collection('reviews').doc(reviewId);

    await _db.runTransaction((transaction) async {
      final reviewSnap = await transaction.get(reviewRef);
      final reviewData = reviewSnap.data();
      if (!reviewSnap.exists || reviewData == null) {
        throw StateError('Review not found');
      }
      final ownerUid = reviewData['uid'] as String? ?? '';
      if (ownerUid != uid) {
        throw StateError('Not your review');
      }
      final shopSnap = await transaction.get(shopRef);
      final shopData = shopSnap.data() ?? {};
      final oldSafety = (reviewData['safety'] as num?)?.toInt() ?? 0;
      final oldGuide = (reviewData['guide'] as num?)?.toInt() ?? 0;
      final oldBoat = (reviewData['boat'] as num?)?.toInt() ?? 0;
      final count = (shopData['review_count'] as num?)?.toInt() ?? 0;
      final nextCount = (count - 1).clamp(0, 1 << 30);
      final sumSafety =
          ((shopData['sum_safety'] as num?)?.toDouble() ?? 0) - oldSafety;
      final sumGuide =
          ((shopData['sum_guide'] as num?)?.toDouble() ?? 0) - oldGuide;
      final sumBoat =
          ((shopData['sum_boat'] as num?)?.toDouble() ?? 0) - oldBoat;
      final avgSafety = nextCount == 0 ? 0.0 : sumSafety / nextCount;
      final avgGuide = nextCount == 0 ? 0.0 : sumGuide / nextCount;
      final avgBoat = nextCount == 0 ? 0.0 : sumBoat / nextCount;
      final avgOverall = nextCount == 0
          ? 0.0
          : DiveStar.overall(
              safety: avgSafety,
              guide: avgGuide,
              boat: avgBoat,
            );
      final oldGuest =
          ((oldSafety + oldGuide + oldBoat) / 3).round().clamp(1, 5);
      final productKey = (reviewData['product_id'] as String? ?? '').trim();
      final optionKey = (reviewData['option_id'] as String? ?? '').trim();

      List<Map<String, dynamic>>? nextProducts;
      if (productKey.isNotEmpty) {
        final products = ShopProduct.listFrom(shopId, shopData['products']);
        nextProducts = [
          for (final item in products)
            if (item.id == productKey)
              item
                  .removeGuestStarReview(oldGuest, optionId: optionKey)
                  .toMap()
            else
              item.toMap(),
        ];
      }

      final bookingId = (reviewData['booking_id'] as String? ?? '').trim();
      transaction.delete(reviewRef);
      transaction.delete(userReviewRef);
      transaction.set(shopRef, {
        'review_count': nextCount,
        'sum_safety': nextCount == 0 ? 0 : sumSafety,
        'sum_guide': nextCount == 0 ? 0 : sumGuide,
        'sum_boat': nextCount == 0 ? 0 : sumBoat,
        'avg_safety': avgSafety,
        'avg_guide': avgGuide,
        'avg_boat': avgBoat,
        'avg_overall': avgOverall,
        'safety_pass':
            nextCount > 0 && avgSafety >= DiveStar.safetyPassThreshold,
        'products': ?nextProducts,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (bookingId.isNotEmpty) {
        transaction.set(
          _userDoc(uid).collection('bookings').doc(bookingId),
          {
            'reviewed': false,
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
    await _bumpActivityAndMaybeUpgrade(uid: uid, reviewDelta: -1);
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
  Future<List<PendingInstructor>> fetchPendingInstructors() async {
    final snapshot = await _users.get();
    return [
      for (final doc in snapshot.docs)
        if (_toPendingInstructor(doc) case final pending?) pending,
    ];
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
  Future<CommunityPostsPage> fetchCommunityPosts({
    int limit = 20,
    Object? cursor,
  }) async {
    final pageSize = limit < 1 ? 20 : limit;
    Query<Map<String, dynamic>> query = _posts
        .orderBy('created_at', descending: true)
        .limit(pageSize + 1);
    if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }
    final snapshot = await query.get();
    final docs = snapshot.docs;
    final hasMore = docs.length > pageSize;
    final pageDocs = hasMore ? docs.sublist(0, pageSize) : docs;
    return CommunityPostsPage(
      posts: [for (final doc in pageDocs) _toCommunityPost(doc)],
      nextCursor: pageDocs.isEmpty ? null : pageDocs.last,
      hasMore: hasMore,
    );
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
      userRole: (data['user_role'] as String?)?.trim().isNotEmpty == true
          ? (data['user_role'] as String).trim()
          : (business ? 'business' : 'diver'),
      loginId: (data['login_id'] as String?)?.trim() ?? '',
      paidPurchaseCount: (data['paid_purchase_count'] as num?)?.toInt() ?? 0,
      reviewCount: (data['review_count'] as num?)?.toInt() ?? 0,
      gradeLocked: data['member_grade_locked'] == true,
      phone: (data['phone'] as String?)?.trim() ?? '',
      accountBlocked: data['account_blocked'] == true,
      withdrawnAt: data['withdrawn_at'] is Timestamp
          ? (data['withdrawn_at'] as Timestamp).toDate()
          : null,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt,
      nationality: normalizeNationalityCode(data['nationality'] as String?) ??
          '',
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
  Future<List<MemberAccount>> fetchMembers() async {
    final snapshot = await _users.get();
    final members = [for (final doc in snapshot.docs) _toMemberAccount(doc)];
    members.sort(compareMembersByRecentLogin);
    return members;
  }

  @override
  Stream<List<MemberAccount>> watchMembers() {
    return _users.snapshots().map((snapshot) {
      final members = [for (final doc in snapshot.docs) _toMemberAccount(doc)];
      members.sort(compareMembersByRecentLogin);
      return members;
    });
  }

  @override
  Future<void> setMemberAdmin({
    required String uid,
    required bool admin,
    required String actorUid,
  }) async {
    if (!admin && actorUid == uid) {
      throw StateError('ADMIN_SELF');
    }
    final doc = await _userDoc(uid).get();
    final currently = doc.data()?['is_admin'] == true;
    if (!admin && currently) {
      final admins = await _users.where('is_admin', isEqualTo: true).limit(2).get();
      if (admins.docs.length <= 1) {
        throw StateError('ADMIN_LAST');
      }
    }
    await _userDoc(uid).set({
      'is_admin': admin,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setAccountBlocked({
    required String uid,
    required bool blocked,
  }) {
    return _userDoc(uid).set({
      'account_blocked': blocked,
      'blocked_at': blocked ? FieldValue.serverTimestamp() : FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> withdrawMember(String uid) {
    return _userDoc(uid).set({
      'withdrawn_at': FieldValue.serverTimestamp(),
      'display_name': '',
      'phone': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    final list = <DiveStarForm>[];
    for (final doc in snap.docs) {
      try {
        list.add(DiveStarForm.fromDocument(doc.id, doc.data()));
      } catch (_) {
        // Skip corrupt docs so the import screen still opens.
      }
    }
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

  @override
  Future<DiveStarForm> activateDiveStarForm(String version) async {
    final id = version.trim();
    if (id.isEmpty) {
      throw StateError('Form version is required');
    }
    final targetRef = _diveStarForms.doc(id);
    final targetSnap = await targetRef.get();
    final targetData = targetSnap.data();
    if (!targetSnap.exists || targetData == null) {
      throw StateError('Form not found: $id');
    }
    final all = await _diveStarForms.get();
    final batch = _db.batch();
    for (final doc in all.docs) {
      final activate = doc.id == id;
      batch.set(
        doc.reference,
        {
          'active': activate,
          'status': activate
              ? DiveStarFormStatus.active.firestoreValue
              : DiveStarFormStatus.draft.firestoreValue,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    final refreshed = await targetRef.get();
    return DiveStarForm.fromDocument(
      id,
      refreshed.data() ?? {
        ...targetData,
        'active': true,
        'status': DiveStarFormStatus.active.firestoreValue,
      },
    );
  }

  Map<String, int> _clampScores(DiveStarForm form, Map<String, int> scores) {
    return {
      for (final area in form.areas)
        area.id: (scores[area.id] ?? 0).clamp(0, area.maxPoints),
    };
  }

  Map<String, int> _clampItemScores(
    DiveStarForm form,
    Map<String, int> itemScores,
  ) {
    return {
      for (final item in form.items)
        item.id: (itemScores[item.id] ?? 0).clamp(0, item.maxPoints),
    };
  }

  Future<DiveStarForm> _formForSave(String? formVersion) async {
    final version = formVersion?.trim() ?? '';
    if (version.isNotEmpty) {
      final form = await getDiveStarForm(version);
      if (form != null) {
        return form;
      }
      throw StateError('Form not found: $version');
    }
    return ensureActiveDiveStarForm();
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
    String? formVersion,
    required DiveStarAssessmentType type,
    required DateTime reviewedAt,
    required Map<String, bool> gates,
    required Map<String, int> scores,
    required Map<String, String> comments,
    Map<String, int> itemScores = const {},
    Map<String, String> itemComments = const {},
    Map<String, bool> areaNa = const {},
    List<DiveStarCountryGateAnswer> countryGates = const [],
    int mysteryVisits = 0,
    List<String> auditors = const [],
  }) async {
    final form = await _formForSave(formVersion);
    final clampedScores = _clampScores(form, scores);
    final clampedItems = _clampItemScores(form, itemScores);
    final gateMap = {
      for (final gate in form.gates) gate.id: gates[gate.id] == true,
    };
    final cleanedCountry = [
      for (final gate in countryGates)
        if (gate.title.trim().isNotEmpty)
          DiveStarCountryGateAnswer(
            title: gate.title.trim(),
            criteria: gate.criteria.trim(),
            passed: gate.passed,
          ),
    ];
    final cleanedNa = {
      for (final area in form.areas)
        if (areaNa[area.id] == true &&
            area.id != form.rules.requiredAreaId &&
            area.id != form.thresholds.safetyAreaId)
          area.id: true,
    };
    final visits = mysteryVisits.clamp(0, 20);
    final cleanedAuditors = [
      for (final name in auditors)
        if (name.trim().isNotEmpty) name.trim(),
    ].take(2).toList();
    final result = DiveStarScoring.evaluate(
      form: form,
      gates: gateMap,
      scores: clampedScores,
      itemScores: clampedItems,
      areaNotApplicable: cleanedNa,
      countryGatesPassed: [for (final g in cleanedCountry) g.passed],
      mysteryVisits: visits,
    );
    final areaScoresForStore = {
      for (final area in form.areas)
        area.id: result.areaScores[area.id] ?? clampedScores[area.id] ?? 0,
    };
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
      'assessment_type': type.firestoreValue,
      'reviewed_at': Timestamp.fromDate(reviewedAt.toUtc()),
      'gates': gateMap,
      'scores': areaScoresForStore,
      'comments': {
        for (final entry in comments.entries)
          if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
      },
      'item_scores': clampedItems,
      'item_comments': {
        for (final entry in itemComments.entries)
          if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
      },
      'area_na': cleanedNa,
      'country_gates': [for (final g in cleanedCountry) g.toMap()],
      'mystery_visits': visits,
      'auditors': cleanedAuditors,
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

  DocumentReference<Map<String, dynamic>> _contractTerms(String shopId) =>
      _shops.doc(shopId).collection('contract_terms').doc('current');

  CollectionReference<Map<String, dynamic>> _contractTermRevisions(
    String shopId,
  ) =>
      _contractTerms(shopId).collection('revisions');

  @override
  Future<PartnerContractTerms?> getPartnerContractTerms(String shopId) async {
    final snap = await _contractTerms(shopId).get();
    if (!snap.exists) {
      return null;
    }
    return PartnerContractTerms.fromMap(snap.data());
  }

  @override
  Future<List<PartnerContractTermRevision>> listPartnerContractTermRevisions(
    String shopId,
  ) async {
    final snap = await _contractTermRevisions(shopId)
        .orderBy('at', descending: true)
        .limit(50)
        .get();
    return [
      for (final doc in snap.docs)
        PartnerContractTermRevision.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  Future<void> savePartnerContractTerms({
    required String shopId,
    required PartnerContractTerms next,
    required String adminUid,
    required String actorName,
    required List<PartnerContractTermChange> changes,
  }) async {
    if (changes.isEmpty) {
      throw const PartnerContractTermsUnchanged();
    }
    final terms = _contractTerms(shopId);
    final revision = _contractTermRevisions(shopId).doc();
    final batch = _db.batch();
    batch.set(terms, {
      ...next.toValueMap(),
      PartnerContractTermFields.updatedAt: FieldValue.serverTimestamp(),
      PartnerContractTermFields.updatedByUid: adminUid,
    });
    batch.set(revision, {
      'at': FieldValue.serverTimestamp(),
      'uid': adminUid,
      'actor_name': actorName.trim(),
      'changes': [for (final change in changes) change.toMap()],
    });
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _promotions(String shopId) =>
      _shops.doc(shopId).collection('promotion_proposals');

  @override
  Future<List<PartnerPromotion>> listPartnerPromotions(
    String shopId, {
    int limit = 20,
  }) async {
    final snap = await _promotions(shopId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in snap.docs) PartnerPromotion.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  Future<PartnerPromotion> createPartnerPromotion({
    required String shopId,
    required String partnerUid,
    required String kind,
    required DateTime startsOn,
    required DateTime endsOn,
    required String note,
  }) async {
    validatePartnerPromotion(
      kind: kind,
      startsOn: startsOn,
      endsOn: endsOn,
      note: note,
    );
    final ref = _promotions(shopId).doc();
    final dayStart = DateTime(startsOn.year, startsOn.month, startsOn.day);
    final dayEnd = DateTime(endsOn.year, endsOn.month, endsOn.day);
    final trimmed = note.trim();
    await ref.set({
      'shop_id': shopId,
      'kind': kind,
      'starts_on': dayStart,
      'ends_on': dayEnd,
      'note': trimmed,
      'status': PartnerPromotionStatus.incoming.firestoreValue,
      'created_at': FieldValue.serverTimestamp(),
      'created_by_uid': partnerUid,
    });
    return PartnerPromotion(
      id: ref.id,
      shopId: shopId,
      kind: kind,
      startsOn: dayStart,
      endsOn: dayEnd,
      note: trimmed,
      status: PartnerPromotionStatus.incoming,
      createdAt: DateTime.now().toUtc(),
      createdByUid: partnerUid,
    );
  }

  @override
  Future<void> markPartnerPromotionHandled({
    required String shopId,
    required String proposalId,
    required String adminUid,
  }) {
    return _promotions(shopId).doc(proposalId).update({
      'status': PartnerPromotionStatus.handled.firestoreValue,
      'handled_at': FieldValue.serverTimestamp(),
      'handled_by_uid': adminUid,
    });
  }

  DocumentReference<Map<String, dynamic>> _partnerApplication(String uid) =>
      _db.collection('partner_applications').doc(uid);

  @override
  Future<PartnerApplication?> getPartnerApplication(String applicantUid) async {
    final snap = await _partnerApplication(applicantUid).get();
    if (!snap.exists) {
      return null;
    }
    return PartnerApplication.fromMap(snap.id, snap.data() ?? {});
  }

  @override
  Future<PartnerApplication> createPartnerApplication({
    required String applicantUid,
    required String loginId,
    required String shopName,
    required String contactName,
    required String phone,
    required String region,
    required String intro,
    required String link,
    required bool consent,
  }) async {
    validatePartnerApplication(
      shopName: shopName,
      contactName: contactName,
      phone: phone,
      region: region,
      intro: intro,
      link: link,
      consent: consent,
    );
    final login = loginId.trim();
    if (login.isEmpty || login.length > PartnerApplicationLimits.login) {
      throw const PartnerApplicationInvalid('login');
    }
    final ref = _partnerApplication(applicantUid);
    final trimmedLink = link.trim();
    await ref.set({
      'applicant_uid': applicantUid,
      'login_id': login,
      'shop_name': shopName.trim(),
      'contact_name': contactName.trim(),
      'phone': phone.trim(),
      'region': region.trim(),
      'intro': intro.trim(),
      'link': trimmedLink,
      'consent': true,
      'status': PartnerApplicationStatus.incoming.firestoreValue,
      'created_at': FieldValue.serverTimestamp(),
    });
    return PartnerApplication(
      applicantUid: applicantUid,
      loginId: login,
      shopName: shopName.trim(),
      contactName: contactName.trim(),
      phone: phone.trim(),
      region: region.trim(),
      intro: intro.trim(),
      link: trimmedLink,
      consent: true,
      status: PartnerApplicationStatus.incoming,
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<PartnerApplication>> listPartnerApplications() async {
    final snap = await _db.collection('partner_applications').get();
    return [
      for (final doc in snap.docs)
        PartnerApplication.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  Future<void> markPartnerApplicationHandled({
    required String applicantUid,
    required String adminUid,
  }) {
    return _partnerApplication(applicantUid).update({
      'status': PartnerApplicationStatus.handled.firestoreValue,
      'handled_at': FieldValue.serverTimestamp(),
      'handled_by_uid': adminUid,
    });
  }

  CollectionReference<Map<String, dynamic>> _partnerContracts(String shopId) =>
      _shops.doc(shopId).collection('partner_contracts');

  CollectionReference<Map<String, dynamic>> _partnerContractEvents(
    String shopId,
    String contractId,
  ) =>
      _partnerContracts(shopId).doc(contractId).collection('events');

  Future<void> _appendPartnerContractEvent({
    required String shopId,
    required String contractId,
    required PartnerContractEventType type,
    required String uid,
    required String docSha256,
    Map<String, dynamic>? meta,
  }) {
    return _partnerContractEvents(shopId, contractId).doc().set({
      'type': type.firestoreValue,
      'uid': uid,
      'at': FieldValue.serverTimestamp(),
      'doc_sha256': docSha256,
      if (meta != null && meta.isNotEmpty) 'meta': meta,
    });
  }

  @override
  Future<List<PartnerContract>> listPartnerContracts(
    String shopId, {
    bool forPartner = false,
  }) async {
    final spec = partnerContractListQuery(forPartner: forPartner);
    Query<Map<String, dynamic>> query = _partnerContracts(shopId);
    if (spec.statusIn.isNotEmpty) {
      query = query.where('status', whereIn: spec.statusIn);
    }
    if (spec.orderByUploadedAt) {
      query = query.orderBy('uploaded_at', descending: true);
    }
    final snap = await query.get();
    return [
      for (final doc in snap.docs)
        PartnerContract.fromDocument(doc.id, doc.data()),
    ];
  }

  @override
  Future<PartnerContract?> getPartnerContract({
    required String shopId,
    required String contractId,
  }) async {
    final snap = await _partnerContracts(shopId).doc(contractId).get();
    if (!snap.exists) {
      return null;
    }
    return PartnerContract.fromDocument(snap.id, snap.data() ?? {});
  }

  @override
  Future<List<PartnerContractEvent>> listPartnerContractEvents({
    required String shopId,
    required String contractId,
  }) async {
    final snap = await _partnerContractEvents(shopId, contractId)
        .orderBy('at', descending: false)
        .get();
    return [
      for (final doc in snap.docs)
        PartnerContractEvent.fromDocument(doc.id, doc.data()),
    ];
  }

  @override
  Future<PartnerContract> createPartnerContractDraft({
    required String shopId,
    required String adminUid,
    required PartnerContractKind kind,
    required String title,
    required String version,
    required String fileUrl,
    required String fileSha256,
    String fileContentType = 'application/pdf',
    DateTime? validFrom,
    DateTime? validUntil,
  }) async {
    final ref = _partnerContracts(shopId).doc();
    final payload = <String, dynamic>{
      'shop_id': shopId,
      'kind': kind.firestoreValue,
      'title': title.trim(),
      'version': version.trim().isEmpty ? '1' : version.trim(),
      'status': PartnerContractStatus.drafting.firestoreValue,
      'file_url': fileUrl,
      'file_sha256': fileSha256,
      'file_content_type': fileContentType,
      'uploaded_at': FieldValue.serverTimestamp(),
      'uploaded_by_uid': adminUid,
      if (validFrom != null) 'valid_from': Timestamp.fromDate(validFrom.toUtc()),
      if (validUntil != null)
        'valid_until': Timestamp.fromDate(validUntil.toUtc()),
      'signer_plan': [
        for (final step in PartnerContractSignerStep.defaultPlan())
          step.toMap(),
      ],
      'revision_note': '',
      'void_reason': '',
      'server_seal_hash': null,
      'identity_reauth_at': null,
      'composite_pdf_url': null,
      'external_esign_provider': null,
      'external_esign_envelope_id': null,
      'updated_at': FieldValue.serverTimestamp(),
    };
    await ref.set(payload);
    await _appendPartnerContractEvent(
      shopId: shopId,
      contractId: ref.id,
      type: PartnerContractEventType.uploaded,
      uid: adminUid,
      docSha256: fileSha256,
    );
    final created = await ref.get();
    return PartnerContract.fromDocument(ref.id, created.data() ?? payload);
  }

  @override
  Future<void> sendPartnerContract({
    required String shopId,
    required String contractId,
    required String adminUid,
  }) async {
    final ref = _partnerContracts(shopId).doc(contractId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('Contract not found');
    }
    final current = PartnerContract.fromDocument(snap.id, snap.data() ?? {});
    if (current.status != PartnerContractStatus.drafting &&
        current.status != PartnerContractStatus.awaitingSignature) {
      throw StateError('Cannot send sealed contract');
    }
    await ref.set({
      'status': PartnerContractStatus.awaitingSignature.firestoreValue,
      'sent_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _appendPartnerContractEvent(
      shopId: shopId,
      contractId: contractId,
      type: PartnerContractEventType.sent,
      uid: adminUid,
      docSha256: current.fileSha256,
    );
  }

  @override
  Future<void> voidPartnerContract({
    required String shopId,
    required String contractId,
    required String adminUid,
    String reason = '',
  }) async {
    final ref = _partnerContracts(shopId).doc(contractId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('Contract not found');
    }
    final current = PartnerContract.fromDocument(snap.id, snap.data() ?? {});
    if (current.isSealed) {
      throw StateError('Sealed contract cannot be voided');
    }
    await ref.set({
      'status': PartnerContractStatus.voided.firestoreValue,
      'voided_at': FieldValue.serverTimestamp(),
      'void_reason': reason.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _appendPartnerContractEvent(
      shopId: shopId,
      contractId: contractId,
      type: PartnerContractEventType.voided,
      uid: adminUid,
      docSha256: current.fileSha256,
      meta: {'reason': reason.trim()},
    );
  }

  @override
  Future<void> markPartnerContractViewed({
    required String shopId,
    required String contractId,
    required String partnerUid,
  }) async {
    final ref = _partnerContracts(shopId).doc(contractId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('Contract not found');
    }
    final current = PartnerContract.fromDocument(snap.id, snap.data() ?? {});
    if (current.status == PartnerContractStatus.drafting) {
      throw StateError('Draft hidden from partner');
    }
    if (!current.canPartnerAct) {
      return;
    }
    await ref.set({
      'last_viewed_at': FieldValue.serverTimestamp(),
      'last_viewed_by_uid': partnerUid,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _appendPartnerContractEvent(
      shopId: shopId,
      contractId: contractId,
      type: PartnerContractEventType.viewed,
      uid: partnerUid,
      docSha256: current.fileSha256,
    );
  }

  @override
  Future<void> requestPartnerContractRevision({
    required String shopId,
    required String contractId,
    required String partnerUid,
    required String memo,
  }) async {
    final ref = _partnerContracts(shopId).doc(contractId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('Contract not found');
    }
    final current = PartnerContract.fromDocument(snap.id, snap.data() ?? {});
    if (!current.canPartnerAct) {
      throw StateError('Not awaiting signature');
    }
    await ref.set({
      'revision_note': memo.trim(),
      'revision_requested_at': FieldValue.serverTimestamp(),
      'revision_requested_by_uid': partnerUid,
      'status': PartnerContractStatus.awaitingSignature.firestoreValue,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _appendPartnerContractEvent(
      shopId: shopId,
      contractId: contractId,
      type: PartnerContractEventType.revisionRequested,
      uid: partnerUid,
      docSha256: current.fileSha256,
      meta: {'memo': memo.trim()},
    );
  }

  @override
  Future<void> signPartnerContract({
    required String shopId,
    required String contractId,
    required String partnerUid,
    required String signerName,
    required String signaturePngBase64,
    required String expectedSha256,
  }) async {
    final ref = _partnerContracts(shopId).doc(contractId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('Contract not found');
    }
    final current = PartnerContract.fromDocument(snap.id, snap.data() ?? {});
    if (!current.canPartnerAct) {
      throw StateError('Not awaiting signature');
    }
    if (expectedSha256 != current.fileSha256) {
      throw StateError('file_sha256_mismatch');
    }
    await ref.set({
      'signature': {
        'signer_uid': partnerUid,
        'signer_name': signerName.trim(),
        'signature_png_base64': signaturePngBase64,
        'doc_sha256': current.fileSha256,
        'signed_at': FieldValue.serverTimestamp(),
      },
      'status': PartnerContractStatus.executed.firestoreValue,
      'executed_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _appendPartnerContractEvent(
      shopId: shopId,
      contractId: contractId,
      type: PartnerContractEventType.signed,
      uid: partnerUid,
      docSha256: current.fileSha256,
    );
    await _appendPartnerContractEvent(
      shopId: shopId,
      contractId: contractId,
      type: PartnerContractEventType.executed,
      uid: partnerUid,
      docSha256: current.fileSha256,
    );
  }

  @override
  Future<List<int>> fetchPartnerContractFileBytes(String fileUrl) async {
    final readable = await _photos.readableUrl(fileUrl);
    final response = await http.get(Uri.parse(readable));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Failed to download contract PDF (${response.statusCode})');
    }
    return response.bodyBytes;
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
    String? mapUrl,
    String? nearestHub,
    List<AccessRoute>? accessRoutes,
    String? featureBlurb,
    List<String>? featureTags,
    List<NearbySpot>? nearbySpots,
    String? localContact,
    String? checkIn,
    String? checkOut,
    String? businessHours,
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

    if (mapUrl != null && !isShopMapUrlValid(mapUrl)) {
      throw StateError('INVALID_MAP_URL');
    }

    final ref = _shops.doc(shopId);
    // Never read or write products[] here — unit prices live in the workbench.
    await ref.set({
      'name': name.trim(),
      'location': location.trim(),
      'product_name': productName.trim(),
      'consumer_price': consumerPrice,
      'professional_price': professionalPrice,
      if (intro != null) 'intro': intro.trim(),
      if (address != null) 'address': address.trim(),
      if (amenities != null) 'amenities': amenities,
      if (mapUrl != null) 'map_url': mapUrl.trim(),
      if (nearestHub != null) 'nearest_hub': nearestHub.trim(),
      if (accessRoutes != null)
        'access_routes': [
          for (final route in accessRoutes.take(kMaxAccessRoutes))
            if (!route.isEmpty) route.toMap(),
        ],
      if (featureBlurb != null) 'feature_blurb': featureBlurb.trim(),
      if (featureTags != null)
        'feature_tags': [
          for (final tag in featureTags.take(kMaxFeatureTags))
            if (tag.trim().isNotEmpty) clampShort(tag),
        ],
      if (nearbySpots != null)
        'nearby_spots': [
          for (final spot in nearbySpots.take(kMaxNearbySpots))
            if (!spot.isEmpty) spot.toMap(),
        ],
      if (localContact != null) 'local_contact': localContact.trim(),
      if (checkIn != null) 'check_in': checkIn.trim(),
      if (checkOut != null) 'check_out': checkOut.trim(),
      if (businessHours != null) 'business_hours': businessHours.trim(),
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
    bool clearAbsentFormFields = false,
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
    final rawProducts = snap.data()?['products'];
    final previousRaw = _rawProductMap(rawProducts, saved.id);
    final current = <String, Map<String, dynamic>>{
      for (final entry in _rawProductEntries(rawProducts))
        entry.key: entry.value,
    };
    // Keep an existing cover if the edit omitted bytes/url (avoids wiping R2).
    // An explicit gallery, even an empty one, is the new photo list.
    final previousCover = previousRaw?['cover_url'] as String? ?? '';
    if (gallery == null && saved.coverUrl.isEmpty && previousCover.isNotEmpty) {
      saved = saved.copyWith(coverUrl: previousCover);
    }
    current[saved.id] = ShopProduct.mergePersistedMap(
      previous: previousRaw,
      product: saved,
      clearAbsentFormFields: clearAbsentFormFields,
    );
    final next = current.values.toList();
    final coverForShop = saved.coverUrl.isNotEmpty
        ? saved.coverUrl
        : (snap.data()?['cover_url'] as String? ?? '');
    final written = current[saved.id];
    final previousProduct = previousRaw == null
        ? null
        : ShopProduct.fromMap(shopId, previousRaw);
    final nextProduct = written == null
        ? saved
        : ShopProduct.fromMap(shopId, written);
    final lines = productPriceCapacityChanges(
      previous: previousProduct,
      next: nextProduct,
    );
    final actor = _auth.currentUser?.uid ?? '';
    final batch = _db.batch();
    batch.set(ref, {
      'products': next,
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
    if (actor.isNotEmpty) {
      for (final line in lines) {
        batch.set(ref.collection('product_changes').doc(), {
          'product_id': line.productId,
          'option_id': line.optionId,
          'field': line.field,
          'before': line.before,
          'after': line.after,
          'actor_uid': actor,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  @override
  Future<List<ProductChangeRecord>> listProductChanges(String shopId) async {
    final snap =
        await _shops.doc(shopId).collection('product_changes').get();
    final rows = <ProductChangeRecord>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final created = data['created_at'];
      final at = created is Timestamp
          ? created.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0);
      rows.add(
        ProductChangeRecord(
          shopId: shopId,
          productId: data['product_id'] as String? ?? '',
          optionId: data['option_id'] as String? ?? '',
          field: data['field'] as String? ?? '',
          before: (data['before'] as num?)?.toInt() ?? 0,
          after: (data['after'] as num?)?.toInt() ?? 0,
          actorUid: data['actor_uid'] as String? ?? '',
          createdAt: at,
        ),
      );
    }
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (rows.length > 12) {
      return rows.sublist(0, 12);
    }
    return rows;
  }

  DocumentReference<Map<String, dynamic>> _dailyStatsDoc(
    String shopId,
    DateTime now,
  ) =>
      _shops.doc(shopId).collection('daily_stats').doc(shopDayId(now));

  @override
  Future<bool> recordShopDay({
    required String shopId,
    required DateTime now,
    bool visit = false,
    bool productView = false,
  }) async {
    if (!visit && !productView) {
      return false;
    }
    final ref = _dailyStatsDoc(shopId, now);
    return _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) {
        final created = ShopDayStats(
          dayId: ref.id,
          visits: visit ? 1 : 0,
          productViews: productView ? 1 : 0,
          dwellSeconds: 0,
        );
        if (!dailyStatsCreateAllowed(
          dayId: created.dayId,
          visits: created.visits,
          productViews: created.productViews,
          dwellSeconds: created.dwellSeconds,
        )) {
          return false;
        }
        transaction.set(ref, created.toMap());
        return true;
      }
      final data = snap.data() ?? const <String, dynamic>{};
      final visits = (data['visits'] as num?)?.toInt() ?? 0;
      final views = (data['product_views'] as num?)?.toInt() ?? 0;
      final dwell = (data['dwell_seconds'] as num?)?.toInt() ?? 0;
      final nextVisits = visits + (visit ? 1 : 0);
      final nextViews = views + (productView ? 1 : 0);
      if (!dailyStatsUpdateAllowed(
        exists: true,
        visits: visits,
        productViews: views,
        dwellSeconds: dwell,
        nextVisits: nextVisits,
        nextProductViews: nextViews,
        nextDwellSeconds: dwell,
      )) {
        return false;
      }
      transaction.update(ref, {
        'visits': nextVisits,
        'product_views': nextViews,
      });
      return true;
    });
  }

  @override
  Future<bool> recordShopDwell({
    required String shopId,
    required DateTime now,
    required int seconds,
  }) async {
    final delta = cappedDwellDelta(seconds);
    if (delta == 0) {
      return true;
    }
    final ref = _dailyStatsDoc(shopId, now);
    return _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) {
        return false;
      }
      final data = snap.data() ?? const <String, dynamic>{};
      final visits = (data['visits'] as num?)?.toInt() ?? 0;
      final views = (data['product_views'] as num?)?.toInt() ?? 0;
      final dwell = (data['dwell_seconds'] as num?)?.toInt() ?? 0;
      final nextDwell = dwell + delta;
      if (!dailyStatsUpdateAllowed(
        exists: true,
        visits: visits,
        productViews: views,
        dwellSeconds: dwell,
        nextVisits: visits,
        nextProductViews: views,
        nextDwellSeconds: nextDwell,
      )) {
        return false;
      }
      transaction.update(ref, {'dwell_seconds': nextDwell});
      return true;
    });
  }

  @override
  Future<List<ShopDayStats>> listShopDailyStats(String shopId) async {
    final snap = await _shops.doc(shopId).collection('daily_stats').get();
    final rows = <ShopDayStats>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      rows.add(
        ShopDayStats(
          dayId: doc.id,
          visits: (data['visits'] as num?)?.toInt() ?? 0,
          productViews: (data['product_views'] as num?)?.toInt() ?? 0,
          dwellSeconds: (data['dwell_seconds'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    rows.sort((a, b) => a.dayId.compareTo(b.dayId));
    return rows;
  }

  Map<String, dynamic>? _rawProductMap(dynamic raw, String productId) {
    for (final entry in _rawProductEntries(raw)) {
      if (entry.key == productId) {
        return entry.value;
      }
    }
    return null;
  }

  Iterable<MapEntry<String, Map<String, dynamic>>> _rawProductEntries(
    dynamic raw,
  ) sync* {
    if (raw is! List) {
      return;
    }
    for (final item in raw) {
      if (item is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(item);
      final id = map['id'] as String? ?? '';
      if (id.isEmpty) {
        continue;
      }
      yield MapEntry(id, map);
    }
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
    List<String> reasonTags = const [],
  }) async {
    final ref = _shops.doc(shopId);
    final snap = await ref.get();
    final current = ShopProduct.listFrom(shopId, snap.data()?['products']);
    final next = [
      for (final item in current)
        if (item.id == productId)
          ProductPublishGuard.applyStatusChange(
            product: item,
            status: status,
            reviewNote: reviewNote,
            reasonTags: reasonTags,
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
  Future<List<TourBooking>> fetchShopBookings(String shopId) async {
    final snapshot = await _shopBookings(shopId).get();
    final bookings = [
      for (final doc in snapshot.docs) _toBooking(doc.id, doc.data()),
    ];
    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }

  Future<List<TourBooking>> _shopBookingsInRange(
    String shopId, {
    required String field,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _shopBookings(shopId)
        .where(field, isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where(field, isLessThan: Timestamp.fromDate(end))
        .get();
    return [
      for (final doc in snapshot.docs) _toBooking(doc.id, doc.data()),
    ];
  }

  @override
  Future<List<TourBooking>> fetchShopBookingsCreatedBetween({
    required String shopId,
    required DateTime start,
    required DateTime end,
  }) {
    return _shopBookingsInRange(
      shopId,
      field: 'created_at',
      start: start,
      end: end,
    );
  }

  @override
  Future<List<TourBooking>> fetchShopBookingsCancelledBetween({
    required String shopId,
    required DateTime start,
    required DateTime end,
  }) {
    return _shopBookingsInRange(
      shopId,
      field: 'cancelled_at',
      start: start,
      end: end,
    );
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
  Stream<List<TourBooking>> watchLatestShopBookings(
    String shopId, {
    int limit = 5,
  }) {
    final capped = limit < 1 ? 5 : limit;
    return _shopBookings(shopId)
        .orderBy('created_at', descending: true)
        .limit(capped)
        .snapshots()
        .map((snapshot) {
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
    final userBookingRef = _bookings(uid).doc(bookingId);
    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(userBookingRef);
      if (!snap.exists) {
        return;
      }
      final booking = _toBooking(snap.id, snap.data() ?? {});
      if (!booking.isActive) {
        return;
      }
      if (booking.seatsHeld > 0 && booking.productId.isNotEmpty) {
        await _restoreSeatsInTxn(transaction, booking);
      }
      final quote = RefundPolicy.forUserCancel(tourDate: booking.scheduledFor);
      final nextPayment = !booking.isPaid
          ? PaymentStatus.unpaid
          : (quote.percent > 0
              ? PaymentStatus.refunded
              : PaymentStatus.captured);
      final patch = {
        'status': BookingStatus.cancelled.firestoreValue,
        'refund_percent': quote.percent,
        'refund_amount': quote.amountFor(booking.price),
        'payment_status': nextPayment.firestoreValue,
        'seats_held': 0,
        'cancelled_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      transaction.set(userBookingRef, patch, SetOptions(merge: true));
      transaction.set(
        _shopBookings(booking.shopId).doc(bookingId),
        patch,
        SetOptions(merge: true),
      );
    });
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
  Future<void> ackPartnerBooking({
    required String shopId,
    required String bookingId,
  }) async {
    final shopRef = _shopBookings(shopId).doc(bookingId);
    final snap = await shopRef.get();
    if (!snap.exists) {
      return;
    }
    await shopRef.set(
      {
        'partner_acked_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
      await _db.runTransaction((transaction) async {
        final freshShop = await transaction.get(doc.reference);
        if (!freshShop.exists) {
          return;
        }
        final fresh = _toBooking(freshShop.id, freshShop.data() ?? {});
        if (!fresh.isActive) {
          return;
        }
        if (fresh.seatsHeld > 0 && fresh.productId.isNotEmpty) {
          await _restoreSeatsInTxn(transaction, fresh);
        }
        final patch = {
          'status': BookingStatus.weatherCancelled.firestoreValue,
          'refund_percent': 100,
          'refund_amount': quote.amountFor(fresh.price),
          'payment_status': fresh.isPaid
              ? PaymentStatus.refunded.firestoreValue
              : PaymentStatus.unpaid.firestoreValue,
          'refund_notice_seen': false,
          'seats_held': 0,
          'cancelled_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };
        transaction.set(doc.reference, patch, SetOptions(merge: true));
        if (fresh.uid.isNotEmpty) {
          transaction.set(
            _bookings(fresh.uid).doc(fresh.id),
            patch,
            SetOptions(merge: true),
          );
        }
      });
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

  CollectionReference<Map<String, dynamic>> get _seatEvents =>
      _db.collection('seat_events');

  @override
  Future<bool> createSeatDemand(SeatDemand demand) async {
    if (!demand.withinShape) {
      debugPrint('seat demand rejected ${demand.id}');
      return false;
    }
    final wrote = await _createWithoutRead(
      _db.collection('seat_demand').doc(demand.id),
      Map<String, dynamic>.from(demand.toMap()),
      label: 'seat demand',
    );
    return wrote == _SeatWrite.created;
  }

  @override
  Future<bool> createSeatEvent(SeatLifeEvent event) async {
    if (!event.withinShape) {
      debugPrint('seat life event rejected ${event.id}');
      return false;
    }
    final data = Map<String, dynamic>.from(event.toStoredMap());
    data['at'] = event.at.toUtc();
    final wrote = await _createWithoutRead(_seatEvents.doc(event.id), data);
    return wrote == _SeatWrite.created;
  }

  @override
  Future<bool> bumpSeatDay({
    required String dayId,
    required String field,
  }) async {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dayId) ||
        !seatDayFields.contains(field)) {
      debugPrint('seat life day rejected $dayId $field');
      return false;
    }
    final ref = _db.collection('seat_daily').doc(dayId);
    try {
      await ref.update({field: FieldValue.increment(1)});
      return true;
    } on FirebaseException catch (error, stackTrace) {
      // A missing document is not `not-found`. The update rule reads
      // resource.data, that value is null, and Firestore returns
      // permission-denied. Create is still allowed.
      if (error.code != 'not-found' && error.code != 'permission-denied') {
        _logSeatFailure('day update', ref.path, error, stackTrace);
        return false;
      }
      final wrote = await _createWithoutRead(
        ref,
        Map<String, dynamic>.from(seatDayCreate(field)),
      );
      if (wrote == _SeatWrite.created) {
        return true;
      }
      if (wrote == _SeatWrite.duplicate && error.code == 'not-found') {
        try {
          await ref.update({field: FieldValue.increment(1)});
          return true;
        } on FirebaseException catch (retry, retryStack) {
          _logSeatFailure('day update', ref.path, retry, retryStack);
          return false;
        }
      }
      _logSeatFailure('day update', ref.path, error, stackTrace);
      return false;
    }
  }

  Future<_SeatWrite> _createWithoutRead(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data, {
    String label = 'seat life',
  }) async {
    final projectId = _db.app.options.projectId;
    final token = await _auth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      debugPrint('$label create failed (signed out) ${ref.path}');
      return _SeatWrite.failed;
    }
    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents/${ref.parent.path}'
      '?documentId=${Uri.encodeQueryComponent(ref.id)}',
    );
    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fields': seatRestFields(data)}),
      );
      if (response.statusCode == 200) {
        return _SeatWrite.created;
      }
      if (response.statusCode == 409 ||
          response.body.contains('ALREADY_EXISTS')) {
        debugPrint('$label duplicate ${ref.path}');
        return _SeatWrite.duplicate;
      }
      debugPrint(
        '$label create failed ${response.statusCode} ${ref.path} ${response.body}',
      );
      return _SeatWrite.failed;
    } catch (error, stackTrace) {
      debugPrint('$label create failed ${ref.path} $error');
      debugPrint('$stackTrace');
      return _SeatWrite.failed;
    }
  }

  @override
  Future<void> saveSeatOutcome(SeatOutcome outcome) async {
    final data = Map<String, dynamic>.from(outcome.toMap());
    if (!seatOutcomeAllowed(data)) {
      debugPrint('seat life outcome rejected ${outcome.seatId}');
      return;
    }
    final ref = _db.collection('seat_outcomes').doc(outcome.seatId);
    final snap = await ref.get();
    final existing = snap.data();
    if (existing != null && sameSeatMap(existing, data)) {
      return;
    }
    await ref.set(data);
  }

  @override
  Future<List<SeatLifeEvent>> listSeatEvents() async {
    final snap = await _seatEvents.get();
    final rows = <SeatLifeEvent>[];
    for (final doc in snap.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final at = data['at'];
      if (at is Timestamp) {
        data['at'] = at.toDate().toUtc().toIso8601String();
      }
      final parsed = SeatLifeEvent.fromMap(doc.id, data);
      if (parsed != null) {
        rows.add(parsed);
      }
    }
    return rows;
  }

  @override
  Future<List<SeatLifeEvent>> listSeatEventsBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    final snap = await _seatEvents
        .where('at', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('at', isLessThan: Timestamp.fromDate(to))
        .get();
    final rows = <SeatLifeEvent>[];
    for (final doc in snap.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      final at = data['at'];
      if (at is Timestamp) {
        data['at'] = at.toDate().toUtc().toIso8601String();
      }
      final parsed = SeatLifeEvent.fromMap(doc.id, data);
      if (parsed != null) {
        rows.add(parsed);
      }
    }
    return rows;
  }

  void _logSeatFailure(
    String action,
    String path,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('seat life $action failed $error $path');
    debugPrint('$stackTrace');
  }
}

enum _SeatWrite { created, duplicate, failed }
