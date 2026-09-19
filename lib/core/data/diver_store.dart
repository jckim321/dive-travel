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
import 'package:dive_travel_app/core/models/dive_log.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/models/gear_item.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

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
  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<DiverSnapshot>? _diverSubscription;
  StreamSubscription<List<ShopLiveStats>>? _shopSubscription;
  StreamSubscription<List<TourBooking>>? _bookingSubscription;
  StreamSubscription<List<PendingInstructor>>? _pendingSubscription;
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
  List<CommunityPost> _posts = const [];
  List<TourBooking> _shopBookings = const [];
  late List<GearItem> _gear;
  InstructorDiscount _instructorDiscount = InstructorDiscount.standard;
  bool _loading = true;

  DiverStats get stats => _stats;
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
  List<CommunityPost> get posts => List.unmodifiable(_posts);
  List<CommunityPost> get visiblePosts => [
    for (final post in _posts)
      if (!post.hidden) post,
  ];
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
      if (booking.isActive) {
        total += booking.price;
      }
    }
    return total;
  }

  int get partnerCommissionThisMonth =>
      RefundPolicy.commissionOn(partnerGrossThisMonth);

  int get partnerNetThisMonth => RefundPolicy.netPayout(partnerGrossThisMonth);

  List<ShopLiveStats> get plaqueQueue => [
    for (final stats in _shopStats)
      if (stats.qualifiesForPlaque || stats.plaqueStatus != PlaqueStatus.none)
        stats,
  ];
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
  final Set<String> _favoriteShopIds = {};

  Uint8List? coverBytesFor(String id) {
    return _coverBytes[id] ?? _coverBytes[id.split('--').first];
  }

  List<DiveShop> lastCallResorts({int limit = 4}) {
    final last = [
      for (final shop in shops)
        if (shop.departure?.lastCall == true ||
            (shop.departure?.emptySeats ?? 99) <= 2)
          shop,
    ];
    last.sort((a, b) {
      final aStart = a.departure?.start ?? DateTime(2099);
      final bStart = b.departure?.start ?? DateTime(2099);
      return aStart.compareTo(bStart);
    });
    return last.take(limit).toList();
  }

  List<DiveShop> rankedResorts({int limit = 3}) {
    return DiveShopCatalog.ranked(shops, limit: limit);
  }

  List<DiveShop> popularResorts({int limit = 4}) {
    final copy = [...shops];
    copy.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return copy.take(limit).toList();
  }

  List<DiveShop> favoriteResorts({int limit = 4}) {
    final saved = [
      for (final shop in shops)
        if (_favoriteShopIds.contains(shop.id)) shop,
    ];
    if (saved.length >= limit) {
      return saved.take(limit).toList();
    }
    final needles = [for (final region in _regions) region.name.toLowerCase()];
    final fromLogs = [
      for (final shop in shops)
        if (!_favoriteShopIds.contains(shop.id) &&
            needles.any((needle) => shop.searchBlob.contains(needle)))
          shop,
    ];
    return [...saved, ...fromLogs].take(limit).toList();
  }

  bool isFavoriteShop(String shopId) => _favoriteShopIds.contains(shopId);

  void toggleFavoriteShop(String shopId) {
    if (_favoriteShopIds.contains(shopId)) {
      _favoriteShopIds.remove(shopId);
    } else {
      _favoriteShopIds.add(shopId);
    }
    notifyListeners();
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

  Future<void> createBooking({
    required DiveShop shop,
    required int price,
    DateTime? tourDate,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    await _repository.createBooking(
      uid: uid,
      shopId: shop.id,
      shopName: shop.name,
      productName: shop.productName,
      price: price,
      tourDate: tourDate,
    );
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
    Uint8List? coverBytes,
    String? coverFileName,
    String? coverContentType,
    bool removeCover = false,
  }) {
    if (coverBytes != null && coverBytes.isNotEmpty) {
      _coverBytes[shopId] = coverBytes;
      notifyListeners();
    } else if (removeCover) {
      _coverBytes.remove(shopId);
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
      coverBytes: coverBytes,
      coverFileName: coverFileName,
      coverContentType: coverContentType,
      removeCover: removeCover,
    );
  }

  Future<void> saveShopProduct({
    required String shopId,
    required ShopProduct product,
    Uint8List? photoBytes,
    String? photoFileName,
    String? photoContentType,
    bool useAsResortCover = false,
  }) {
    if (photoBytes != null && photoBytes.isNotEmpty) {
      _coverBytes['$shopId--${product.id}'] = photoBytes;
      if (useAsResortCover) {
        _coverBytes[shopId] = photoBytes;
      }
      notifyListeners();
    }
    return _repository.saveShopProduct(
      shopId: shopId,
      product: product,
      photoBytes: photoBytes,
      photoFileName: photoFileName,
      photoContentType: photoContentType,
      useAsResortCover: useAsResortCover,
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
    _postsSubscription?.cancel();
    _shopBookingSubscription?.cancel();
    if (user == null) {
      _stats = const DiverStats(
        displayName: '다이버',
        totalLogCount: 0,
        uniqueRegionsCount: 0,
        isInstructor: false,
      );
      _regions = const [];
      _logs = const [];
      _shopStats = const [];
      _bookings = const [];
      _pendingInstructors = const [];
      _posts = const [];
      _shopBookings = const [];
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
        notifyListeners();
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
      _pendingInstructors = const [];
      return;
    }
    if (_pendingSubscription != null) {
      return;
    }
    _pendingSubscription = _repository.watchPendingInstructors().listen(
      (pending) {
        _pendingInstructors = pending;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('관리자 강사 대기열 구독 실패: $error');
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

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    _authSubscription?.cancel();
    _diverSubscription?.cancel();
    _shopSubscription?.cancel();
    _bookingSubscription?.cancel();
    _pendingSubscription?.cancel();
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
