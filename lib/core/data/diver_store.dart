import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
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
import 'package:dive_travel_app/core/models/partner_contract.dart';
import 'package:dive_travel_app/core/models/partner_contract_terms.dart';
import 'package:dive_travel_app/core/auth/auth_identity.dart';
import 'package:dive_travel_app/core/models/partner_application.dart';
import 'package:dive_travel_app/core/models/partner_promotion.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/core/models/gear_item.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/review_detail_options.dart';
import 'package:dive_travel_app/core/models/trial_data_cleanup.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
import 'package:dive_travel_app/core/models/same_boat_alert.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';
import 'package:dive_travel_app/core/models/price_revision.dart';
import 'package:dive_travel_app/core/models/product_publish_guard.dart';
import 'package:dive_travel_app/core/models/product_change.dart';
import 'package:dive_travel_app/core/models/shop_day_stats.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/storage/r2_photo_storage.dart';

/// Outcome flags from [DiverStore.saveShopProduct].
class ShopProductSaveResult {
  const ShopProductSaveResult({this.stagedPriceOrNewOptions = false});

  final bool stagedPriceOrNewOptions;
}

/// Merge readable cover/gallery URLs from [hydratedCovers] onto [current].
///
/// Only shop `coverUrl` / `galleryUrls` and each product's `coverUrl` are
/// taken from the hydrated snapshot. Seat inventory, same-boat flags, and
/// every other product/shop field keep the **current** values.
@visibleForTesting
List<ShopLiveStats> mergeHydratedShopCovers({
  required List<ShopLiveStats> current,
  required List<ShopLiveStats> hydratedCovers,
}) {
  final byId = {for (final item in hydratedCovers) item.shopId: item};
  return [
    for (final item in current)
      if (byId.containsKey(item.shopId))
        mergeShopCoverUrls(current: item, hydrated: byId[item.shopId]!)
      else
        item,
  ];
}

@visibleForTesting
ShopLiveStats mergeShopCoverUrls({
  required ShopLiveStats current,
  required ShopLiveStats hydrated,
}) {
  final productCovers = <String, String>{
    for (final product in hydrated.products)
      if (product.coverUrl.isNotEmpty) product.id: product.coverUrl,
  };
  return current.copyWith(
    coverUrl: hydrated.coverUrl ?? current.coverUrl,
    galleryUrls:
        hydrated.galleryUrls.isEmpty ? current.galleryUrls : hydrated.galleryUrls,
    products: [
      for (final product in current.products)
        if (productCovers.containsKey(product.id))
          product.copyWith(coverUrl: productCovers[product.id]!)
        else
          product,
    ],
  );
}

/// Result of [DiverStore.discardPartnerOption].
enum PartnerOptionDiscardResult { deleted, closed }

class _GatedShopProduct {
  const _GatedShopProduct(this.product, this.stagedPriceOrNewOptions);

  final ShopProduct product;
  final bool stagedPriceOrNewOptions;
}

class DiverStore extends ChangeNotifier {
  /// Explore/홈 auto-refresh window for shop stats cache.
  static const shopStatsCacheTtl = Duration(minutes: 5);

  DiverStore(this._repository) {
    _gear = List<GearItem>.from(_defaultGear);
    _authSubscription = _repository.authState().listen((user) {
      _uid = user?.uid;
      _email = user?.email;
      _authDisplayName = user?.displayName;
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
  final SeatViewBuffer _seatViews = SeatViewBuffer();
  Timer? _seatViewTimer;
  String? _uid;
  String? _email;
  String? _authDisplayName;
  var _shopStatsLoaded = false;
  Future<void>? _shopStatsRefresh;
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
  Future<void>? _adminInboxRefresh;
  Future<void>? _adminInboxNext;
  var _adminInboxStale = false;
  var _closed = false;
  var _salesLoaded = false;
  var _salesLoading = false;
  final _analyticsCache = <String, List<_AnalyticsCacheSpan>>{};

  DiverStats _stats = const DiverStats(
    displayName: '다이버',
    totalLogCount: 0,
    uniqueRegionsCount: 0,
    isInstructor: false,
  );
  List<DiveRegion> _regions = const [];
  List<SameBoatAlert> _seatAlerts = const [];
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

  DiverStats get stats => _stats;

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
    return SameBoatBoard.filteredOffers(
      _sameBoatProducts(),
      filter,
      now ?? DateTime.now(),
    );
  }

  List<SameBoatAlert> get seatAlerts => List.unmodifiable(_seatAlerts);

  /// Stores the current zero-result search on the member document.
  /// Does not send a message. Returns [SeatAlertWrite.alreadySaved] when the
  /// five conditions are already in the list.
  Future<SeatAlertWrite> saveSeatAlert(SameBoatSearch search) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in required');
    }
    final update = appendSeatAlert(
      existing: _seatAlerts,
      search: search,
      now: DateTime.now(),
    );
    if (update.result == SeatAlertWrite.alreadySaved) {
      return SeatAlertWrite.alreadySaved;
    }
    final previous = _seatAlerts;
    _seatAlerts = update.alerts;
    notifyListeners();
    try {
      await _repository.saveSeatAlerts(uid: uid, alerts: update.alerts);
    } catch (error) {
      _seatAlerts = previous;
      notifyListeners();
      rethrow;
    }
    return SeatAlertWrite.saved;
  }

  List<SameBoatOffer> sameBoatResults({DateTime? now}) {
    return SameBoatBoard.results(_sameBoatProducts(), now: now ?? DateTime.now());
  }

  List<ShopProduct> _sameBoatProducts() {
    return [
      for (final stats in _shopStats)
        for (final product in stats.products) product,
    ];
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

  /// Creator product submissions waiting for owner approval.
  ///
  /// Affiliate-partner products never enter this queue (H1a). Legacy
  /// `price_revision` rows are ignored. Creators use
  /// [ProductListingKind.diverPlanned] and still appear for approve/reject.
  List<ShopProduct> get pendingProductApprovals {
    final out = <ShopProduct>[];
    for (final stats in _shopStats) {
      for (final product in stats.products) {
        if (!product.isPendingApproval) {
          continue;
        }
        // Partner (and other non-creator) pending rows stay out of the queue.
        if (product.listingKind != ProductListingKind.diverPlanned) {
          continue;
        }
        out.add(product);
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
    String? guestDisplayName,
    String guestBirthDate = '',
    String guestContact = '',
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
      guestDisplayName: (guestDisplayName ?? _resolveGuestDisplayName()).trim(),
      guestBirthDate: guestBirthDate.trim(),
      guestContact: guestContact.trim(),
    );
    unawaited(refreshShopStat(hull));
    if (saved && fromFlag && productId != null && productId.isNotEmpty) {
      unawaited(
        _recordSeatPay(
          shopId: hull,
          productId: productId,
          optionId: seatOptionId.isNotEmpty ? seatOptionId : optionId,
          price: price,
          partySize: partySize,
          tourDate: tourDate,
        ),
      );
    }
    return saved;
  }

  /// Profile/login display name only; never invents from email local-part.
  String get profileGuestName => _resolveGuestDisplayName();

  String _resolveGuestDisplayName() {
    return resolveGuestDisplayName(
      authDisplayName: _authDisplayName,
      profileDisplayName: _stats.displayName,
      email: _email,
    );
  }

  Future<SeatFlagPlant> plantSeatFlag({
    required String shopId,
    required String productId,
    required int partySize,
    String optionId = '',
    int lockedPrice = 0,
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
      lockedPrice: lockedPrice,
    );
    unawaited(refreshShopStat(hull));
    if (result == SeatFlagPlant.planted) {
      unawaited(
        _recordSeatFlag(
          shopId: hull,
          productId: productId,
          optionId: optionId,
          partySize: partySize,
          price: lockedPrice,
          at: now,
        ),
      );
    }
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
      unawaited(
        _recordSeatCancel(
          shopId: hull,
          productId: productId,
          optionId: optionId,
          at: DateTime.now(),
        ),
      );
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

  Future<void> approveInstructor(String uid) {
    return _commitMemberChange(
      uid: uid,
      patch: (member) => member.copyWith(isInstructor: true),
      write: () => _repository.approveInstructor(uid),
    );
  }

  Future<void> setMemberGrade({
    required String uid,
    required MemberGrade grade,
  }) {
    return _commitMemberChange(
      uid: uid,
      patch: (member) => member.copyWith(grade: grade, gradeLocked: true),
      write: () => _repository.setMemberGrade(uid: uid, grade: grade),
    );
  }

  Future<void> setMemberAdmin({
    required String uid,
    required bool admin,
  }) {
    final actorUid = _uid;
    if (actorUid == null || actorUid.isEmpty) {
      throw StateError('Signed-in admin required');
    }
    return _commitMemberChange(
      uid: uid,
      patch: (member) => member.copyWith(isAdmin: admin),
      write: () => _repository.setMemberAdmin(
        uid: uid,
        admin: admin,
        actorUid: actorUid,
      ),
    );
  }

  Future<void> setAccountBlocked({
    required String uid,
    required bool blocked,
  }) {
    return _commitMemberChange(
      uid: uid,
      patch: (member) => member.copyWith(accountBlocked: blocked),
      write: () => _repository.setAccountBlocked(uid: uid, blocked: blocked),
    );
  }

  Future<void> withdrawMember(String uid) {
    return _commitMemberChange(
      uid: uid,
      patch: (member) => member.copyWith(
        displayName: '',
        phone: '',
        withdrawnAt: DateTime.now().toUtc(),
      ),
      write: () => _repository.withdrawMember(uid),
    );
  }

  /// Patches one list row immediately, then refreshes in the background.
  /// A failed write restores that row.
  Future<void> _commitMemberChange({
    required String uid,
    required MemberAccount Function(MemberAccount member) patch,
    required Future<void> Function() write,
  }) async {
    final previous = _memberByUid(uid);
    _markAdminInboxStale();
    if (previous != null) {
      _replaceMember(patch(previous));
    }
    try {
      await write();
      unawaited(refreshAdminInbox());
    } catch (error) {
      if (previous != null) {
        _replaceMember(previous);
      }
      unawaited(refreshAdminInbox());
      rethrow;
    }
  }

  MemberAccount? _memberByUid(String uid) {
    for (final member in _members) {
      if (member.uid == uid) {
        return member;
      }
    }
    return null;
  }

  void _replaceMember(MemberAccount member) {
    if (_closed) {
      return;
    }
    _members = [
      for (final item in _members)
        if (item.uid == member.uid) member else item,
    ];
    notifyListeners();
  }

  void _markAdminInboxStale() {
    if (_adminInboxRefresh != null) {
      _adminInboxStale = true;
    }
  }

  Future<void> ensureMemberProfile(MemberAccount member) async {
    final email = member.email.trim();
    final fallback = email.contains('@') ? email.split('@').first : email;
    await _repository.adminRepairMemberProfile(
      uid: member.uid,
      email: email,
      displayName: fallback.isEmpty ? member.uid : fallback,
    );
    await refreshAdminInbox();
  }

  Future<void> rejectInstructor(String uid) {
    return _commitMemberChange(
      uid: uid,
      patch: (member) => member.copyWith(isInstructor: false),
      write: () => _repository.rejectInstructor(uid),
    );
  }

  Future<void> unlockMemberGrade(String uid) async {
    await _repository.unlockMemberGrade(uid);
    await refreshAdminInbox();
  }

  /// Shop ids already claimed via any member's [MemberAccount.ownedShopId].
  Set<String> get claimedPartnerShopIds {
    return {
      for (final m in _members)
        if (m.ownedShopId.trim().isNotEmpty) m.ownedShopId.trim(),
    };
  }

  /// Resorts with no partner owner (eligible for promote).
  List<DiveShop> get unownedPartnerShops {
    final claimed = claimedPartnerShopIds;
    return [
      for (final shop in resortHulls)
        if (!claimed.contains(shop.id)) shop,
    ];
  }

  Future<void> promoteMemberToPartner({
    required String uid,
    required String shopId,
  }) async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    final actorUid = _uid;
    if (actorUid == null || actorUid.isEmpty) {
      throw StateError('Signed-in admin required');
    }
    MemberAccount? target;
    for (final m in _members) {
      if (m.uid == uid) {
        target = m;
        break;
      }
    }
    if (target?.isBusiness == true) {
      throw StateError('ALREADY_PARTNER');
    }
    final shop = shopId.trim();
    if (shop.isEmpty) {
      throw StateError('PARTNER_SHOP_REQUIRED');
    }
    if (claimedPartnerShopIds.contains(shop)) {
      throw StateError('SHOP_ALREADY_OWNED');
    }
    await _commitMemberChange(
      uid: uid,
      patch: (member) => member.copyWith(
        isBusiness: true,
        ownedShopId: shop,
        userRole: 'business',
      ),
      write: () => _repository.promoteMemberToPartner(
        uid: uid,
        shopId: shop,
        actorUid: actorUid,
        actorName: _stats.displayName,
      ),
    );
  }

  Future<String> promoteMemberToPartnerWithNewShop({
    required String uid,
    required String shopName,
  }) async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    final shopId = await _repository.createEmptyShop(name: shopName);
    await promoteMemberToPartner(uid: uid, shopId: shopId);
    await refreshShopStats();
    return shopId;
  }

  Future<void> demoteMemberFromPartner(String uid) async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    final actorUid = _uid;
    if (actorUid == null || actorUid.isEmpty) {
      throw StateError('Signed-in admin required');
    }
    await _commitMemberChange(
      uid: uid,
      patch: (member) => member.copyWith(
        isBusiness: false,
        userRole: 'diver',
        clearOwnedShopId: true,
      ),
      write: () => _repository.demoteMemberFromPartner(
        uid: uid,
        actorUid: actorUid,
        actorName: _stats.displayName,
      ),
    );
  }

  Future<TrialDataSnapshot> fetchTrialDataCounts() async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    final actorUid = _uid;
    if (actorUid == null || actorUid.isEmpty) {
      throw StateError('Signed-in admin required');
    }
    return _repository.fetchTrialDataCounts(
      actorUid: actorUid,
      actorEmail: _email ?? '',
    );
  }

  Future<TrialDeleteResult> runTrialDataDeletion({
    required TrialDeleteSelection selection,
    required String confirmPhrase,
    required bool backupAcknowledged,
    void Function(TrialDeleteProgress progress)? onProgress,
  }) async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    final actorUid = _uid;
    if (actorUid == null || actorUid.isEmpty) {
      throw StateError('Signed-in admin required');
    }
    final result = await _repository.runTrialDataDeletion(
      selection: selection,
      confirmPhrase: confirmPhrase,
      backupAcknowledged: backupAcknowledged,
      actorUid: actorUid,
      actorName: _stats.displayName,
      actorEmail: _email ?? '',
      onProgress: onProgress,
    );
    await refreshAdminInbox();
    await refreshShopStats();
    return result;
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

  Future<PartnerContractTerms?> getPartnerContractTerms(String shopId) {
    return _repository.getPartnerContractTerms(shopId);
  }

  Future<List<PartnerContractTermRevision>> listPartnerContractTermRevisions(
    String shopId,
  ) {
    return _repository.listPartnerContractTermRevisions(shopId);
  }

  /// Saves terms and one history line together. Refuses an empty diff.
  Future<void> savePartnerContractTerms({
    required String shopId,
    required PartnerContractTerms next,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in required');
    }
    final current =
        await _repository.getPartnerContractTerms(shopId) ??
            PartnerContractTerms.empty;
    final changes = diffPartnerContractTerms(current, next);
    if (changes.isEmpty) {
      throw const PartnerContractTermsUnchanged();
    }
    final name = _stats.displayName.trim();
    await _repository.savePartnerContractTerms(
      shopId: shopId,
      next: next,
      adminUid: uid,
      actorName: name.isEmpty ? uid : name,
      changes: changes,
    );
  }

  Future<void> sendPartnerPromotion({
    required String shopId,
    required String kind,
    required DateTime startsOn,
    required DateTime endsOn,
    required String note,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in required');
    }
    await _repository.createPartnerPromotion(
      shopId: shopId,
      partnerUid: uid,
      kind: kind,
      startsOn: startsOn,
      endsOn: endsOn,
      note: note,
    );
  }

  Future<void> setNationality(String code) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in required');
    }
    await _repository.setNationality(uid: uid, code: code);
  }

  Future<void> clearNationality() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in required');
    }
    await _repository.clearNationality(uid);
  }

  Future<PartnerApplication?> myPartnerApplication() {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      return Future.value(null);
    }
    return _repository.getPartnerApplication(uid);
  }

  Future<PartnerApplication> submitPartnerApplication({
    required String shopName,
    required String contactName,
    required String phone,
    required String region,
    required String intro,
    required String link,
    required bool consent,
  }) {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in required');
    }
    if (_stats.isAdmin || _stats.isBusiness) {
      throw StateError('not allowed');
    }
    final fromEmail = AuthIdentity.loginIdFromAuthEmail(_email);
    final email = (_email ?? '').trim();
    final login = (fromEmail ?? (email.isEmpty ? uid : email)).trim();
    return _repository.createPartnerApplication(
      applicantUid: uid,
      loginId: login,
      shopName: shopName,
      contactName: contactName,
      phone: phone,
      region: region,
      intro: intro,
      link: link,
      consent: consent,
    );
  }

  Future<List<PartnerApplication>> loadPartnerApplications() {
    return _repository.listPartnerApplications();
  }

  Future<void> markPartnerApplicationHandled(String applicantUid) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in required');
    }
    await _repository.markPartnerApplicationHandled(
      applicantUid: applicantUid,
      adminUid: uid,
    );
  }

  /// Reads each shop's own proposal list. Does not use a collection group.
  Future<List<PartnerPromotion>> loadPartnerPromotionInbox({
    int perShop = 20,
  }) async {
    final ids = <String>{for (final shop in shops) shop.hullId};
    final batches = <List<PartnerPromotion>>[];
    for (final id in ids) {
      batches.add(await _repository.listPartnerPromotions(id, limit: perShop));
    }
    return mergePartnerPromotions(batches, perShop: perShop);
  }

  Future<void> markPartnerPromotionHandled({
    required String shopId,
    required String proposalId,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in required');
    }
    await _repository.markPartnerPromotionHandled(
      shopId: shopId,
      proposalId: proposalId,
      adminUid: uid,
    );
  }

  Future<List<ProductChangeRecord>> listProductChanges(String shopId) {
    return _repository.listProductChanges(shopId);
  }

  Future<bool> recordShopDay({
    required String shopId,
    required DateTime now,
    bool visit = false,
    bool productView = false,
  }) {
    return _repository.recordShopDay(
      shopId: shopId,
      now: now,
      visit: visit,
      productView: productView,
    );
  }

  Future<bool> recordShopDwell({
    required String shopId,
    required DateTime now,
    required int seconds,
  }) {
    return _repository.recordShopDwell(
      shopId: shopId,
      now: now,
      seconds: seconds,
    );
  }

  Future<List<ShopDayStats>> listShopDailyStats(String shopId) {
    return _repository.listShopDailyStats(shopId);
  }

  Future<List<PartnerContract>> listPartnerContracts(
    String shopId, {
    bool forPartner = false,
  }) {
    return _repository.listPartnerContracts(shopId, forPartner: forPartner);
  }

  Future<PartnerContract?> getPartnerContract({
    required String shopId,
    required String contractId,
  }) {
    return _repository.getPartnerContract(
      shopId: shopId,
      contractId: contractId,
    );
  }

  Future<List<PartnerContractEvent>> listPartnerContractEvents({
    required String shopId,
    required String contractId,
  }) {
    return _repository.listPartnerContractEvents(
      shopId: shopId,
      contractId: contractId,
    );
  }

  /// Upload PDF bytes to R2, then create a drafting vault document.
  Future<PartnerContract> uploadPartnerContractDraft({
    required String shopId,
    required Uint8List pdfBytes,
    required PartnerContractKind kind,
    required String title,
    required String version,
    DateTime? validFrom,
    DateTime? validUntil,
  }) async {
    final adminUid = _uid;
    if (adminUid == null || adminUid.isEmpty) {
      throw StateError('Sign in required');
    }
    final digest = sha256.convert(pdfBytes).toString();
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final objectKey = 'partner_contracts/$shopId/${stamp}_$digest.pdf';
    final fileUrl = await _photos.upload(
      objectKey: objectKey,
      bytes: pdfBytes,
      contentType: 'application/pdf',
    );
    return _repository.createPartnerContractDraft(
      shopId: shopId,
      adminUid: adminUid,
      kind: kind,
      title: title,
      version: version,
      fileUrl: fileUrl,
      fileSha256: digest,
      validFrom: validFrom,
      validUntil: validUntil,
    );
  }

  Future<void> sendPartnerContract({
    required String shopId,
    required String contractId,
  }) {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Sign in required');
    }
    return _repository.sendPartnerContract(
      shopId: shopId,
      contractId: contractId,
      adminUid: uid,
    );
  }

  Future<void> voidPartnerContract({
    required String shopId,
    required String contractId,
    String reason = '',
  }) {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Sign in required');
    }
    return _repository.voidPartnerContract(
      shopId: shopId,
      contractId: contractId,
      adminUid: uid,
      reason: reason,
    );
  }

  Future<void> markPartnerContractViewed({
    required String shopId,
    required String contractId,
  }) {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Sign in required');
    }
    return _repository.markPartnerContractViewed(
      shopId: shopId,
      contractId: contractId,
      partnerUid: uid,
    );
  }

  Future<void> requestPartnerContractRevision({
    required String shopId,
    required String contractId,
    required String memo,
  }) {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Sign in required');
    }
    return _repository.requestPartnerContractRevision(
      shopId: shopId,
      contractId: contractId,
      partnerUid: uid,
      memo: memo,
    );
  }

  /// Re-download PDF, verify SHA-256, then sign. Throws [StateError] on mismatch.
  Future<void> signPartnerContractVerified({
    required String shopId,
    required String contractId,
    required String signerName,
    required String signaturePngBase64,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Sign in required');
    }
    final doc = await _repository.getPartnerContract(
      shopId: shopId,
      contractId: contractId,
    );
    if (doc == null) {
      throw StateError('Contract not found');
    }
    final bytes = await _repository.fetchPartnerContractFileBytes(doc.fileUrl);
    final liveSha = sha256.convert(bytes).toString();
    if (liveSha != doc.fileSha256) {
      throw StateError('file_sha256_mismatch');
    }
    await _repository.signPartnerContract(
      shopId: shopId,
      contractId: contractId,
      partnerUid: uid,
      signerName: signerName,
      signaturePngBase64: signaturePngBase64,
      expectedSha256: liveSha,
    );
  }

  Future<List<int>> fetchPartnerContractFileBytes(String fileUrl) {
    return _repository.fetchPartnerContractFileBytes(fileUrl);
  }

  Future<String> partnerContractReadableUrl(String fileUrl) {
    return _photos.readableUrl(fileUrl);
  }

  int partnerContractAwaitingCount(List<PartnerContract> docs) {
    return docs
        .where((d) => d.status == PartnerContractStatus.awaitingSignature)
        .length;
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

  /// TODO(a1-desk-save-timing): temporary write/read probe — remove after latency check.
  Future<ShopProfileSaveProbe> saveShopProfile({
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
    } else if (coverBytes != null && coverBytes.isNotEmpty) {
      _coverBytes[shopId] = coverBytes;
    } else if (removeCover) {
      _coverBytes.remove(shopId);
      _galleryBytes.remove(shopId);
    }
    final writeSw = Stopwatch()..start();
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
      mapUrl: mapUrl,
      nearestHub: nearestHub,
      accessRoutes: accessRoutes,
      featureBlurb: featureBlurb,
      featureTags: featureTags,
      nearbySpots: nearbySpots,
      localContact: localContact,
      checkIn: checkIn,
      checkOut: checkOut,
      businessHours: businessHours,
      country: country,
      continent: continent,
      curated: curated,
      coverBytes: coverBytes,
      coverFileName: coverFileName,
      coverContentType: coverContentType,
      removeCover: removeCover,
      gallery: gallery,
    );
    writeSw.stop();
    _patchLocalShopProfile(
      shopId: shopId,
      name: name,
      location: location,
      productName: productName,
      consumerPrice: consumerPrice,
      professionalPrice: professionalPrice,
      intro: intro,
      address: address,
      amenities: amenities,
      mapUrl: mapUrl,
      nearestHub: nearestHub,
      accessRoutes: accessRoutes,
      featureBlurb: featureBlurb,
      featureTags: featureTags,
      nearbySpots: nearbySpots,
      localContact: localContact,
      checkIn: checkIn,
      checkOut: checkOut,
      businessHours: businessHours,
      country: country,
      continent: continent,
      curated: curated,
      removeCover: removeCover,
      gallery: gallery,
    );
    notifyListeners();
    // Do not block the save UX on the follow-up read.
    final readFuture = () async {
      final readSw = Stopwatch()..start();
      try {
        await refreshShopStat(shopId);
      } catch (error, stackTrace) {
        debugPrint('saveShopProfile background refresh failed: $error');
        debugPrint('$stackTrace');
      }
      return readSw.elapsed;
    }();
    return ShopProfileSaveProbe(
      write: writeSw.elapsed,
      readFuture: readFuture,
    );
  }

  void _patchLocalShopProfile({
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
    bool removeCover = false,
    List<ShopGallerySlot>? gallery,
  }) {
    final id = shopId.trim();
    if (id.isEmpty) {
      return;
    }
    final index = _shopStats.indexWhere((item) => item.shopId == id);
    final previous = index >= 0 ? _shopStats[index] : null;
    final catalog = DiveShopCatalog.byId(id);
    List<String>? nextGallery;
    String? nextCover;
    var clearCover = false;
    if (gallery != null) {
      final hasNewBytes = gallery.any((slot) => slot.hasBytes);
      if (!hasNewBytes) {
        nextGallery = [
          for (final slot in gallery)
            if ((slot.url ?? '').trim().isNotEmpty) slot.url!.trim(),
        ];
        if (nextGallery.isEmpty) {
          clearCover = true;
        } else {
          nextCover = nextGallery.first;
        }
      }
    } else if (removeCover) {
      nextGallery = const [];
      clearCover = true;
    }
    final patched = (previous ??
            ShopLiveStats(
              shopId: id,
              reviewCount: 0,
              avgSafety: 0,
              avgGuide: 0,
              avgBoat: 0,
              avgOverall: 0,
              diveStar: 0,
              name: catalog?.name,
              location: catalog?.location,
            ))
        .copyWith(
          name: name.trim(),
          location: location.trim(),
          productName: productName.trim(),
          consumerPrice: consumerPrice,
          professionalPrice: professionalPrice,
          intro: intro?.trim(),
          address: address?.trim(),
          amenities: amenities,
          mapUrl: mapUrl?.trim(),
          nearestHub: nearestHub?.trim(),
          accessRoutes: accessRoutes,
          featureBlurb: featureBlurb?.trim(),
          featureTags: featureTags,
          nearbySpots: nearbySpots,
          localContact: localContact?.trim(),
          checkIn: checkIn?.trim(),
          checkOut: checkOut?.trim(),
          businessHours: businessHours?.trim(),
          country: country?.trim() ?? catalog?.country,
          continent: continent?.trim() ?? catalog?.continent,
          curated: curated,
          coverUrl: nextCover,
          clearCoverUrl: clearCover,
          galleryUrls: nextGallery,
        );
    if (index >= 0) {
      final next = [..._shopStats];
      next[index] = patched;
      _shopStats = next;
    } else {
      _shopStats = [..._shopStats, patched];
    }
    _shopStatsLoaded = true;
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

  /// Shop id used for partner UI + saves.
  String get partnerOwnedShopId =>
      stats.ownedShopId ?? AppConstants.defaultPartnerShopId;

  Future<ShopProductSaveResult> saveShopProduct({
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
    // everyone else needs admin.
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

    final previous = _findShopProduct(shopId, product.id);
    final gated = _withSaveIntent(
      product: product,
      previous: previous,
      pendingGallery: gallery,
      creatorSubmission: creatorSubmission,
      creatorUid: creatorUid,
      intent: intent,
      publishAsPartner: isOwnerPartner,
    );

    await _repository.saveShopProduct(
      shopId: shopId,
      product: gated.product,
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
      _productFrames['$shopId--${gated.product.id}'] = frames;
      Uint8List? first;
      for (final frame in frames) {
        if (frame != null && frame.isNotEmpty) {
          first = frame;
          break;
        }
      }
      if (first != null) {
        _coverBytes['$shopId--${gated.product.id}'] = first;
        if (useAsResortCover) {
          _coverBytes[shopId] = first;
        }
      }
    } else if (photoBytes != null && photoBytes.isNotEmpty) {
      _coverBytes['$shopId--${gated.product.id}'] = photoBytes;
      if (useAsResortCover) {
        _coverBytes[shopId] = photoBytes;
      }
    }
    // Show the saved product in partner lists immediately, then confirm via fetch.
    _upsertLocalShopProduct(shopId, gated.product);
    final refreshed = await refreshShopStat(shopId);
    if (!refreshed) {
      throw StateError('SHOP_STAT_REFRESH_FAILED');
    }
    // Stale fetch can omit the row we just wrote — keep the gated product.
    _upsertLocalShopProduct(shopId, gated.product);
    return ShopProductSaveResult(
      stagedPriceOrNewOptions: gated.stagedPriceOrNewOptions,
    );
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

  ShopProduct? _findShopProduct(String shopId, String productId) {
    final sid = shopId.trim();
    final pid = productId.trim();
    if (sid.isEmpty || pid.isEmpty) {
      return null;
    }
    for (final stats in _shopStats) {
      if (stats.shopId != sid) {
        continue;
      }
      for (final item in stats.products) {
        if (item.id == pid) {
          return item;
        }
      }
    }
    return null;
  }

  ShopProduct _pendingAfterSave({
    required ShopProduct product,
    required ShopProduct? previous,
    required String submitter,
    List<ShopGallerySlot>? pendingGallery,
  }) {
    if (previous?.publishStatus == ProductPublishStatus.rejected) {
      return ProductPublishGuard.applyResubmit(
        previous: previous!,
        next: product.copyWith(submittedByUid: submitter),
        resubmitNote: product.resubmitNote,
        pendingGallery: pendingGallery,
      );
    }
    return product.copyWith(
      publishStatus: ProductPublishStatus.pending,
      submittedAt: DateTime.now(),
      active: false,
      submittedByUid: submitter,
    );
  }

  /// Affiliate-partner go-live: ignore legacy price_revision / pending_options.
  ShopProduct _partnerGoLive(ShopProduct product, String submitter) {
    return product.copyWith(
      publishStatus: ProductPublishStatus.approved,
      active: true,
      submittedAt: product.submittedAt ?? DateTime.now(),
      submittedByUid: submitter.isNotEmpty ? submitter : product.submittedByUid,
      // Do not apply staged revision; drop the field so it cannot resurface.
      priceRevision: null,
    );
  }

  _GatedShopProduct _withSaveIntent({
    required ShopProduct product,
    ShopProduct? previous,
    List<ShopGallerySlot>? pendingGallery,
    required bool creatorSubmission,
    required String creatorUid,
    required ProductSaveIntent? intent,
    bool publishAsPartner = false,
  }) {
    final submitter = creatorUid.isNotEmpty
        ? creatorUid
        : product.submittedByUid;

    // Creators still wait in the admin queue (unchanged).
    if (creatorSubmission) {
      return _GatedShopProduct(
        _pendingAfterSave(
          product: product,
          previous: previous,
          submitter: submitter,
          pendingGallery: pendingGallery,
        ),
        false,
      );
    }

    final adminPublisher = stats.isAdmin && !publishAsPartner;

    if (intent == null) {
      if (!adminPublisher) {
        // Partner save without intent → immediate listing (H1a).
        return _GatedShopProduct(_partnerGoLive(product, submitter), false);
      }
      ProductPublishGuard.ensureCanApprove(product);
      return _GatedShopProduct(
        product.copyWith(
          publishStatus: ProductPublishStatus.approved,
          active: true,
          reviewedAt: DateTime.now(),
          reviewNote: '',
          rejectedContentHash: '',
          rejectedReasonTags: const [],
          rejectedSectionHashes: const {},
          resubmitCount: 0,
          resubmitNote: '',
          submittedAt: product.submittedAt ?? DateTime.now(),
          priceRevision: null,
        ),
        false,
      );
    }
    switch (intent) {
      case ProductSaveIntent.keepEditing:
        // Temp-save is draft-only. Never demote an approved listing.
        if (previous?.publishStatus == ProductPublishStatus.approved) {
          return _GatedShopProduct(_partnerGoLive(product, submitter), false);
        }
        final prevStatus = previous?.publishStatus;
        final nextStatus = ProductPublishGuard.keepEditingStatus(prevStatus);
        // Creator pending stays pending; partner new/draft stays draft.
        return _GatedShopProduct(
          product.copyWith(
            publishStatus: nextStatus,
            active: false,
            submittedByUid: submitter,
            reviewNote: previous?.reviewNote ?? product.reviewNote,
            rejectedContentHash:
                previous?.rejectedContentHash ?? product.rejectedContentHash,
            rejectedReasonTags:
                previous?.rejectedReasonTags ?? product.rejectedReasonTags,
            rejectedSectionHashes: previous?.rejectedSectionHashes ??
                product.rejectedSectionHashes,
            resubmitCount: previous?.resubmitCount ?? product.resubmitCount,
            resubmitNote: previous?.resubmitNote ?? product.resubmitNote,
            priceRevision: null,
          ),
          false,
        );
      case ProductSaveIntent.submitForReview:
        // Affiliate partner: publish immediately (incl. admin→partner overlay).
        if (!adminPublisher) {
          return _GatedShopProduct(_partnerGoLive(product, submitter), false);
        }
        return _GatedShopProduct(
          _pendingAfterSave(
            product: product,
            previous: previous,
            submitter: submitter,
            pendingGallery: pendingGallery,
          ),
          false,
        );
      case ProductSaveIntent.publish:
        if (!stats.isAdmin) {
          throw StateError('Admin only');
        }
        // Ignore legacy price_revision rather than merging it.
        final next = product.copyWith(priceRevision: null);
        ProductPublishGuard.ensureCanApprove(next);
        return _GatedShopProduct(
          next.copyWith(
            publishStatus: ProductPublishStatus.approved,
            active: true,
            reviewedAt: DateTime.now(),
            reviewNote: '',
            rejectedContentHash: '',
            rejectedReasonTags: const [],
            rejectedSectionHashes: const {},
            resubmitCount: 0,
            resubmitNote: '',
            submittedAt: next.submittedAt ?? DateTime.now(),
            priceRevision: null,
          ),
          false,
        );
      case ProductSaveIntent.takeDown:
        return _GatedShopProduct(
          product.copyWith(active: false, priceRevision: null),
          false,
        );
      case ProductSaveIntent.preserveListing:
        return _GatedShopProduct(product, false);
    }
  }

  Future<void> approvePriceRevision({
    required String shopId,
    required String productId,
    required String expectedFreshness,
  }) async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    final previous = _findShopProduct(shopId, productId);
    if (previous == null) {
      throw StateError('Product not found');
    }
    PriceRevisionGuard.ensureFreshPending(
      revision: previous.priceRevision,
      expectedFreshness: expectedFreshness,
    );
    final live = applyPriceRevisionToLive(previous);
    ProductPublishGuard.ensureCanApprove(live);
    await saveShopProduct(
      shopId: shopId,
      product: live,
      intent: ProductSaveIntent.publish,
    );
  }

  Future<void> rejectPriceRevision({
    required String shopId,
    required String productId,
    required String expectedFreshness,
    String reviewNote = '',
  }) async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    final previous = _findShopProduct(shopId, productId);
    if (previous == null) {
      throw StateError('Product not found');
    }
    PriceRevisionGuard.ensureFreshPending(
      revision: previous.priceRevision,
      expectedFreshness: expectedFreshness,
    );
    final revision = previous.priceRevision!.copyWith(
      status: PriceRevisionStatus.rejected,
      reviewNote: reviewNote.trim(),
    );
    await saveShopProduct(
      shopId: shopId,
      product: previous.copyWith(priceRevision: revision),
      intent: ProductSaveIntent.preserveListing,
    );
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
    final next = SameBoatSeatOpenLogic.applyAdminStatus(current, status);
    // Show the new row before the write. A failed write puts the old row back.
    _upsertLocalShopProduct(shopId, next);
    try {
      await saveShopProduct(
        shopId: shopId,
        product: next,
        intent: ProductSaveIntent.preserveListing,
      );
    } catch (error) {
      // Refresh can fail after the write landed. Keep the open row then.
      if (error is StateError && error.message == 'SHOP_STAT_REFRESH_FAILED') {
        _upsertLocalShopProduct(shopId, next);
      } else {
        _upsertLocalShopProduct(shopId, current);
      }
      rethrow;
    }
    if (status == SameBoatStatus.approved) {
      unawaited(_recordSeatOpens(next));
    }
  }

  Future<void> deleteShopProduct({
    required String shopId,
    required String productId,
  }) async {
    final effective = stats;
    final owned = effective.ownedShopId;
    final isOwnerPartner =
        effective.isBusiness && owned != null && owned == shopId;
    if (!_stats.isAdmin && !isOwnerPartner) {
      throw StateError('Not allowed to delete this shop product');
    }
    await _repository.deleteShopProduct(shopId: shopId, productId: productId);
    await refreshShopStat(shopId);
  }

  /// Partner close / reopen. Reloads latest so seat fields are not stale-overwritten.
  Future<void> setPartnerProductActive({
    required String shopId,
    required String productId,
    required bool active,
  }) async {
    final effective = stats;
    final owned = effective.ownedShopId;
    final isOwnerPartner =
        effective.isBusiness && owned != null && owned == shopId;
    if (!_stats.isAdmin && !isOwnerPartner) {
      throw StateError('Not allowed to edit this shop product');
    }
    final latest = await _requireFreshShopProduct(shopId, productId);
    await saveShopProduct(
      shopId: shopId,
      product: latest.copyWith(active: active),
      intent: ProductSaveIntent.preserveListing,
    );
  }

  /// Discard an option/individual line. Reloads latest; seat commitment → close.
  ///
  /// Returns `closed` when bookable was cleared instead of deleting.
  Future<PartnerOptionDiscardResult> discardPartnerOption({
    required String shopId,
    required String productId,
    required String optionId,
    DateTime? now,
  }) async {
    final effective = stats;
    final owned = effective.ownedShopId;
    final isOwnerPartner =
        effective.isBusiness && owned != null && owned == shopId;
    if (!_stats.isAdmin && !isOwnerPartner) {
      throw StateError('Not allowed to edit this shop product');
    }
    final latest = await _requireFreshShopProduct(shopId, productId);
    ShopProductOption? target;
    for (final option in latest.options) {
      if (option.id == optionId) {
        target = option;
        break;
      }
    }
    if (target == null) {
      throw StateError('Option not found');
    }
    final clock = now ?? DateTime.now();
    if (optionHasSeatCommitment(target, now: clock)) {
      final nextOptions = [
        for (final option in latest.options)
          if (option.id == optionId)
            option.copyWith(bookable: false)
          else
            option,
      ];
      await saveShopProduct(
        shopId: shopId,
        product: latest.copyWith(options: nextOptions),
        intent: ProductSaveIntent.preserveListing,
      );
      return PartnerOptionDiscardResult.closed;
    }
    final nextOptions = [
      for (final option in latest.options)
        if (option.id != optionId && option.parentOptionId != optionId) option,
    ];
    await saveShopProduct(
      shopId: shopId,
      product: latest.copyWith(options: nextOptions),
      intent: ProductSaveIntent.preserveListing,
    );
    return PartnerOptionDiscardResult.deleted;
  }

  /// Reloads one shop then returns the product (partner close / seats open).
  Future<ShopProduct> requireFreshShopProduct({
    required String shopId,
    required String productId,
  }) =>
      _requireFreshShopProduct(shopId, productId);

  Future<ShopProduct> _requireFreshShopProduct(
    String shopId,
    String productId,
  ) async {
    final refreshed = await refreshShopStat(shopId);
    if (!refreshed) {
      throw StateError('SHOP_STAT_REFRESH_FAILED');
    }
    final latest = _findShopProduct(shopId, productId);
    if (latest == null) {
      throw StateError('Product not found');
    }
    return latest;
  }

  /// TODO(a1-desk-save-timing): probe — remove after approve latency check.
  Future<ShopProfileSaveProbe> approveShopProduct({
    required String shopId,
    required String productId,
  }) async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    final previous = _findShopProduct(shopId, productId);
    final writeSw = Stopwatch()..start();
    await _repository.setShopProductPublishStatus(
      shopId: shopId,
      productId: productId,
      status: ProductPublishStatus.approved,
    );
    writeSw.stop();
    if (previous != null) {
      _upsertLocalShopProduct(
        shopId,
        ProductPublishGuard.applyStatusChange(
          product: previous,
          status: ProductPublishStatus.approved,
        ),
      );
    }
    final readFuture = () async {
      final readSw = Stopwatch()..start();
      await refreshShopStat(shopId);
      readSw.stop();
      return readSw.elapsed;
    }();
    return ShopProfileSaveProbe(
      write: writeSw.elapsed,
      readFuture: readFuture,
    );
  }

  /// TODO(a1-desk-save-timing): probe — remove after reject latency check.
  Future<ShopProfileSaveProbe> rejectShopProduct({
    required String shopId,
    required String productId,
    String reviewNote = '',
    List<String> reasonTags = const [],
  }) async {
    if (!_stats.isAdmin) {
      throw StateError('Admin only');
    }
    final previous = _findShopProduct(shopId, productId);
    final writeSw = Stopwatch()..start();
    await _repository.setShopProductPublishStatus(
      shopId: shopId,
      productId: productId,
      status: ProductPublishStatus.rejected,
      reviewNote: reviewNote,
      reasonTags: reasonTags,
    );
    writeSw.stop();
    if (previous != null) {
      _upsertLocalShopProduct(
        shopId,
        ProductPublishGuard.applyStatusChange(
          product: previous,
          status: ProductPublishStatus.rejected,
          reviewNote: reviewNote,
          reasonTags: reasonTags,
        ),
      );
    }
    final readFuture = () async {
      final readSw = Stopwatch()..start();
      await refreshShopStat(shopId);
      readSw.stop();
      return readSw.elapsed;
    }();
    return ShopProfileSaveProbe(
      write: writeSw.elapsed,
      readFuture: readFuture,
    );
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

  Future<void> cancelBookingAsGuest(String bookingId) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    TourBooking? booking;
    for (final item in _bookings) {
      if (item.id == bookingId) {
        booking = item;
        break;
      }
    }
    await _repository.cancelBookingAsGuest(uid: uid, bookingId: bookingId);
    if (booking != null && booking.fromFlag && booking.productId.isNotEmpty) {
      unawaited(_recordSeatBookingCancel(booking));
    }
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

  /// Partner voucher 「확인했어요」 — shop doc read receipt only.
  Future<void> ackPartnerBooking({
    required String shopId,
    required String bookingId,
  }) {
    return _repository.ackPartnerBooking(
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

  /// Call sites: [refreshShopStats], [refreshShopStat].
  ///
  /// Resolves readable cover/gallery URLs, then **merges URLs only** into the
  /// current [_shopStats] via [mergeHydratedShopCovers] so seat / same-boat /
  /// active fields are never rolled back by a stale hydrate snapshot.
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
      _shopStats = mergeHydratedShopCovers(
        current: _shopStats,
        hydratedCovers: hydrated,
      );
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

  Future<void> ensureShopStatsLoaded() {
    final inflight = _shopStatsRefresh;
    if (inflight != null) {
      return inflight;
    }
    final fetchedAt = _shopStatsFetchedAt;
    if (_shopStatsLoaded &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < shopStatsCacheTtl) {
      return Future<void>.value();
    }
    return refreshShopStats();
  }

  /// Test helper: pretend the last shop-stats fetch happened [ago] ago.
  @visibleForTesting
  void debugBackdateShopStatsFetch(Duration ago) {
    _shopStatsFetchedAt = DateTime.now().subtract(ago);
    _shopStatsLoaded = true;
  }

  Future<void> refreshShopStats() {
    final inflight = _shopStatsRefresh;
    if (inflight != null) {
      return inflight;
    }
    final run = _refreshShopStatsBody();
    _shopStatsRefresh = run;
    return run;
  }

  Future<void> _refreshShopStatsBody() async {
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
      _shopStatsRefresh = null;
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

  Future<void> ensureAdminInboxLoaded() {
    if (!_stats.isAdmin) {
      return Future<void>.value();
    }
    final inflight = _adminInboxRefresh;
    if (inflight != null) {
      if (_adminInboxStale) {
        return refreshAdminInbox();
      }
      return inflight;
    }
    if (_adminInboxLoaded) {
      return Future<void>.value();
    }
    return refreshAdminInbox();
  }

  Future<void> refreshAdminInbox() {
    if (!_stats.isAdmin) {
      return Future<void>.value();
    }
    final inflight = _adminInboxRefresh;
    if (inflight != null) {
      _adminInboxStale = true;
      return _adminInboxNext ??= inflight.then((_) {
        _adminInboxNext = null;
        return refreshAdminInbox();
      });
    }
    final run = _refreshAdminInboxBody();
    _adminInboxRefresh = run;
    return run;
  }

  Future<void> _refreshAdminInboxBody() async {
    _adminInboxStale = false;
    try {
      final pending = await _repository.fetchPendingInstructors();
      final members = await _repository.fetchMembers();
      if (_adminInboxStale || _closed) {
        return;
      }
      _pendingInstructors = pending;
      _members = members;
      _adminInboxLoaded = true;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('관리자 인박스 로드 실패: $error');
      debugPrint('$stackTrace');
    } finally {
      _adminInboxRefresh = null;
    }
  }

  /// Range read for the admin overview. Does not fill the bookings menu cache.
  Future<List<TourBooking>> fetchShopBookingsCreatedBetween({
    required String shopId,
    required DateTime start,
    required DateTime end,
  }) {
    return _repository.fetchShopBookingsCreatedBetween(
      shopId: shopId,
      start: start,
      end: end,
    );
  }

  Future<List<TourBooking>> fetchShopBookingsCancelledBetween({
    required String shopId,
    required DateTime start,
    required DateTime end,
  }) {
    return _repository.fetchShopBookingsCancelledBetween(
      shopId: shopId,
      start: start,
      end: end,
    );
  }

  /// Shop bookings with [createdAt] in `[start, end)`, cached when a wider
  /// span for that shop is already loaded. Does not fill the bookings menu.
  Future<List<TourBooking>> loadAdminAnalyticsBookings({
    required DateTime start,
    required DateTime end,
  }) async {
    await ensureShopStatsLoaded();
    final byId = <String, TourBooking>{};
    for (final stats in _shopStats) {
      final id = stats.shopId;
      final spans = _analyticsCache[id];
      _AnalyticsCacheSpan? hit;
      if (spans != null) {
        for (final span in spans) {
          if (span.covers(start, end)) {
            hit = span;
            break;
          }
        }
      }
      final List<TourBooking> rows;
      if (hit != null) {
        rows = [
          for (final booking in hit.bookings)
            if (!booking.createdAt.isBefore(start) &&
                booking.createdAt.isBefore(end))
              booking,
        ];
      } else {
        rows = await fetchShopBookingsCreatedBetween(
          shopId: id,
          start: start,
          end: end,
        );
        _analyticsCache.putIfAbsent(id, () => []).add(
          _AnalyticsCacheSpan(start, end, rows),
        );
      }
      for (final booking in rows) {
        byId['$id|${booking.id}'] = booking;
      }
    }
    return byId.values.toList();
  }

  /// Newest shop bookings. One listener per shop until a combined feed exists.
  Stream<List<TourBooking>> watchLatestShopBookings(
    String shopId, {
    int limit = 5,
  }) {
    return _repository.watchLatestShopBookings(shopId, limit: limit);
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
      _seatAlerts = const [];
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
      // Catalog only. users, bookings, and logs stay unsubscribed until sign-in.
      unawaited(refreshShopStats());
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
            _seatAlerts = snapshot.seatAlerts;
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

  /// One view per seat per 30 seconds, or when the detail screen leaves.
  void watchSeatView({
    required String shopId,
    required String productId,
    required String optionId,
    required String region,
    required String resort,
    required DateTime? departure,
    required int price,
  }) {
    final uid = _uid;
    if (uid == null || uid.isEmpty || productId.isEmpty) {
      return;
    }
    final consented = _stats.nationalityConsentAt != null;
    _seatViews.watch(
      SeatLifeEvent(
        id: 'pending',
        kind: 'view',
        seatId: seatLifeId(productId, optionId),
        shopId: shopId.split('--').first,
        productId: productId,
        optionId: optionId,
        region: region,
        resort: resort,
        departure: departure == null ? '' : seatDayId(departure),
        price: price,
        memberGrade: _stats.memberGrade.firestoreValue,
        nationality: consented ? _stats.nationality : '',
        shareNationality: consented,
        userKey: seatUserKey(uid),
        at: DateTime.now(),
      ),
      DateTime.now(),
    );
    _armSeatViewTimer();
  }

  void flushSeatViews({bool leaving = false}) {
    final due = _seatViews.poll(DateTime.now(), leaving: leaving);
    for (final event in due) {
      unawaited(_commitSeat(event));
    }
    if (leaving && _seatViews.isEmpty) {
      _seatViewTimer?.cancel();
      _seatViewTimer = null;
    }
  }

  /// Expired holds and passed departures. Running twice writes the same line.
  Future<void> sweepSeatLives() async {
    final actor = _uid;
    if (!_stats.isAdmin || actor == null || actor.isEmpty) {
      return;
    }
    try {
      final now = DateTime.now();
      final existing = await _repository.listSeatEvents();
      final ids = {for (final event in existing) event.id};
      final bySeat = <String, List<SeatLifeEvent>>{};
      for (final event in existing) {
        bySeat.putIfAbsent(event.seatId, () => []).add(event);
      }
      final seats = _seatLifeSeats(now);
      final fresh = seatSweepEvents(
        seats: seats,
        now: now,
        existingIds: ids,
        actorUid: actor,
      );
      for (final event in fresh) {
        await _commitSeat(event);
        bySeat.putIfAbsent(event.seatId, () => []).add(event);
      }
      for (final seat in seats) {
        await _repository.saveSeatOutcome(
          summarizeSeat(seat: seat, events: bySeat[seat.seatId] ?? const []),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('seat life sweep failed $error');
      debugPrint('$stackTrace');
    }
  }

  void _armSeatViewTimer() {
    if (_seatViewTimer != null || !seatViewTimersLive) {
      return;
    }
    _seatViewTimer = Timer.periodic(seatViewFlushInterval, (_) {
      flushSeatViews();
    });
  }

  Future<void> _recordSeatOpens(ShopProduct product) async {
    final now = DateTime.now();
    if (product.listsOnSameBoat) {
      await _commitSeat(_openEvent(product, '', now));
    }
    for (final option in product.options) {
      if (option.listsOnSameBoat) {
        await _commitSeat(_openEvent(product, option.id, now));
      }
    }
  }

  SeatLifeEvent _openEvent(ShopProduct product, String optionId, DateTime now) {
    final seat = _seatFor(product, optionId);
    return SeatLifeEvent(
      id: openEventId(seat.seatId),
      kind: 'open',
      seatId: seat.seatId,
      shopId: seat.shopId,
      productId: seat.productId,
      optionId: seat.optionId,
      region: seat.region,
      resort: seat.resort,
      departure: seat.departureDay,
      price: seat.price,
      memberGrade: _stats.memberGrade.firestoreValue,
      userKey: seatUserKey(_uid ?? ''),
      at: now,
    );
  }

  Future<void> _recordSeatFlag({
    required String shopId,
    required String productId,
    required String optionId,
    required int partySize,
    required int price,
    required DateTime at,
  }) async {
    final product = _productById(productId);
    final until = ShopProduct.personalFlagUntil(
      at,
      _flagClosesAt(product, optionId),
    );
    final seat = _seatFor(
      product,
      optionId,
      shopId: shopId,
      productId: productId,
    );
    await _commitSeat(
      SeatLifeEvent(
        id: flagEventId(seatUserKey(_uid ?? ''), seat.seatId, until),
        kind: 'flag',
        seatId: seat.seatId,
        shopId: seat.shopId,
        productId: productId,
        optionId: optionId,
        region: seat.region,
        resort: seat.resort,
        departure: seat.departureDay,
        price: price,
        partySize: partySize,
        memberGrade: _stats.memberGrade.firestoreValue,
        nationality: _consentedNationality,
        shareNationality: _stats.nationalityConsentAt != null,
        userKey: seatUserKey(_uid ?? ''),
        at: at,
      ),
    );
  }

  Future<void> _recordSeatPay({
    required String shopId,
    required String productId,
    required String optionId,
    required int price,
    required int partySize,
    required DateTime? tourDate,
  }) async {
    final now = DateTime.now();
    final product = _productById(productId);
    final seat = _seatFor(
      product,
      optionId,
      shopId: shopId,
      productId: productId,
    );
    await _commitSeat(
      SeatLifeEvent(
        id: payEventId(
          seatUserKey(_uid ?? ''),
          seat.seatId,
          tourDate,
          price,
          partySize,
        ),
        kind: 'pay',
        seatId: seat.seatId,
        shopId: seat.shopId,
        productId: productId,
        optionId: optionId,
        region: seat.region,
        resort: seat.resort,
        departure: tourDate == null ? seat.departureDay : seatDayId(tourDate),
        price: price,
        partySize: partySize,
        memberGrade: _stats.memberGrade.firestoreValue,
        nationality: _consentedNationality,
        shareNationality: _stats.nationalityConsentAt != null,
        userKey: seatUserKey(_uid ?? ''),
        at: now,
      ),
    );
  }

  Future<void> _recordSeatCancel({
    required String shopId,
    required String productId,
    required String optionId,
    required DateTime at,
  }) async {
    final product = _productById(productId);
    final seat = _seatFor(
      product,
      optionId,
      shopId: shopId,
      productId: productId,
    );
    await _commitSeat(
      SeatLifeEvent(
        id: unflagEventId(seatUserKey(_uid ?? ''), seat.seatId, at),
        kind: 'cancel',
        seatId: seat.seatId,
        shopId: seat.shopId,
        productId: productId,
        optionId: optionId,
        region: seat.region,
        resort: seat.resort,
        departure: seat.departureDay,
        memberGrade: _stats.memberGrade.firestoreValue,
        userKey: seatUserKey(_uid ?? ''),
        at: at,
      ),
    );
  }

  Future<void> _recordSeatBookingCancel(TourBooking booking) async {
    final now = DateTime.now();
    final optionId = booking.seatOptionId.isNotEmpty
        ? booking.seatOptionId
        : booking.optionId;
    final product = _productById(booking.productId);
    final seat = _seatFor(
      product,
      optionId,
      shopId: booking.shopId,
      productId: booking.productId,
    );
    await _commitSeat(
      SeatLifeEvent(
        id: cancelEventId(booking.id),
        kind: 'cancel',
        seatId: seat.seatId,
        shopId: seat.shopId,
        productId: booking.productId,
        optionId: optionId,
        region: seat.region,
        resort: seat.resort,
        departure: booking.tourDate == null
            ? seat.departureDay
            : seatDayId(booking.tourDate!),
        price: booking.price,
        partySize: booking.partySize,
        memberGrade: _stats.memberGrade.firestoreValue,
        userKey: seatUserKey(_uid ?? ''),
        at: now,
      ),
    );
  }

  Future<void> _commitSeat(SeatLifeEvent event) async {
    try {
      if (!event.withinShape) {
        return;
      }
      final created = await _repository.createSeatEvent(event);
      if (!created) {
        return;
      }
      final field = seatDayField(event.kind);
      if (field == null) {
        return;
      }
      await _repository.bumpSeatDay(dayId: seatDayId(event.at), field: field);
    } catch (error, stackTrace) {
      debugPrint('seat life record failed $error');
      debugPrint('$stackTrace');
    }
  }

  String get _consentedNationality =>
      _stats.nationalityConsentAt == null ? '' : _stats.nationality;

  ShopProduct? _productById(String productId) {
    for (final product in allShopProducts) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  DateTime? _flagClosesAt(ShopProduct? product, String optionId) {
    if (product == null) {
      return null;
    }
    if (optionId.isEmpty) {
      return product.flagClosesAt;
    }
    for (final option in product.options) {
      if (option.id == optionId) {
        return option.flagClosesAt ?? product.flagClosesAt;
      }
    }
    return product.flagClosesAt;
  }

  SeatLifeSeat _seatFor(
    ShopProduct? product,
    String optionId, {
    String shopId = '',
    String productId = '',
  }) {
    final resolvedShop = product?.shopId ?? shopId;
    final hull = resolvedShop.split('--').first;
    ShopProductOption? option;
    if (product != null && optionId.isNotEmpty) {
      for (final item in product.options) {
        if (item.id == optionId) {
          option = item;
          break;
        }
      }
    }
    final optionPrice = option?.consumerPrice ?? 0;
    final price = optionPrice > 0
        ? optionPrice
        : (product?.consumerPrice ?? 0);
    return SeatLifeSeat(
      productId: product?.id ?? productId,
      optionId: optionId,
      shopId: hull,
      region: _regionForShop(hull),
      resort: _resortForShop(hull),
      departure: option?.departureStart ?? product?.departureStart,
      price: price,
      capacity: option?.capacity ?? product?.capacity ?? 0,
      booked: option?.bookedSeats ?? product?.bookedSeats ?? 0,
      holds: [
        for (final hold in option?.flagHolds ?? product?.flagHolds ?? const <SeatHold>[])
          SeatLifeHold(
            uid: hold.uid,
            seats: hold.seats,
            expiresAt: hold.expiresAt,
            lockedPrice: hold.lockedPrice,
          ),
      ],
    );
  }

  List<SeatLifeSeat> _seatLifeSeats(DateTime now) {
    final seats = <SeatLifeSeat>[];
    final seen = <String>{};
    for (final product in allShopProducts) {
      void add(String optionId, {required bool live, required List<SeatHold> holds, DateTime? departure}) {
        final departed = departure != null && seatDeparturePassed(departure, now);
        if (!live && holds.isEmpty && !departed) {
          return;
        }
        final seat = _seatFor(product, optionId);
        if (seen.add(seat.seatId)) {
          seats.add(seat);
        }
      }

      add(
        '',
        live: product.listsOnSameBoat,
        holds: product.flagHolds,
        departure: product.departureStart,
      );
      for (final option in product.options) {
        add(
          option.id,
          live: option.listsOnSameBoat,
          holds: option.flagHolds,
          departure: option.departureStart ?? product.departureStart,
        );
      }
    }
    return seats;
  }

  String _regionForShop(String hullId) {
    for (final shop in shops) {
      if (shop.hullId == hullId) {
        return shop.country;
      }
    }
    return '';
  }

  String _resortForShop(String hullId) {
    for (final shop in shops) {
      if (shop.hullId == hullId) {
        return shop.name;
      }
    }
    return '';
  }

  @override
  void dispose() {
    _closed = true;
    _loadingTimeout?.cancel();
    _seatViewTimer?.cancel();
    _authSubscription?.cancel();
    _diverSubscription?.cancel();
    _bookingSubscription?.cancel();
    _shopBookingSubscription?.cancel();
    _discountSubscription?.cancel();
    super.dispose();
  }
}

bool get seatViewTimersLive {
  final name = WidgetsBinding.instance.runtimeType.toString();
  return !name.contains('Test');
}

class _AnalyticsCacheSpan {
  _AnalyticsCacheSpan(this.start, this.end, this.bookings);

  final DateTime start;
  final DateTime end;
  final List<TourBooking> bookings;

  bool covers(DateTime from, DateTime to) =>
      !from.isBefore(start) && !to.isAfter(end);
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

/// TODO(a1-desk-save-timing): temporary probe result — remove after latency check.
class ShopProfileSaveProbe {
  const ShopProfileSaveProbe({
    required this.write,
    required this.readFuture,
  });

  final Duration write;
  final Future<Duration> readFuture;
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
