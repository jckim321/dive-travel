import 'dart:async';
import 'dart:typed_data';

import 'package:dive_travel_app/core/constants/app_constants.dart';
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
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

/// 위젯 테스트용 메모리 저장소. 프로덕션은 Firestore를 씁니다.
class MemoryDiverRepository implements DiverRepository {
  MemoryDiverRepository({AppUser? user}) : _user = user {
    _posts = List<CommunityPost>.from(CommunityPostCatalog.seeds);
    _snapshot = DiverSnapshot.empty(
      displayName: user?.displayName ?? '다이버',
      isAdmin: _resolvedAdmin,
      isBusiness: _resolvedBusiness,
      ownedShopId: _ownedShopId ?? AppConstants.defaultPartnerShopId,
    );
    for (final comment in CommunityPostCatalog.seedComments) {
      _comments.putIfAbsent(comment.postId, () => []).add(comment);
    }
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
    repo._seedAdminInbox();
    repo._snapshot = DiverSnapshot.empty(
      displayName: '테스트 다이버',
      isInstructor: isInstructor,
      proStatus: repo._proStatus,
      isAdmin: repo._resolvedAdmin,
      isBusiness: repo._resolvedBusiness,
      ownedShopId: repo._ownedShopId,
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
  final _shopStats = <String, ShopLiveStats>{};
  final _bookings = <TourBooking>[];
  final _pending = <PendingInstructor>[];
  late List<CommunityPost> _posts;
  final _shopBookings = <String, List<TourBooking>>{};
  final _comments = <String, List<CommunityComment>>{};
  int _postSequence = 0;
  int _commentSequence = 0;
  bool _seededPosts = true;

  final _authController = StreamController<AppUser?>.broadcast();
  final _diverController = StreamController<DiverSnapshot>.broadcast();
  final _shopController = StreamController<List<ShopLiveStats>>.broadcast();
  final _bookingController = StreamController<List<TourBooking>>.broadcast();
  final _pendingController =
      StreamController<List<PendingInstructor>>.broadcast();
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
    );
    _diverController.add(_snapshot);
  }

  @override
  Stream<DiverSnapshot> watchDiver(String uid) async* {
    yield _snapshot;
    yield* _diverController.stream;
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
      logs: logs,
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
      logs: logs,
    );
    _diverController.add(_snapshot);
  }

  @override
  Stream<List<ShopLiveStats>> watchShopStats() async* {
    yield _shopStats.values.toList();
    yield* _shopController.stream;
  }

  @override
  Stream<List<TourBooking>> watchBookings(String uid) async* {
    yield List<TourBooking>.from(_bookings);
    yield* _bookingController.stream;
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
    _bookingSequence += 1;
    final booking = TourBooking(
      id: 'booking-$_bookingSequence',
      uid: uid,
      shopId: shopId.split('--').first,
      shopName: shopName,
      productName: productName,
      price: price,
      createdAt: DateTime.now(),
      tourDate: tourDate ?? DateTime.now().add(const Duration(days: 7)),
    );
    _bookings.insert(0, booking);
    _shopBookings.putIfAbsent(booking.shopId, () => []).insert(0, booking);
    _bookingController.add(List<TourBooking>.from(_bookings));
    _shopBookingController.add(
      List<TourBooking>.from(_shopBookings[booking.shopId] ?? const []),
    );
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
    final current = _shopStats[shopId];
    final count = (current?.reviewCount ?? 0) + 1;
    final avgSafety =
        ((current?.avgSafety ?? 0) * (count - 1) + safety) / count;
    final avgGuide = ((current?.avgGuide ?? 0) * (count - 1) + guide) / count;
    final avgBoat = ((current?.avgBoat ?? 0) * (count - 1) + boat) / count;
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
      diveStar: DiveStar.fromAverages(
        safety: avgSafety,
        guide: avgGuide,
        boat: avgBoat,
        reviewCount: count,
      ),
      plaqueStatus: current?.plaqueStatus ?? PlaqueStatus.none,
    );
    if (bookingId != null) {
      final index = _bookings.indexWhere((item) => item.id == bookingId);
      if (index >= 0) {
        final old = _bookings[index];
        _bookings[index] = old.copyWith(reviewed: true);
        _bookingController.add(List<TourBooking>.from(_bookings));
      }
    }
    _shopController.add(_shopStats.values.toList());
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
  Stream<List<PendingInstructor>> watchPendingInstructors() async* {
    yield List<PendingInstructor>.from(_pending);
    yield* _pendingController.stream;
  }

  @override
  Stream<List<CommunityPost>> watchCommunityPosts() async* {
    yield List<CommunityPost>.from(_posts);
    yield* _postsController.stream;
  }

  @override
  Future<void> ensureSeedPosts() async {
    if (_seededPosts) {
      return;
    }
    _posts = List<CommunityPost>.from(CommunityPostCatalog.seeds);
    _seededPosts = true;
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
    Uint8List? coverBytes,
    String? coverFileName,
    String? coverContentType,
    bool removeCover = false,
  }) async {
    final current = _shopStats[shopId];
    final coverUrl = removeCover
        ? ''
        : (coverBytes == null
            ? current?.coverUrl
            : 'memory://shop-cover-$shopId');
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
              productName: productName,
              consumerPrice: consumerPrice,
              professionalPrice: professionalPrice,
              intro: intro ?? current?.intro,
              address: address ?? current?.address,
              coverUrl: coverUrl,
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
  }) async {
    final current = _shopStats[shopId];
    final coverUrl = photoBytes == null
        ? product.coverUrl
        : 'memory://shop-product-$shopId-${product.id}';
    final saved = ShopProduct(
      id: product.id,
      shopId: product.shopId,
      name: product.name,
      consumerPrice: product.consumerPrice,
      professionalPrice: product.professionalPrice,
      active: product.active,
      blurb: product.blurb,
      durationLabel: product.durationLabel,
      coverUrl: coverUrl,
    );
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
      coverBytes: useAsResortCover ? photoBytes : null,
    );
    _shopStats[shopId] = _shopStats[shopId]!.copyWith(
      products: products,
      coverUrl: useAsResortCover
          ? (photoBytes == null ? saved.coverUrl : 'memory://shop-cover-$shopId')
          : _shopStats[shopId]!.coverUrl,
    );
    _shopController.add(_shopStats.values.toList());
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
      paymentStatus: quote.percent > 0 ? 'refunded' : 'captured',
    );
    _bookings[index] = updated;
    _replaceShopBooking(updated);
    _bookingController.add(List<TourBooking>.from(_bookings));
    _shopBookingController.add(
      List<TourBooking>.from(_shopBookings[updated.shopId] ?? const []),
    );
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
        paymentStatus: 'refunded',
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
    _postsController.close();
    _shopBookingController.close();
    _commentController.close();
    _discountController.close();
  }
}
