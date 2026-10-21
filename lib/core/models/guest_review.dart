/// One guest trip review shown on a shop detail page.
class GuestReview {
  const GuestReview({
    required this.id,
    required this.shopId,
    required this.stars,
    required this.comment,
    required this.createdAt,
    this.authorDisplayName = '',
    this.productId = '',
  });

  final String id;
  final String shopId;
  final int stars;
  final String comment;
  final DateTime createdAt;
  final String authorDisplayName;
  final String productId;

  factory GuestReview.fromMap(String id, Map<String, dynamic> data) {
    final overall = (data['overall'] as num?)?.toDouble();
    final safety = (data['safety'] as num?)?.toInt();
    final guide = (data['guide'] as num?)?.toInt();
    final boat = (data['boat'] as num?)?.toInt();
    final stars = overall != null
        ? overall.round().clamp(1, 5)
        : (((safety ?? 0) + (guide ?? 0) + (boat ?? 0)) / 3).round().clamp(1, 5);
    final created = _readTime(data['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return GuestReview(
      id: id,
      shopId: data['shop_id'] as String? ?? '',
      stars: stars,
      comment: (data['comment'] as String? ?? '').trim(),
      createdAt: created,
      authorDisplayName: (data['author_display_name'] as String? ?? '').trim(),
      productId: data['product_id'] as String? ?? '',
    );
  }

  static DateTime? _readTime(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is DateTime) {
      return raw;
    }
    // Firestore Timestamp without importing cloud_firestore in the model.
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

  /// Opaque cursor for the next [DiverRepository.fetchShopReviewsPage] call.
  final Object? cursor;
}
