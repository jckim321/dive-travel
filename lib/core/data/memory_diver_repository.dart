import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'package:dive_travel_app/core/auth/password_change.dart';
import 'package:dive_travel_app/core/auth/pending_profile.dart';
import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/member_profile_repair.dart';
import 'package:dive_travel_app/core/constants/nationality.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/models/shop_operating.dart';
import 'package:dive_travel_app/core/data/diver_repository.dart';
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
import 'package:dive_travel_app/core/models/partner_contract.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/core/models/partner_contract_terms.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/core/data/partner_provision.dart';
import 'package:dive_travel_app/core/models/shop_hull_id.dart';
import 'package:dive_travel_app/core/models/partner_application.dart';
import 'package:dive_travel_app/core/models/partner_promotion.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/active_seat_flag.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/core/models/review_detail_options.dart';
import 'package:dive_travel_app/core/models/product_publish_guard.dart';
import 'package:dive_travel_app/core/models/product_change.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';
import 'package:dive_travel_app/core/models/shop_day_stats.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/models/trial_data_cleanup.dart';

/// 위젯 테스트용 메모리 저장소. 프로덕션은 Firestore를 씁니다.
class MemoryDiverRepository implements DiverRepository {
  MemoryDiverRepository({AppUser? user}) : _user = user {
    _posts = [];
    _snapshot = DiverSnapshot.empty(
      displayName: user?.displayName ?? '다이버',
      isAdmin: _resolvedAdmin,
      isBusiness: _resolvedBusiness,
      ownedShopId: _ownedShopId ?? AppConstants.defaultPartnerShopId,
      memberGrade: _memberGrade,
    );
  }

  factory MemoryDiverRepository.forTest({
    bool isInstructor = false,
    bool isAdmin = false,
    bool isBusiness = false,
    String? ownedShopId,
    String birthDate = '',
    String phone = '',
  }) {
    final repo = MemoryDiverRepository(
      user: const AppUser(
        uid: 'test-user',
        email: 'test@dive.local',
        displayName: '테스트 다이버',
      ),
    );
    repo._isInstructor = isInstructor;
    repo._isAdmin = isAdmin;
    // H8: admin no longer implies partner — set isBusiness explicitly in tests.
    repo._isBusiness =
        isBusiness || AppConstants.grantBusinessToCurrentSession;
    repo._ownedShopId = ownedShopId ??
        (repo._isBusiness ? AppConstants.defaultPartnerShopId : null);
    repo._proStatus = isInstructor
        ? ProVerificationStatus.approved
        : ProVerificationStatus.none;
    repo._memberGrade = MemberGrade.silver;
    repo._seedAdminInbox();
    repo._snapshot = DiverSnapshot.empty(
      displayName: '테스트 다이버',
      isInstructor: isInstructor,
      proStatus: repo._proStatus,
      isAdmin: repo._resolvedAdmin,
      isBusiness: repo._resolvedBusiness,
      ownedShopId: repo._ownedShopId,
      memberGrade: repo._memberGrade,
      birthDate: birthDate,
      phone: phone,
    );
    return repo;
  }

  AppUser? _user;
  late DiverSnapshot _snapshot;
  int _logSequence = 0;
  int _bookingSequence = 0;

  /// Test-only: fail createBooking after the user copy, before the shop copy.
  /// Clears itself on use. Ensures purchase bump does not run on mid-fail.
  bool debugFailBeforeShopBookingWrite = false;

  /// Test-only: signup's profile ensure throws [ProfileWriteException].
  bool debugFailSignupProfile = false;

  /// Test-only: the next partner provision creates the diver, then fails
  /// before promote. Clears itself on use.
  bool debugFailNextPartnerPromote = false;

  /// How many Auth users [provisionPartner] created. Resumes do not increment.
  int partnerAuthCreateCount = 0;

  /// How many times [ensureUserDocument] ran.
  int debugEnsureCount = 0;

  /// Test-only: uids whose stored grade should be treated as missing.
  final debugMissingGradeUids = <String>{};

  /// Last admin repair field map, without timestamps.
  Map<String, Object?>? debugLastRepair;

  /// Test-only pause before a nationality save or clear finishes.
  Future<void> Function()? debugDelayNationalityWrite;

  /// Test-only pause before [saveShopProduct] writes.
  Future<void> Function()? debugDelayShopProductSave;

  /// When set for this shop, [fetchShopStat] returns it instead of storage.
  ShopLiveStats? debugFetchShopStatOverride;
  bool _isInstructor = false;
  bool _isAdmin = false;
  bool _isBusiness = false;
  String? _ownedShopId;
  ProVerificationStatus _proStatus = ProVerificationStatus.none;
  MemberGrade _memberGrade = MemberGrade.silver;
  final _shopStats = <String, ShopLiveStats>{};
  final _productChanges = <String, List<ProductChangeRecord>>{};
  final _dailyStats = <String, Map<String, ShopDayStats>>{};
  final _seatEvents = <String, Map<String, Object?>>{};
  final _seatDemands = <String, Map<String, Object>>{};
  final _seatDays = <String, Map<String, int>>{};
  final _seatOutcomes = <String, Map<String, Object?>>{};
  int debugSeatOutcomeWrites = 0;
  final _shopReviews = <String, List<GuestReview>>{};
  /// Running shop sums for accurate edit/delete (mirrors Firestore sum_*).
  final _shopReviewSums = <String, List<double>>{};
  final _myReviews = <String, List<GuestReview>>{};
  int _reviewSequence = 0;
  int _assessmentSequence = 0;
  int _shareSequence = 0;
  int _applicationSequence = 0;
  int _emailOutboxSequence = 0;
  DiveStarForm? _diveStarForm;
  final _formsByVersion = <String, DiveStarForm>{};
  final _assessments = <String, List<DiveStarAssessment>>{};
  List<PartnerDocument>? _partnerDocuments;
  final _partnerContracts = <String, List<PartnerContract>>{};
  final _partnerContractEvents = <String, List<PartnerContractEvent>>{};
  final _partnerContractFiles = <String, List<int>>{};
  final _contractTerms = <String, PartnerContractTerms>{};
  final _contractTermRevisions = <String, List<PartnerContractTermRevision>>{};
  final _promotions = <String, List<PartnerPromotion>>{};
  final _partnerApplications = <String, PartnerApplication>{};
  int promotionReadCount = 0;
  int applicationReadCount = 0;
  PartnerContractListQuery? lastPartnerContractListQuery;
  DiveStarApplicationListQuery? lastDiveStarApplicationListQuery;
  int _contractSequence = 0;
  int _contractTermRevisionSequence = 0;
  int _promotionSequence = 0;
  int _contractEventSequence = 0;
  PartnerDocConfig? _partnerDocConfig;
  final _documentShares = <DocumentShareRecord>[];
  final _applications = <DiveStarApplication>[];
  final _emailOutbox = <PartnerEmailOutboxItem>[];
  final _bookings = <TourBooking>[];
  final _pending = <PendingInstructor>[];
  final _members = <MemberAccount>[];
  late List<CommunityPost> _posts;
  final _shopBookings = <String, List<TourBooking>>{};
  final _comments = <String, List<CommunityComment>>{};
  final _activeSeatFlags = <String, List<ActiveSeatFlag>>{};
  int _postSequence = 0;
  int _commentSequence = 0;
  Future<void> _txnTail = Future<void>.value();

  /// Serializes seat mutations so concurrent plant/createBooking races are testable.
  Future<T> _runTxn<T>(Future<T> Function() body) {
    final done = Completer<T>();
    _txnTail = _txnTail.then((_) async {
      try {
        done.complete(await body());
      } catch (error, stack) {
        done.completeError(error, stack);
      }
    });
    return done.future;
  }

  List<ActiveSeatFlag> _flagsFor(String uid) =>
      List<ActiveSeatFlag>.from(_activeSeatFlags[uid] ?? const []);

  /// Test helper: mark a seeded shop paused, ended, or closed.
  void debugSetOperatingStatus(String shopId, ShopOperatingStatus status) {
    final current = _shopStats[shopId];
    if (current == null) {
      return;
    }
    _shopStats[shopId] = current.copyWith(operatingStatus: status);
    _shopController.add(_shopStats.values.toList());
  }

  /// Test helper: seed expired / live flag index rows without planting on a shop.
  void seedActiveSeatFlags(String uid, List<ActiveSeatFlag> flags) {
    _activeSeatFlags[uid] = List<ActiveSeatFlag>.from(flags);
  }

  List<ActiveSeatFlag> readActiveSeatFlags(String uid) => _flagsFor(uid);

  final _authController = StreamController<AppUser?>.broadcast();
  final _diverController = StreamController<DiverSnapshot>.broadcast();
  final _shopController = StreamController<List<ShopLiveStats>>.broadcast();
  final _bookingController = StreamController<List<TourBooking>>.broadcast();
  final _pendingController =
      StreamController<List<PendingInstructor>>.broadcast();
  final _membersController = StreamController<List<MemberAccount>>.broadcast();
  final _postsController = StreamController<List<CommunityPost>>.broadcast();
  final _shopBookingController =
      StreamController<List<TourBooking>>.broadcast();
  final _commentController =
      StreamController<List<CommunityComment>>.broadcast();
  final _discountController = StreamController<InstructorDiscount>.broadcast();
  InstructorDiscount _discount = InstructorDiscount.standard;

  bool get _resolvedBusiness => _isBusiness;

  bool get _resolvedAdmin => _isAdmin;

  void _seedAdminInbox() {
    if (_pending.isEmpty) {
      _pending.add(
        const PendingInstructor(
          uid: 'pending-instructor',
          email: 'instructor@dive.local',
          displayName: '대기 강사',
          agency: 'PADI',
          photoUrl: '',
        ),
      );
    }
    if (_members.isEmpty) {
      _members.add(
        MemberAccount(
          uid: _user?.uid ?? 'test-user',
          email: _user?.email ?? 'test@dive.local',
          displayName: _user?.displayName ?? '테스트 다이버',
          grade: _memberGrade,
          isAdmin: _resolvedAdmin,
          isInstructor: _isInstructor,
        ),
      );
      _members.add(
        MemberAccount(
          uid: 'pending-instructor',
          email: 'instructor@dive.local',
          displayName: '대기 강사',
          grade: MemberGrade.silver,
          totalLogCount: 12,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          lastSeenAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
    }
    _shopStats.putIfAbsent(
      'bohol-hideout',
      () => const ShopLiveStats(
        shopId: 'bohol-hideout',
        reviewCount: 12,
        avgSafety: 4.9,
        avgGuide: 4.8,
        avgBoat: 4.7,
        avgOverall: 4.8,
        diveStar: 2,
      ),
    );
  }

  void _emitSnapshot() {
    _diverController.add(_snapshot);
  }

  @override
  Stream<AppUser?> authState() async* {
    yield _user;
    yield* _authController.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    _authPassword = password;
    _user = AppUser(
      uid: 'memory-${email.hashCode}',
      email: email,
      displayName: email.split('@').first,
    );
    await ensureUserDocument(_user!);
    _authController.add(_user);
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
    await signIn(email: email, password: password);
    if (displayName != null && displayName.trim().isNotEmpty && _user != null) {
      _user = AppUser(
        uid: _user!.uid,
        email: _user!.email,
        displayName: displayName.trim(),
      );
      _authController.add(_user);
    }
    final id = (loginId ?? '').trim().toLowerCase();
    if (id.isNotEmpty && _user != null) {
      _loginIds[_user!.uid] = id;
    }
    if (debugFailSignupProfile) {
      debugFailSignupProfile = false;
      throw ProfileWriteException(uid: _user!.uid, code: 'permission-denied');
    }
    await ensureUserDocument(
      _user!,
      loginId: loginId,
      nationality: nationality,
      birthDate: birthDate,
      phone: phone,
      termsAccepted: termsAccepted,
      privacyAccepted: privacyAccepted,
      marketingOptIn: marketingOptIn,
    );
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _authPassword = null;
    _authController.add(null);
  }

  String? _authPassword;

  /// Test-only: next [changePassword] throws this [PasswordChangeException] code.
  /// Clears itself on use.
  String? debugPasswordChangeCode;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final forced = debugPasswordChangeCode;
    if (forced != null) {
      debugPasswordChangeCode = null;
      throw PasswordChangeException(forced);
    }
    final email = _user?.email?.trim() ?? '';
    if (_user == null || email.isEmpty || _authPassword == null) {
      throw const PasswordChangeException(PasswordChangeException.relogin);
    }
    if (newPassword.length < 6) {
      throw const PasswordChangeException(PasswordChangeException.tooShort);
    }
    if (currentPassword != _authPassword) {
      throw const PasswordChangeException(PasswordChangeException.wrong);
    }
    _authPassword = newPassword;
  }

  @override
  Future<AppUser?> currentAuthUser() async => _user;

  final _blocked = <String, bool>{};
  final _withdrawnAt = <String, DateTime>{};
  final _phones = <String, String>{};

  @override
  Future<bool> isLoginBlocked(String uid) async {
    return _blocked[uid] == true || _withdrawnAt.containsKey(uid);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  final _loginIds = <String, String>{};
  final _roleHistory = <String, List<Map<String, dynamic>>>{};
  final _createdShops = <String, String>{};

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
    final index = _members.indexWhere((m) => m.uid == uid);
    final member = index >= 0 ? _members[index] : null;
    final already = (member?.isBusiness ?? false) ||
        (uid == _user?.uid && _isBusiness);
    if (already) {
      throw StateError('ALREADY_PARTNER');
    }
    if (uid == _user?.uid) {
      _isBusiness = true;
      _ownedShopId = shop;
      _snapshot = DiverSnapshot.empty(
        displayName: _snapshot.stats.displayName,
        isInstructor: _isInstructor,
        proStatus: _proStatus,
        isAdmin: _resolvedAdmin,
        isBusiness: true,
        ownedShopId: shop,
        memberGrade: _memberGrade,
      );
      _diverController.add(_snapshot);
    }
    final entry = <String, dynamic>{
      'action': 'promote_partner',
      'by_uid': actorUid,
      'by_name': actorName,
      'shop_id': shop,
    };
    _roleHistory.putIfAbsent(uid, () => []).add(entry);
    if (index >= 0) {
      _members[index] = _members[index].copyWith(
        isBusiness: true,
        ownedShopId: shop,
        userRole: 'business',
      );
    } else {
      _members.add(
        MemberAccount(
          uid: uid,
          email: '',
          displayName: uid,
          grade: MemberGrade.silver,
          isBusiness: true,
          ownedShopId: shop,
          userRole: 'business',
        ),
      );
    }
    _membersController.add(List<MemberAccount>.from(_members));
  }

  @override
  Future<void> demoteMemberFromPartner({
    required String uid,
    required String actorUid,
    required String actorName,
  }) async {
    final index = _members.indexWhere((m) => m.uid == uid);
    final member = index >= 0 ? _members[index] : null;
    final was = (member?.isBusiness ?? false) ||
        (uid == _user?.uid && _isBusiness) ||
        ((member?.ownedShopId ?? '').isNotEmpty);
    if (!was) {
      throw StateError('NOT_PARTNER');
    }
    final prevShop = member?.ownedShopId.isNotEmpty == true
        ? member!.ownedShopId
        : _ownedShopId;
    if (uid == _user?.uid) {
      _isBusiness = false;
      _ownedShopId = null;
      _snapshot = DiverSnapshot.empty(
        displayName: _snapshot.stats.displayName,
        isInstructor: _isInstructor,
        proStatus: _proStatus,
        isAdmin: _resolvedAdmin,
        isBusiness: false,
        ownedShopId: null,
        memberGrade: _memberGrade,
      );
      _diverController.add(_snapshot);
    }
    _roleHistory.putIfAbsent(uid, () => []).add({
      'action': 'demote_partner',
      'by_uid': actorUid,
      'by_name': actorName,
      'shop_id': prevShop,
    });
    if (index >= 0) {
      _members[index] = _members[index].copyWith(
        isBusiness: false,
        ownedShopId: '',
        userRole: 'diver',
        clearOwnedShopId: true,
      );
    }
    _membersController.add(List<MemberAccount>.from(_members));
  }

  @override
  Future<String> createEmptyShop({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw StateError('SHOP_NAME_REQUIRED');
    }
    final id =
        'shop-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    _createdShops[id] = trimmed;
    _shopStats.putIfAbsent(
      id,
      () => ShopLiveStats(
        shopId: id,
        reviewCount: 0,
        avgSafety: 0,
        avgGuide: 0,
        avgBoat: 0,
        avgOverall: 0,
        diveStar: 0,
      ),
    );
    return id;
  }

  @override
  Future<ShopHullResolve> ensureShopHull({required String name}) async {
    final trimmed = name.trim();
    final hits = [
      for (final entry in _createdShops.entries)
        if (entry.value == trimmed)
          ShopHullChoice(documentId: entry.key, name: entry.value),
    ];
    final decision = decideShopHull(
      name: trimmed,
      sameName: hits,
      documentExists: _createdShops.containsKey,
      collisionSuffix: DateTime.now().millisecondsSinceEpoch.toRadixString(36),
    );
    if (decision.choices.length > 1) {
      return ShopHullResolve.choose(decision.choices);
    }
    if (decision.createId == null) {
      return ShopHullResolve.existing(decision.hullId);
    }
    final id = decision.createId!;
    if (_createdShops.containsKey(id)) {
      return ShopHullResolve.existing(id);
    }
    _createdShops[id] = trimmed;
    _shopStats.putIfAbsent(
      id,
      () => ShopLiveStats(
        shopId: id,
        reviewCount: 0,
        avgSafety: 0,
        avgGuide: 0,
        avgBoat: 0,
        avgOverall: 0,
        diveStar: 0,
      ),
    );
    return ShopHullResolve.created(id);
  }

  /// Test helper: role_history entries written by promote/demote.
  List<Map<String, dynamic>> roleHistoryFor(String uid) =>
      List<Map<String, dynamic>>.from(_roleHistory[uid] ?? const []);

  /// Test helper: plant a shop name for Jeju Orange resolve.
  void seedShopName(String shopId, String name) {
    _createdShops[shopId] = name;
  }

  /// Test helper: name stored for a shop document, if any.
  String? createdShopName(String shopId) => _createdShops[shopId];

  var _partnerUidSeq = 0;

  @override
  Future<PartnerProvisionResult> provisionPartner({
    required String shopName,
    required String loginId,
    required String password,
    required String actorUid,
    required String actorName,
    String? hullId,
  }) {
    final sessionUid = _user?.uid;
    return runPartnerProvision(
      shopName: shopName,
      loginId: loginId,
      password: password,
      actorUid: actorUid,
      actorName: actorName,
      selectedHullId: hullId,
      ensureShop: (name) => ensureShopHull(name: name),
      findLogin: (stored) async => _partnerLoginHit(stored),
      hullClaimedByOther: (hull, exceptUid) async {
        for (final member in _members) {
          if (member.uid == exceptUid) continue;
          if (member.ownedShopId.trim() == hull) return true;
        }
        return false;
      },
      createDiver: (draft) async {
        if (sessionUid != _user?.uid) {
          throw StateError('ADMIN_SESSION_LOST');
        }
        partnerAuthCreateCount += draft.signInExisting ? 0 : 1;
        final uid = 'partner-${_partnerUidSeq++}';
        _loginIds[uid] = draft.storedLoginId;
        _members.add(
          MemberAccount(
            uid: uid,
            email: draft.email,
            displayName: draft.displayName,
            grade: MemberGrade.silver,
            userRole: 'diver',
            loginId: draft.storedLoginId,
          ),
        );
        _membersController.add(List<MemberAccount>.from(_members));
        return ProvisionedDiver(uid: uid, createdAuth: !draft.signInExisting);
      },
      promote: ({
        required uid,
        required hullId,
        required actorUid,
        required actorName,
      }) async {
        if (debugFailNextPartnerPromote) {
          debugFailNextPartnerPromote = false;
          throw StateError('PROMOTE_FAILED');
        }
        await promoteMemberToPartner(
          uid: uid,
          shopId: hullId,
          actorUid: actorUid,
          actorName: actorName,
        );
      },
      primaryUid: () => _user?.uid,
    );
  }

  PartnerLoginHit? _partnerLoginHit(String stored) {
    for (final member in _members) {
      final id = member.loginId.isNotEmpty
          ? member.loginId
          : (_loginIds[member.uid] ?? '');
      if (id != stored) continue;
      return PartnerLoginHit(
        uid: member.uid,
        isBusiness: member.isBusiness,
        ownedShopId: member.ownedShopId,
        hasUserDoc: true,
      );
    }
    return null;
  }

  @override
  Future<void> fixPartnerShopHull({
    required String uid,
    required String shopId,
    required String actorUid,
    required String actorName,
  }) async {
    final hull = partnerShopHull(shopId);
    if (hull.isEmpty || hull.contains('--')) {
      throw StateError('SHOP_HULL_EMPTY');
    }
    final index = _members.indexWhere((member) => member.uid == uid);
    if (index < 0) {
      throw StateError('NOT_PARTNER');
    }
    final member = _members[index];
    final partner = member.isBusiness || member.ownedShopId.trim().isNotEmpty;
    if (!partner) {
      throw StateError('NOT_PARTNER');
    }
    for (final other in _members) {
      if (other.uid == uid) continue;
      if (other.ownedShopId.trim() == hull) {
        throw StateError('SHOP_ALREADY_OWNED');
      }
    }
    _roleHistory.putIfAbsent(uid, () => []).add({
      'action': 'fix_shop_hull',
      'by_uid': actorUid,
      'by_name': actorName,
      'shop_id': hull,
    });
    _members[index] = member.copyWith(
      isBusiness: true,
      ownedShopId: hull,
      userRole: 'business',
    );
    _membersController.add(List<MemberAccount>.from(_members));
  }

  @override
  Future<TrialDataSnapshot> fetchTrialDataCounts({
    required String actorUid,
    required String actorEmail,
  }) async {
    final exact = <({String id, String name})>[];
    final similar = <({String id, String name})>[];
    _createdShops.forEach((id, name) {
      if (name == kJejuOrangeShopName) {
        exact.add((id: id, name: name));
      } else if (name.contains('제주') && name.contains('오렌지')) {
        similar.add((id: id, name: name));
      }
    });
    // Also treat default catalog hull as trial unless seeded orange.
    JejuOrangeResolve jeju;
    if (exact.length == 1) {
      jeju = JejuOrangeResolve(
        kind: JejuOrangeResolveKind.exactOne,
        shopId: exact.first.id,
        shopName: exact.first.name,
        candidates: [...exact, ...similar],
      );
    } else if (exact.length > 1 || similar.length > 1) {
      jeju = JejuOrangeResolve(
        kind: JejuOrangeResolveKind.ambiguous,
        candidates: [...exact, ...similar],
      );
    } else if (similar.length == 1) {
      jeju = JejuOrangeResolve(
        kind: JejuOrangeResolveKind.ambiguous,
        candidates: similar,
      );
    } else {
      jeju = const JejuOrangeResolve(kind: JejuOrangeResolveKind.none);
    }

    final protected = <String>{actorUid};
    for (final m in _members) {
      if (AppOwner.isOwnerEmail(m.email) ||
          m.email.toLowerCase() == actorEmail.trim().toLowerCase() ||
          (jeju.protectedShopId != null &&
              m.ownedShopId == jeju.protectedShopId)) {
        protected.add(m.uid);
      }
    }

    final rows = [
      TrialCountRow(
        bucket: TrialDataBucket.usersTotal,
        label: '회원 전체',
        pathHint: 'users',
        status: TrialCountStatus.ok,
        count: _members.length,
        deletable: true,
      ),
      TrialCountRow(
        bucket: TrialDataBucket.shops,
        label: '샵',
        pathHint: 'shops',
        status: TrialCountStatus.ok,
        count: _createdShops.length,
        deletable: true,
      ),
      const TrialCountRow(
        bucket: TrialDataBucket.shopProductsEmbedded,
        label: '상품(임베디드)',
        pathHint: 'shops/*/products[]',
        status: TrialCountStatus.unavailable,
        detail: '샵 문서 배열이라 count() 불가',
      ),
      const TrialCountRow(
        bucket: TrialDataBucket.partnerContracts,
        label: '서류함 계약',
        pathHint: 'shops/*/partner_contracts',
        status: TrialCountStatus.ok,
        count: 0,
        protected: true,
        detail: '규칙상 삭제 불가',
      ),
      const TrialCountRow(
        bucket: TrialDataBucket.settingsPricing,
        label: 'settings/pricing',
        pathHint: 'settings/pricing',
        status: TrialCountStatus.unavailable,
        protected: true,
        detail: '앱에서 확인 불가',
      ),
    ];

    return TrialDataSnapshot(
      rows: rows,
      jejuOrange: jeju,
      protectedUserUids: protected,
      fetchedAt: DateTime.now(),
    );
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
    final snap = await fetchTrialDataCounts(
      actorUid: actorUid,
      actorEmail: actorEmail,
    );
    if (snap.jejuOrange.blocksDeletion) {
      throw StateError('JEJU_ORANGE_AMBIGUOUS');
    }
    final guard = trialDeletionGuard(
      snapshot: snap,
      includeJejuOrange: selection.includeJejuOrange,
      actorUid: actorUid,
      actorEmail: actorEmail,
      accounts: [
        for (final member in _members)
          (
            uid: member.uid,
            email: member.email,
            ownedShopId: member.ownedShopId,
          ),
      ],
    );
    final protected = guard.shopId;
    onProgress?.call(
      const TrialDeleteProgress(message: 'memory delete', done: 1, total: 1),
    );
    final notes = <String>[];
    if (selection.includeJejuOrange && snap.jejuOrange.protectedShopId != null) {
      notes.add(
        '이번 실행만 제주 오렌지 샵 보호를 풀었습니다. 관리자 본인·서류함·심사 양식·문서 설정은 남깁니다.',
      );
    }
    var success = 0;
    if (selection.trialShops) {
      final removeIds = [
        for (final id in _createdShops.keys)
          if (protected == null || id != protected) id,
      ];
      for (final id in removeIds) {
        _createdShops.remove(id);
        _shopStats.remove(id);
        success += 1;
        notes.add('샵 삭제 $id');
      }
    }
    if (selection.trialUsers) {
      final before = _members.length;
      _members.removeWhere((m) => !guard.userUids.contains(m.uid));
      success += before - _members.length;
      notes.add(
        'Auth 계정은 앱에서 못 지웁니다. Console → Authentication → Users에서 지우세요.',
      );
    }
    if (!selection.anySelected) {
      // unreachable
    }
    notes.add('서류함·확정 평가·R2·Auth는 남을 수 있습니다.');
    notes.add('건너뛴 항목: 없음');
    return TrialDeleteResult(
      successCount: success,
      failureCount: 0,
      notes: notes,
    );
  }

  String _nationality = '';
  DateTime? _nationalityConsentAt;
  List<SameBoatAlert> _seatAlerts = const [];
  String _birthDate = '';
  String _phone = '';
  final _consentByUid = <String, Map<String, Object?>>{};

  /// Test helper: last consent payload written for [uid].
  @visibleForTesting
  Map<String, Object?>? debugConsentFor(String uid) => _consentByUid[uid];

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
    debugEnsureCount += 1;
    final id = (loginId ?? '').trim().toLowerCase();
    if (id.isNotEmpty) {
      _loginIds[user.uid] = id;
    }
    final country = normalizeNationalityCode(nationality);
    if (country != null) {
      _nationality = country;
      _nationalityConsentAt = DateTime.now().toUtc();
    }
    final birth = (birthDate ?? '').trim();
    if (birth.isNotEmpty) {
      _birthDate = birth;
    }
    final contact = (phone ?? '').trim();
    if (contact.isNotEmpty) {
      _phone = contact;
    }
    final now = DateTime.now().toUtc();
    final consent = Map<String, Object?>.from(_consentByUid[user.uid] ?? {});
    if (termsAccepted == true) {
      consent['consent_terms'] = true;
      consent['consent_terms_at'] = now;
    }
    if (privacyAccepted == true) {
      consent['consent_privacy'] = true;
      consent['consent_privacy_at'] = now;
    }
    if (marketingOptIn != null) {
      consent['consent_marketing'] = marketingOptIn;
      consent['consent_marketing_at'] = now;
    }
    if (consent.isNotEmpty) {
      _consentByUid[user.uid] = consent;
    }
    final closed = _blocked[user.uid] == true || _withdrawnAt.containsKey(user.uid);
    final name = closed
        ? ''
        : (user.displayName ?? user.email?.split('@').first ?? '다이버');
    if (!closed && contact.isNotEmpty) {
      _phones[user.uid] = contact;
    }
    final index = _members.indexWhere((m) => m.uid == user.uid);
    if (index < 0) {
      _members.add(
        MemberAccount(
          uid: user.uid,
          email: user.email ?? '',
          displayName: name,
          grade: MemberGrade.silver,
          isAdmin: false,
          isInstructor: false,
          isBusiness: false,
          ownedShopId: '',
          loginId: _loginIds[user.uid] ?? '',
          phone: closed ? '' : (_phones[user.uid] ?? ''),
          accountBlocked: _blocked[user.uid] == true,
          withdrawnAt: _withdrawnAt[user.uid],
        ),
      );
      _membersController.add(List<MemberAccount>.from(_members));
    } else if (!closed) {
      final login = _loginIds[user.uid] ?? '';
      final current = _members[index];
      _members[index] = current.copyWith(
        email: current.email.trim().isEmpty ? (user.email ?? '') : null,
        displayName: current.displayName.trim().isEmpty ? name : null,
        loginId: login.isEmpty ? null : login,
        phone: contact.isEmpty ? null : contact,
      );
      _membersController.add(List<MemberAccount>.from(_members));
    }
    _snapshot = DiverSnapshot.empty(
      displayName: user.displayName ?? user.email?.split('@').first ?? '다이버',
      isInstructor: _isInstructor,
      proStatus: _proStatus == ProVerificationStatus.none && _isInstructor
          ? ProVerificationStatus.approved
          : _proStatus,
      isAdmin: _resolvedAdmin,
      isBusiness: _resolvedBusiness,
      ownedShopId: _ownedShopId,
      memberGrade: _memberGrade,
      nationality: _nationality,
      nationalityConsentAt: _nationalityConsentAt,
      birthDate: _birthDate,
      phone: _phone,
    );
    _diverController.add(_snapshot);
  }

  @override
  Future<void> adminRepairMemberProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final index = _members.indexWhere((member) => member.uid == uid);
    if (index < 0) return;
    final current = _members[index];
    final patch = memberProfileRepairPatch(
      gradeMissing: debugMissingGradeUids.contains(uid),
      existingEmail: current.email,
      existingName: current.displayName,
      email: email,
      displayName: displayName,
      uid: uid,
    );
    debugLastRepair = patch;
    if (patch.isEmpty) return;
    debugMissingGradeUids.remove(uid);
    _members[index] = current.copyWith(
      grade: patch.containsKey('member_grade') ? MemberGrade.silver : null,
      email: patch['email'] as String?,
      displayName: patch['display_name'] as String?,
    );
    _membersController.add(List<MemberAccount>.from(_members));
  }

  @override
  Future<void> setNationality({
    required String uid,
    required String code,
  }) async {
    if (_user?.uid != uid) {
      throw StateError('Sign in required');
    }
    final country = normalizeNationalityCode(code);
    if (country == null) {
      throw StateError('nationality');
    }
    final delay = debugDelayNationalityWrite;
    if (delay != null) {
      await delay();
    }
    _nationality = country;
    _nationalityConsentAt = DateTime.now().toUtc();
    _snapshot = DiverSnapshot(
      stats: _snapshot.stats.copyWith(
        nationality: _nationality,
        nationalityConsentAt: _nationalityConsentAt,
      ),
      regions: _snapshot.regions,
      logs: _snapshot.logs,
      favoriteShopIds: _snapshot.favoriteShopIds,
    );
    _diverController.add(_snapshot);
  }

  @override
  Future<void> clearNationality(String uid) async {
    if (_user?.uid != uid) {
      throw StateError('Sign in required');
    }
    final delay = debugDelayNationalityWrite;
    if (delay != null) {
      await delay();
    }
    _nationality = '';
    _nationalityConsentAt = null;
    _snapshot = DiverSnapshot(
      stats: _snapshot.stats.copyWith(
        nationality: '',
        clearNationalityConsentAt: true,
      ),
      regions: _snapshot.regions,
      logs: _snapshot.logs,
      favoriteShopIds: _snapshot.favoriteShopIds,
    );
    _diverController.add(_snapshot);
  }

  @override
  Future<void> saveSeatAlerts({
    required String uid,
    required List<SameBoatAlert> alerts,
  }) async {
    if (_user?.uid != uid) {
      throw StateError('Sign in required');
    }
    _seatAlerts = List<SameBoatAlert>.from(alerts);
    _diverController.add(_snapshot);
  }

  @override
  Stream<DiverSnapshot> watchDiver(String uid) async* {
    // Profile stream — strip logs so callers mirror Firestore on-demand logs.
    yield DiverSnapshot(
      stats: _snapshot.stats,
      regions: _snapshot.regions,
      logs: const [],
      favoriteShopIds: _snapshot.favoriteShopIds,
      seatAlerts: _seatAlerts,
    );
    yield* _diverController.stream.map(
      (snap) => DiverSnapshot(
        stats: snap.stats,
        regions: snap.regions,
        logs: const [],
        favoriteShopIds: snap.favoriteShopIds,
        seatAlerts: _seatAlerts,
      ),
    );
  }

  @override
  Future<DiveLogsPage> fetchDiveLogs(
    String uid, {
    int limit = 50,
    Object? cursor,
  }) async {
    final pageSize = limit < 1 ? 50 : limit;
    final all = [..._snapshot.logs]
      ..sort((a, b) => b.divedAt.compareTo(a.divedAt));
    var start = 0;
    if (cursor is int) {
      start = cursor.clamp(0, all.length);
    }
    final end = (start + pageSize).clamp(0, all.length);
    final page = all.sublist(start, end);
    final next = end < all.length ? end : null;
    return DiveLogsPage(
      logs: page,
      nextCursor: next,
      hasMore: next != null,
    );
  }

  @override
  Future<void> setFavoriteShop({
    required String uid,
    required String shopId,
    required bool favorite,
  }) async {
    final next = Set<String>.from(_snapshot.favoriteShopIds);
    if (favorite) {
      next.add(shopId);
    } else {
      next.remove(shopId);
    }
    _snapshot = DiverSnapshot(
      stats: _snapshot.stats,
      regions: _snapshot.regions,
      logs: _snapshot.logs,
      favoriteShopIds: next,
    );
    _emitSnapshot();
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
    _logSequence += 1;
    final logs = [
      DiveLog(
        id: 'memory-$_logSequence',
        siteName: trimmed,
        divedAt: divedAt,
        memo: memo.trim(),
        regionId: resolved.id,
        photoUrl: photoBytes == null ? null : 'memory://photo-$_logSequence',
        profile: profile,
        createdAt: DateTime.now(),
      ),
      ..._snapshot.logs,
    ];
    _snapshot = DiverSnapshot.fromLogs(
      displayName: _snapshot.stats.displayName,
      isInstructor: _snapshot.stats.isInstructor,
      proStatus: _snapshot.stats.proStatus,
      isAdmin: _snapshot.stats.isAdmin,
      isBusiness: _snapshot.stats.isBusiness,
      ownedShopId: _snapshot.stats.ownedShopId,
      memberGrade: _snapshot.stats.memberGrade,
      logs: logs,
      favoriteShopIds: _snapshot.favoriteShopIds,
    );
    _diverController.add(_snapshot);
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
    final logs = [
      for (final log in _snapshot.logs)
        if (log.id == logId)
          DiveLog(
            id: log.id,
            siteName: trimmed,
            divedAt: divedAt,
            memo: memo.trim(),
            regionId: resolved.id,
            photoUrl: removePhoto
                ? null
                : (photoBytes == null ? log.photoUrl : 'memory://photo-$logId'),
            profile: profile,
            createdAt: log.createdAt ?? log.writtenAt,
          )
        else
          log,
    ];
    _snapshot = DiverSnapshot.fromLogs(
      displayName: _snapshot.stats.displayName,
      isInstructor: _snapshot.stats.isInstructor,
      proStatus: _snapshot.stats.proStatus,
      isAdmin: _snapshot.stats.isAdmin,
      isBusiness: _snapshot.stats.isBusiness,
      ownedShopId: _snapshot.stats.ownedShopId,
      memberGrade: _snapshot.stats.memberGrade,
      logs: logs,
      favoriteShopIds: _snapshot.favoriteShopIds,
    );
    _diverController.add(_snapshot);
  }

  /// Test counter for shop-stats get calls (cache TTL).
  int fetchShopStatsCalls = 0;

  @override
  Future<List<ShopLiveStats>> fetchShopStats() async {
    fetchShopStatsCalls += 1;
    return _shopStats.values.toList();
  }

  @override
  Future<ShopLiveStats?> fetchShopStat(String shopId) async {
    final override = debugFetchShopStatOverride;
    final id = shopId.trim();
    if (override != null && override.shopId == id) {
      return override;
    }
    return _shopStats[id];
  }

  @override
  Stream<List<ShopLiveStats>> watchShopStats() async* {
    yield _shopStats.values.toList();
    yield* _shopController.stream;
  }

  @override
  Stream<List<TourBooking>> watchBookings(String uid) async* {
    List<TourBooking> forUid() => [
          for (final booking in _bookings)
            if (booking.uid == uid || uid.isEmpty) booking,
        ];
    yield forUid();
    yield* _bookingController.stream.map((_) => forUid());
  }

  @override
  Future<TourBooking?> createBooking({
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
  }) {
    return _runTxn(() async {
      final hullId = shopId.split('--').first;
      final shopRecord = _shopStats[hullId];
      if (shopRecord != null && !shopRecord.operatingStatus.acceptsCustomers) {
        return null;
      }
      final now = DateTime.now();
      final seatKey = seatOptionId;
      var seatsHeld = 0;

      if (productId != null && productId.isNotEmpty && partySize > 0) {
        final current = _shopStats[hullId];
        if (current == null) {
          return null;
        }
        ShopProduct? target;
        for (final item in current.products) {
          if (item.id == productId) {
            target = item;
            break;
          }
        }
        if (target == null) {
          return null;
        }
        final opens = target.opensEmptySeatsFor(seatKey);
        if (opens) {
          final before = target.bookedSeatsFor(seatKey);
          final captured = target.capturePayment(
            partySize,
            now,
            uid: uid,
            optionId: seatKey,
          );
          if (captured.bookedSeatsFor(seatKey) <= before) {
            return null;
          }
          seatsHeld = partySize;
          _shopStats[hullId] = current.copyWith(
            products: [
              for (final item in current.products)
                if (item.id == productId) captured else item,
            ],
          );
          _shopController.add(_shopStats.values.toList());
          final live = ActiveSeatFlag.liveOnly(_flagsFor(uid), now);
          _activeSeatFlags[uid] = ActiveSeatFlag.withoutProduct(
            live,
            hullId,
            productId,
          );
        }
      }

      _bookingSequence += 1;
      final booking = TourBooking(
        id: 'booking-$_bookingSequence',
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
      // Dual write: user copy keeps contact. Shop copy keeps the name only.
      _bookings.insert(0, booking);
      if (debugFailBeforeShopBookingWrite) {
        debugFailBeforeShopBookingWrite = false;
        _bookings.removeAt(0);
        _bookingController.add(List<TourBooking>.from(_bookings));
        return null;
      }
      _shopBookings.putIfAbsent(booking.shopId, () => []).insert(
            0,
            booking.copyWith(guestBirthDate: '', guestContact: ''),
          );
      _bookingController.add(List<TourBooking>.from(_bookings));
      _shopBookingController.add(
        List<TourBooking>.from(_shopBookings[booking.shopId] ?? const []),
      );
      if (paymentStatus == PaymentStatus.captured && uid.isNotEmpty) {
        _bumpActivityLocal(uid: uid, purchaseDelta: 1);
      }
      return booking;
    });
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
  }) {
    return _runTxn(() async {
      if (uid.isEmpty || partySize <= 0) {
        return SeatFlagPlant.unavailable;
      }
      final hull = shopId.split('--').first;
      final current = _shopStats[hull];
      if (current == null || !current.operatingStatus.acceptsCustomers) {
        return SeatFlagPlant.unavailable;
      }
      ShopProduct? target;
      for (final item in current.products) {
        if (item.id == productId) {
          target = item.pruneExpiredHolds(now);
          break;
        }
      }
      if (target == null) {
        return SeatFlagPlant.unavailable;
      }
      if (!target.opensEmptySeatsFor(optionId) ||
          !target.isBoardLiveFor(optionId)) {
        return SeatFlagPlant.unavailable;
      }
      final closeAt = target.flagClosesAtFor(optionId);
      if (ShopProduct.isTooLateToPlant(now, closeAt)) {
        return SeatFlagPlant.tooLate;
      }
      if (target.memberHasLiveFlagOnProduct(uid, now)) {
        return SeatFlagPlant.alreadyHeld;
      }

      var liveFlags = ActiveSeatFlag.liveOnly(_flagsFor(uid), now);
      _activeSeatFlags[uid] = liveFlags;
      if (liveFlags.length >= ActiveSeatFlag.maxLivePerUser) {
        return SeatFlagPlant.limitReached;
      }
      if (target.bookableSeatsFor(uid, now, optionId: optionId) < partySize) {
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
        return SeatFlagPlant.taken;
      }
      final hold = planted.liveFlagFor(uid, now, optionId: optionId)!;
      liveFlags = [
        ...liveFlags,
        ActiveSeatFlag(
          shopId: hull,
          productId: productId,
          optionId: optionId,
          expiresAt: hold.expiresAt,
        ),
      ];
      _activeSeatFlags[uid] = liveFlags;
      _shopStats[hull] = current.copyWith(
        products: [
          for (final item in current.products)
            if (item.id == productId) planted else item.pruneExpiredHolds(now),
        ],
      );
      _shopController.add(_shopStats.values.toList());
      return SeatFlagPlant.planted;
    });
  }

  @override
  Future<SeatFlagPlant> replaceSeatFlag({
    required String shopId,
    required String productId,
    required int partySize,
    required DateTime now,
    String optionId = '',
    String uid = '',
    int lockedPrice = 0,
  }) {
    return _runTxn(() async {
      if (uid.isEmpty || partySize <= 0) {
        return SeatFlagPlant.unavailable;
      }
      final hull = shopId.split('--').first;
      final current = _shopStats[hull];
      if (current == null) {
        return SeatFlagPlant.unavailable;
      }
      ShopProduct? target;
      for (final item in current.products) {
        if (item.id == productId) {
          target = item.pruneExpiredHolds(now);
          break;
        }
      }
      if (target == null || !target.memberHasLiveFlagOnProduct(uid, now)) {
        return SeatFlagPlant.unavailable;
      }
      final resolved = target.memberHasLiveFlag(uid, now, optionId: optionId)
          ? optionId
          : target.liveFlagOptionIdFor(uid, now);
      if (!target.opensEmptySeatsFor(resolved) ||
          !target.isBoardLiveFor(resolved)) {
        return SeatFlagPlant.unavailable;
      }
      if (target.bookableSeatsFor(uid, now, optionId: resolved) < partySize) {
        return SeatFlagPlant.taken;
      }
      final replaced = target.replaceFlagParty(
        partySize: partySize,
        now: now,
        optionId: resolved,
        uid: uid,
        lockedPrice: lockedPrice,
      );
      final hold = replaced.liveFlagFor(uid, now, optionId: resolved);
      if (hold == null || hold.seats != partySize) {
        return SeatFlagPlant.taken;
      }
      _shopStats[hull] = current.copyWith(
        products: [
          for (final item in current.products)
            if (item.id == productId) replaced else item.pruneExpiredHolds(now),
        ],
      );
      _shopController.add(_shopStats.values.toList());
      return SeatFlagPlant.planted;
    });
  }

  @override
  Future<bool> cancelSeatFlag({
    required String uid,
    required String shopId,
    required String productId,
    required DateTime now,
    String optionId = '',
  }) {
    return _runTxn(() async {
      if (uid.isEmpty) {
        return false;
      }
      final hull = shopId.split('--').first;
      final current = _shopStats[hull];
      if (current == null) {
        return false;
      }
      ShopProduct? target;
      for (final item in current.products) {
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
      _shopStats[hull] = current.copyWith(
        products: [
          for (final item in current.products)
            if (item.id == productId) next else item,
        ],
      );
      final live = ActiveSeatFlag.liveOnly(_flagsFor(uid), now);
      _activeSeatFlags[uid] = ActiveSeatFlag.withoutProduct(
        live,
        hull,
        productId,
      );
      _shopController.add(_shopStats.values.toList());
      return true;
    });
  }

  void _restoreSeatsIfNeeded(TourBooking booking) {
    if (booking.seatsHeld <= 0 || booking.productId.isEmpty) {
      return;
    }
    final current = _shopStats[booking.shopId];
    if (current == null) {
      return;
    }
    final seatKey = booking.seatsOptionKey;
    _shopStats[booking.shopId] = current.copyWith(
      products: [
        for (final item in current.products)
          if (item.id == booking.productId)
            item.releaseBookedSeats(booking.seatsHeld, optionId: seatKey)
          else
            item,
      ],
    );
    _shopController.add(_shopStats.values.toList());
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
    final booking = OperationReviewPolicy.requireEligibleBooking(
      bookingId: resolvedBookingId,
      bookings: _bookings,
      uid: uid,
      shopId: shopId,
    );

    final current = _shopStats[shopId];
    final prevSums = _shopReviewSums[shopId] ?? const [0.0, 0.0, 0.0];
    final count = (current?.reviewCount ?? 0) + 1;
    final sumSafety = prevSums[0] + safeSafety;
    final sumGuide = prevSums[1] + safeGuide;
    final sumBoat = prevSums[2] + safeBoat;
    _shopReviewSums[shopId] = [sumSafety, sumGuide, sumBoat];
    final avgSafety = sumSafety / count;
    final avgGuide = sumGuide / count;
    final avgBoat = sumBoat / count;
    final guestStars =
        ((safeSafety + safeGuide + safeBoat) / 3).round().clamp(1, 5);
    final productKey = (productId?.trim().isNotEmpty ?? false)
        ? productId!.trim()
        : booking.productId.trim();
    final optionKey = (optionId?.trim().isNotEmpty ?? false)
        ? optionId!.trim()
        : booking.optionId.trim();

    var link = ReviewProductLinkStatus.missingProductId;
    final products = <ShopProduct>[];
    if (productKey.isEmpty) {
      products.addAll(current?.products ?? const []);
      link = ReviewProductLinkStatus.missingProductId;
    } else {
      var found = false;
      for (final item in current?.products ?? const <ShopProduct>[]) {
        if (item.id == productKey) {
          found = true;
          products.add(
            item.withGuestStarReview(guestStars, optionId: optionKey),
          );
        } else {
          products.add(item);
        }
      }
      link = found
          ? ReviewProductLinkStatus.linked
          : ReviewProductLinkStatus.productNotFound;
    }
    _reviewSequence += 1;
    final review = GuestReview(
      id: 'review-$_reviewSequence',
      shopId: shopId,
      uid: uid,
      bookingId: resolvedBookingId,
      safety: safeSafety,
      guide: safeGuide,
      boat: safeBoat,
      stars: guestStars,
      comment: safeComment ?? '',
      createdAt: DateTime.now().toUtc(),
      authorDisplayName: authorDisplayName?.trim() ?? '',
      productId: productKey,
      optionId: optionKey,
      details: safeDetails,
    );
    final existing = _shopReviews[shopId] ?? <GuestReview>[];
    _shopReviews[shopId] = [review, ...existing];
    final mine = _myReviews[uid] ?? <GuestReview>[];
    _myReviews[uid] = [review, ...mine];
    _shopStats[shopId] = ShopLiveStats(
      shopId: shopId,
      reviewCount: count,
      avgSafety: avgSafety,
      avgGuide: avgGuide,
      avgBoat: avgBoat,
      avgOverall: DiveStar.overall(
        safety: avgSafety,
        guide: avgGuide,
        boat: avgBoat,
      ),
      // Keep admin-assigned grade; reviews must not recompute it.
      diveStar: current?.diveStar ?? 0,
      diveStarReviewedAt: current?.diveStarReviewedAt,
      diveStarExpiresAt: current?.diveStarExpiresAt,
      plaqueStatus: current?.plaqueStatus ?? PlaqueStatus.none,
      operatingStatus:
          current?.operatingStatus ?? ShopOperatingStatus.active,
      operatingNote: current?.operatingNote ?? '',
      name: current?.name,
      location: current?.location,
      country: current?.country,
      continent: current?.continent,
      curated: current?.curated ?? false,
      productName: current?.productName,
      consumerPrice: current?.consumerPrice,
      professionalPrice: current?.professionalPrice,
      commissionRate: current?.commissionRate ?? 0.12,
      internalScore: current?.internalScore ?? 0,
      products: products,
      intro: current?.intro,
      address: current?.address,
      coverUrl: current?.coverUrl,
      galleryUrls: current?.galleryUrls ?? const [],
      amenities: current?.amenities ?? const [],
    );
    final index = _bookings.indexWhere((item) => item.id == resolvedBookingId);
    if (index >= 0) {
      final old = _bookings[index];
      _bookings[index] = old.copyWith(reviewed: true);
      _bookingController.add(List<TourBooking>.from(_bookings));
    }
    _shopController.add(_shopStats.values.toList());
    _bumpActivityLocal(uid: uid, reviewDelta: 1);
    return OperationReviewOutcome(
      productLink: link,
      productId: productKey,
    );
  }

  @override
  Future<List<GuestReview>> listMyReviews(String uid) async {
    final list = List<GuestReview>.from(_myReviews[uid] ?? const []);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
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
    final shopList = _shopReviews[shopId] ?? <GuestReview>[];
    final index = shopList.indexWhere((item) => item.id == reviewId);
    if (index < 0) {
      throw StateError('Review not found');
    }
    final old = shopList[index];
    if (old.uid != uid) {
      throw StateError('Not your review');
    }
    final current = _shopStats[shopId];
    final count = current?.reviewCount ?? 0;
    if (count <= 0) {
      throw StateError('Shop has no reviews to update');
    }
    final prevSums = _shopReviewSums[shopId] ?? const [0.0, 0.0, 0.0];
    final sumSafety = prevSums[0] - old.safety + safeSafety;
    final sumGuide = prevSums[1] - old.guide + safeGuide;
    final sumBoat = prevSums[2] - old.boat + safeBoat;
    _shopReviewSums[shopId] = [sumSafety, sumGuide, sumBoat];
    final avgSafety = sumSafety / count;
    final avgGuide = sumGuide / count;
    final avgBoat = sumBoat / count;
    final oldGuest =
        ((old.safety + old.guide + old.boat) / 3).round().clamp(1, 5);
    final newGuest =
        ((safeSafety + safeGuide + safeBoat) / 3).round().clamp(1, 5);
    final products = <ShopProduct>[];
    for (final item in current?.products ?? const <ShopProduct>[]) {
      if (old.productId.isNotEmpty && item.id == old.productId) {
        products.add(
          item.replaceGuestStarReview(
            oldGuest,
            newGuest,
            optionId: old.optionId,
          ),
        );
      } else {
        products.add(item);
      }
    }
    final updated = GuestReview(
      id: old.id,
      shopId: old.shopId,
      uid: old.uid,
      bookingId: old.bookingId,
      safety: safeSafety,
      guide: safeGuide,
      boat: safeBoat,
      stars: newGuest,
      comment: safeComment ?? '',
      createdAt: old.createdAt,
      editedAt: DateTime.now().toUtc(),
      authorDisplayName: old.authorDisplayName,
      productId: old.productId,
      optionId: old.optionId,
      details: safeDetails,
    );
    shopList[index] = updated;
    _shopReviews[shopId] = shopList;
    final mine = _myReviews[uid] ?? <GuestReview>[];
    final myIndex = mine.indexWhere((item) => item.id == reviewId);
    if (myIndex >= 0) {
      mine[myIndex] = updated;
      _myReviews[uid] = mine;
    }
    if (current != null) {
      _shopStats[shopId] = ShopLiveStats(
        shopId: shopId,
        reviewCount: count,
        avgSafety: avgSafety,
        avgGuide: avgGuide,
        avgBoat: avgBoat,
        avgOverall: DiveStar.overall(
          safety: avgSafety,
          guide: avgGuide,
          boat: avgBoat,
        ),
        diveStar: current.diveStar,
        diveStarReviewedAt: current.diveStarReviewedAt,
        diveStarExpiresAt: current.diveStarExpiresAt,
        plaqueStatus: current.plaqueStatus,
        operatingStatus: current.operatingStatus,
        operatingNote: current.operatingNote,
        name: current.name,
        location: current.location,
        country: current.country,
        continent: current.continent,
        curated: current.curated,
        productName: current.productName,
        consumerPrice: current.consumerPrice,
        professionalPrice: current.professionalPrice,
        commissionRate: current.commissionRate,
        internalScore: current.internalScore,
        products: products,
        intro: current.intro,
        address: current.address,
        coverUrl: current.coverUrl,
        galleryUrls: current.galleryUrls,
        amenities: current.amenities,
      );
      _shopController.add(_shopStats.values.toList());
    }
  }

  @override
  Future<void> deleteOperationReview({
    required String uid,
    required String shopId,
    required String reviewId,
  }) async {
    final shopList = _shopReviews[shopId] ?? <GuestReview>[];
    final index = shopList.indexWhere((item) => item.id == reviewId);
    if (index < 0) {
      throw StateError('Review not found');
    }
    final old = shopList[index];
    if (old.uid != uid) {
      throw StateError('Not your review');
    }
    shopList.removeAt(index);
    _shopReviews[shopId] = shopList;
    final mine = _myReviews[uid] ?? <GuestReview>[];
    mine.removeWhere((item) => item.id == reviewId);
    _myReviews[uid] = mine;

    final current = _shopStats[shopId];
    final count = current?.reviewCount ?? 0;
    final nextCount = (count - 1).clamp(0, 1 << 30);
    final prevSums = _shopReviewSums[shopId] ?? const [0.0, 0.0, 0.0];
    final sumSafety = prevSums[0] - old.safety;
    final sumGuide = prevSums[1] - old.guide;
    final sumBoat = prevSums[2] - old.boat;
    _shopReviewSums[shopId] = nextCount == 0
        ? [0.0, 0.0, 0.0]
        : [sumSafety, sumGuide, sumBoat];
    final avgSafety = nextCount == 0 ? 0.0 : sumSafety / nextCount;
    final avgGuide = nextCount == 0 ? 0.0 : sumGuide / nextCount;
    final avgBoat = nextCount == 0 ? 0.0 : sumBoat / nextCount;
    final oldGuest =
        ((old.safety + old.guide + old.boat) / 3).round().clamp(1, 5);
    final products = <ShopProduct>[];
    for (final item in current?.products ?? const <ShopProduct>[]) {
      if (old.productId.isNotEmpty && item.id == old.productId) {
        products.add(
          item.removeGuestStarReview(oldGuest, optionId: old.optionId),
        );
      } else {
        products.add(item);
      }
    }
    if (old.bookingId.isNotEmpty) {
      final bIndex = _bookings.indexWhere((item) => item.id == old.bookingId);
      if (bIndex >= 0) {
        _bookings[bIndex] = _bookings[bIndex].copyWith(reviewed: false);
        _bookingController.add(List<TourBooking>.from(_bookings));
      }
    }
    if (current != null) {
      _shopStats[shopId] = ShopLiveStats(
        shopId: shopId,
        reviewCount: nextCount,
        avgSafety: avgSafety,
        avgGuide: avgGuide,
        avgBoat: avgBoat,
        avgOverall: nextCount == 0
            ? 0
            : DiveStar.overall(
                safety: avgSafety,
                guide: avgGuide,
                boat: avgBoat,
              ),
        diveStar: current.diveStar,
        diveStarReviewedAt: current.diveStarReviewedAt,
        diveStarExpiresAt: current.diveStarExpiresAt,
        plaqueStatus: current.plaqueStatus,
        operatingStatus: current.operatingStatus,
        operatingNote: current.operatingNote,
        name: current.name,
        location: current.location,
        country: current.country,
        continent: current.continent,
        curated: current.curated,
        productName: current.productName,
        consumerPrice: current.consumerPrice,
        professionalPrice: current.professionalPrice,
        commissionRate: current.commissionRate,
        internalScore: current.internalScore,
        products: products,
        intro: current.intro,
        address: current.address,
        coverUrl: current.coverUrl,
        galleryUrls: current.galleryUrls,
        amenities: current.amenities,
      );
      _shopController.add(_shopStats.values.toList());
    }
    _bumpActivityLocal(uid: uid, reviewDelta: -1);
  }

  /// Test helper: insert a booking into the in-memory list.
  void seedBooking(TourBooking booking) {
    _bookings.removeWhere((item) => item.id == booking.id);
    _bookings.add(booking);
    _bookingController.add(List<TourBooking>.from(_bookings));
  }

  @override
  Future<GuestReviewsPage> fetchShopReviewsPage({
    required String shopId,
    int limit = 10,
    Object? cursor,
  }) async {
    final pageSize = limit < 1 ? 10 : limit;
    final all = List<GuestReview>.from(_shopReviews[shopId] ?? const []);
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    var start = 0;
    if (cursor is int) {
      start = cursor;
    }
    if (start < 0) {
      start = 0;
    }
    if (start >= all.length) {
      return const GuestReviewsPage(reviews: [], hasMore: false);
    }
    final end = (start + pageSize).clamp(0, all.length);
    final page = all.sublist(start, end);
    final next = end;
    return GuestReviewsPage(
      reviews: page,
      hasMore: next < all.length,
      cursor: next < all.length ? next : null,
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
    _proStatus = ProVerificationStatus.pending;
    _snapshot = DiverSnapshot(
      stats: _snapshot.stats.copyWith(proStatus: _proStatus),
      regions: _snapshot.regions,
      logs: _snapshot.logs,
      favoriteShopIds: _snapshot.favoriteShopIds,
    );
    _pending.removeWhere((item) => item.uid == uid);
    _pending.add(
      PendingInstructor(
        uid: uid,
        email: _user?.email ?? '',
        displayName: _snapshot.stats.displayName,
        agency: agency,
        photoUrl: 'memory://ccard-$uid',
      ),
    );
    _diverController.add(_snapshot);
    _pendingController.add(List<PendingInstructor>.from(_pending));
  }

  @override
  Future<List<PendingInstructor>> fetchPendingInstructors() async {
    return List<PendingInstructor>.from(_pending);
  }

  @override
  Stream<List<PendingInstructor>> watchPendingInstructors() async* {
    yield List<PendingInstructor>.from(_pending);
    yield* _pendingController.stream;
  }

  @override
  Future<CommunityPostsPage> fetchCommunityPosts({
    int limit = 20,
    Object? cursor,
  }) async {
    final pageSize = limit < 1 ? 20 : limit;
    final all = [..._posts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    var start = 0;
    if (cursor is int) {
      start = cursor.clamp(0, all.length);
    }
    final end = (start + pageSize).clamp(0, all.length);
    final page = all.sublist(start, end);
    final next = end < all.length ? end : null;
    return CommunityPostsPage(
      posts: page,
      nextCursor: next,
      hasMore: next != null,
    );
  }

  @override
  Stream<List<CommunityPost>> watchCommunityPosts() async* {
    yield List<CommunityPost>.from(_posts);
    yield* _postsController.stream;
  }

  @override
  Future<void> ensureSeedPosts() async {
    _posts.removeWhere((post) => post.id.startsWith('seed-'));
    for (final key in _comments.keys.toList()) {
      if (key.startsWith('seed-')) {
        _comments.remove(key);
      }
    }
    _postsController.add(List<CommunityPost>.from(_posts));
  }

  @override
  Future<void> approveInstructor(String uid) async {
    _pending.removeWhere((item) => item.uid == uid);
    _pendingController.add(List<PendingInstructor>.from(_pending));
    final index = _members.indexWhere((member) => member.uid == uid);
    if (index >= 0) {
      _members[index] = _members[index].copyWith(isInstructor: true);
      _membersController.add(List<MemberAccount>.from(_members));
    }
    if (_user?.uid == uid) {
      _isInstructor = true;
      _proStatus = ProVerificationStatus.approved;
      _snapshot = DiverSnapshot(
        stats: _snapshot.stats.copyWith(
          isInstructor: true,
          proStatus: ProVerificationStatus.approved,
        ),
        regions: _snapshot.regions,
        logs: _snapshot.logs,
        favoriteShopIds: _snapshot.favoriteShopIds,
      );
      _emitSnapshot();
    }
  }

  @override
  Future<void> rejectInstructor(String uid) async {
    _pending.removeWhere((item) => item.uid == uid);
    _pendingController.add(List<PendingInstructor>.from(_pending));
    final index = _members.indexWhere((member) => member.uid == uid);
    if (index >= 0) {
      _members[index] = _members[index].copyWith(isInstructor: false);
      _membersController.add(List<MemberAccount>.from(_members));
    }
    if (_user?.uid == uid) {
      _isInstructor = false;
      _proStatus = ProVerificationStatus.rejected;
      _snapshot = DiverSnapshot(
        stats: _snapshot.stats.copyWith(
          isInstructor: false,
          proStatus: ProVerificationStatus.rejected,
        ),
        regions: _snapshot.regions,
        logs: _snapshot.logs,
        favoriteShopIds: _snapshot.favoriteShopIds,
      );
      _emitSnapshot();
    }
  }

  /// Test-only pause after the member list is copied, before it is returned.
  Future<void> Function()? debugDelayFetchMembers;

  @override
  Future<List<MemberAccount>> fetchMembers() async {
    final members = List<MemberAccount>.from(_members);
    members.sort(compareMembersByRecentLogin);
    final delay = debugDelayFetchMembers;
    if (delay != null) {
      await delay();
    }
    return members;
  }

  @override
  Stream<List<MemberAccount>> watchMembers() async* {
    yield List<MemberAccount>.from(_members);
    yield* _membersController.stream;
  }

  void _bumpActivityLocal({
    required String uid,
    int purchaseDelta = 0,
    int reviewDelta = 0,
  }) {
    final index = _members.indexWhere((item) => item.uid == uid);
    MemberAccount? member = index >= 0 ? _members[index] : null;
    final purchases = (member?.paidPurchaseCount ??
            (_user?.uid == uid ? _snapshot.stats.paidPurchaseCount : 0)) +
        purchaseDelta;
    final reviews = (member?.reviewCount ??
            (_user?.uid == uid ? _snapshot.stats.reviewCount : 0)) +
        reviewDelta;
    final locked = member?.gradeLocked ??
        (_user?.uid == uid && _snapshot.stats.gradeLocked);
    final current = member?.grade ??
        (_user?.uid == uid ? _snapshot.stats.memberGrade : MemberGrade.silver);
    final earned = MemberGrade.fromActivity(
      paidPurchases: purchases,
      reviews: reviews,
    );
    final upgraded =
        purchaseDelta == 1 && !locked && earned.rank > current.rank;
    final nextGrade = upgraded ? earned : current;
    if (index >= 0) {
      _members[index] = _members[index].copyWith(
        grade: nextGrade,
        paidPurchaseCount: purchases,
        reviewCount: reviews,
      );
    }
    _membersController.add(List<MemberAccount>.from(_members));
    if (_user?.uid == uid) {
      _memberGrade = nextGrade;
      _snapshot = DiverSnapshot(
        stats: _snapshot.stats.copyWith(
          memberGrade: nextGrade,
          paidPurchaseCount: purchases,
          reviewCount: reviews,
          gradeCelebrationPending: upgraded ? true : null,
          gradeCelebrationTo: upgraded ? earned : null,
        ),
        regions: _snapshot.regions,
        logs: _snapshot.logs,
        favoriteShopIds: _snapshot.favoriteShopIds,
      );
      _emitSnapshot();
    }
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
    final index = _members.indexWhere((m) => m.uid == uid);
    final currently = index >= 0 && _members[index].isAdmin;
    final adminCount = _members.where((m) => m.isAdmin).length;
    if (!admin && currently && adminCount <= 1) {
      throw StateError('ADMIN_LAST');
    }
    if (index >= 0) {
      _members[index] = _members[index].copyWith(isAdmin: admin);
      _membersController.add(List<MemberAccount>.from(_members));
    }
    if (_user?.uid == uid) {
      _isAdmin = admin;
    }
  }

  @override
  Future<void> setAccountBlocked({
    required String uid,
    required bool blocked,
  }) async {
    if (blocked) {
      _blocked[uid] = true;
    } else {
      _blocked.remove(uid);
    }
    final index = _members.indexWhere((m) => m.uid == uid);
    if (index >= 0) {
      _members[index] = _members[index].copyWith(accountBlocked: blocked);
      _membersController.add(List<MemberAccount>.from(_members));
    }
  }

  @override
  Future<void> withdrawMember(String uid) async {
    _withdrawnAt[uid] = DateTime.now().toUtc();
    _phones.remove(uid);
    final index = _members.indexWhere((m) => m.uid == uid);
    if (index >= 0) {
      _members[index] = _members[index].copyWith(
        displayName: '',
        phone: '',
        withdrawnAt: _withdrawnAt[uid],
      );
      _membersController.add(List<MemberAccount>.from(_members));
    }
  }

  @override
  Future<void> setMemberGrade({
    required String uid,
    required MemberGrade grade,
  }) async {
    final index = _members.indexWhere((item) => item.uid == uid);
    final prev = index >= 0 ? _members[index].grade : MemberGrade.silver;
    final celebrate = grade.rank > prev.rank;
    if (index >= 0) {
      _members[index] = _members[index].copyWith(
        grade: grade,
        gradeLocked: true,
      );
    } else {
      _members.add(
        MemberAccount(
          uid: uid,
          email: '',
          displayName: uid,
          grade: grade,
          gradeLocked: true,
        ),
      );
    }
    _membersController.add(List<MemberAccount>.from(_members));
    if (_user?.uid == uid) {
      _memberGrade = grade;
      _snapshot = DiverSnapshot(
        stats: _snapshot.stats.copyWith(
          memberGrade: grade,
          gradeLocked: true,
          gradeCelebrationPending: celebrate ? true : null,
          gradeCelebrationTo: celebrate ? grade : null,
        ),
        regions: _snapshot.regions,
        logs: _snapshot.logs,
        favoriteShopIds: _snapshot.favoriteShopIds,
      );
      _emitSnapshot();
    }
  }

  @override
  Future<void> unlockMemberGrade(String uid) async {
    final index = _members.indexWhere((item) => item.uid == uid);
    if (index >= 0) {
      _members[index] = _members[index].copyWith(gradeLocked: false);
      _membersController.add(List<MemberAccount>.from(_members));
    }
    if (_user?.uid == uid) {
      _snapshot = DiverSnapshot(
        stats: _snapshot.stats.copyWith(gradeLocked: false),
        regions: _snapshot.regions,
        logs: _snapshot.logs,
        favoriteShopIds: _snapshot.favoriteShopIds,
      );
      _emitSnapshot();
    }
  }

  @override
  Future<void> touchLastSeen(String uid) async {
    final now = DateTime.now();
    final index = _members.indexWhere((item) => item.uid == uid);
    if (index >= 0) {
      _members[index] = _members[index].copyWith(lastSeenAt: now);
      _membersController.add(List<MemberAccount>.from(_members));
    }
  }

  @override
  Future<void> clearGradeCelebration(String uid) async {
    if (_user?.uid == uid) {
      _snapshot = DiverSnapshot(
        stats: _snapshot.stats.copyWith(
          gradeCelebrationPending: false,
          clearCelebrationTo: true,
        ),
        regions: _snapshot.regions,
        logs: _snapshot.logs,
        favoriteShopIds: _snapshot.favoriteShopIds,
      );
      _emitSnapshot();
    }
  }

  @override
  Future<void> setPlaqueStatus({
    required String shopId,
    required PlaqueStatus status,
  }) async {
    final current = _shopStats[shopId];
    if (current == null) {
      _shopStats[shopId] = ShopLiveStats(
        shopId: shopId,
        reviewCount: 0,
        avgSafety: 0,
        avgGuide: 0,
        avgBoat: 0,
        avgOverall: 0,
        diveStar: 0,
        plaqueStatus: status,
      );
    } else {
      _shopStats[shopId] = current.copyWith(plaqueStatus: status);
    }
    _shopController.add(_shopStats.values.toList());
  }

  @override
  Future<void> setInternalScore({
    required String shopId,
    required int score,
  }) async {
    final clamped = score.clamp(0, 100);
    final current = _shopStats[shopId];
    if (current == null) {
      _shopStats[shopId] = ShopLiveStats(
        shopId: shopId,
        reviewCount: 0,
        avgSafety: 0,
        avgGuide: 0,
        avgBoat: 0,
        avgOverall: 0,
        diveStar: 0,
        internalScore: clamped,
      );
    } else {
      _shopStats[shopId] = current.copyWith(internalScore: clamped);
    }
    _shopController.add(_shopStats.values.toList());
  }

  @override
  Future<void> setDiveStarGrade({
    required String shopId,
    required int grade,
    required DateTime reviewedAt,
    required DateTime expiresAt,
  }) async {
    final clamped = DiveStar.clampGrade(grade);
    final current = _shopStats[shopId];
    if (current == null) {
      _shopStats[shopId] = ShopLiveStats(
        shopId: shopId,
        reviewCount: 0,
        avgSafety: 0,
        avgGuide: 0,
        avgBoat: 0,
        avgOverall: 0,
        diveStar: clamped,
        diveStarReviewedAt: reviewedAt.toUtc(),
        diveStarExpiresAt: expiresAt.toUtc(),
      );
    } else {
      _shopStats[shopId] = current.copyWith(
        diveStar: clamped,
        diveStarReviewedAt: reviewedAt.toUtc(),
        diveStarExpiresAt: expiresAt.toUtc(),
      );
    }
    _shopController.add(_shopStats.values.toList());
  }

  final _operatingEvents = <String, List<ShopOperatingEvent>>{};
  var _operatingEventSeq = 0;

  @override
  Future<void> setShopOperatingStatus({
    required String shopId,
    required ShopOperatingStatus status,
    required String note,
    required String byUid,
    required String byName,
  }) async {
    final id = shopId.trim();
    final safeNote = clampOperatingNote(note);
    final safeName = clampOperatingByName(byName, byUid);
    final current = _shopStats[id];
    final from = current?.operatingStatus ?? ShopOperatingStatus.active;
    if (current == null) {
      _shopStats[id] = ShopLiveStats(
        shopId: id,
        reviewCount: 0,
        avgSafety: 0,
        avgGuide: 0,
        avgBoat: 0,
        avgOverall: 0,
        diveStar: 0,
        operatingStatus: status,
        operatingNote: safeNote,
      );
    } else {
      _shopStats[id] = current.copyWith(
        operatingStatus: status,
        operatingNote: safeNote,
        setOperatingNote: true,
      );
    }
    _operatingEventSeq += 1;
    final events = _operatingEvents.putIfAbsent(id, () => []);
    events.insert(
      0,
      ShopOperatingEvent(
        id: 'operating-$_operatingEventSeq',
        at: DateTime.now().toUtc(),
        byUid: byUid,
        byName: safeName,
        kind: 'status',
        fromStatus: from,
        toStatus: status,
        note: safeNote,
      ),
    );
    _shopController.add(_shopStats.values.toList());
  }

  @override
  Future<List<ShopOperatingEvent>> fetchShopOperatingEvents(String shopId) async {
    final events = _operatingEvents[shopId.trim()] ?? const <ShopOperatingEvent>[];
    return List<ShopOperatingEvent>.from(events);
  }

  @override
  Future<ShopOwnerTransfer> transferShopOwner({
    required String shopId,
    required String toUid,
    required String byUid,
    required String byName,
    String? shopName,
  }) async {
    final id = shopId.trim();
    final nextUid = toUid.trim();
    if (id.isEmpty || nextUid.isEmpty) {
      throw StateError('OWNER_NOT_FOUND');
    }
    final toIndex = _members.indexWhere((member) => member.uid == nextUid);
    if (toIndex < 0) {
      throw StateError('OWNER_NOT_FOUND');
    }
    final target = _members[toIndex];
    if (target.isAdmin) {
      throw StateError('OWNER_IS_ADMIN');
    }
    if (target.isBusiness || target.ownedShopId.trim().isNotEmpty) {
      throw StateError('OWNER_HAS_SHOP');
    }
    final fromIndex = _members.indexWhere(
      (member) => member.ownedShopId.trim() == id,
    );
    if (fromIndex < 0) {
      throw StateError('NO_CURRENT_OWNER');
    }
    final previous = _members[fromIndex];
    if (previous.uid == target.uid) {
      throw StateError('SAME_OWNER');
    }
    final fromOwnerId = operatingOwnerHandle(
      uid: previous.uid,
      loginId: previous.loginId,
      email: previous.email,
    );
    final toOwnerId = operatingOwnerHandle(
      uid: target.uid,
      loginId: target.loginId,
      email: target.email,
    );
    final currentName = (_shopStats[id]?.name ?? '').trim();
    final requested = (shopName ?? '').trim();
    final rename = requested.isNotEmpty && requested != currentName;
    final fromName = rename ? clampOperatingShopName(currentName) : '';
    final toName = rename ? clampOperatingShopName(requested) : '';
    _members[fromIndex] = previous.copyWith(
      isBusiness: false,
      userRole: 'diver',
      clearOwnedShopId: true,
    );
    _members[toIndex] = target.copyWith(
      isBusiness: true,
      userRole: 'business',
      ownedShopId: id,
    );
    if (previous.uid == _user?.uid) {
      _isBusiness = false;
      _ownedShopId = null;
    }
    if (target.uid == _user?.uid) {
      _isBusiness = true;
      _ownedShopId = id;
    }
    _roleHistory.putIfAbsent(previous.uid, () => []).add({
      'action': 'transfer_owner_from',
      'by_uid': byUid,
      'by_name': byName,
      'shop_id': id,
    });
    _roleHistory.putIfAbsent(target.uid, () => []).add({
      'action': 'transfer_owner_to',
      'by_uid': byUid,
      'by_name': byName,
      'shop_id': id,
    });
    if (rename) {
      final current = _shopStats[id];
      if (current == null) {
        _shopStats[id] = ShopLiveStats(
          shopId: id,
          name: requested,
          reviewCount: 0,
          avgSafety: 0,
          avgGuide: 0,
          avgBoat: 0,
          avgOverall: 0,
          diveStar: 0,
        );
      } else {
        _shopStats[id] = current.copyWith(name: requested);
      }
    }
    _operatingEventSeq += 1;
    final events = _operatingEvents.putIfAbsent(id, () => []);
    events.insert(
      0,
      ShopOperatingEvent(
        id: 'operating-$_operatingEventSeq',
        at: DateTime.now().toUtc(),
        byUid: byUid,
        byName: clampOperatingByName(byName, byUid),
        kind: 'owner',
        fromOwnerId: fromOwnerId,
        toOwnerId: toOwnerId,
        fromName: fromName,
        toName: toName,
      ),
    );
    _membersController.add(List<MemberAccount>.from(_members));
    _shopController.add(_shopStats.values.toList());
    return ShopOwnerTransfer(
      fromUid: previous.uid,
      toUid: target.uid,
      fromOwnerId: fromOwnerId,
      toOwnerId: toOwnerId,
      fromName: fromName,
      toName: toName,
      appliedName: rename ? requested : '',
    );
  }

  @override
  Future<DiveStarForm> ensureActiveDiveStarForm() async {
    for (final form in _formsByVersion.values) {
      if (form.active) {
        _diveStarForm = form;
        return form;
      }
    }
    if (_diveStarForm != null && _diveStarForm!.active) {
      _formsByVersion.putIfAbsent(_diveStarForm!.version, () => _diveStarForm!);
      return _diveStarForm!;
    }
    final seed = DiveStarForm.v1();
    _diveStarForm = seed;
    _formsByVersion.putIfAbsent(seed.version, () => seed);
    return seed;
  }

  @override
  Future<DiveStarForm?> getDiveStarForm(String version) async {
    final id = version.trim();
    if (id.isEmpty) {
      return null;
    }
    return _formsByVersion[id] ??
        (_diveStarForm?.version == id ? _diveStarForm : null);
  }

  @override
  Future<List<DiveStarForm>> listDiveStarForms() async {
    final map = Map<String, DiveStarForm>.from(_formsByVersion);
    final active = _diveStarForm;
    if (active != null) {
      map.putIfAbsent(active.version, () => active);
    }
    final list = map.values.toList()
      ..sort((a, b) => a.version.compareTo(b.version));
    return list;
  }

  @override
  Future<DiveStarForm> importDiveStarFormDraft(DiveStarForm form) async {
    final id = form.version.trim();
    if (id.isEmpty) {
      throw StateError('Form version is required');
    }
    if (_formsByVersion.containsKey(id) || _diveStarForm?.version == id) {
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
    _formsByVersion[id] = draft;
    return draft;
  }

  @override
  Future<DiveStarForm> activateDiveStarForm(String version) async {
    final id = version.trim();
    if (id.isEmpty) {
      throw StateError('Form version is required');
    }
    if (_diveStarForm != null) {
      _formsByVersion.putIfAbsent(
        _diveStarForm!.version,
        () => _diveStarForm!,
      );
    }
    final existing = _formsByVersion[id];
    if (existing == null) {
      throw StateError('Form not found: $id');
    }
    for (final entry in _formsByVersion.entries.toList()) {
      _formsByVersion[entry.key] = DiveStarForm(
        version: entry.value.version,
        active: entry.key == id,
        status: entry.key == id
            ? DiveStarFormStatus.active
            : DiveStarFormStatus.draft,
        rules: entry.value.rules,
        gates: entry.value.gates,
        areas: entry.value.areas,
        items: entry.value.items,
        thresholds: entry.value.thresholds,
      );
    }
    final activated = _formsByVersion[id]!;
    _diveStarForm = activated;
    return activated;
  }

  @override
  Future<List<DiveStarAssessment>> listDiveStarAssessments(String shopId) async {
    final list = List<DiveStarAssessment>.from(_assessments[shopId] ?? const []);
    list.sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
    return list;
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
    DiveStarForm form;
    final version = formVersion?.trim() ?? '';
    if (version.isNotEmpty) {
      final found = await getDiveStarForm(version);
      if (found == null) {
        throw StateError('Form not found: $version');
      }
      form = found;
    } else {
      form = await ensureActiveDiveStarForm();
    }
    final clampedScores = {
      for (final area in form.areas)
        area.id: (scores[area.id] ?? 0).clamp(0, area.maxPoints),
    };
    final clampedItems = {
      for (final item in form.items)
        item.id: (itemScores[item.id] ?? 0).clamp(0, item.maxPoints),
    };
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
    final list = _assessments.putIfAbsent(shopId, () => []);
    final updating = assessmentId != null && assessmentId.isNotEmpty;
    if (updating) {
      final existingIndex = list.indexWhere((item) => item.id == assessmentId);
      if (existingIndex < 0) {
        throw StateError('Assessment not found: $assessmentId');
      }
      if (list[existingIndex].confirmed) {
        throw StateError('Confirmed assessments cannot be edited');
      }
    }
    final id = updating ? assessmentId! : 'assess-${++_assessmentSequence}';
    final assessment = DiveStarAssessment(
      id: id,
      shopId: shopId,
      formVersion: form.version,
      type: type,
      reviewedAt: reviewedAt.toUtc(),
      gates: gateMap,
      scores: areaScoresForStore,
      comments: {
        for (final entry in comments.entries)
          if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
      },
      itemScores: clampedItems,
      itemComments: {
        for (final entry in itemComments.entries)
          if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
      },
      areaNa: cleanedNa,
      countryGates: cleanedCountry,
      mysteryVisits: visits,
      auditors: cleanedAuditors,
      totalScore: result.totalScore,
      candidateGrade: result.candidateGrade,
      gatesPassed: result.gatesPassed,
    );
    final index = list.indexWhere((item) => item.id == id);
    if (index >= 0) {
      list[index] = assessment;
    } else {
      list.insert(0, assessment);
    }
    return assessment;
  }

  @override
  Future<DiveStarAssessment> confirmDiveStarAssessment({
    required String shopId,
    required String assessmentId,
    DateTime? expiresAt,
  }) async {
    final list = _assessments[shopId];
    if (list == null) {
      throw StateError('Assessment not found: $assessmentId');
    }
    final index = list.indexWhere((item) => item.id == assessmentId);
    if (index < 0) {
      throw StateError('Assessment not found: $assessmentId');
    }
    final assessment = list[index];
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
    final confirmed = assessment.copyWith(
      confirmed: true,
      confirmedAt: DateTime.now().toUtc(),
    );
    list[index] = confirmed;
    return confirmed;
  }

  @override
  Future<void> deleteDiveStarAssessment({
    required String shopId,
    required String assessmentId,
  }) async {
    final list = _assessments[shopId];
    if (list == null) {
      throw StateError('Assessment not found: $assessmentId');
    }
    final index = list.indexWhere((item) => item.id == assessmentId);
    if (index < 0) {
      throw StateError('Assessment not found: $assessmentId');
    }
    if (list[index].confirmed) {
      throw StateError('Confirmed assessments cannot be deleted');
    }
    list.removeAt(index);
  }

  @override
  Future<List<PartnerDocument>> ensurePartnerDocumentsSeeded() async {
    return _partnerDocuments ??= List<PartnerDocument>.from(
      PartnerDocument.phase1Seeds(),
    );
  }

  @override
  Future<List<PartnerDocument>> listApprovedPublicPartnerDocuments() async {
    final all = await ensurePartnerDocumentsSeeded();
    return [
      for (final doc in all)
        if (doc.audience == PartnerDocAudience.public &&
            doc.status == PartnerDocStatus.approved)
          doc,
    ];
  }

  @override
  Future<PartnerDocConfig> ensurePartnerDocConfig() async {
    return _partnerDocConfig ??= PartnerDocConfig.defaultConfig;
  }

  @override
  Future<void> savePartnerDocConfig(PartnerDocConfig config) async {
    _partnerDocConfig = config;
  }

  @override
  Future<void> updatePartnerDocumentStatus({
    required String documentId,
    required PartnerDocStatus status,
  }) async {
    final list = await ensurePartnerDocumentsSeeded();
    final index = list.indexWhere((item) => item.id == documentId);
    if (index < 0) {
      throw StateError('Document not found: $documentId');
    }
    list[index] = list[index].copyWith(status: status);
  }

  List<PartnerContract> _contractsFor(String shopId) =>
      _partnerContracts.putIfAbsent(shopId, () => []);

  String _eventKey(String shopId, String contractId) => '$shopId/$contractId';

  void _appendContractEvent({
    required String shopId,
    required String contractId,
    required PartnerContractEventType type,
    required String uid,
    required String docSha256,
    Map<String, dynamic> meta = const {},
  }) {
    final key = _eventKey(shopId, contractId);
    final list = _partnerContractEvents.putIfAbsent(key, () => []);
    list.add(
      PartnerContractEvent(
        id: 'cevt-${++_contractEventSequence}',
        type: type,
        uid: uid,
        at: DateTime.now().toUtc(),
        docSha256: docSha256,
        meta: meta,
      ),
    );
  }

  PartnerContract _requireContract(String shopId, String contractId) {
    final list = _contractsFor(shopId);
    final index = list.indexWhere((c) => c.id == contractId);
    if (index < 0) {
      throw StateError('Contract not found: $contractId');
    }
    return list[index];
  }

  void _replaceContract(PartnerContract next) {
    final list = _contractsFor(next.shopId);
    final index = list.indexWhere((c) => c.id == next.id);
    if (index < 0) {
      throw StateError('Contract not found: ${next.id}');
    }
    if (list[index].isSealed) {
      throw StateError('Sealed contract cannot be modified');
    }
    list[index] = next;
  }

  /// Test helper: seed PDF bytes for a vault file URL.
  void seedPartnerContractFile(String fileUrl, List<int> bytes) {
    _partnerContractFiles[fileUrl] = List<int>.from(bytes);
  }

  /// Test helper: insert a vault document without a write/read round trip.
  void seedPartnerContract(PartnerContract contract) {
    _contractsFor(contract.shopId).add(contract);
  }

  @override
  Future<List<PartnerContract>> listPartnerContracts(
    String shopId, {
    bool forPartner = false,
  }) async {
    final spec = partnerContractListQuery(forPartner: forPartner);
    lastPartnerContractListQuery = spec;
    var list = List<PartnerContract>.from(_contractsFor(shopId));
    if (spec.statusIn.isNotEmpty) {
      list = [
        for (final doc in list)
          if (spec.statusIn.contains(doc.status.firestoreValue)) doc,
      ];
    }
    if (spec.orderByUploadedAt) {
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    }
    return list;
  }

  @override
  Future<PartnerContract?> getPartnerContract({
    required String shopId,
    required String contractId,
  }) async {
    final list = _contractsFor(shopId);
    for (final item in list) {
      if (item.id == contractId) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<List<PartnerContractEvent>> listPartnerContractEvents({
    required String shopId,
    required String contractId,
  }) async {
    return List<PartnerContractEvent>.from(
      _partnerContractEvents[_eventKey(shopId, contractId)] ?? const [],
    );
  }

  @override
  Future<PartnerContractTerms?> getPartnerContractTerms(String shopId) async {
    return _contractTerms[shopId];
  }

  @override
  Future<List<PartnerContractTermRevision>> listPartnerContractTermRevisions(
    String shopId,
  ) async {
    final list = List<PartnerContractTermRevision>.from(
      _contractTermRevisions[shopId] ?? const [],
    );
    list.sort((a, b) => b.at.compareTo(a.at));
    return list;
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
    final now = DateTime.now().toUtc();
    final stored = PartnerContractTerms(
      commissionRatePercent: next.commissionRatePercent,
      partyDiscountPercent: next.partyDiscountPercent,
      seasonDiscountPercent: next.seasonDiscountPercent,
      instructorFocPay: next.instructorFocPay,
      instructorFocFree: next.instructorFocFree,
      validFrom: next.validFrom,
      validUntil: next.validUntil,
      updatedAt: now,
      updatedByUid: adminUid,
    );
    final revision = PartnerContractTermRevision(
      id: 'ctr-${++_contractTermRevisionSequence}',
      at: now,
      uid: adminUid,
      actorName: actorName.trim(),
      changes: List<PartnerContractTermChange>.from(changes),
    );
    _contractTerms[shopId] = stored;
    _contractTermRevisions.putIfAbsent(shopId, () => []).add(revision);
  }

  @override
  Future<List<PartnerPromotion>> listPartnerPromotions(
    String shopId, {
    int limit = 20,
  }) async {
    promotionReadCount++;
    final rows = List<PartnerPromotion>.from(_promotions[shopId] ?? const []);
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (rows.length > limit) {
      return rows.sublist(0, limit);
    }
    return rows;
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
    final created = PartnerPromotion(
      id: 'promo-${++_promotionSequence}',
      shopId: shopId,
      kind: kind,
      startsOn: DateTime(startsOn.year, startsOn.month, startsOn.day),
      endsOn: DateTime(endsOn.year, endsOn.month, endsOn.day),
      note: note.trim(),
      status: PartnerPromotionStatus.incoming,
      createdAt: DateTime.now().toUtc(),
      createdByUid: partnerUid,
    );
    _promotions.putIfAbsent(shopId, () => []).add(created);
    return created;
  }

  @override
  Future<void> markPartnerPromotionHandled({
    required String shopId,
    required String proposalId,
    required String adminUid,
  }) async {
    final list = _promotions[shopId];
    if (list == null) {
      throw StateError('Proposal not found: $proposalId');
    }
    final index = list.indexWhere((item) => item.id == proposalId);
    if (index < 0) {
      throw StateError('Proposal not found: $proposalId');
    }
    final current = list[index];
    if (current.status != PartnerPromotionStatus.incoming) {
      throw StateError('Proposal already handled: $proposalId');
    }
    list[index] = PartnerPromotion(
      id: current.id,
      shopId: current.shopId,
      kind: current.kind,
      startsOn: current.startsOn,
      endsOn: current.endsOn,
      note: current.note,
      status: PartnerPromotionStatus.handled,
      createdAt: current.createdAt,
      createdByUid: current.createdByUid,
      handledAt: DateTime.now().toUtc(),
      handledByUid: adminUid,
    );
  }

  @override
  Future<PartnerApplication?> getPartnerApplication(String applicantUid) async {
    applicationReadCount++;
    return _partnerApplications[applicantUid];
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
    if (_partnerApplications.containsKey(applicantUid)) {
      throw StateError('already');
    }
    final created = PartnerApplication(
      applicantUid: applicantUid,
      loginId: login,
      shopName: shopName.trim(),
      contactName: contactName.trim(),
      phone: phone.trim(),
      region: region.trim(),
      intro: intro.trim(),
      link: link.trim(),
      consent: true,
      status: PartnerApplicationStatus.incoming,
      createdAt: DateTime.now().toUtc(),
    );
    _partnerApplications[applicantUid] = created;
    return created;
  }

  @override
  Future<List<PartnerApplication>> listPartnerApplications() async {
    return List<PartnerApplication>.from(_partnerApplications.values);
  }

  @override
  Future<void> markPartnerApplicationHandled({
    required String applicantUid,
    required String adminUid,
  }) async {
    final current = _partnerApplications[applicantUid];
    if (current == null) {
      throw StateError('Application not found: $applicantUid');
    }
    if (current.status != PartnerApplicationStatus.incoming) {
      throw StateError('Application already handled: $applicantUid');
    }
    _partnerApplications[applicantUid] = PartnerApplication(
      applicantUid: current.applicantUid,
      loginId: current.loginId,
      shopName: current.shopName,
      contactName: current.contactName,
      phone: current.phone,
      region: current.region,
      intro: current.intro,
      link: current.link,
      consent: current.consent,
      status: PartnerApplicationStatus.handled,
      createdAt: current.createdAt,
      handledAt: DateTime.now().toUtc(),
      handledByUid: adminUid,
    );
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
    final now = DateTime.now().toUtc();
    final doc = PartnerContract(
      id: 'pct-${++_contractSequence}',
      shopId: shopId,
      kind: kind,
      title: title.trim(),
      version: version.trim().isEmpty ? '1' : version.trim(),
      status: PartnerContractStatus.drafting,
      fileUrl: fileUrl,
      fileSha256: fileSha256,
      fileContentType: fileContentType,
      uploadedAt: now,
      uploadedByUid: adminUid,
      validFrom: validFrom,
      validUntil: validUntil,
      signerPlan: PartnerContractSignerStep.defaultPlan(),
    );
    _contractsFor(shopId).insert(0, doc);
    _appendContractEvent(
      shopId: shopId,
      contractId: doc.id,
      type: PartnerContractEventType.uploaded,
      uid: adminUid,
      docSha256: fileSha256,
    );
    return doc;
  }

  @override
  Future<void> sendPartnerContract({
    required String shopId,
    required String contractId,
    required String adminUid,
  }) async {
    final current = _requireContract(shopId, contractId);
    if (current.status != PartnerContractStatus.drafting &&
        current.status != PartnerContractStatus.awaitingSignature) {
      throw StateError('Cannot send sealed contract');
    }
    final now = DateTime.now().toUtc();
    _replaceContract(
      PartnerContract(
        id: current.id,
        shopId: current.shopId,
        kind: current.kind,
        title: current.title,
        version: current.version,
        status: PartnerContractStatus.awaitingSignature,
        fileUrl: current.fileUrl,
        fileSha256: current.fileSha256,
        fileContentType: current.fileContentType,
        uploadedAt: current.uploadedAt,
        uploadedByUid: current.uploadedByUid,
        validFrom: current.validFrom,
        validUntil: current.validUntil,
        sentAt: now,
        executedAt: current.executedAt,
        voidedAt: current.voidedAt,
        voidReason: current.voidReason,
        signerPlan: current.signerPlan,
        signature: current.signature,
        revisionNote: current.revisionNote,
        revisionRequestedAt: current.revisionRequestedAt,
        lastViewedAt: current.lastViewedAt,
      ),
    );
    _appendContractEvent(
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
    final current = _requireContract(shopId, contractId);
    if (current.status == PartnerContractStatus.executed ||
        current.status == PartnerContractStatus.voided) {
      throw StateError('Sealed contract cannot be voided again');
    }
    final now = DateTime.now().toUtc();
    _replaceContract(
      PartnerContract(
        id: current.id,
        shopId: current.shopId,
        kind: current.kind,
        title: current.title,
        version: current.version,
        status: PartnerContractStatus.voided,
        fileUrl: current.fileUrl,
        fileSha256: current.fileSha256,
        fileContentType: current.fileContentType,
        uploadedAt: current.uploadedAt,
        uploadedByUid: current.uploadedByUid,
        validFrom: current.validFrom,
        validUntil: current.validUntil,
        sentAt: current.sentAt,
        executedAt: current.executedAt,
        voidedAt: now,
        voidReason: reason.trim(),
        signerPlan: current.signerPlan,
        signature: current.signature,
        revisionNote: current.revisionNote,
        revisionRequestedAt: current.revisionRequestedAt,
        lastViewedAt: current.lastViewedAt,
      ),
    );
    _appendContractEvent(
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
    final current = _requireContract(shopId, contractId);
    if (current.status == PartnerContractStatus.drafting) {
      throw StateError('Draft hidden from partner');
    }
    if (!current.canPartnerAct) {
      return;
    }
    final now = DateTime.now().toUtc();
    _replaceContract(
      PartnerContract(
        id: current.id,
        shopId: current.shopId,
        kind: current.kind,
        title: current.title,
        version: current.version,
        status: current.status,
        fileUrl: current.fileUrl,
        fileSha256: current.fileSha256,
        fileContentType: current.fileContentType,
        uploadedAt: current.uploadedAt,
        uploadedByUid: current.uploadedByUid,
        validFrom: current.validFrom,
        validUntil: current.validUntil,
        sentAt: current.sentAt,
        executedAt: current.executedAt,
        voidedAt: current.voidedAt,
        voidReason: current.voidReason,
        signerPlan: current.signerPlan,
        signature: current.signature,
        revisionNote: current.revisionNote,
        revisionRequestedAt: current.revisionRequestedAt,
        lastViewedAt: now,
      ),
    );
    _appendContractEvent(
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
    final current = _requireContract(shopId, contractId);
    if (!current.canPartnerAct) {
      throw StateError('Not awaiting signature');
    }
    final now = DateTime.now().toUtc();
    _replaceContract(
      PartnerContract(
        id: current.id,
        shopId: current.shopId,
        kind: current.kind,
        title: current.title,
        version: current.version,
        status: PartnerContractStatus.awaitingSignature,
        fileUrl: current.fileUrl,
        fileSha256: current.fileSha256,
        fileContentType: current.fileContentType,
        uploadedAt: current.uploadedAt,
        uploadedByUid: current.uploadedByUid,
        validFrom: current.validFrom,
        validUntil: current.validUntil,
        sentAt: current.sentAt,
        executedAt: current.executedAt,
        voidedAt: current.voidedAt,
        voidReason: current.voidReason,
        signerPlan: current.signerPlan,
        signature: current.signature,
        revisionNote: memo.trim(),
        revisionRequestedAt: now,
        lastViewedAt: current.lastViewedAt,
      ),
    );
    _appendContractEvent(
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
    final current = _requireContract(shopId, contractId);
    if (!current.canPartnerAct) {
      throw StateError('Not awaiting signature');
    }
    if (expectedSha256 != current.fileSha256) {
      throw StateError('file_sha256_mismatch');
    }
    final now = DateTime.now().toUtc();
    final signature = PartnerContractSignature(
      signerUid: partnerUid,
      signerName: signerName.trim(),
      signaturePngBase64: signaturePngBase64,
      signedAt: now,
      docSha256: current.fileSha256,
    );
    _replaceContract(
      PartnerContract(
        id: current.id,
        shopId: current.shopId,
        kind: current.kind,
        title: current.title,
        version: current.version,
        status: PartnerContractStatus.executed,
        fileUrl: current.fileUrl,
        fileSha256: current.fileSha256,
        fileContentType: current.fileContentType,
        uploadedAt: current.uploadedAt,
        uploadedByUid: current.uploadedByUid,
        validFrom: current.validFrom,
        validUntil: current.validUntil,
        sentAt: current.sentAt,
        executedAt: now,
        voidedAt: current.voidedAt,
        voidReason: current.voidReason,
        signerPlan: current.signerPlan,
        signature: signature,
        revisionNote: current.revisionNote,
        revisionRequestedAt: current.revisionRequestedAt,
        lastViewedAt: current.lastViewedAt,
      ),
    );
    _appendContractEvent(
      shopId: shopId,
      contractId: contractId,
      type: PartnerContractEventType.signed,
      uid: partnerUid,
      docSha256: current.fileSha256,
    );
    _appendContractEvent(
      shopId: shopId,
      contractId: contractId,
      type: PartnerContractEventType.executed,
      uid: partnerUid,
      docSha256: current.fileSha256,
    );
  }

  @override
  Future<List<int>> fetchPartnerContractFileBytes(String fileUrl) async {
    final bytes = _partnerContractFiles[fileUrl];
    if (bytes == null) {
      throw StateError('Contract file not found in memory store');
    }
    return List<int>.from(bytes);
  }

  @override
  Future<List<DocumentShareRecord>> listDocumentShares({int limit = 50}) async {
    final list = List<DocumentShareRecord>.from(_documentShares);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
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
    final record = DocumentShareRecord(
      id: 'share-${++_shareSequence}',
      documentId: documentId,
      documentTitle: documentTitle,
      shopId: shopId,
      shopName: shopName,
      method: method,
      adminUid: adminUid,
      createdAt: DateTime.now().toUtc(),
    );
    _documentShares.insert(0, record);
    return record;
  }

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
    final now = DateTime.now().toUtc();
    final app = DiveStarApplication(
      id: 'app-${++_applicationSequence}',
      shopId: shopId,
      shopName: shopName,
      partnerUid: partnerUid,
      companyName: companyName.trim(),
      contactName: contactName.trim(),
      contactEmail: contactEmail.trim(),
      contactPhone: contactPhone.trim(),
      country: country.trim(),
      notes: notes.trim(),
      signaturePngBase64: signaturePngBase64,
      pipelineStatus: DiveStarPipelineStatus.loiReceived,
      submittedAt: now,
      reminderDueAt: now.add(const Duration(days: 14)),
    );
    _applications.insert(0, app);
    return app;
  }

  @override
  Future<List<DiveStarApplication>> listDiveStarApplications({
    String? shopId,
    String? partnerUid,
    int limit = 50,
  }) async {
    lastDiveStarApplicationListQuery = DiveStarApplicationListQuery(
      shopId: shopId,
      partnerUid: partnerUid,
    );
    var list = List<DiveStarApplication>.from(_applications);
    if (partnerUid != null && partnerUid.isNotEmpty) {
      list = [for (final a in list) if (a.partnerUid == partnerUid) a];
    } else if (shopId != null && shopId.isNotEmpty) {
      list = [for (final a in list) if (a.shopId == shopId) a];
    }
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    if (list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
  }

  @override
  Future<DiveStarApplication> updateDiveStarApplicationPipeline({
    required String applicationId,
    required DiveStarPipelineStatus status,
    DateTime? reminderDueAt,
    bool clearReminder = false,
  }) async {
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index < 0) {
      throw StateError('Application not found: $applicationId');
    }
    final updated = _applications[index].copyWith(
      pipelineStatus: status,
      reminderDueAt: reminderDueAt,
      clearReminder: clearReminder,
    );
    _applications[index] = updated;
    return updated;
  }

  @override
  Future<PartnerEmailOutboxItem> queuePartnerEmail({
    required String toEmail,
    required String subject,
    required String body,
    String applicationId = '',
    String shopId = '',
  }) async {
    final item = PartnerEmailOutboxItem(
      id: 'mail-${++_emailOutboxSequence}',
      toEmail: toEmail.trim(),
      subject: subject.trim(),
      body: body.trim(),
      status: 'pending',
      createdAt: DateTime.now().toUtc(),
      applicationId: applicationId,
      shopId: shopId,
    );
    _emailOutbox.insert(0, item);
    return item;
  }

  @override
  Future<List<PartnerEmailOutboxItem>> listPartnerEmailOutbox({
    int limit = 30,
  }) async {
    final list = List<PartnerEmailOutboxItem>.from(_emailOutbox);
    if (list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
  }

  @override
  Future<void> markPartnerEmailOutboxSent(String outboxId) async {
    final index = _emailOutbox.indexWhere((m) => m.id == outboxId);
    if (index < 0) {
      return;
    }
    final old = _emailOutbox[index];
    _emailOutbox[index] = PartnerEmailOutboxItem(
      id: old.id,
      toEmail: old.toEmail,
      subject: old.subject,
      body: old.body,
      status: 'sent',
      createdAt: old.createdAt,
      applicationId: old.applicationId,
      shopId: old.shopId,
    );
  }

  @override
  Future<void> setPostHidden({
    required String postId,
    required bool hidden,
  }) async {
    final index = _posts.indexWhere((item) => item.id == postId);
    if (index < 0) {
      return;
    }
    _posts[index] = _posts[index].copyWith(hidden: hidden);
    _postsController.add(List<CommunityPost>.from(_posts));
  }

  @override
  Future<void> deletePost(String postId) async {
    _posts.removeWhere((item) => item.id == postId);
    _postsController.add(List<CommunityPost>.from(_posts));
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
    if (mapUrl != null && !isShopMapUrlValid(mapUrl)) {
      throw StateError('INVALID_MAP_URL');
    }
    final current = _shopStats[shopId];
    List<String> galleryUrls;
    String? coverUrl;

    if (gallery != null) {
      galleryUrls = [
        for (var i = 0; i < gallery.length; i++)
          if (gallery[i].hasBytes)
            'memory://shop-gallery-$shopId-$i'
          else if (gallery[i].hasUrl)
            gallery[i].url!.trim(),
      ];
      coverUrl = galleryUrls.isEmpty ? '' : galleryUrls.first;
    } else {
      galleryUrls = current?.galleryUrls ?? const [];
      coverUrl = removeCover
          ? ''
          : (coverBytes == null
                ? current?.coverUrl
                : 'memory://shop-cover-$shopId');
      if (coverBytes != null &&
          coverBytes.isNotEmpty &&
          (galleryUrls.isEmpty || galleryUrls.first != coverUrl)) {
        galleryUrls = [
          coverUrl!,
          for (final url in galleryUrls)
            if (url != coverUrl) url,
        ];
      } else if (removeCover) {
        galleryUrls = const [];
      }
    }

    // Prices stay. A new country rewrites only each product's continent.
    final region = continent?.trim();
    final previousProducts = current?.products ?? const <ShopProduct>[];
    final products = region == null
        ? previousProducts
        : [
            for (final product in previousProducts)
              product.copyWith(continent: region),
          ];
    if (region != null) {
      final raws = _productRawByShop[shopId];
      if (raws != null) {
        for (final raw in raws.values) {
          raw['continent'] = region;
        }
      }
    }

    _shopStats[shopId] =
        (current ??
                ShopLiveStats(
                  shopId: shopId,
                  reviewCount: 0,
                  avgSafety: 0,
                  avgGuide: 0,
                  avgBoat: 0,
                  avgOverall: 0,
                  diveStar: 0,
                ))
            .copyWith(
              name: name,
              location: location,
              country: country ?? current?.country,
              continent: continent ?? current?.continent,
              curated:
                  curated ?? current?.curated ?? shopId.startsWith('curated-'),
              productName: productName,
              consumerPrice: consumerPrice,
              professionalPrice: professionalPrice,
              intro: intro ?? current?.intro,
              address: address ?? current?.address,
              amenities: amenities ?? current?.amenities,
              mapUrl: mapUrl ?? current?.mapUrl,
              nearestHub: nearestHub ?? current?.nearestHub,
              accessRoutes: accessRoutes ?? current?.accessRoutes,
              featureBlurb: featureBlurb ?? current?.featureBlurb,
              featureTags: featureTags ?? current?.featureTags,
              nearbySpots: nearbySpots ?? current?.nearbySpots,
              localContact: localContact ?? current?.localContact,
              checkIn: checkIn ?? current?.checkIn,
              checkOut: checkOut ?? current?.checkOut,
              businessHours: businessHours ?? current?.businessHours,
              coverUrl: coverUrl,
              galleryUrls: galleryUrls,
              products: products,
            );
    _shopController.add(_shopStats.values.toList());
  }

  /// Raw product maps so merge can preserve unknown / legacy keys in tests.
  final _productRawByShop = <String, Map<String, Map<String, dynamic>>>{};

  /// Test helper: stash extra raw keys on a product before [saveShopProduct].
  void seedProductRawOverlay(
    String shopId,
    String productId,
    Map<String, dynamic> extra,
  ) {
    final byId = _productRawByShop.putIfAbsent(shopId, () => {});
    final previous = byId[productId] ?? <String, dynamic>{'id': productId};
    byId[productId] = {...previous, ...extra};
  }

  Map<String, dynamic>? readProductRaw(String shopId, String productId) {
    return _productRawByShop[shopId]?[productId];
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
    bool preserveSeatFields = false,
    bool recordProductChanges = true,
  }) async {
    final delay = debugDelayShopProductSave;
    if (delay != null) {
      await delay();
    }
    final current = _shopStats[shopId];
    final ShopProduct saved;
    Uint8List? coverBytes;
    if (gallery != null) {
      final urls = <String>[];
      for (var i = 0; i < gallery.length; i++) {
        final slot = gallery[i];
        if (slot.hasBytes) {
          urls.add('memory://shop-product-$shopId-${product.id}-$i');
          coverBytes ??= slot.bytes;
        } else if (slot.hasUrl) {
          urls.add(slot.url!.trim());
        }
      }
      saved = product.copyWith(
        photoUrls: urls,
        coverUrl: urls.isEmpty ? '' : urls.first,
      );
    } else {
      final coverUrl = photoBytes == null
          ? product.coverUrl
          : 'memory://shop-product-$shopId-${product.id}';
      saved = product.copyWith(coverUrl: coverUrl);
      coverBytes = photoBytes;
    }
    final byId = _productRawByShop.putIfAbsent(shopId, () => {});
    ShopProduct? previousProduct;
    for (final item in current?.products ?? const <ShopProduct>[]) {
      if (item.id == product.id) {
        previousProduct = item;
        break;
      }
    }
    var previousRaw = byId[saved.id] ?? previousProduct?.toMap();
    // Bookings update the live product before the raw map. Re-read those
    // seat keys so a form save does not put back the count from open time.
    if (preserveSeatFields && previousProduct != null) {
      previousRaw = ShopProduct.copySeatInventory(
        base: previousRaw ?? <String, dynamic>{'id': saved.id},
        from: previousProduct.toMap(),
      );
    }
    if (gallery == null &&
        saved.coverUrl.isEmpty &&
        previousProduct != null &&
        previousProduct.coverUrl.isNotEmpty) {
      // Match Firestore: keep prior cover when edit omits bytes/url.
    }
    var toPersist = saved;
    if (gallery == null &&
        toPersist.coverUrl.isEmpty &&
        (previousRaw?['cover_url'] as String?)?.isNotEmpty == true) {
      toPersist = toPersist.copyWith(
        coverUrl: previousRaw!['cover_url'] as String,
      );
    }
    final merged = ShopProduct.mergePersistedMap(
      previous: previousRaw,
      product: toPersist,
      clearAbsentFormFields: clearAbsentFormFields,
      preserveSeatFields: preserveSeatFields,
    );
    byId[toPersist.id] = merged;
    final parsed = ShopProduct.fromMap(shopId, merged);
    final products = [
      for (final item in current?.products ?? const <ShopProduct>[])
        if (item.id != product.id) item,
      parsed,
    ];
    await saveShopProfile(
      shopId: shopId,
      name: current?.name ?? product.name,
      location: current?.location ?? '',
      productName: product.name,
      consumerPrice: product.consumerPrice,
      professionalPrice: product.professionalPrice,
      coverBytes: useAsResortCover ? coverBytes : null,
    );
    final shopCover = !useAsResortCover
        ? _shopStats[shopId]!.coverUrl
        : (coverBytes != null
              ? 'memory://shop-cover-$shopId'
              : (parsed.coverUrl.isNotEmpty
                    ? parsed.coverUrl
                    : _shopStats[shopId]!.coverUrl));
    _shopStats[shopId] = _shopStats[shopId]!.copyWith(
      products: products,
      coverUrl: shopCover,
    );
    final prior = previousRaw == null
        ? previousProduct
        : ShopProduct.fromMap(shopId, previousRaw);
    final lines = productPriceCapacityChanges(
      previous: prior,
      next: parsed,
    );
    if (recordProductChanges && lines.isNotEmpty) {
      final at = DateTime.now();
      final stored = _productChanges.putIfAbsent(shopId, () => []);
      stored.addAll([
        for (final line in lines)
          ProductChangeRecord(
            shopId: shopId,
            productId: line.productId,
            optionId: line.optionId,
            field: line.field,
            before: line.before,
            after: line.after,
            actorUid: 'memory',
            createdAt: at,
          ),
      ]);
    }
    _shopController.add(_shopStats.values.toList());
  }

  @override
  Future<List<ProductChangeRecord>> listProductChanges(String shopId) async {
    final rows = [...?_productChanges[shopId]];
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (rows.length > 12) {
      return rows.sublist(0, 12);
    }
    return rows;
  }

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
    final dayId = shopDayId(now);
    final days = _dailyStats.putIfAbsent(shopId, () => {});
    final current = days[dayId];
    if (current == null) {
      final created = ShopDayStats(
        dayId: dayId,
        visits: visit ? 1 : 0,
        productViews: productView ? 1 : 0,
        dwellSeconds: 0,
      );
      if (!dailyStatsCreateAllowed(
        dayId: dayId,
        visits: created.visits,
        productViews: created.productViews,
        dwellSeconds: created.dwellSeconds,
      )) {
        return false;
      }
      days[dayId] = created;
      return true;
    }
    final next = ShopDayStats(
      dayId: dayId,
      visits: current.visits + (visit ? 1 : 0),
      productViews: current.productViews + (productView ? 1 : 0),
      dwellSeconds: current.dwellSeconds,
    );
    if (!dailyStatsUpdateAllowed(
      exists: true,
      visits: current.visits,
      productViews: current.productViews,
      dwellSeconds: current.dwellSeconds,
      nextVisits: next.visits,
      nextProductViews: next.productViews,
      nextDwellSeconds: next.dwellSeconds,
    )) {
      return false;
    }
    days[dayId] = next;
    return true;
  }

  @override
  Future<bool> recordShopDwell({
    required String shopId,
    required DateTime now,
    required int seconds,
  }) async {
    final dayId = shopDayId(now);
    final current = _dailyStats[shopId]?[dayId];
    if (current == null) {
      return false;
    }
    final delta = cappedDwellDelta(seconds);
    if (delta == 0) {
      return true;
    }
    final nextDwell = current.dwellSeconds + delta;
    if (!dailyStatsUpdateAllowed(
      exists: true,
      visits: current.visits,
      productViews: current.productViews,
      dwellSeconds: current.dwellSeconds,
      nextVisits: current.visits,
      nextProductViews: current.productViews,
      nextDwellSeconds: nextDwell,
    )) {
      return false;
    }
    _dailyStats[shopId]![dayId] = ShopDayStats(
      dayId: dayId,
      visits: current.visits,
      productViews: current.productViews,
      dwellSeconds: nextDwell,
    );
    return true;
  }

  @override
  Future<List<ShopDayStats>> listShopDailyStats(String shopId) async {
    final days = _dailyStats[shopId];
    if (days == null) {
      return const [];
    }
    final rows = days.values.toList()
      ..sort((a, b) => a.dayId.compareTo(b.dayId));
    return rows;
  }

  @override
  Future<void> deleteShopProduct({
    required String shopId,
    required String productId,
  }) async {
    final current = _shopStats[shopId];
    if (current == null) {
      return;
    }
    _shopStats[shopId] = current.copyWith(
      products: [
        for (final item in current.products)
          if (item.id != productId) item,
      ],
    );
    _shopController.add(_shopStats.values.toList());
  }

  @override
  Future<void> setShopProductPublishStatus({
    required String shopId,
    required String productId,
    required ProductPublishStatus status,
    String reviewNote = '',
    List<String> reasonTags = const [],
  }) async {
    final current = _shopStats[shopId];
    if (current == null) {
      return;
    }
    final products = [
      for (final item in current.products)
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
    _shopStats[shopId] = current.copyWith(products: products);
    _shopController.add(_shopStats.values.toList());
  }

  @override
  Future<void> setShopProductListingKind({
    required String shopId,
    required String productId,
    required ProductListingKind listingKind,
  }) async {
    final current = _shopStats[shopId];
    if (current == null) {
      return;
    }
    final now = DateTime.now();
    final products = [
      for (final item in current.products)
        if (item.id == productId)
          item.copyWith(
            listingKind: listingKind,
            featuredAt: listingKind.isHomeShelf ? now : null,
          )
        else
          item,
    ];
    _shopStats[shopId] = current.copyWith(products: products);
    _shopController.add(_shopStats.values.toList());
  }

  @override
  Future<List<TourBooking>> fetchShopBookings(String shopId) async {
    return List<TourBooking>.from(_shopBookings[shopId] ?? const []);
  }

  @override
  Future<List<TourBooking>> fetchShopBookingsCreatedBetween({
    required String shopId,
    required DateTime start,
    required DateTime end,
  }) async {
    return [
      for (final booking in _shopBookings[shopId] ?? const <TourBooking>[])
        if (!booking.createdAt.isBefore(start) && booking.createdAt.isBefore(end))
          booking,
    ];
  }

  @override
  Future<List<TourBooking>> fetchShopBookingsCancelledBetween({
    required String shopId,
    required DateTime start,
    required DateTime end,
  }) async {
    return [
      for (final booking in _shopBookings[shopId] ?? const <TourBooking>[])
        if (booking.cancelledAt != null &&
            !booking.cancelledAt!.isBefore(start) &&
            booking.cancelledAt!.isBefore(end))
          booking,
    ];
  }

  @override
  Stream<List<TourBooking>> watchShopBookings(String shopId) async* {
    yield List<TourBooking>.from(_shopBookings[shopId] ?? const []);
    yield* _shopBookingController.stream;
  }

  @override
  Stream<List<TourBooking>> watchLatestShopBookings(
    String shopId, {
    int limit = 5,
  }) async* {
    List<TourBooking> top() {
      final list = [...(_shopBookings[shopId] ?? const <TourBooking>[])];
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (list.length <= limit) {
        return list;
      }
      return list.sublist(0, limit);
    }

    yield top();
    yield* _shopBookingController.stream.map((_) => top());
  }

  @override
  Future<void> cancelBookingAsGuest({
    required String uid,
    required String bookingId,
  }) {
    return _runTxn(() async {
      final index = _bookings.indexWhere((item) => item.id == bookingId);
      if (index < 0) {
        return;
      }
      final booking = _bookings[index];
      if (!booking.isActive) {
        return;
      }
      final quote = RefundPolicy.forUserCancel(tourDate: booking.scheduledFor);
      final updated = booking.copyWith(
        status: BookingStatus.cancelled,
        refundPercent: quote.percent,
        refundAmount: quote.amountFor(booking.price),
        paymentStatus: booking.isPaid
            ? (quote.percent > 0
                ? PaymentStatus.refunded
                : PaymentStatus.captured)
            : PaymentStatus.unpaid,
        seatsHeld: 0,
        cancelledAt: DateTime.now(),
      );
      _restoreSeatsIfNeeded(booking);
      _bookings[index] = updated;
      _replaceShopBooking(updated);
      _bookingController.add(List<TourBooking>.from(_bookings));
      _shopBookingController.add(
        List<TourBooking>.from(_shopBookings[updated.shopId] ?? const []),
      );
    });
  }

  @override
  Future<bool> confirmShopBooking({
    required String shopId,
    required String bookingId,
  }) async {
    final list = _shopBookings[shopId];
    if (list == null) {
      return false;
    }
    final shopIndex = list.indexWhere((item) => item.id == bookingId);
    if (shopIndex < 0) {
      return false;
    }
    final booking = list[shopIndex];
    if (!booking.awaitsShopConfirm) {
      return false;
    }
    final updated = booking.copyWith(
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.captured,
    );
    list[shopIndex] = updated;
    final userIndex = _bookings.indexWhere((item) => item.id == bookingId);
    if (userIndex >= 0) {
      _bookings[userIndex] = _bookings[userIndex].copyWith(
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.captured,
      );
    } else {
      _bookings.insert(0, updated);
    }
    _bookingController.add(List<TourBooking>.from(_bookings));
    _shopBookingController.add(List<TourBooking>.from(list));
    if (updated.uid.isNotEmpty) {
      _bumpActivityLocal(uid: updated.uid, purchaseDelta: 1);
    }
    return true;
  }

  @override
  Future<void> ackPartnerBooking({
    required String shopId,
    required String bookingId,
  }) async {
    final list = _shopBookings[shopId];
    if (list == null) {
      return;
    }
    final index = list.indexWhere((item) => item.id == bookingId);
    if (index < 0) {
      return;
    }
    list[index] = list[index].copyWith(partnerAckedAt: DateTime.now());
    _shopBookingController.add(List<TourBooking>.from(list));
  }

  @override
  Future<void> cancelBookingsForWeather({
    required String shopId,
    required DateTime tourDate,
  }) {
    return _runTxn(() async {
      final day = RefundPolicy.dateOnly(tourDate);
      final quote = RefundPolicy.weatherCancel();
      for (var i = 0; i < _bookings.length; i++) {
        final booking = _bookings[i];
        if (booking.shopId != shopId || !booking.isActive) {
          continue;
        }
        if (RefundPolicy.dateOnly(booking.scheduledFor) != day) {
          continue;
        }
        _restoreSeatsIfNeeded(booking);
        _bookings[i] = booking.copyWith(
          status: BookingStatus.weatherCancelled,
          refundPercent: 100,
          refundAmount: quote.amountFor(booking.price),
          refundNoticeSeen: false,
          paymentStatus: booking.isPaid
              ? PaymentStatus.refunded
              : PaymentStatus.unpaid,
          seatsHeld: 0,
          cancelledAt: DateTime.now(),
        );
        _replaceShopBooking(_bookings[i]);
      }
      _bookingController.add(List<TourBooking>.from(_bookings));
      _shopBookingController.add(
        List<TourBooking>.from(_shopBookings[shopId] ?? const []),
      );
    });
  }

  @override
  Future<void> acknowledgeRefundNotice({
    required String uid,
    required String bookingId,
  }) async {
    final index = _bookings.indexWhere((item) => item.id == bookingId);
    if (index < 0) {
      return;
    }
    _bookings[index] = _bookings[index].copyWith(refundNoticeSeen: true);
    _replaceShopBooking(_bookings[index]);
    _bookingController.add(List<TourBooking>.from(_bookings));
  }

  void _replaceShopBooking(TourBooking booking) {
    final visible = booking.copyWith(guestBirthDate: '', guestContact: '');
    final list = _shopBookings.putIfAbsent(booking.shopId, () => []);
    final index = list.indexWhere((item) => item.id == booking.id);
    if (index >= 0) {
      list[index] = visible;
    } else {
      list.insert(0, visible);
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
  }) async {
    _postSequence += 1;
    _posts.insert(
      0,
      CommunityPost(
        id: 'post-$_postSequence',
        type: type,
        title: title.trim(),
        subtitle: subtitle.trim(),
        authorUid: uid,
        authorName: authorName,
        createdAt: DateTime.now(),
        language: language,
        shopId: shopId,
        destination: destination,
        windowLabel: windowLabel,
        capacity: capacity,
        bookedSeats: bookedSeats,
        lookingSeats: lookingSeats,
        soloShare: soloShare,
        kind: kind,
      ),
    );
    _postsController.add(List<CommunityPost>.from(_posts));
  }

  @override
  Stream<List<CommunityComment>> watchComments(String postId) async* {
    yield List<CommunityComment>.from(_comments[postId] ?? const []);
    yield* _commentController.stream;
  }

  @override
  Future<void> addComment({
    required String postId,
    required String uid,
    required String authorName,
    required String body,
    required String language,
  }) async {
    _commentSequence += 1;
    final comment = CommunityComment(
      id: 'comment-$_commentSequence',
      postId: postId,
      authorUid: uid,
      authorName: authorName,
      body: body.trim(),
      createdAt: DateTime.now(),
      language: language.isEmpty ? LanguageDetector.detect(body) : language,
    );
    _comments.putIfAbsent(postId, () => []).add(comment);
    _commentController.add(List<CommunityComment>.from(_comments[postId]!));
  }

  @override
  Stream<InstructorDiscount> watchInstructorDiscount() async* {
    yield _discount;
    yield* _discountController.stream;
  }

  @override
  Future<void> saveInstructorDiscount(InstructorDiscount discount) async {
    _discount = discount;
    _discountController.add(discount);
  }

  List<Map<String, Object>> get debugSeatDemands =>
      _seatDemands.values.toList();

  @override
  Future<bool> createSeatDemand(SeatDemand demand) async {
    if (!demand.withinShape || _seatDemands.containsKey(demand.id)) {
      return false;
    }
    _seatDemands[demand.id] = demand.toMap();
    return true;
  }

  final debugSeatDemandQueries = <(DateTime, DateTime)>[];

  @override
  Future<List<SeatDemand>> listSeatDemandsBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    debugSeatDemandQueries.add((from, to));
    final rows = <SeatDemand>[];
    for (final entry in _seatDemands.entries) {
      final parsed = SeatDemand.fromStored(
        entry.key,
        Map<String, dynamic>.from(entry.value),
      );
      if (parsed != null &&
          !parsed.at.isBefore(from) &&
          parsed.at.isBefore(to)) {
        rows.add(parsed);
      }
    }
    return rows;
  }

  @override
  Future<bool> createSeatEvent(SeatLifeEvent event) async {
    if (_seatEvents.containsKey(event.id) || !event.withinShape) {
      return false;
    }
    _seatEvents[event.id] = event.toStoredMap();
    return true;
  }

  @override
  Future<bool> bumpSeatDay({
    required String dayId,
    required String field,
  }) async {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dayId) ||
        !seatDayFields.contains(field)) {
      return false;
    }
    final current = _seatDays[dayId];
    if (current == null) {
      final created = seatDayCreate(field);
      if (!seatDayCreateAllowed(created)) {
        return false;
      }
      _seatDays[dayId] = created;
      return true;
    }
    final next = Map<String, int>.from(current);
    next[field] = (current[field] ?? 0) + 1;
    if (!seatDayPlusOneAllowed(current, next)) {
      return false;
    }
    _seatDays[dayId] = next;
    return true;
  }

  Map<String, int>? debugSeatDay(String dayId) => _seatDays[dayId];

  @override
  Future<void> saveSeatOutcome(SeatOutcome outcome) async {
    final data = outcome.toMap();
    if (!seatOutcomeAllowed(data)) {
      return;
    }
    final existing = _seatOutcomes[outcome.seatId];
    if (existing != null && sameSeatMap(existing, data)) {
      return;
    }
    _seatOutcomes[outcome.seatId] = data;
    debugSeatOutcomeWrites += 1;
  }

  @override
  Future<List<SeatLifeEvent>> listSeatEvents() async {
    final rows = <SeatLifeEvent>[];
    for (final entry in _seatEvents.entries) {
      final parsed = SeatLifeEvent.fromMap(
        entry.key,
        Map<String, dynamic>.from(entry.value),
      );
      if (parsed != null) {
        rows.add(parsed);
      }
    }
    return rows;
  }

  final debugSeatEventQueries = <(DateTime, DateTime)>[];

  @override
  Future<List<SeatLifeEvent>> listSeatEventsBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    debugSeatEventQueries.add((from, to));
    final rows = <SeatLifeEvent>[];
    for (final entry in _seatEvents.entries) {
      final parsed = SeatLifeEvent.fromMap(
        entry.key,
        Map<String, dynamic>.from(entry.value),
      );
      if (parsed != null &&
          !parsed.at.isBefore(from) &&
          parsed.at.isBefore(to)) {
        rows.add(parsed);
      }
    }
    return rows;
  }

  final _meetingReports = <String, Map<String, dynamic>>{};

  Map<String, Map<String, dynamic>> get debugMeetingReports => {
    for (final entry in _meetingReports.entries)
      entry.key: Map<String, dynamic>.from(entry.value),
  };

  @override
  Future<void> saveMeetingReport(PartnerMeetingReport report) async {
    if (report.shared || !report.withinShape) {
      return;
    }
    _meetingReports[report.id] = Map<String, dynamic>.from(report.toMap());
  }

  @override
  Future<List<PartnerMeetingReport>> listMeetingReports() async {
    final rows = <PartnerMeetingReport>[];
    for (final entry in _meetingReports.entries) {
      final parsed = PartnerMeetingReport.fromMap(
        entry.key,
        Map<String, dynamic>.from(entry.value),
      );
      if (parsed != null) {
        rows.add(parsed);
      }
    }
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
  }

  final debugMeetingReportQueries = <MeetingReportListQuery>[];

  @override
  Future<List<PartnerMeetingReport>> listSharedMeetingReports({
    required String shopId,
  }) async {
    final query = MeetingReportListQuery.sharedForOwnedShop(shopId);
    if (query == null) {
      return const [];
    }
    debugMeetingReportQueries.add(query);
    final rows = <PartnerMeetingReport>[];
    for (final entry in _meetingReports.entries) {
      final parsed = PartnerMeetingReport.fromMap(
        entry.key,
        Map<String, dynamic>.from(entry.value),
      );
      if (parsed == null ||
          parsed.shared != query.shared ||
          parsed.recipe.hullId != query.shopId) {
        continue;
      }
      rows.add(parsed);
    }
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
  }

  @override
  Future<PartnerMeetingReport?> getMeetingReport(String id) async {
    final key = id.trim();
    final current = _meetingReports[key];
    if (current == null) {
      return null;
    }
    final parsed = PartnerMeetingReport.fromMap(
      key,
      Map<String, dynamic>.from(current),
    );
    if (parsed == null) {
      return null;
    }
    if (_resolvedAdmin) {
      return parsed;
    }
    final hull = partnerShopHull(_ownedShopId ?? '');
    final allowed =
        _resolvedBusiness &&
        parsed.shared &&
        hull.isNotEmpty &&
        hull == parsed.recipe.hullId;
    if (!allowed) {
      throw StateError('permission-denied');
    }
    return parsed;
  }

  @override
  Future<bool> setMeetingReportShared({
    required String id,
    required bool shared,
    DateTime? at,
  }) async {
    final current = _meetingReports[id];
    if (current == null) {
      return false;
    }
    final parsed = PartnerMeetingReport.fromMap(
      id,
      Map<String, dynamic>.from(current),
    );
    if (parsed == null) {
      return false;
    }
    final next = shared ? parsed.share(at ?? DateTime.now()) : parsed.unshare();
    if (!next.withinShape) {
      return false;
    }
    _meetingReports[id] = Map<String, dynamic>.from(next.toMap());
    return true;
  }

  void dispose() {
    _authController.close();
    _diverController.close();
    _shopController.close();
    _bookingController.close();
    _pendingController.close();
    _membersController.close();
    _postsController.close();
    _shopBookingController.close();
    _commentController.close();
    _discountController.close();
  }
}
