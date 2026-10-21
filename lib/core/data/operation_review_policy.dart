import 'package:dive_travel_app/core/models/pro_verification.dart';

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
}

class ReviewValidationException implements Exception {
  const ReviewValidationException(this.code);

  final ReviewValidationCode code;

  @override
  String toString() => 'ReviewValidationException($code)';
}
