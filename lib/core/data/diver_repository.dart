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
import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/core/models/dive_star_assessment.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/core/models/partner_contract.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';
import 'package:dive_travel_app/core/models/review_detail_options.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/models/trial_data_cleanup.dart';

abstract class DiverRepository {
  Stream<AppUser?> authState();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
    String? loginId,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  /// 로그인/회원가입 직후 users/{uid} 문서가 없으면 생성합니다.
  Future<void> ensureUserDocument(AppUser user, {String? loginId});

  /// Admin: promote member to partner (is_business + owned_shop_id + history).
  Future<void> promoteMemberToPartner({
    required String uid,
    required String shopId,
    required String actorUid,
    required String actorName,
  });

  /// Admin: demote partner back to diver (clears business flags + history).
  Future<void> demoteMemberFromPartner({
    required String uid,
    required String actorUid,
    required String actorName,
  });

  /// Creates a minimal shop doc and returns its id (admin partner promote).
  Future<String> createEmptyShop({required String name});

  /// H9: admin trial-data counts (prefer Firestore count(), no full scans).
  Future<TrialDataSnapshot> fetchTrialDataCounts({
    required String actorUid,
    required String actorEmail,
  });

  /// H9: selective trial-data deletion (skips protected rows).
  Future<TrialDeleteResult> runTrialDataDeletion({
    required TrialDeleteSelection selection,
    required String confirmPhrase,
    required bool backupAcknowledged,
    required String actorUid,
    required String actorName,
    required String actorEmail,
    void Function(TrialDeleteProgress progress)? onProgress,
  });

  /// Profile fields only (no logs subcollection). Prefer [fetchDiveLogs] for logs.
  Stream<DiverSnapshot> watchDiver(String uid);

  /// Newest-first page of dive logs (`users/{uid}/logs`).
  Future<DiveLogsPage> fetchDiveLogs(
    String uid, {
    int limit = 50,
    Object? cursor,
  });

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

  /// One-shot shops list (prefer over [watchShopStats] for cost).
  Future<List<ShopLiveStats>> fetchShopStats();

  Future<ShopLiveStats?> fetchShopStat(String shopId);

  /// Legacy realtime shops; prefer [fetchShopStats].
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

  /// Reviews written by [uid], newest first (`users/{uid}/reviews`).
  Future<List<GuestReview>> listMyReviews(String uid);

  /// Updates scores/comment/details; recomputes shop + product aggregates.
  Future<void> updateOperationReview({
    required String uid,
    required String shopId,
    required String reviewId,
    required int safety,
    required int guide,
    required int boat,
    String? comment,
    ReviewDetails? details,
  });

  /// Deletes a review and rolls back shop/product aggregates; clears booking.reviewed.
  Future<void> deleteOperationReview({
    required String uid,
    required String shopId,
    required String reviewId,
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

  Future<List<PendingInstructor>> fetchPendingInstructors();

  /// Legacy realtime pending instructors; prefer [fetchPendingInstructors].
  Stream<List<PendingInstructor>> watchPendingInstructors();

  /// Newest-first page of community posts.
  Future<CommunityPostsPage> fetchCommunityPosts({
    int limit = 20,
    Object? cursor,
  });

  /// Legacy realtime posts; prefer [fetchCommunityPosts].
  Stream<List<CommunityPost>> watchCommunityPosts();

  Future<void> ensureSeedPosts();

  Future<void> approveInstructor(String uid);

  Future<void> rejectInstructor(String uid);

  Future<List<MemberAccount>> fetchMembers();

  /// Legacy realtime members; prefer [fetchMembers].
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

  Future<DiveStarForm?> getDiveStarForm(String version);

  Future<List<DiveStarForm>> listDiveStarForms();

  /// Saves a draft form at `dive_star_forms/{version}`. Fails if version exists.
  Future<DiveStarForm> importDiveStarFormDraft(DiveStarForm form);

  /// Makes [version] the only active form; others become draft/inactive.
  Future<DiveStarForm> activateDiveStarForm(String version);

  Future<List<DiveStarAssessment>> listDiveStarAssessments(String shopId);

  /// Saves a draft assessment; does **not** change shop `dive_star_grade`.
  /// When [assessmentId] is set, overwrites that draft. Confirmed records throw.
  /// [formVersion] selects which form to score against (default: active form).
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

  /// H6: per-shop contract vault (no collectionGroup).
  Future<List<PartnerContract>> listPartnerContracts(String shopId);

  Future<PartnerContract?> getPartnerContract({
    required String shopId,
    required String contractId,
  });

  Future<List<PartnerContractEvent>> listPartnerContractEvents({
    required String shopId,
    required String contractId,
  });

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
  });

  Future<void> sendPartnerContract({
    required String shopId,
    required String contractId,
    required String adminUid,
  });

  Future<void> voidPartnerContract({
    required String shopId,
    required String contractId,
    required String adminUid,
    String reason = '',
  });

  Future<void> markPartnerContractViewed({
    required String shopId,
    required String contractId,
    required String partnerUid,
  });

  Future<void> requestPartnerContractRevision({
    required String shopId,
    required String contractId,
    required String partnerUid,
    required String memo,
  });

  /// Partner signs after client re-hashes PDF and matches [expectedSha256].
  Future<void> signPartnerContract({
    required String shopId,
    required String contractId,
    required String partnerUid,
    required String signerName,
    required String signaturePngBase64,
    required String expectedSha256,
  });

  /// Download PDF bytes for vault file (R2 readable URL or http).
  Future<List<int>> fetchPartnerContractFileBytes(String fileUrl);

  Future<List<DocumentShareRecord>> listDocumentShares({int limit = 50});

  Future<DocumentShareRecord> recordDocumentShare({
    required String documentId,
    required String documentTitle,
    required String shopId,
    required String shopName,
    required PartnerDocShareMethod method,
    required String adminUid,
  });

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
  });

  Future<List<DiveStarApplication>> listDiveStarApplications({
    String? shopId,
    String? partnerUid,
    int limit = 50,
  });

  Future<DiveStarApplication> updateDiveStarApplicationPipeline({
    required String applicationId,
    required DiveStarPipelineStatus status,
    DateTime? reminderDueAt,
    bool clearReminder = false,
  });

  Future<PartnerEmailOutboxItem> queuePartnerEmail({
    required String toEmail,
    required String subject,
    required String body,
    String applicationId = '',
    String shopId = '',
  });

  Future<List<PartnerEmailOutboxItem>> listPartnerEmailOutbox({
    int limit = 30,
  });

  Future<void> markPartnerEmailOutboxSent(String outboxId);

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
  });

  Future<void> saveShopProduct({
    required String shopId,
    required ShopProduct product,
    Uint8List? photoBytes,
    String? photoFileName,
    String? photoContentType,
    bool useAsResortCover = false,
    List<ShopGallerySlot>? gallery,
    /// When true, empty workbench fields delete persisted keys; unknown keys stay.
    bool clearAbsentFormFields = false,
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
    List<String> reasonTags = const [],
  });

  Future<void> setShopProductListingKind({
    required String shopId,
    required String productId,
    required ProductListingKind listingKind,
  });

  Stream<InstructorDiscount> watchInstructorDiscount();

  Future<void> saveInstructorDiscount(InstructorDiscount discount);

  Future<List<TourBooking>> fetchShopBookings(String shopId);

  /// Partner/admin realtime; prefer [fetchShopBookings] for admin sales.
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
    String guestDisplayName = '',
  });

  Future<SeatFlagPlant> plantSeatFlag({
    required String shopId,
    required String productId,
    required int partySize,
    required DateTime now,
    String optionId = '',
    String uid = '',
  });

  Future<bool> cancelSeatFlag({
    required String uid,
    required String shopId,
    required String productId,
    required DateTime now,
    String optionId = '',
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

  /// Partner read receipt only (`partner_acked_at` on shop booking doc).
  Future<void> ackPartnerBooking({
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
