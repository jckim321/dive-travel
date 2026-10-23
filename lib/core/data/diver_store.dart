import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_repository.dart';
import 'package:dive_travel_app/core/data/diver_snapshot.dart';
import 'package:dive_travel_app/core/data/operation_review_policy.dart';
import 'package:dive_travel_app/core/data/refund_policy.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/dive_log.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/core/models/dive_star_assessment.dart';
import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/core/models/gear_item.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/review_detail_options.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/product_publish_guard.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/dev/dev_roles.dart';
import 'package:dive_travel_app/core/storage/r2_photo_storage.dart';

class DiverStore extends ChangeNotifier {
  /// Explore/홈 auto-refresh window for shop stats cache.
  static const shopStatsCacheTtl = Duration(minutes: 5);

  DiverStore(this._repository) {
    _gear = List<GearItem>.from(_defaultGear);
    _authSubscription = _repository.authState().listen((user) {
      _uid = user?.uid;
      _email = user?.email;
      if (user == null) {
        _devRoleOverlay = null;
      }
      _bindDiver(user);
    });
    _discountSubscription = _repository.watchInstructorDiscount().listen(
      (discount) {
        _instructorDiscount = discount;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('강사 할인 구독 실패: $error');
      },
    );
  }

  final DiverRepository _repository;
  final R2PhotoStorage _photos = const R2PhotoStorage();
  var _shopCoverHydrateGen = 0;
  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<DiverSnapshot>? _diverSubscription;
  StreamSubscription<List<TourBooking>>? _bookingSubscription;
  StreamSubscription<List<TourBooking>>? _shopBookingSubscription;
  StreamSubscription<InstructorDiscount>? _discountSubscription;
  Timer? _loadingTimeout;
  String? _uid;
  String? _email;
  DevRoleOverlay? _devRoleOverlay;
  var _shopStatsLoaded = false;
  var _shopStatsLoading = false;
  DateTime? _shopStatsFetchedAt;
  List<GuestReview> _myReviews = const [];
  var _myReviewsLoaded = false;
  var _myReviewsLoading = false;
  var _postsLoaded = false;
  var _postsLoading = false;
  var _postsHasMore = false;
  Object? _postsCursor;
  var _logsLoaded = false;
  var _logsLoading = false;
  var _logsHasMore = false;
  Object? _logsCursor;
  var _adminInboxLoaded = false;
  var _adminInboxLoading = false;
  var _salesLoaded = false;
  var _salesLoading = false;

  DiverStats _stats = const DiverStats(
    displayName: '다이버',
    totalLogCount: 0,
    uniqueRegionsCount: 0,
    isInstructor: false,
  );
  List<DiveRegion> _regions = const [];
  List<DiveLog> _logs = const [];
  List<ShopLiveStats> _shopStats = const [];
  List<TourBooking> _bookings = const [];
  List<PendingInstructor> _pendingInstructors = const [];
  List<MemberAccount> _members = const [];
  List<CommunityPost> _posts = const [];
  List<TourBooking> _shopBookings = const [];
  List<TourBooking> _salesBookings = const [];
  final _salesByShop = <String, List<TourBooking>>{};
  late List<GearItem> _gear;
  InstructorDiscount _instructorDiscount = InstructorDiscount.standard;
  bool _loading = true;
  /// PIN unlock for admin console; cleared on sign-out.
  var _adminConsoleUnlocked = false;

  DiverStats get stats {
    // When DevRoles is off or this account cannot use them, ignore any leftover overlay.
    if (!DevRoles.enabled || !DevRoles.canUse(_email)) {
      return _stats;
    }
    final overlay = _devRoleOverlay;
    if (overlay == null) {
      return _stats;
    }
    return _stats.copyWith(
      isAdmin: overlay.effectiveIsAdmin,
      isBusiness: overlay.effectiveIsBusiness,
      ownedShopId: overlay.effectiveOwnedShopId,
      clearOwnedShopId: overlay.kind != DevRoleKind.partner,
    );
  }

  DevRoleOverlay? get devRoleOverlay => _devRoleOverlay;

  bool get canUseDevRoles => DevRoles.canUse(_email);

  String? get email => _email;

  bool get adminConsoleUnlocked => _adminConsoleUnlocked;

  void unlockAdminConsole() {
    if (_adminConsoleUnlocked) {
      return;
    }
    _adminConsoleUnlocked = true;
    notifyListeners();
  }

  void lockAdminConsole() {
    if (!_adminConsoleUnlocked) {
      return;
    }
    _adminConsoleUnlocked = false;
    notifyListeners();
  }
  List<DiveRegion> get regions => List.unmodifiable(_regions);
  List<DiveLog> get logs {
    final copy = [..._logs];
    copy.sort((a, b) {
      final written = b.writtenAt.compareTo(a.writtenAt);
      if (written != 0) {
        return written;
      }
      return b.divedAt.compareTo(a.divedAt);
    });
    return List.unmodifiable(copy);
  }

  List<TourBooking> get bookings => List.unmodifiable(_bookings);
  List<PendingInstructor> get pendingInstructors =>
      List.unmodifiable(_pendingInstructors);
  List<MemberAccount> get members => List.unmodifiable(_members);
  List<CommunityPost> get posts => List.unmodifiable(_posts);
  bool get postsHasMore => _postsHasMore;
  bool get logsHasMore => _logsHasMore;
  bool get shopStatsLoaded => _shopStatsLoaded;
  DateTime? get shopStatsFetchedAt => _shopStatsFetchedAt;
  List<GuestReview> get myReviews => List.unmodifiable(_myReviews);
  bool get myReviewsLoaded => _myReviewsLoaded;
  List<CommunityPost> get visiblePosts => [
    for (final post in _posts)
      if (!post.hidden) post,
  ];

  List<SameBoatOffer> sameBoatOffers(SameBoatFilter filter, {DateTime? now}) {
    final all = <ShopProduct>[
      for (final stats in _shopStats)
        for (final product in stats.products) product,
    ];
    return SameBoatBoard.filteredOffers(all, filter, now ?? DateTime.now());
  }

  List<SameBoatOffer> myLiveFlags({DateTime? now}) {
    final member = uid;
    if (member == null || member.isEmpty) {
      return const [];
    }
    final clock = now ?? DateTime.now();
    final found = <SameBoatOffer>[];
    for (final stats in _shopStats) {
      for (final product in stats.products) {
        for (final option in product.options) {
          final mine = option.flagHolds.any(
            (hold) => hold.uid == member && hold.expiresAt.isAfter(clock),
          );
          if (mine) {
            found.add(SameBoatOffer(product: product, option: option));
          }
        }
        final mine = product.flagHolds.any(
          (hold) => hold.uid == member && hold.expiresAt.isAfter(clock),
        );
        if (mine) {
          found.add(SameBoatOffer(product: product));
        }
      }
    }
    return found;
  }

  String shopLabelFor(String shopId) {
    for (final stats in _shopStats) {
      final name = stats.name;
      if (stats.shopId == shopId && name != null && name.isNotEmpty) {
        return name;
      }
    }
    return '';
  }

  List<TourBooking> get shopBookings => List.unmodifiable(_shopBookings);
  List<TourBooking> get thisMonthShopBookings {
    final now = DateTime.now();
    return [
      for (final booking in _shopBookings)
        if (booking.createdAt.year == now.year &&
            booking.createdAt.month == now.month)
          booking,
    ];
  }

  int get partnerGrossThisMonth {
    var total = 0;
    for (final booking in thisMonthShopBookings) {
      if (booking.isActive && booking.isPaid) {
        total += booking.price;
      }
    }
    return total;
  }

  int get partnerCommissionThisMonth =>
      RefundPolicy.commissionOn(partnerGrossThisMonth);

  int get partnerNetThisMonth => RefundPolicy.netPayout(partnerGrossThisMonth);

  static const salesKindOrder = <String>[
    'explore_only',
    'flag',
    'diver_planned',
    'curated',
    'dive_star',
    'hot_spot',
    'next_departure',
  ];

  List<TourBooking> get salesBookings => List.unmodifiable(_salesBookings);

  Map<String, int> salesThisMonthByKind([DateTime? now]) {
    final clock = now ?? DateTime.now();
    final totals = {for (final kind in salesKindOrder) kind: 0};
    for (final booking in _salesBookings) {
      if (!booking.isActive || !booking.isPaid) {
        continue;
      }
      final at = booking.createdAt;
      if (at.year != clock.year || at.month != clock.month) {
        continue;
      }
      final key = booking.salesKind;
      totals[key] = (totals[key] ?? 0) + booking.price;
    }
    return totals;
  }

  int get salesTotalThisMonth {
    var total = 0;
    for (final amount in salesThisMonthByKind().values) {
      total += amount;
    }
    return total;
  }

  /// 경영 대시보드용 방문·신규·퍼널 집계.
  AdminOpsSnapshot adminOpsSnapshot([DateTime? now]) {
    final clock = now ?? DateTime.now();
    final todayStart = DateTime(clock.year, clock.month, clock.day);
    final weekAgo = todayStart.subtract(const Duration(days: 7));
    final monthAgo = todayStart.subtract(const Duration(days: 30));
    var seenToday = 0;
    var seen7 = 0;
    var seen30 = 0;
    var dormant = 0;
    var newToday = 0;
    var new7 = 0;
    var new30 = 0;
    var newPaid30 = 0;
    for (final m in _members) {
      final seen = m.lastSeenAt;
      if (seen != null) {
        if (!seen.isBefore(todayStart)) seenToday++;
        if (!seen.isBefore(weekAgo)) seen7++;
        if (!seen.isBefore(monthAgo)) {
          seen30++;
        } else {
          dormant++;
        }
      } else {
        dormant++;
      }
      final created = m.createdAt;
      if (created != null) {
        if (!created.isBefore(todayStart)) newToday++;
        if (!created.isBefore(weekAgo)) new7++;
        if (!created.isBefore(monthAgo)) {
          new30++;
          if (m.paidPurchaseCount > 0) newPaid30++;
        }
      }
    }
    var requested = 0;
    var paid = 0;
    var cancelled = 0;
    var unpaidReviews = 0;
    for (final b in _salesBookings) {
      if (b.isPaid && b.isActive) {
        paid++;
        if (!b.reviewed) unpaidReviews++;
      } else if (b.isActive && !b.isPaid) {
        requested++;
      } else if (!b.isActive) {
        cancelled++;
      }
    }
    final conversion = (paid + requested) == 0
        ? 0.0
        : paid / (paid + requested);
    final nearUpgrade = [
      for (final m in _members)
        if (m.grade != MemberGrade.platinum && !m.gradeLocked)
          m,
    ]..sort((a, b) {
        final da = MemberGrade.deficitToNext(
          current: a.grade,
          paidPurchases: a.paidPurchaseCount,
          reviews: a.reviewCount,
        );
        final db = MemberGrade.deficitToNext(
          current: b.grade,
          paidPurchases: b.paidPurchaseCount,
          reviews: b.reviewCount,
        );
        return (da.$1 + da.$2).compareTo(db.$1 + db.$2);
      });
    return AdminOpsSnapshot(
      seenToday: seenToday,
      seen7d: seen7,
      seen30d: seen30,
      dormant: dormant,
      newToday: newToday,
      new7d: new7,
      new30d: new30,
      newPaid30d: newPaid30,
      bookingRequested: requested,
      bookingPaid: paid,
      bookingCancelled: cancelled,
      conversionRate: conversion,
      unpaidReviewCount: unpaidReviews,
      nearUpgrade: nearUpgrade.take(5).toList(),
    );
  }

  List<ShopLiveStats> get plaqueQueue => [
    for (final stats in _shopStats)
      if (stats.qualifiesForPlaque || stats.plaqueStatus != PlaqueStatus.none)
        stats,
  ];

  /// Partner/admin submissions waiting for owner approval.
  List<ShopProduct> get pendingProductApprovals {
    final out = <ShopProduct>[];
    for (final stats in _shopStats) {
      for (final product in stats.products) {
        if (product.isPendingApproval) {
          out.add(product);
        }
      }
    }
    out.sort((a, b) {
      final aAt = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
    return out;
  }

  List<ShopProduct> get allShopProducts {
    final out = <ShopProduct>[
      for (final stats in _shopStats)
        for (final product in stats.products) product,
    ];
    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  List<ShopProduct> productsForShop(String shopId) {
    return liveStatsFor(shopId)?.products ?? const [];
  }

  bool get hasAnyPublicProduct => _shopStats.any(
    (stats) => stats.products.any((product) => product.isListedPublicly),
  );

  /// Home shelf: one card per resort, newest admin feature first.
  /// Never flash catalog seeds then clear them once Firestore products arrive.
  List<DiveShop> resortsFeaturedAs(
    ProductListingKind kind, {
    int limit = ProductListingKind.homeShelfLimit,
    Set<String> excludeHullIds = const {},
  }) {
    if (!kind.isHomeShelf) {
      return const [];
    }
    final statsByShop = {for (final stats in _shopStats) stats.shopId: stats};
    final scored = <({DiveShop card, DateTime at})>[];

    for (final hull in DiveShopCatalog.hulls(shops)) {
      if (excludeHullIds.contains(hull.hullId)) {
        continue;
      }
      final stats = statsByShop[hull.hullId];
      final matches = [
        for (final product in _dedupedProducts(stats?.products ?? const []))
          if (product.isListedPublicly && product.listingKind == kind) product,
      ];
      if (matches.isEmpty) {
        continue;
      }
      matches.sort(
        (a, b) => _homeFeatureTime(b).compareTo(_homeFeatureTime(a)),
      );
      final best = matches.first;
      scored.add((
        card: _hullCardForProduct(hull, best),
        at: _homeFeatureTime(best),
      ));
    }

    scored.sort((a, b) => b.at.compareTo(a.at));
    return [for (final item in scored.take(limit)) item.card];
  }

  static DateTime _homeFeatureTime(ShopProduct product) {
    return product.featuredAt ??
        product.submittedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Public products for admin home curation (newest submit first).
  List<ShopProduct> get publicProductsForCuration {
    final out = <ShopProduct>[];
    for (final stats in _shopStats) {
      for (final product in _dedupedProducts(stats.products)) {
        if (product.isListedPublicly) {
          out.add(product);
        }
      }
    }
    out.sort((a, b) {
      final aAt = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
    return out;
  }

  int countOnHomeShelf(ProductListingKind kind) {
    if (!kind.isHomeShelf) {
      return 0;
    }
    var count = 0;
    for (final stats in _shopStats) {
      for (final product in _dedupedProducts(stats.products)) {
        if (product.isListedPublicly && product.listingKind == kind) {
          count++;
        }
      }
    }
    return count;
  }

  /// Home / explore card for one public product (id carries product sku).
  DiveShop listingCardForProduct(DiveShop hull, ShopProduct product) {
    return _hullCardForProduct(hull, product);
  }

  DiveShop _hullCardForProduct(DiveShop hull, ShopProduct product) {
    final cover = product.coverUrl.isNotEmpty
        ? product.coverUrl
        : (liveStatsFor(hull.hullId)?.coverUrl ?? hull.coverUrl);
    final gallery = [
      for (final url in product.photoUrls)
        if (url.trim().isNotEmpty) url.trim(),
    ];
    return hull.copyWith(
      id: '${hull.hullId}--${product.id}',
      productName: product.name,
      consumerPrice: product.consumerPrice,
      professionalPrice: product.professionalPrice,
      blurb: product.blurb.isNotEmpty ? product.blurb : hull.blurb,
      durationLabel: product.derivedDurationLabel.isNotEmpty
          ? product.derivedDurationLabel
          : hull.durationLabel,
      coverUrl: cover,
      galleryUrls: gallery.isNotEmpty ? gallery : hull.galleryUrls,
      rating: product.guestReviewCount > 0 ? product.guestRating : 0,
      reviewCount: product.guestReviewCount,
    );
  }

  /// Newest public product time on a hull (explore / home recent sort).
  DateTime latestPublicProductAt(String hullId) {
    final products = liveStatsFor(hullId)?.products ?? const <ShopProduct>[];
    var best = DateTime.fromMillisecondsSinceEpoch(0);
    for (final product in products) {
      if (!product.isListedPublicly) {
        continue;
      }
      final at = product.submittedAt;
      if (at != null && at.isAfter(best)) {
        best = at;
      }
    }
    return best;
  }

  static List<ShopProduct> _dedupedProducts(List<ShopProduct> products) {
    final byId = <String, ShopProduct>{};
    for (final product in products) {
      if (product.id.isEmpty) {
        continue;
      }
      byId[product.id] = product;
    }
    return byId.values.toList();
  }

  List<GearItem> get gear => List.unmodifiable(_gear);
  InstructorDiscount get instructorDiscount => _instructorDiscount;
  bool get loading => _loading;

  TourPriceQuote quoteFor(DiveShop shop) {
    return TourPricePolicy.quote(
      shop,
      isInstructor: _stats.isInstructor,
      discount: _instructorDiscount,
    );
  }

  String? get uid => _uid;

  List<ShopLiveStats> get shopStats => _shopStats;

  List<DiveShop> get shops => DiveShopCatalog.withLiveStats(_shopStats);

  List<DiveShop> get resortHulls => DiveShopCatalog.hulls(shops);

  List<DiveShop> listingsOnHull(String hullId) {
    final live = liveStatsFor(hullId);
    return [
      for (final shop in DiveShopCatalog.listingsOnHull(shops, hullId))
        shop.withLiveProduct(live),
    ];
  }

  final Map<String, Uint8List> _coverBytes = {};
  final Map<String, List<Uint8List>> _galleryBytes = {};
  final Map<String, List<Uint8List?>> _productFrames = {};
  final Set<String> _favoriteShopIds = {};

  Uint8List? coverBytesFor(String id) {
    return _coverBytes[id] ?? _coverBytes[id.split('--').first];
  }

  List<Uint8List> galleryBytesFor(String id) {
    return _galleryBytes[id] ?? _galleryBytes[id.split('--').first] ?? const [];
  }

  List<Uint8List?> productFramesFor(String id) {
    return _productFrames[id] ?? const [];
  }

  List<DiveShop> get favoriteShops {
    final seen = <String>{};
    return [
      for (final shop in resortHulls)
        if (_favoriteShopIds.contains(shop.hullId) && seen.add(shop.hullId))
          shop,
    ];
  }

  bool isFavoriteShop(String shopId) =>
      _favoriteShopIds.contains(shopId.split('--').first);

  Future<void> toggleFavoriteShop(String shopId) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    final hullId = shopId.split('--').first;
    final wasFavorite = _favoriteShopIds.contains(hullId);
    if (wasFavorite) {
      _favoriteShopIds.remove(hullId);
    } else {
      _favoriteShopIds.add(hullId);
    }
    notifyListeners();
    try {
      await _repository.setFavoriteShop(
        uid: uid,
        shopId: hullId,
        favorite: !wasFavorite,
      );
    } catch (_) {
      if (wasFavorite) {
        _favoriteShopIds.add(hullId);
      } else {
        _favoriteShopIds.remove(hullId);
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeFavoriteShop(String shopId) async {
    final hullId = shopId.split('--').first;
    if (!_favoriteShopIds.contains(hullId)) {
      return;
    }
    await toggleFavoriteShop(hullId);
  }

  TravelStyleInsight get travelStyle => TravelStyleAnalyzer.analyze(
    regions: _regions,
    stats: _stats,
    shops: shops,
  );

  TourBooking? get nextTrip => TravelStyleAnalyzer.nextTrip(_bookings);

  double continentProgress(String continent) {
    final hits = _regions.where((region) => region.continent == continent);
    if (hits.isEmpty) {
      return 0;
    }
    final logs = hits.fold<int>(0, (sum, region) => sum + region.logCount);
    return (logs / 20).clamp(0.0, 1.0);
  }

  void toggleGear(String id) {
    final index = _gear.indexWhere((item) => item.id == id);
    if (index < 0) {
      return;
    }
    _gear[index] = _gear[index].copyWith(packed: !_gear[index].packed);
    notifyListeners();
  }

  Future<void> addLog({
    required String siteName,
    required DateTime divedAt,
    required String memo,
    Uint8List? photoBytes,
    String? photoFileName,
    String? photoContentType,
    DiveProfile? profile,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    await _repository.addLog(
      uid: uid,
      siteName: siteName,
      divedAt: divedAt,
      memo: memo,
      photoBytes: photoBytes,
      photoFileName: photoFileName,
      photoContentType: photoContentType,
      profile: profile,
    );
    await refreshLogs();
  }

  Future<void> updateLog({
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
    final uid = _uid;
    if (uid == null) {
      return;
    }
    await _repository.updateLog(
      uid: uid,
      logId: logId,
      siteName: siteName,
      divedAt: divedAt,
      memo: memo,
      photoBytes: photoBytes,
      photoFileName: photoFileName,
      photoContentType: photoContentType,
      profile: profile,
      removePhoto: removePhoto,
    );
    await refreshLogs();
  }

  Future<bool> createBooking({
    required DiveShop shop,
    required int price,
    DateTime? tourDate,
    String? productId,
    int partySize = 0,
    String optionId = '',
    String seatOptionId = '',
    ProductListingKind listingKind = ProductListingKind.exploreOnly,
    bool fromFlag = false,
    String? productName,
    String optionName = '',
    int divers = 0,
    int nondivers = 0,
    int children = 0,
    int infants = 0,
    List<BookingLine> quoteLines = const [],
    BookingStatus status = BookingStatus.requested,
    PaymentStatus paymentStatus = PaymentStatus.unpaid,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return false;
    }
    final hull = shop.id.split('--').first;
    final saved = await _repository.createBooking(
      uid: uid,
      shopId: shop.id,
      shopName: shop.name,
      productName: productName ?? shop.productName,
      price: price,
      tourDate: tourDate,
      productId: productId,
      partySize: partySize,
      optionId: optionId,
      optionName: optionName,
      seatOptionId: seatOptionId,
      listingKind: listingKind,
      fromFlag: fromFlag,
      divers: divers,
      nondivers: nondivers,
      children: children,
      infants: infants,
      quoteLines: quoteLines,
      status: status,
      paymentStatus: paymentStatus,
    );
    unawaited(refreshShopStat(hull));
    return saved;
  }

  Future<SeatFlagPlant> plantSeatFlag({
    required String shopId,
    required String productId,
    required int partySize,
    String optionId = '',
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return SeatFlagPlant.unavailable;
    }
    final now = DateTime.now();
    final hull = shopId.split('--').first;
    final result = await _repository.plantSeatFlag(
      shopId: hull,
      productId: productId,
      partySize: partySize,
      now: now,
      optionId: optionId,
      uid: uid,
    );
    unawaited(refreshShopStat(hull));
    return result;
  }

  Future<bool> cancelSeatFlag({
    required String shopId,
    required String productId,
    String optionId = '',
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return false;
    }
    final hull = shopId.split('--').first;
    final ok = await _repository.cancelSeatFlag(
      uid: uid,
      shopId: hull,
      productId: productId,
      now: DateTime.now(),
      optionId: optionId,
    );
    if (ok) {
      unawaited(refreshShopStat(hull));
    }
    return ok;
  }

  Future<OperationReviewOutcome> submitOperationReview({
    required String shopId,
    required int safety,
    required int guide,
    required int boat,
    String? bookingId,
    String? logId,
    String? productId,
    String? optionId,
    String? comment,
    ReviewDetails? details,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const OperationReviewOutcome(
        productLink: ReviewProductLinkStatus.missingProductId,
      );
    }
    final name = _stats.displayName.trim();
    final outcome = await _repository.submitOperationReview(
      uid: uid,
      shopId: shopId,
      safety: safety,
      guide: guide,
      boat: boat,
      bookingId: bookingId,
      logId: logId,
      productId: productId,
      optionId: optionId,
      comment: comment,
      authorDisplayName: name.isEmpty ? null : name,
      details: details,
    );
    await refreshShopStat(shopId);
    await refreshMyReviews();
    return outcome;
  }

  Future<List<GuestReview>> listMyReviews() async {
    await refreshMyReviews();
    return myReviews;
  }

  Future<void> ensureMyReviewsLoaded() async {
    if (_myReviewsLoaded || _myReviewsLoading) {
      return;
    }
    await refreshMyReviews();
  }

  Future<void> refreshMyReviews() async {
    final uid = _uid;
    if (uid == null) {
      _myReviews = const [];
      _myReviewsLoaded = false;
      notifyListeners();
      return;
    }
    _myReviewsLoading = true;
    try {
      _myReviews = await _repository.listMyReviews(uid);
      _myReviewsLoaded = true;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('내 후기 로드 실패: $error');
      debugPrint('$stackTrace');
      rethrow;
    } finally {
      _myReviewsLoading = false;
    }
  }

  Future<void> updateOperationReview({
    required String shopId,
    required String reviewId,
    required int safety,
    required int guide,
    required int boat,
    String? comment,
    ReviewDetails? details,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Sign in required');
    }
    await _repository.updateOperationReview(
      uid: uid,
      shopId: shopId,
      reviewId: reviewId,
      safety: safety,
      guide: guide,
      boat: boat,
      comment: comment,
      details: details,
    );
    await refreshShopStat(shopId);
    await refreshMyReviews();
  }

  Future<void> deleteOperationReview({
    required String shopId,
    required String reviewId,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Sign in required');
    }
    await _repository.deleteOperationReview(
      uid: uid,
      shopId: shopId,
      reviewId: reviewId,
    );
    await refreshShopStat(shopId);
    await refreshMyReviews();
  }

  Future<GuestReviewsPage> fetchShopReviewsPage({
    required String shopId,
    int limit = 10,
    Object? cursor,
  }) {
    return _repository.fetchShopReviewsPage(
      shopId: shopId,
      limit: limit,
      cursor: cursor,
    );
  }

  Future<void> submitProVerification({
    required String agency,
    required Uint8List photoBytes,
    required String photoFileName,
    required String photoContentType,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    await _repository.submitProVerification(
      uid: uid,
      agency: agency,
      photoBytes: photoBytes,
      photoFileName: photoFileName,
      photoContentType: photoContentType,
    );
  }

  Future<void> approveInstructor(String uid) async {
    await _repository.approveInstructor(uid);
    await refreshAdminInbox();
  }

  Future<void> setMemberGrade({
    required String uid,
    required MemberGrade grade,
  }) async {
    await _repository.setMemberGrade(uid: uid, grade: grade);
    await refreshAdminInbox();
  }

  Future<void> unlockMemberGrade(String uid) async {
    await _repository.unlockMemberGrade(uid);
    await refreshAdminInbox();
  }

  Future<void> touchLastSeen() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return Future.value();
    }
    return _repository.touchLastSeen(uid);
  }

  Future<void> clearGradeCelebration() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return Future.value();
    }
    return _repository.clearGradeCelebration(uid);
  }

  Future<void> rejectInstructor(String uid) async {
    await _repository.rejectInstructor(uid);
    await refreshAdminInbox();
  }

  Future<void> setPlaqueStatus({
    required String shopId,
    required PlaqueStatus status,
  }) async {
    await _repository.setPlaqueStatus(shopId: shopId, status: status);
    await refreshShopStat(shopId);
  }

  Future<void> setInternalScore({
    required String shopId,
    required int score,
  }) async {
    await _repository.setInternalScore(shopId: shopId, score: score);
    await refreshShopStat(shopId);
  }

  Future<void> setDiveStarGrade({
    required String shopId,
    required int grade,
    required DateTime reviewedAt,
    required DateTime expiresAt,
  }) async {
    await _repository.setDiveStarGrade(
      shopId: shopId,
      grade: grade,
      reviewedAt: reviewedAt,
      expiresAt: expiresAt,
    );
    await refreshShopStat(shopId);
  }

  Future<DiveStarForm> ensureActiveDiveStarForm() {
    return _repository.ensureActiveDiveStarForm();
  }

  Future<DiveStarForm?> getDiveStarForm(String version) {
    return _repository.getDiveStarForm(version);
  }

  Future<List<DiveStarForm>> listDiveStarForms() {
    return _repository.listDiveStarForms();
  }

  Future<DiveStarForm> importDiveStarFormDraft(DiveStarForm form) {
    return _repository.importDiveStarFormDraft(form);
  }

  Future<DiveStarForm> activateDiveStarForm(String version) {
    return _repository.activateDiveStarForm(version);
  }

  Future<List<DiveStarAssessment>> listDiveStarAssessments(String shopId) {
    return _repository.listDiveStarAssessments(shopId);
  }

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
  }) {
    return _repository.saveDiveStarAssessment(
      shopId: shopId,
      assessmentId: assessmentId,
      formVersion: formVersion,
      type: type,
      reviewedAt: reviewedAt,
      gates: gates,
      scores: scores,
      comments: comments,
      itemScores: itemScores,
      itemComments: itemComments,
      areaNa: areaNa,
      countryGates: countryGates,
      mysteryVisits: mysteryVisits,
      auditors: auditors,
    );
  }

  Future<DiveStarAssessment> confirmDiveStarAssessment({
    required String shopId,
    required String assessmentId,
    DateTime? expiresAt,
  }) {
    return _repository.confirmDiveStarAssessment(
      shopId: shopId,
      assessmentId: assessmentId,
      expiresAt: expiresAt,
    );
  }

  Future<void> deleteDiveStarAssessment({
    required String shopId,
    required String assessmentId,
  }) {
    return _repository.deleteDiveStarAssessment(
      shopId: shopId,
      assessmentId: assessmentId,
    );
  }

  Future<List<PartnerDocument>> ensurePartnerDocumentsSeeded() {
    return _repository.ensurePartnerDocumentsSeeded();
  }

  Future<List<PartnerDocument>> listApprovedPublicPartnerDocuments() {
    return _repository.listApprovedPublicPartnerDocuments();
  }

  Future<PartnerDocConfig> ensurePartnerDocConfig() {
    return _repository.ensurePartnerDocConfig();
  }

  Future<void> savePartnerDocConfig(PartnerDocConfig config) {
    return _repository.savePartnerDocConfig(config);
  }

  Future<void> updatePartnerDocumentStatus({
    required String documentId,
    required PartnerDocStatus status,
  }) {
    return _repository.updatePartnerDocumentStatus(
      documentId: documentId,
      status: status,
    );
  }

  Future<List<DocumentShareRecord>> listDocumentShares({int limit = 50}) {
    return _repository.listDocumentShares(limit: limit);
  }

  Future<DocumentShareRecord> recordDocumentShare({
    required String documentId,
    required String documentTitle,
    required String shopId,
    required String shopName,
    required PartnerDocShareMethod method,
    required String adminUid,
  }) {
    return _repository.recordDocumentShare(
      documentId: documentId,
      documentTitle: documentTitle,
      shopId: shopId,
      shopName: shopName,
      method: method,
      adminUid: adminUid,
    );
  }

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
  }) {
    return _repository.submitDiveStarApplication(
      shopId: shopId,
      shopName: shopName,
      partnerUid: partnerUid,
      companyName: companyName,
      contactName: contactName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      country: country,
      notes: notes,
      signaturePngBase64: signaturePngBase64,
    );
  }

  Future<List<DiveStarApplication>> listDiveStarApplications({
    String? shopId,
    String? partnerUid,
    int limit = 50,
  }) {
    return _repository.listDiveStarApplications(
      shopId: shopId,
      partnerUid: partnerUid,
      limit: limit,
    );
  }

  Future<DiveStarApplication> updateDiveStarApplicationPipeline({
    required String applicationId,
    required DiveStarPipelineStatus status,
    DateTime? reminderDueAt,
    bool clearReminder = false,
  }) {
    return _repository.updateDiveStarApplicationPipeline(
      applicationId: applicationId,
      status: status,
      reminderDueAt: reminderDueAt,
      clearReminder: clearReminder,
    );
  }

  Future<PartnerEmailOutboxItem> queuePartnerEmail({
    required String toEmail,
    required String subject,
    required String body,
    String applicationId = '',
    String shopId = '',
  }) {
    return _repository.queuePartnerEmail(
      toEmail: toEmail,
      subject: subject,
      body: body,
      applicationId: applicationId,
      shopId: shopId,
    );
  }

  Future<List<PartnerEmailOutboxItem>> listPartnerEmailOutbox({
    int limit = 30,
  }) {
    return _repository.listPartnerEmailOutbox(limit: limit);
  }

  Future<void> markPartnerEmailOutboxSent(String outboxId) {
    return _repository.markPartnerEmailOutboxSent(outboxId);
  }

  Future<void> setPostHidden({required String postId, required bool hidden}) async {
    await _repository.setPostHidden(postId: postId, hidden: hidden);
    await refreshCommunityPosts();
  }

  Future<void> deletePost(String postId) async {
    await _repository.deletePost(postId);
    await refreshCommunityPosts();
  }

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
    bool creatorProposal = false,
    String? creatorUid,
  }) async {
    final owned = _stats.ownedShopId;
    final isOwnerPartner =
        _stats.isBusiness && owned != null && owned == shopId;
    final isCreatorProposal =
        creatorProposal &&
        shopId.startsWith('curated-') &&
        creatorUid != null &&
        creatorUid == _uid;
    if (!_stats.isAdmin && !isOwnerPartner && !isCreatorProposal) {
      throw StateError('Not allowed to edit this shop profile');
    }
    if (gallery != null) {
      final local = [
        for (final slot in gallery)
          if (slot.hasBytes) slot.bytes!,
      ];
      if (local.isNotEmpty) {
        _coverBytes[shopId] = local.first;
        _galleryBytes[shopId] = local;
      } else if (gallery.isEmpty) {
        _coverBytes.remove(shopId);
        _galleryBytes.remove(shopId);
      }
      notifyListeners();
    } else if (coverBytes != null && coverBytes.isNotEmpty) {
      _coverBytes[shopId] = coverBytes;
      notifyListeners();
    } else if (removeCover) {
      _coverBytes.remove(shopId);
      _galleryBytes.remove(shopId);
      notifyListeners();
    }
    await _repository.saveShopProfile(
      shopId: shopId,
      name: name,
      location: location,
      productName: productName,
      consumerPrice: consumerPrice,
      professionalPrice: professionalPrice,
      intro: intro,
      address: address,
      amenities: amenities,
      country: country,
      continent: continent,
      curated: curated,
      coverBytes: coverBytes,
      coverFileName: coverFileName,
      coverContentType: coverContentType,
      removeCover: removeCover,
      gallery: gallery,
    );
    await refreshShopStat(shopId);
  }

  /// Products this diver submitted from My (departure desk).
  List<ShopProduct> craftedProductsFor(String uid) {
    if (uid.isEmpty) {
      return const [];
    }
    final out = <ShopProduct>[];
    for (final stats in _shopStats) {
      for (final product in stats.products) {
        if (product.submittedByUid == uid) {
          out.add(product);
        }
      }
    }
    out.sort((a, b) {
      final aAt = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
    return out;
  }

  /// Shop id used for partner UI + saves (DevRoles overlay, else Firestore).
  String get partnerOwnedShopId =>
      stats.ownedShopId ?? AppConstants.defaultPartnerShopId;

  Future<void> saveShopProduct({
    required String shopId,
    required ShopProduct product,
    Uint8List? photoBytes,
    String? photoFileName,
    String? photoContentType,
    bool useAsResortCover = false,
    List<ShopGallerySlot>? gallery,
    bool creatorSubmission = false,
    String? submitterUid,
    ProductSaveIntent? intent,
  }) async {
    // Partners may only manage their own hull; divers may submit as creators;
    // everyone else needs admin. Use overlay-aware [stats] so DevRoles shop
    // matches list/form lockedShopId.
    final effective = stats;
    final owned = effective.ownedShopId;
    final isOwnerPartner =
        effective.isBusiness && owned != null && owned == shopId;
    final creatorUid = submitterUid?.trim() ?? '';
    if (creatorSubmission) {
      if (creatorUid.isEmpty || creatorUid != _uid) {
        throw StateError('A signed-in creator is required');
      }
      ShopProduct? current;
      for (final stats in _shopStats) {
        for (final item in stats.products) {
          if (item.id == product.id) {
            current = item;
            break;
          }
        }
        if (current != null) {
          break;
        }
      }
      if (current != null &&
          (current.submittedByUid.isEmpty ||
              current.submittedByUid != creatorUid)) {
        throw StateError('Only the original creator can edit this product');
      }
    }
    if (!_stats.isAdmin && !isOwnerPartner && !creatorSubmission) {
      throw StateError('Not allowed to edit this shop product');
    }

    final gated = _withSaveIntent(
      product: product,
      creatorSubmission: creatorSubmission,
      creatorUid: creatorUid,
      intent: intent,
    );

    await _repository.saveShopProduct(
      shopId: shopId,
      product: gated,
      photoBytes: photoBytes,
      photoFileName: photoFileName,
      photoContentType: photoContentType,
      useAsResortCover: useAsResortCover,
      gallery: gallery,
      // Same-boat seat screen only patches seat fields — keep other keys as-is.
      clearAbsentFormFields: intent != ProductSaveIntent.preserveListing,
    );
    // Only mirror bytes locally after a durable R2 URL was written.
    if (gallery != null) {
      final frames = <Uint8List?>[
        for (final slot in gallery)
          if (slot.hasBytes || slot.hasUrl) slot.hasBytes ? slot.bytes : null,
      ];
      _productFrames['$shopId--${gated.id}'] = frames;
      Uint8List? first;
      for (final frame in frames) {
        if (frame != null && frame.isNotEmpty) {
          first = frame;
          break;
        }
      }
      if (first != null) {
        _coverBytes['$shopId--${gated.id}'] = first;
        if (useAsResortCover) {
          _coverBytes[shopId] = first;
        }
      }
    } else if (photoBytes != null && photoBytes.isNotEmpty) {
      _coverBytes['$shopId--${gated.id}'] = photoBytes;
      if (useAsResortCover) {
        _coverBytes[shopId] = photoBytes;
      }
    }
    // Show the saved product in partner lists immediately, then confirm via fetch.
    _upsertLocalShopProduct(shopId, gated);
    final refreshed = await refreshShopStat(shopId);
    if (!refreshed) {
      throw StateError('SHOP_STAT_REFRESH_FAILED');
    }
  }

  void _upsertLocalShopProduct(String shopId, ShopProduct product) {
    final id = shopId.trim();
    if (id.isEmpty) {
      return;
    }
    final next = [..._shopStats];
    final index = next.indexWhere((item) => item.shopId == id);
    if (index < 0) {
      next.add(
        ShopLiveStats(
          shopId: id,
          reviewCount: 0,
          avgSafety: 0,
          avgGuide: 0,
          avgBoat: 0,
          avgOverall: 0,
          diveStar: 0,
          products: [product],
        ),
      );
    } else {
      final current = next[index];
      final products = [
        for (final item in current.products)
          if (item.id != product.id) item,
        product,
      ];
      next[index] = current.copyWith(products: products);
    }
    _shopStats = next;
    _shopStatsLoaded = true;
    notifyListeners();
  }

  ShopProduct _withSaveIntent({
    required ShopProduct product,
    required bool creatorSubmission,
    required String creatorUid,
    required ProductSaveIntent? intent,
  }) {
    final submitter = creatorUid.isNotEmpty
        ? creatorUid
        : product.submittedByUid;
    // Callers that do not pick a branch keep the old rule: creators and
    // partners wait, an admin save goes live.
    if (creatorSubmission || intent == null) {
      final forcePending = creatorSubmission || !_stats.isAdmin;
      if (forcePending) {
        return product.copyWith(
          publishStatus: ProductPublishStatus.pending,
          submittedAt: DateTime.now(),
          active: false,
          submittedByUid: submitter,
        );
      }
      ProductPublishGuard.ensureCanApprove(product);
      return product.copyWith(
        publishStatus: ProductPublishStatus.approved,
        active: true,
        reviewedAt: DateTime.now(),
        reviewNote: '',
        rejectedContentHash: '',
        resubmitCount: 0,
        resubmitNote: '',
        submittedAt: product.submittedAt ?? DateTime.now(),
      );
    }
    switch (intent) {
      case ProductSaveIntent.keepEditing:
        return product.copyWith(
          publishStatus: ProductPublishStatus.draft,
          active: false,
          submittedByUid: submitter,
        );
      case ProductSaveIntent.submitForReview:
        // Keep review_note so admin still sees the prior reject reason.
        return product.copyWith(
          publishStatus: ProductPublishStatus.pending,
          submittedAt: DateTime.now(),
          active: false,
          submittedByUid: submitter,
        );
      case ProductSaveIntent.publish:
        if (!_stats.isAdmin) {
          throw StateError('Admin only');
        }
        ProductPublishGuard.ensureCanApprove(product);
        return product.copyWith(
          publishStatus: ProductPublishStatus.approved,
          active: true,
          reviewedAt: DateTime.now(),
          reviewNote: '',
          rejectedContentHash: '',
          resubmitCount: 0,
          resubmitNote: '',
          submittedAt: product.submittedAt ?? DateTime.now(),
        );
      case ProductSaveIntent.takeDown:
        return product.copyWith(active: false);
      case ProductSaveIntent.preserveListing:
        return product;
    }
  }

  Future<void> setSameBoatStatus({
    required String shopId,
    required String productId,
    required SameBoatStatus status,
  }) async {
    ShopProduct? current;
    for (final item in allShopProducts) {
      if (item.shopId == shopId && item.id == productId) {
        current = item;
        break;
      }
    }
    if (current == null) {
      throw StateError('Product not found');
    }
    final next = current.copyWith(
      sameBoatStatus: status,
      openEmptySeats: status == SameBoatStatus.closed
          ? false
          : current.openEmptySeats,
      options: [
        for (final option in current.options)
          if (option.sameBoatStatus.isPendingReview ||
              option.openEmptySeats ||
              option.sameBoatStatus.isBoardLive)
            option.copyWith(
              sameBoatStatus: status,
              openEmptySeats:
                  status == SameBoatStatus.closed ? false : option.openEmptySeats,
            )
          else
            option,
      ],
    );
    await saveShopProduct(
      shopId: shopId,
      product: next,
      intent: ProductSaveIntent.preserveListing,
    );
  }

  Future<void> deleteShopProduct({
    required String shopId,
    required String productId,
  }) async {
    final owned = _stats.ownedShopId;
    final isOwnerPartner =
        _stats.isBusiness && owned != null && owned == shopId;
    if (!_stats.isAdmin && !isOwnerPartner) {
      throw StateError('Not allowed to delete this shop product');
    }
    await _repository.deleteShopProduct(shopId: shopId, productId: productId);
    await refreshShopStat(shopId);
  }

  Future<void> approveShopProduct({
    required String shopId,
    required String productId,
  }) async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    await _repository.setShopProductPublishStatus(
      shopId: shopId,
      productId: productId,
      status: ProductPublishStatus.approved,
    );
    await refreshShopStat(shopId);
  }

  Future<void> rejectShopProduct({
    required String shopId,
    required String productId,
    String reviewNote = '',
  }) async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    await _repository.setShopProductPublishStatus(
      shopId: shopId,
      productId: productId,
      status: ProductPublishStatus.rejected,
      reviewNote: reviewNote,
    );
    await refreshShopStat(shopId);
  }

  /// Admin-only: place a public product on a home shelf (or clear with exploreOnly).
  Future<void> setProductHomeShelf({
    required String shopId,
    required String productId,
    required ProductListingKind listingKind,
  }) async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    ShopProduct? current;
    for (final product in productsForShop(shopId)) {
      if (product.id == productId) {
        current = product;
        break;
      }
    }
    if (current == null || !current.isListedPublicly) {
      throw StateError('Product not public');
    }
    if (listingKind.isHomeShelf &&
        current.listingKind != listingKind &&
        countOnHomeShelf(listingKind) >= ProductListingKind.homeShelfLimit) {
      throw StateError('Home shelf full');
    }
    await _repository.setShopProductListingKind(
      shopId: shopId,
      productId: productId,
      listingKind: listingKind,
    );
    await refreshShopStat(shopId);
  }

  Future<void> saveInstructorDiscount(InstructorDiscount discount) {
    return _repository.saveInstructorDiscount(discount);
  }

  Future<void> cancelBookingAsGuest(String bookingId) {
    final uid = _uid;
    if (uid == null) {
      return Future.value();
    }
    return _repository.cancelBookingAsGuest(uid: uid, bookingId: bookingId);
  }

  Future<bool> confirmShopBooking({
    required String shopId,
    required String bookingId,
  }) {
    return _repository.confirmShopBooking(
      shopId: shopId,
      bookingId: bookingId,
    );
  }

  Future<void> cancelBookingsForWeather({
    required String shopId,
    required DateTime tourDate,
  }) {
    return _repository.cancelBookingsForWeather(
      shopId: shopId,
      tourDate: tourDate,
    );
  }

  Future<void> acknowledgeRefundNotice(String bookingId) {
    final uid = _uid;
    if (uid == null) {
      return Future.value();
    }
    return _repository.acknowledgeRefundNotice(uid: uid, bookingId: bookingId);
  }

  Future<void> addCommunityPost({
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
    final uid = _uid;
    if (uid == null) {
      return;
    }
    await _repository.addCommunityPost(
      uid: uid,
      authorName: _stats.displayName,
      title: title,
      subtitle: subtitle,
      type: type,
      language: language,
      shopId: shopId,
      destination: destination,
      windowLabel: windowLabel,
      capacity: capacity,
      bookedSeats: bookedSeats,
      lookingSeats: lookingSeats,
      soloShare: soloShare,
      kind: kind,
    );
    await refreshCommunityPosts();
  }

  Stream<List<CommunityComment>> watchComments(String postId) {
    return _repository.watchComments(postId);
  }

  Future<void> addComment({
    required String postId,
    required String body,
    required String language,
  }) {
    final uid = _uid;
    if (uid == null) {
      return Future.value();
    }
    return _repository.addComment(
      postId: postId,
      uid: uid,
      authorName: _stats.displayName,
      body: body,
      language: language,
    );
  }

  Future<void> _hydrateShopCovers(List<ShopLiveStats> stats) async {
    if (!R2Config.isReady || stats.isEmpty) {
      return;
    }
    final gen = ++_shopCoverHydrateGen;
    try {
      final hydrated = await Future.wait([
        for (final item in stats) _hydrateOneShopCover(item),
      ]);
      if (gen != _shopCoverHydrateGen) {
        return;
      }
      final byId = {for (final item in hydrated) item.shopId: item};
      _shopStats = [
        for (final item in _shopStats) byId.remove(item.shopId) ?? item,
        ...byId.values,
      ];
      notifyListeners();
    } catch (error) {
      debugPrint('R2 cover hydrate failed: $error');
    }
  }

  Future<ShopLiveStats> _hydrateOneShopCover(ShopLiveStats stats) async {
    final cover = stats.coverUrl;
    final nextCover = (cover == null || cover.isEmpty)
        ? cover
        : await _photos.readableUrl(cover);
    final nextGallery = [
      for (final url in stats.galleryUrls) await _photos.readableUrl(url),
    ];
    final nextProducts = [
      for (final product in stats.products)
        product.coverUrl.isEmpty
            ? product
            : product.copyWith(
                coverUrl: await _photos.readableUrl(product.coverUrl),
              ),
    ];
    return stats.copyWith(
      coverUrl: nextCover,
      galleryUrls: nextGallery,
      products: nextProducts,
    );
  }

  ShopLiveStats? liveStatsFor(String shopId) {
    for (final stats in _shopStats) {
      if (stats.shopId == shopId) {
        return stats;
      }
    }
    return null;
  }

  Future<void> ensureShopStatsLoaded() async {
    if (_shopStatsLoading) {
      return;
    }
    final fetchedAt = _shopStatsFetchedAt;
    if (_shopStatsLoaded &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < shopStatsCacheTtl) {
      return;
    }
    await refreshShopStats();
  }

  /// Test helper: pretend the last shop-stats fetch happened [ago] ago.
  @visibleForTesting
  void debugBackdateShopStatsFetch(Duration ago) {
    _shopStatsFetchedAt = DateTime.now().subtract(ago);
    _shopStatsLoaded = true;
  }

  Future<void> refreshShopStats() async {
    if (_shopStatsLoading) {
      return;
    }
    _shopStatsLoading = true;
    try {
      final stats = await _repository.fetchShopStats();
      _shopStats = stats;
      _shopStatsLoaded = true;
      _shopStatsFetchedAt = DateTime.now();
      notifyListeners();
      unawaited(_hydrateShopCovers(stats));
    } catch (error, stackTrace) {
      debugPrint('샵 통계 로드 실패: $error');
      debugPrint('$stackTrace');
    } finally {
      _shopStatsLoading = false;
    }
  }

  /// Reloads one shop into [_shopStats]. Returns false if missing or on error.
  Future<bool> refreshShopStat(String shopId) async {
    final id = shopId.trim();
    if (id.isEmpty) {
      return false;
    }
    try {
      final updated = await _repository.fetchShopStat(id);
      if (updated == null) {
        return false;
      }
      final next = [..._shopStats];
      final index = next.indexWhere((item) => item.shopId == id);
      if (index >= 0) {
        next[index] = updated;
      } else {
        next.add(updated);
      }
      _shopStats = next;
      _shopStatsLoaded = true;
      notifyListeners();
      unawaited(_hydrateShopCovers([updated]));
      return true;
    } catch (error, stackTrace) {
      debugPrint('샵 통계 단건 갱신 실패: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Future<void> ensureCommunityPostsLoaded() async {
    if (_postsLoaded || _postsLoading) {
      return;
    }
    await refreshCommunityPosts();
  }

  Future<void> refreshCommunityPosts() async {
    if (_postsLoading) {
      return;
    }
    _postsLoading = true;
    try {
      final page = await _repository.fetchCommunityPosts(limit: 20);
      _posts = page.posts;
      _postsCursor = page.nextCursor;
      _postsHasMore = page.hasMore;
      _postsLoaded = true;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('커뮤니티 게시글 로드 실패: $error');
      debugPrint('$stackTrace');
    } finally {
      _postsLoading = false;
    }
  }

  Future<void> loadMoreCommunityPosts() async {
    if (_postsLoading || !_postsHasMore) {
      return;
    }
    _postsLoading = true;
    try {
      final page = await _repository.fetchCommunityPosts(
        limit: 20,
        cursor: _postsCursor,
      );
      _posts = [..._posts, ...page.posts];
      _postsCursor = page.nextCursor;
      _postsHasMore = page.hasMore;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('커뮤니티 게시글 더보기 실패: $error');
      debugPrint('$stackTrace');
    } finally {
      _postsLoading = false;
    }
  }

  Future<void> ensureLogsLoaded() async {
    if (_logsLoaded || _logsLoading) {
      return;
    }
    await refreshLogs();
  }

  Future<void> refreshLogs() async {
    final uid = _uid;
    if (uid == null || _logsLoading) {
      return;
    }
    _logsLoading = true;
    try {
      final page = await _repository.fetchDiveLogs(uid, limit: 50);
      _logs = page.logs;
      _logsCursor = page.nextCursor;
      _logsHasMore = page.hasMore;
      _logsLoaded = true;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('로그북 로드 실패: $error');
      debugPrint('$stackTrace');
    } finally {
      _logsLoading = false;
    }
  }

  Future<void> loadMoreLogs() async {
    final uid = _uid;
    if (uid == null || _logsLoading || !_logsHasMore) {
      return;
    }
    _logsLoading = true;
    try {
      final page = await _repository.fetchDiveLogs(
        uid,
        limit: 50,
        cursor: _logsCursor,
      );
      _logs = [..._logs, ...page.logs];
      _logsCursor = page.nextCursor;
      _logsHasMore = page.hasMore;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('로그북 더보기 실패: $error');
      debugPrint('$stackTrace');
    } finally {
      _logsLoading = false;
    }
  }

  Future<void> ensureAdminInboxLoaded() async {
    if (!_stats.isAdmin) {
      return;
    }
    if (_adminInboxLoaded || _adminInboxLoading) {
      return;
    }
    await refreshAdminInbox();
  }

  Future<void> refreshAdminInbox() async {
    if (!_stats.isAdmin || _adminInboxLoading) {
      return;
    }
    _adminInboxLoading = true;
    try {
      final pending = await _repository.fetchPendingInstructors();
      final members = await _repository.fetchMembers();
      _pendingInstructors = pending;
      _members = members;
      _adminInboxLoaded = true;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('관리자 인박스 로드 실패: $error');
      debugPrint('$stackTrace');
    } finally {
      _adminInboxLoading = false;
    }
  }

  Future<void> ensureSalesBookingsLoaded() async {
    if (!_stats.isAdmin) {
      return;
    }
    if (_salesLoaded || _salesLoading) {
      return;
    }
    await refreshSalesBookings();
  }

  Future<void> refreshSalesBookings() async {
    if (!_stats.isAdmin || _salesLoading) {
      return;
    }
    _salesLoading = true;
    try {
      if (!_shopStatsLoaded) {
        await refreshShopStats();
      }
      final ids = <String>{
        for (final stats in _shopStats)
          if (stats.shopId.isNotEmpty) stats.shopId,
      };
      final byShop = <String, List<TourBooking>>{};
      for (final id in ids) {
        byShop[id] = await _repository.fetchShopBookings(id);
      }
      _salesByShop
        ..clear()
        ..addAll(byShop);
      _salesBookings = [
        for (final list in _salesByShop.values) ...list,
      ];
      _salesLoaded = true;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('관리자 예약 로드 실패: $error');
      debugPrint('$stackTrace');
    } finally {
      _salesLoading = false;
    }
  }

  void _bindDiver(AppUser? user) {
    _diverSubscription?.cancel();
    _bookingSubscription?.cancel();
    _shopBookingSubscription?.cancel();
    if (user == null) {
      _adminConsoleUnlocked = false;
      _stats = const DiverStats(
        displayName: '다이버',
        totalLogCount: 0,
        uniqueRegionsCount: 0,
        isInstructor: false,
      );
      _regions = const [];
      _logs = const [];
      _favoriteShopIds.clear();
      _shopStats = const [];
      _bookings = const [];
      _pendingInstructors = const [];
      _members = const [];
      _posts = const [];
      _shopBookings = const [];
      _salesByShop.clear();
      _salesBookings = const [];
      _shopStatsLoaded = false;
      _shopStatsFetchedAt = null;
      _myReviews = const [];
      _myReviewsLoaded = false;
      _postsLoaded = false;
      _postsHasMore = false;
      _postsCursor = null;
      _logsLoaded = false;
      _logsHasMore = false;
      _logsCursor = null;
      _adminInboxLoaded = false;
      _salesLoaded = false;
      _loadingTimeout?.cancel();
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(const Duration(seconds: 10), () {
      if (!_loading) {
        return;
      }
      _loading = false;
      notifyListeners();
    });
    unawaited(_repository.ensureSeedPosts());
    unawaited(_repository.touchLastSeen(user.uid));
    // One-shot shop cache for Explore/home; pull-to-refresh thereafter.
    unawaited(refreshShopStats());
    _diverSubscription = _repository
        .watchDiver(user.uid)
        .listen(
          (snapshot) {
            _loadingTimeout?.cancel();
            _stats = snapshot.stats;
            _regions = snapshot.regions;
            // Logs stay on-demand via [refreshLogs]; do not clear local cache.
            _favoriteShopIds
              ..clear()
              ..addAll(snapshot.favoriteShopIds);
            _loading = false;
            _rebindRoleInboxes();
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Firestore 다이버 구독 실패: $error');
            debugPrint('$stackTrace');
            _loadingTimeout?.cancel();
            _loading = false;
            notifyListeners();
          },
        );
    // Guest bookings stay realtime for status UX.
    _bookingSubscription = _repository
        .watchBookings(user.uid)
        .listen(
          (bookings) {
            _bookings = bookings;
            notifyListeners();
          },
          onError: (Object error) {
            debugPrint('Firestore 예약 구독 실패: $error');
          },
        );
  }

  void _rebindRoleInboxes() {
    final effective = stats;
    _bindAdminInbox(effective.isAdmin);
    _bindPartnerInbox(effective.isBusiness, effective.ownedShopId);
  }

  /// Owner-only: overlay UI role; keeps Firestore `is_admin` true.
  Future<void> applyDevRole({
    required DevRoleKind kind,
    String? ownedShopId,
  }) async {
    final uid = _uid;
    if (uid == null || !DevRoles.canUse(_email)) {
      throw StateError('Dev roles are owner-only');
    }
    if (kind == DevRoleKind.partner) {
      final shop = (ownedShopId ?? '').trim();
      if (shop.isEmpty) {
        throw StateError('Partner role needs a shop id');
      }
      await _repository.updateDevTestRole(
        uid: uid,
        isBusiness: true,
        ownedShopId: shop,
        userRole: 'business',
      );
      _devRoleOverlay = DevRoleOverlay(kind: kind, ownedShopId: shop);
      // Keep raw _stats aligned with overlay until the user-doc snapshot arrives.
      _stats = _stats.copyWith(isBusiness: true, ownedShopId: shop);
    } else {
      await _repository.updateDevTestRole(
        uid: uid,
        isBusiness: false,
        ownedShopId: null,
        userRole: kind == DevRoleKind.admin ? 'admin' : 'diver',
      );
      _devRoleOverlay = DevRoleOverlay(kind: kind);
      _stats = _stats.copyWith(isBusiness: false, clearOwnedShopId: true);
    }
    _rebindRoleInboxes();
    notifyListeners();
  }

  void clearDevRoleOverlay() {
    if (_devRoleOverlay == null) {
      return;
    }
    _devRoleOverlay = null;
    _rebindRoleInboxes();
    notifyListeners();
  }

  void _bindAdminInbox(bool isAdmin) {
    if (!isAdmin) {
      _pendingInstructors = const [];
      _members = const [];
      _adminInboxLoaded = false;
      _salesByShop.clear();
      _salesBookings = const [];
      _salesLoaded = false;
      return;
    }
    // Admin lists load when the console screens open (ensure*/refresh*).
  }

  void _bindPartnerInbox(bool isBusiness, String? shopId) {
    if (!isBusiness || shopId == null || shopId.isEmpty) {
      _shopBookingSubscription?.cancel();
      _shopBookingSubscription = null;
      _shopBookings = const [];
      return;
    }
    if (_shopBookingSubscription != null) {
      return;
    }
    // Partner bookings stay realtime (phase-2 will move to get+refresh).
    _shopBookingSubscription = _repository
        .watchShopBookings(shopId)
        .listen(
          (bookings) {
            _shopBookings = bookings;
            notifyListeners();
          },
          onError: (Object error) {
            debugPrint('파트너 예약 구독 실패: $error');
          },
        );
  }

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    _authSubscription?.cancel();
    _diverSubscription?.cancel();
    _bookingSubscription?.cancel();
    _shopBookingSubscription?.cancel();
    _discountSubscription?.cancel();
    super.dispose();
  }
}

class DiverStoreScope extends InheritedNotifier<DiverStore> {
  const DiverStoreScope({
    super.key,
    required DiverStore store,
    required super.child,
  }) : super(notifier: store);

  static DiverStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DiverStoreScope>();
    assert(scope != null, 'DiverStoreScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
  }
}

const _defaultGear = <GearItem>[
  GearItem(id: 'mask', name: '마스크 / 스노클', category: '호흡', packed: true),
  GearItem(id: 'fins', name: '핀', category: '이동', packed: true),
  GearItem(id: 'regulator', name: '레귤레이터', category: '호흡', packed: false),
  GearItem(id: 'bcd', name: 'BCD', category: '부력', packed: false),
  GearItem(id: 'wetsuit', name: '슈트', category: '노출', packed: true),
  GearItem(id: 'computer', name: '다이브 컴퓨터', category: '안전', packed: false),
  GearItem(id: 'smb', name: 'SMB / 릴', category: '안전', packed: false),
  GearItem(id: 'torch', name: '라이트', category: '액세서리', packed: false),
  GearItem(id: 'camera', name: '카메라', category: '액세서리', packed: false),
  GearItem(id: 'firstAid', name: '응급 키트', category: '안전', packed: false),
];
