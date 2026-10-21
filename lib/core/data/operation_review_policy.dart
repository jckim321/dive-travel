import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/review_detail_options.dart';

/// Client + repository checks for guest trip reviews (anti-fake rules 1–4).
abstract final class OperationReviewPolicy {
  static const maxCommentLength = 2000;

  static int clampStars(int value) => value.clamp(1, 5);

  static String? normalizeComment(String? comment) {
    final text = comment?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (text.length > maxCommentLength) {
      throw const ReviewValidationException(ReviewValidationCode.commentTooLong);
    }
    return text;
  }

  static void assertStarsInRange(int safety, int guide, int boat) {
    for (final score in [safety, guide, boat]) {
      if (score < 1 || score > 5) {
        throw const ReviewValidationException(ReviewValidationCode.invalidStars);
      }
    }
  }

  /// Past trip, not cancelled, not yet reviewed.
  static bool isEligibleBooking(
    TourBooking booking, {
    DateTime? now,
    String? shopId,
    String? uid,
  }) {
    final at = now ?? DateTime.now();
    if (!booking.isActive || booking.reviewed) {
      return false;
    }
    if (!booking.scheduledFor.isBefore(at)) {
      return false;
    }
    if (shopId != null &&
        shopId.isNotEmpty &&
        booking.shopId != shopId) {
      return false;
    }
    if (uid != null &&
        uid.isNotEmpty &&
        booking.uid.isNotEmpty &&
        booking.uid != uid) {
      return false;
    }
    return true;
  }

  static TourBooking requireEligibleBooking({
    required String bookingId,
    required List<TourBooking> bookings,
    required String uid,
    required String shopId,
    DateTime? now,
  }) {
    final id = bookingId.trim();
    if (id.isEmpty) {
      throw const ReviewValidationException(ReviewValidationCode.bookingRequired);
    }
    TourBooking? match;
    for (final booking in bookings) {
      if (booking.id == id) {
        match = booking;
        break;
      }
    }
    if (match == null) {
      throw const ReviewValidationException(ReviewValidationCode.bookingNotFound);
    }
    if (match.uid.isNotEmpty && match.uid != uid) {
      throw const ReviewValidationException(ReviewValidationCode.notOwnBooking);
    }
    if (match.shopId != shopId) {
      throw const ReviewValidationException(ReviewValidationCode.shopMismatch);
    }
    if (match.reviewed) {
      throw const ReviewValidationException(ReviewValidationCode.alreadyReviewed);
    }
    if (!match.isActive) {
      throw const ReviewValidationException(ReviewValidationCode.bookingNotActive);
    }
    final at = now ?? DateTime.now();
    if (!match.scheduledFor.isBefore(at)) {
      throw const ReviewValidationException(ReviewValidationCode.tripNotEnded);
    }
    return match;
  }

  /// First past, unreviewed, active booking for [shopId] (logbook helper).
  static TourBooking? findEligibleBookingForShop({
    required List<TourBooking> bookings,
    required String shopId,
    String? uid,
    DateTime? now,
  }) {
    for (final booking in bookings) {
      if (isEligibleBooking(
        booking,
        now: now,
        shopId: shopId,
        uid: uid,
      )) {
        return booking;
      }
    }
    return null;
  }

  /// Empty details pass; present values must be allow-listed.
  static ReviewDetails normalizeDetails(ReviewDetails? raw) {
    if (raw == null || raw.isEmpty) {
      return const ReviewDetails();
    }
    final level = raw.diverLevel?.trim();
    if (level != null &&
        level.isNotEmpty &&
        !ReviewDetailOptions.isDiverLevel(level)) {
      throw const ReviewValidationException(ReviewValidationCode.invalidDetails);
    }
    final band = raw.diveCountBand?.trim();
    if (band != null &&
        band.isNotEmpty &&
        !ReviewDetailOptions.isDiveCountBand(band)) {
      throw const ReviewValidationException(ReviewValidationCode.invalidDetails);
    }
    final vis = raw.visibility?.trim();
    if (vis != null &&
        vis.isNotEmpty &&
        !ReviewDetailOptions.isVisibility(vis)) {
      throw const ReviewValidationException(ReviewValidationCode.invalidDetails);
    }
    final current = raw.current?.trim();
    if (current != null &&
        current.isNotEmpty &&
        !ReviewDetailOptions.isCurrent(current)) {
      throw const ReviewValidationException(ReviewValidationCode.invalidDetails);
    }
    final crowd = raw.guideCrowd?.trim();
    if (crowd != null &&
        crowd.isNotEmpty &&
        !ReviewDetailOptions.isGuideCrowd(crowd)) {
      throw const ReviewValidationException(ReviewValidationCode.invalidDetails);
    }
    final revisit = raw.revisitIntent?.trim();
    if (revisit != null &&
        revisit.isNotEmpty &&
        !ReviewDetailOptions.isRevisitIntent(revisit)) {
      throw const ReviewValidationException(ReviewValidationCode.invalidDetails);
    }
    if (!ReviewDetailOptions.isWaterTempOk(raw.waterTempC)) {
      throw const ReviewValidationException(ReviewValidationCode.invalidWaterTemp);
    }
    final audiences = <String>[];
    for (final item in raw.recommendFor) {
      final key = item.trim();
      if (key.isEmpty) {
        continue;
      }
      if (!ReviewDetailOptions.isAudience(key)) {
        throw const ReviewValidationException(
          ReviewValidationCode.invalidDetails,
        );
      }
      if (!audiences.contains(key)) {
        audiences.add(key);
      }
    }
    return ReviewDetails(
      diverLevel: (level == null || level.isEmpty) ? null : level,
      diveCountBand: (band == null || band.isEmpty) ? null : band,
      visibility: (vis == null || vis.isEmpty) ? null : vis,
      current: (current == null || current.isEmpty) ? null : current,
      waterTempC: raw.waterTempC,
      guideCrowd: (crowd == null || crowd.isEmpty) ? null : crowd,
      recommendFor: audiences,
      revisitIntent: (revisit == null || revisit.isEmpty) ? null : revisit,
    );
  }
}

enum ReviewValidationCode {
  bookingRequired,
  bookingNotFound,
  notOwnBooking,
  shopMismatch,
  alreadyReviewed,
  bookingNotActive,
  tripNotEnded,
  invalidStars,
  commentTooLong,
  invalidDetails,
  invalidWaterTemp,
}

class ReviewValidationException implements Exception {
  const ReviewValidationException(this.code);

  final ReviewValidationCode code;

  @override
  String toString() => 'ReviewValidationException($code)';
}
