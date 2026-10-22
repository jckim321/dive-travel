import 'dart:typed_data';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_snapshot.dart';
import 'package:dive_travel_app/core/data/operation_review_policy.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/dive_log.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
import 'package:dive_travel_app/core/models/dive_star_assessment.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/core/models/review_detail_options.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

abstract class DiverRepository {
  Stream<AppUser?> authState();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  /// 로그인/회원가입 직후 users/{uid} 문서가 없으면 생성합니다.
  Future<void> ensureUserDocument(AppUser user);

  Stream<DiverSnapshot> watchDiver(String uid);

  Future<void> setFavoriteShop({
    required String uid,
    required String shopId,
    required bool favorite,
  });

  Future<void> addLog({
    required String uid,
    required String siteName,
    required DateTime divedAt,
    required String memo,
    Uint8List? photoBytes,
    String? photoFileName,
    String? photoContentType,
    DiveProfile? profile,
  });

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
  });

  Stream<List<ShopLiveStats>> watchShopStats();

  Stream<List<TourBooking>> watchBookings(String uid);

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
  });

  /// Newest-first page of guest reviews for a shop (default 10).
  Future<GuestReviewsPage> fetchShopReviewsPage({
    required String shopId,
    int limit = 10,
    Object? cursor,
  });

  Future<void> submitProVerification({
    required String uid,
    required String agency,
    required Uint8List photoBytes,
    required String photoFileName,
    required String photoContentType,
  });

  Stream<List<PendingInstructor>> watchPendingInstructors();

  Stream<List<CommunityPost>> watchCommunityPosts();

  Future<void> ensureSeedPosts();

  Future<void> approveInstructor(String uid);

  Future<void> rejectInstructor(String uid);

  Stream<List<MemberAccount>> watchMembers();

  Future<void> setMemberGrade({
    required String uid,
    required MemberGrade grade,
  });

  Future<void> unlockMemberGrade(String uid);

  Future<void> touchLastSeen(String uid);

  Future<void> clearGradeCelebration(String uid);

  Future<void> setPlaqueStatus({
    required String shopId,
    required PlaqueStatus status,
  });

  Future<void> setInternalScore({
    required String shopId,
    required int score,
  });

  /// Admin-only Dive Star grade (0–3) with review and expiry dates.
  Future<void> setDiveStarGrade({
    required String shopId,
    required int grade,
    required DateTime reviewedAt,
    required DateTime expiresAt,
  });

  /// Active audit form (seeds v1 once if missing).
  Future<DiveStarForm> ensureActiveDiveStarForm();

  Future<List<DiveStarAssessment>> listDiveStarAssessments(String shopId);

  /// Saves a draft assessment; does **not** change shop `dive_star_grade`.
  /// When [assessmentId] is set, overwrites that draft. Confirmed records throw.
  Future<DiveStarAssessment> saveDiveStarAssessment({
    required String shopId,
    String? assessmentId,
    required DiveStarAssessmentType type,
    required DateTime reviewedAt,
    required Map<String, bool> gates,
    required Map<String, int> scores,
    required Map<String, String> comments,
  });

  /// Applies candidate grade to the shop via [setDiveStarGrade] and marks confirmed.
  Future<DiveStarAssessment> confirmDiveStarAssessment({
    required String shopId,
    required String assessmentId,
    DateTime? expiresAt,
  });

  /// Deletes a draft assessment. Confirmed records throw.
  Future<void> deleteDiveStarAssessment({
    required String shopId,
    required String assessmentId,
  });

  /// Seeds phase-1 public drafts + default config when missing.
  Future<List<PartnerDocument>> ensurePartnerDocumentsSeeded();

  /// Public + approved only (for partner mode).
  Future<List<PartnerDocument>> listApprovedPublicPartnerDocuments();

  Future<PartnerDocConfig> ensurePartnerDocConfig();

  Future<void> savePartnerDocConfig(PartnerDocConfig config);

  Future<void> updatePartnerDocumentStatus({
    required String documentId,
    required PartnerDocStatus status,
  });

  Future<List<DocumentShareRecord>> listDocumentShares({int limit = 50});

  Future<DocumentShareRecord> recordDocumentShare({
    required String documentId,
    required String documentTitle,
    required String shopId,
    required String shopName,
    required PartnerDocShareMethod method,
    required String adminUid,
  });

  Future<void> setPostHidden({required String postId, required bool hidden});

  Future<void> deletePost(String postId);

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
  });

  Future<void> saveShopProduct({
    required String shopId,
    required ShopProduct product,
    Uint8List? photoBytes,
    String? photoFileName,
    String? photoContentType,
    bool useAsResortCover = false,
    List<ShopGallerySlot>? gallery,
  });

  Future<void> deleteShopProduct({
    required String shopId,
    required String productId,
  });

  Future<void> setShopProductPublishStatus({
    required String shopId,
    required String productId,
    required ProductPublishStatus status,
    String reviewNote = '',
  });

  Future<void> setShopProductListingKind({
    required String shopId,
    required String productId,
    required ProductListingKind listingKind,
  });

  Stream<InstructorDiscount> watchInstructorDiscount();

  Future<void> saveInstructorDiscount(InstructorDiscount discount);

  Stream<List<TourBooking>> watchShopBookings(String shopId);

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
  });

  Future<void> plantSeatFlag({
    required String shopId,
    required String productId,
    required int partySize,
    required DateTime now,
    String optionId = '',
    String uid = '',
  });

  Future<void> cancelBookingAsGuest({
    required String uid,
    required String bookingId,
  });

  /// Shop/admin confirms a guest request and records payment as captured.
  Future<bool> confirmShopBooking({
    required String shopId,
    required String bookingId,
  });

  Future<void> cancelBookingsForWeather({
    required String shopId,
    required DateTime tourDate,
  });

  Future<void> acknowledgeRefundNotice({
    required String uid,
    required String bookingId,
  });

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
  });

  Stream<List<CommunityComment>> watchComments(String postId);

  Future<void> addComment({
    required String postId,
    required String uid,
    required String authorName,
    required String body,
    required String language,
  });
}
