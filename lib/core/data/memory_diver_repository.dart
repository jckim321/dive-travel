import 'dart:async';
import 'dart:typed_data';

import 'package:dive_travel_app/core/constants/app_constants.dart';
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
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/core/models/review_detail_options.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

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
    repo._isBusiness = isAdmin || AppConstants.grantBusinessToCurrentSession;
    repo._ownedShopId = AppConstants.defaultPartnerShopId;
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
    );
    return repo;
  }

  AppUser? _user;
  late DiverSnapshot _snapshot;
  int _logSequence = 0;
  int _bookingSequence = 0;
  bool _isInstructor = false;
  bool _isAdmin = false;
  bool _isBusiness = false;
  String? _ownedShopId;
  ProVerificationStatus _proStatus = ProVerificationStatus.none;
  MemberGrade _memberGrade = MemberGrade.silver;
  final _shopStats = <String, ShopLiveStats>{};
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
  int _postSequence = 0;
  int _commentSequence = 0;

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

  bool get _resolvedBusiness =>
      _isBusiness ||
      AppConstants.grantBusinessToCurrentSession ||
      AppOwner.isOwnerEmail(_user?.email);

  bool get _resolvedAdmin =>
      _isAdmin ||
      AppConstants.grantAdminToCurrentSession ||
      AppOwner.isOwnerEmail(_user?.email);

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
  }) {
    return signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _authController.add(null);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> ensureUserDocument(AppUser user) async {
    if (AppOwner.isOwnerEmail(user.email) ||
        AppConstants.grantAdminToCurrentSession) {
      _isAdmin = true;
    }
    if (AppOwner.isOwnerEmail(user.email) ||
        AppConstants.grantBusinessToCurrentSession) {
      _isBusiness = true;
      _ownedShopId ??= AppConstants.defaultPartnerShopId;
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
    );
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
    );
    yield* _diverController.stream.map(
      (snap) => DiverSnapshot(
        stats: snap.stats,
        regions: snap.regions,
        logs: const [],
        favoriteShopIds: snap.favoriteShopIds,
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

  @override
  Future<List<ShopLiveStats>> fetchShopStats() async {
    return _shopStats.values.toList();
  }

  @override
  Future<ShopLiveStats?> fetchShopStat(String shopId) async {
    return _shopStats[shopId.trim()];
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
    final held = _holdOpenSeats(
      hullId,
      productId,
      partySize,
      optionId: seatOptionId,
      uid: uid,
    );
    if (!held) {
      return false;
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
      createdAt: DateTime.now(),
      tourDate: tourDate ?? DateTime.now().add(const Duration(days: 7)),
      status: status,
      paymentStatus: paymentStatus,
      partySize: partySize,
      divers: divers,
      nondivers: nondivers,
      children: children,
      infants: infants,
      quoteLines: quoteLines,
    );
    _bookings.insert(0, booking);
    _shopBookings.putIfAbsent(booking.shopId, () => []).insert(0, booking);
    _bookingController.add(List<TourBooking>.from(_bookings));
    _shopBookingController.add(
      List<TourBooking>.from(_shopBookings[booking.shopId] ?? const []),
    );
    return true;
  }

  bool _holdOpenSeats(
    String shopId,
    String? productId,
    int partySize, {
    String optionId = '',
    String uid = '',
  }) {
    if (productId == null || productId.isEmpty || partySize <= 0) {
      return true;
    }
    final current = _shopStats[shopId];
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
    _shopStats[shopId] = current.copyWith(
      products: [
        for (final item in current.products)
          if (item.id == productId) captured else item,
      ],
    );
    _shopController.add(_shopStats.values.toList());
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
    final current = _shopStats[hull];
    if (current == null) {
      return;
    }
    _shopStats[hull] = current.copyWith(
      products: [
        for (final item in current.products)
          if (item.id == productId)
            item.plantFlag(
              partySize: partySize,
              now: now,
              optionId: optionId,
              uid: uid,
            )
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

  @override
  Future<List<MemberAccount>> fetchMembers() async {
    final members = List<MemberAccount>.from(_members);
    members.sort((a, b) => a.displayName.compareTo(b.displayName));
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
    final upgraded = !locked && earned.rank > current.rank;
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
    String? country,
    String? continent,
    bool? curated,
    Uint8List? coverBytes,
    String? coverFileName,
    String? coverContentType,
    bool removeCover = false,
    List<ShopGallerySlot>? gallery,
  }) async {
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
              coverUrl: coverUrl,
              galleryUrls: galleryUrls,
            );
    _shopController.add(_shopStats.values.toList());
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
    final products = [
      for (final item in current?.products ?? const <ShopProduct>[])
        if (item.id != product.id) item,
      saved,
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
              : (saved.coverUrl.isNotEmpty
                    ? saved.coverUrl
                    : _shopStats[shopId]!.coverUrl));
    _shopStats[shopId] = _shopStats[shopId]!.copyWith(
      products: products,
      coverUrl: shopCover,
    );
    _shopController.add(_shopStats.values.toList());
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
  }) async {
    final current = _shopStats[shopId];
    if (current == null) {
      return;
    }
    final products = [
      for (final item in current.products)
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
  Stream<List<TourBooking>> watchShopBookings(String shopId) async* {
    yield List<TourBooking>.from(_shopBookings[shopId] ?? const []);
    yield* _shopBookingController.stream;
  }

  @override
  Future<void> cancelBookingAsGuest({
    required String uid,
    required String bookingId,
  }) async {
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
          ? (quote.percent > 0 ? PaymentStatus.refunded : PaymentStatus.captured)
          : PaymentStatus.unpaid,
    );
    _bookings[index] = updated;
    _replaceShopBooking(updated);
    _bookingController.add(List<TourBooking>.from(_bookings));
    _shopBookingController.add(
      List<TourBooking>.from(_shopBookings[updated.shopId] ?? const []),
    );
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
      _bookings[userIndex] = updated;
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
  Future<void> cancelBookingsForWeather({
    required String shopId,
    required DateTime tourDate,
  }) async {
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
      _bookings[i] = booking.copyWith(
        status: BookingStatus.weatherCancelled,
        refundPercent: 100,
        refundAmount: quote.amountFor(booking.price),
        refundNoticeSeen: false,
        paymentStatus: booking.isPaid
            ? PaymentStatus.refunded
            : PaymentStatus.unpaid,
      );
      _replaceShopBooking(_bookings[i]);
    }
    _bookingController.add(List<TourBooking>.from(_bookings));
    _shopBookingController.add(
      List<TourBooking>.from(_shopBookings[shopId] ?? const []),
    );
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
    final list = _shopBookings.putIfAbsent(booking.shopId, () => []);
    final index = list.indexWhere((item) => item.id == booking.id);
    if (index >= 0) {
      list[index] = booking;
    } else {
      list.insert(0, booking);
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
