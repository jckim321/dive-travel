import 'dart:typed_data';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_snapshot.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/dive_log.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
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

  Future<void> submitOperationReview({
    required String uid,
    required String shopId,
    required int safety,
    required int guide,
    required int boat,
    String? bookingId,
    String? logId,
    String? comment,
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

  Future<void> setPlaqueStatus({
    required String shopId,
    required PlaqueStatus status,
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
  });

  Stream<InstructorDiscount> watchInstructorDiscount();

  Future<void> saveInstructorDiscount(InstructorDiscount discount);

  Stream<List<TourBooking>> watchShopBookings(String shopId);

  Future<void> createBooking({
    required String uid,
    required String shopId,
    required String shopName,
    required String productName,
    required int price,
    DateTime? tourDate,
  });

  Future<void> cancelBookingAsGuest({
    required String uid,
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
