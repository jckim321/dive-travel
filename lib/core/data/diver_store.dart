import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_repository.dart';
import 'package:dive_travel_app/core/data/diver_snapshot.dart';
import 'package:dive_travel_app/core/data/refund_policy.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/dive_log.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/models/gear_item.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/storage/r2_photo_storage.dart';

class DiverStore extends ChangeNotifier {
  DiverStore(this._repository) {
    _gear = List<GearItem>.from(_defaultGear);
    _authSubscription = _repository.authState().listen((user) {
      _uid = user?.uid;
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
  StreamSubscription<List<ShopLiveStats>>? _shopSubscription;
  StreamSubscription<List<TourBooking>>? _bookingSubscription;
  StreamSubscription<List<PendingInstructor>>? _pendingSubscription;
  StreamSubscription<List<MemberAccount>>? _membersSubscription;
  StreamSubscription<List<CommunityPost>>? _postsSubscription;
  StreamSubscription<List<TourBooking>>? _shopBookingSubscription;
  StreamSubscription<InstructorDiscount>? _discountSubscription;
  Timer? _loadingTimeout;
  String? _uid;

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
  final _salesSubscriptions =
      <String, StreamSubscription<List<TourBooking>>>{};
  late List<GearItem> _gear;
  InstructorDiscount _instructorDiscount = InstructorDiscount.standard;
  bool _loading = true;
  /// PIN unlock for admin console; cleared on sign-out.
  var _adminConsoleUnlocked = false;

  DiverStats get stats => _stats;
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
    return _repository.createBooking(
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
    ShopProduct? current;
    for (final stats in _shopStats) {
      for (final item in stats.products) {
        if (item.id == productId) {
          current = item;
        }
      }
    }
    if (current == null) {
      return SeatFlagPlant.unavailable;
    }
    if (current.memberHasLiveFlag(uid, now, optionId: optionId)) {
      return SeatFlagPlant.alreadyHeld;
    }
    await _repository.plantSeatFlag(
      shopId: shopId.split('--').first,
      productId: productId,
      partySize: partySize,
      now: now,
      optionId: optionId,
      uid: uid,
    );
    return SeatFlagPlant.planted;
  }

  Future<void> submitOperationReview({
    required String shopId,
    required int safety,
    required int guide,
    required int boat,
    String? bookingId,
    String? logId,
    String? comment,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    await _repository.submitOperationReview(
      uid: uid,
      shopId: shopId,
      safety: safety,
      guide: guide,
      boat: boat,
      bookingId: bookingId,
      logId: logId,
      comment: comment,
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
    return _repository.approveInstructor(uid);
  }

  Future<void> setMemberGrade({
    required String uid,
    required MemberGrade grade,
  }) {
    return _repository.setMemberGrade(uid: uid, grade: grade);
  }

  Future<void> rejectInstructor(String uid) {
    return _repository.rejectInstructor(uid);
  }

  Future<void> setPlaqueStatus({
    required String shopId,
    required PlaqueStatus status,
  }) {
    return _repository.setPlaqueStatus(shopId: shopId, status: status);
  }

  Future<void> setPostHidden({required String postId, required bool hidden}) {
    return _repository.setPostHidden(postId: postId, hidden: hidden);
  }

  Future<void> deletePost(String postId) {
    return _repository.deletePost(postId);
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
  }) {
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
    return _repository.saveShopProfile(
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
    // everyone else needs admin.
    final owned = _stats.ownedShopId;
    final isOwnerPartner =
        _stats.isBusiness && owned != null && owned == shopId;
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
      notifyListeners();
    } else if (photoBytes != null && photoBytes.isNotEmpty) {
      _coverBytes['$shopId--${gated.id}'] = photoBytes;
      if (useAsResortCover) {
        _coverBytes[shopId] = photoBytes;
      }
      notifyListeners();
    }
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
      return forcePending
          ? product.copyWith(
              publishStatus: ProductPublishStatus.pending,
              submittedAt: DateTime.now(),
              active: false,
              submittedByUid: submitter,
            )
          : product.copyWith(
              publishStatus: ProductPublishStatus.approved,
              active: true,
              reviewedAt: DateTime.now(),
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
        return product.copyWith(
          publishStatus: ProductPublishStatus.pending,
          submittedAt: DateTime.now(),
          active: false,
          reviewNote: '',
          submittedByUid: submitter,
        );
      case ProductSaveIntent.publish:
        if (!_stats.isAdmin) {
          throw StateError('Admin only');
        }
        return product.copyWith(
          publishStatus: ProductPublishStatus.approved,
          active: true,
          reviewedAt: DateTime.now(),
          reviewNote: '',
          submittedAt: product.submittedAt ?? DateTime.now(),
        );
      case ProductSaveIntent.takeDown:
        return product.copyWith(active: false);
    }
  }

  Future<void> deleteShopProduct({
    required String shopId,
    required String productId,
  }) {
    final owned = _stats.ownedShopId;
    final isOwnerPartner =
        _stats.isBusiness && owned != null && owned == shopId;
    if (!_stats.isAdmin && !isOwnerPartner) {
      return Future.error(
        StateError('Not allowed to delete this shop product'),
      );
    }
    return _repository.deleteShopProduct(shopId: shopId, productId: productId);
  }

  Future<void> approveShopProduct({
    required String shopId,
    required String productId,
  }) {
    if (!_stats.isAdmin) {
      return Future.error(StateError('Admin only'));
    }
    return _repository.setShopProductPublishStatus(
      shopId: shopId,
      productId: productId,
      status: ProductPublishStatus.approved,
    );
  }

  Future<void> rejectShopProduct({
    required String shopId,
    required String productId,
    String reviewNote = '',
  }) {
    if (!_stats.isAdmin) {
      return Future.error(StateError('Admin only'));
    }
    return _repository.setShopProductPublishStatus(
      shopId: shopId,
      productId: productId,
      status: ProductPublishStatus.rejected,
      reviewNote: reviewNote,
    );
  }

  /// Admin-only: place a public product on a home shelf (or clear with exploreOnly).
  Future<void> setProductHomeShelf({
    required String shopId,
    required String productId,
    required ProductListingKind listingKind,
  }) {
    if (!_stats.isAdmin) {
      return Future.error(StateError('Admin only'));
    }
    ShopProduct? current;
    for (final product in productsForShop(shopId)) {
      if (product.id == productId) {
        current = product;
        break;
      }
    }
    if (current == null || !current.isListedPublicly) {
      return Future.error(StateError('Product not public'));
    }
    if (listingKind.isHomeShelf &&
        current.listingKind != listingKind &&
        countOnHomeShelf(listingKind) >= ProductListingKind.homeShelfLimit) {
      return Future.error(StateError('Home shelf full'));
    }
    return _repository.setShopProductListingKind(
      shopId: shopId,
      productId: productId,
      listingKind: listingKind,
    );
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
  }) {
    final uid = _uid;
    if (uid == null) {
      return Future.value();
    }
    return _repository.addCommunityPost(
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
      _shopStats = hydrated;
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

  void _bindDiver(AppUser? user) {
    _diverSubscription?.cancel();
    _shopSubscription?.cancel();
    _bookingSubscription?.cancel();
    _pendingSubscription?.cancel();
    _membersSubscription?.cancel();
    _postsSubscription?.cancel();
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
      _dropSalesWatchers();
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
    _diverSubscription = _repository
        .watchDiver(user.uid)
        .listen(
          (snapshot) {
            _loadingTimeout?.cancel();
            _stats = snapshot.stats;
            _regions = snapshot.regions;
            _logs = snapshot.logs;
            _favoriteShopIds
              ..clear()
              ..addAll(snapshot.favoriteShopIds);
            _loading = false;
            _bindAdminInbox(snapshot.stats.isAdmin);
            _bindPartnerInbox(
              snapshot.stats.isBusiness,
              snapshot.stats.ownedShopId,
            );
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
    _shopSubscription = _repository.watchShopStats().listen(
      (stats) {
        _shopStats = stats;
        _syncSalesWatchers();
        notifyListeners();
        // Public r2.dev may 401 even when uploads succeed — swap covers to
        // signed GETs so Home/Explore keep showing uploaded product photos.
        unawaited(_hydrateShopCovers(stats));
      },
      onError: (Object error) {
        debugPrint('Firestore 샵 통계 구독 실패: $error');
      },
    );
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
    _postsSubscription = _repository.watchCommunityPosts().listen(
      (posts) {
        _posts = posts;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('Firestore 게시글 구독 실패: $error');
      },
    );
  }

  void _bindAdminInbox(bool isAdmin) {
    if (!isAdmin) {
      _pendingSubscription?.cancel();
      _pendingSubscription = null;
      _membersSubscription?.cancel();
      _membersSubscription = null;
      _pendingInstructors = const [];
      _members = const [];
      _dropSalesWatchers();
      return;
    }
    _syncSalesWatchers();
    _pendingSubscription ??= _repository.watchPendingInstructors().listen(
      (pending) {
        _pendingInstructors = pending;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('관리자 강사 대기열 구독 실패: $error');
      },
    );
    _membersSubscription ??= _repository.watchMembers().listen(
      (members) {
        _members = members;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('관리자 회원 목록 구독 실패: $error');
      },
    );
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

  void _syncSalesWatchers() {
    if (!_stats.isAdmin) {
      return;
    }
    final ids = <String>{
      for (final stats in _shopStats)
        if (stats.shopId.isNotEmpty) stats.shopId,
    };
    final stale = [
      for (final id in _salesSubscriptions.keys)
        if (!ids.contains(id)) id,
    ];
    for (final id in stale) {
      _salesSubscriptions.remove(id)?.cancel();
      _salesByShop.remove(id);
    }
    var opened = false;
    for (final id in ids) {
      if (_salesSubscriptions.containsKey(id)) {
        continue;
      }
      opened = true;
      _salesSubscriptions[id] = _repository.watchShopBookings(id).listen(
        (bookings) {
          _salesByShop[id] = bookings;
          _publishSales();
        },
        onError: (Object error) {
          debugPrint('관리자 매출 구독 실패: $error');
        },
      );
    }
    if (stale.isNotEmpty || opened) {
      _publishSales();
    }
  }

  void _publishSales() {
    _salesBookings = [
      for (final list in _salesByShop.values) ...list,
    ];
    notifyListeners();
  }

  void _dropSalesWatchers() {
    for (final sub in _salesSubscriptions.values) {
      sub.cancel();
    }
    _salesSubscriptions.clear();
    _salesByShop.clear();
    if (_salesBookings.isEmpty) {
      return;
    }
    _salesBookings = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    for (final sub in _salesSubscriptions.values) {
      sub.cancel();
    }
    _salesSubscriptions.clear();
    _authSubscription?.cancel();
    _diverSubscription?.cancel();
    _shopSubscription?.cancel();
    _bookingSubscription?.cancel();
    _pendingSubscription?.cancel();
    _membersSubscription?.cancel();
    _postsSubscription?.cancel();
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
