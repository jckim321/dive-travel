import 'package:dive_travel_app/core/models/review_detail_options.dart';

/// One guest trip review shown on a shop detail page / my reviews.
class GuestReview {
  const GuestReview({
    required this.id,
    required this.shopId,
    required this.stars,
    required this.comment,
    required this.createdAt,
    this.uid = '',
    this.bookingId = '',
    this.safety = 0,
    this.guide = 0,
    this.boat = 0,
    this.authorDisplayName = '',
    this.productId = '',
    this.optionId = '',
    this.details = const ReviewDetails(),
    this.editedAt,
  });

  final String id;
  final String shopId;
  final String uid;
  final String bookingId;
  final int stars;
  final int safety;
  final int guide;
  final int boat;
  final String comment;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String authorDisplayName;
  final String productId;
  final String optionId;
  final ReviewDetails details;

  bool get wasEdited => editedAt != null;

  factory GuestReview.fromMap(String id, Map<String, dynamic> data) {
    final overall = (data['overall'] as num?)?.toDouble();
    final safety = (data['safety'] as num?)?.toInt() ?? 0;
    final guide = (data['guide'] as num?)?.toInt() ?? 0;
    final boat = (data['boat'] as num?)?.toInt() ?? 0;
    final stars = overall != null
        ? overall.round().clamp(1, 5)
        : (((safety) + (guide) + (boat)) / 3).round().clamp(1, 5);
    final created =
        _readTime(data['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return GuestReview(
      id: id,
      shopId: data['shop_id'] as String? ?? '',
      uid: data['uid'] as String? ?? '',
      bookingId: data['booking_id'] as String? ?? '',
      safety: safety,
      guide: guide,
      boat: boat,
      stars: stars,
      comment: (data['comment'] as String? ?? '').trim(),
      createdAt: created,
      editedAt: _readTime(data['edited_at']),
      authorDisplayName: (data['author_display_name'] as String? ?? '').trim(),
      productId: data['product_id'] as String? ?? '',
      optionId: data['option_id'] as String? ?? '',
      details: ReviewDetails.fromMap(data),
    );
  }

  static DateTime? _readTime(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is DateTime) {
      return raw;
    }
    try {
      final dynamic value = raw;
      if (value.toDate is Function) {
        return value.toDate() as DateTime;
      }
    } catch (_) {}
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return null;
  }
}

/// One page of shop reviews (newest first).
class GuestReviewsPage {
  const GuestReviewsPage({
    required this.reviews,
    required this.hasMore,
    this.cursor,
  });

  final List<GuestReview> reviews;
  final bool hasMore;

  /// Opaque cursor for the next page (Firestore [DocumentSnapshot] or index).
  final Object? cursor;
}
