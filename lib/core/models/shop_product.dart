/// Where an approved product is featured on home / explore.
enum ProductListingKind {
  diveStar,
  favorites,
  popular,
  nextDeparture,
  curated;

  static ProductListingKind parse(dynamic value) {
    switch (value) {
      case 'favorites':
        return ProductListingKind.favorites;
      case 'popular':
        return ProductListingKind.popular;
      case 'next_departure':
        return ProductListingKind.nextDeparture;
      case 'curated':
        return ProductListingKind.curated;
      default:
        return ProductListingKind.diveStar;
    }
  }

  String get firestoreValue {
    switch (this) {
      case ProductListingKind.diveStar:
        return 'dive_star';
      case ProductListingKind.favorites:
        return 'favorites';
      case ProductListingKind.popular:
        return 'popular';
      case ProductListingKind.nextDeparture:
        return 'next_departure';
      case ProductListingKind.curated:
        return 'curated';
    }
  }
}

/// Partner submissions stay pending until the owner approves.
enum ProductPublishStatus {
  draft,
  pending,
  approved,
  rejected;

  static ProductPublishStatus parse(dynamic value) {
    switch (value) {
      case 'draft':
        return ProductPublishStatus.draft;
      case 'pending':
        return ProductPublishStatus.pending;
      case 'rejected':
        return ProductPublishStatus.rejected;
      case 'approved':
        return ProductPublishStatus.approved;
      default:
        // Legacy products without a status stay live.
        return ProductPublishStatus.approved;
    }
  }

  String get firestoreValue {
    switch (this) {
      case ProductPublishStatus.draft:
        return 'draft';
      case ProductPublishStatus.pending:
        return 'pending';
      case ProductPublishStatus.approved:
        return 'approved';
      case ProductPublishStatus.rejected:
        return 'rejected';
    }
  }

  bool get isPublic => this == ProductPublishStatus.approved;
}

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.shopId,
    required this.name,
    required this.consumerPrice,
    required this.professionalPrice,
    this.active = true,
    this.blurb = '',
    this.durationLabel = '',
    this.coverUrl = '',
    this.listingKind = ProductListingKind.diveStar,
    this.publishStatus = ProductPublishStatus.approved,
    this.submittedAt,
    this.reviewedAt,
    this.reviewNote = '',
  });

  factory ShopProduct.fromMap(String shopId, Map<String, dynamic> data) {
    return ShopProduct(
      id: data['id'] as String? ?? '',
      shopId: shopId,
      name: data['name'] as String? ?? '',
      consumerPrice: (data['consumer_price'] as num?)?.toInt() ?? 0,
      professionalPrice: (data['professional_price'] as num?)?.toInt() ?? 0,
      active: data['active'] != false,
      blurb: data['blurb'] as String? ?? '',
      durationLabel: data['duration_label'] as String? ?? '',
      coverUrl: data['cover_url'] as String? ?? '',
      listingKind: ProductListingKind.parse(data['listing_kind']),
      publishStatus: ProductPublishStatus.parse(data['publish_status']),
      submittedAt: _readTime(data['submitted_at']),
      reviewedAt: _readTime(data['reviewed_at']),
      reviewNote: data['review_note'] as String? ?? '',
    );
  }

  final String id;
  final String shopId;
  final String name;
  final int consumerPrice;
  final int professionalPrice;
  final bool active;
  final String blurb;
  final String durationLabel;
  final String coverUrl;
  final ProductListingKind listingKind;
  final ProductPublishStatus publishStatus;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String reviewNote;

  bool get isPendingApproval =>
      publishStatus == ProductPublishStatus.pending;

  bool get isListedPublicly => active && publishStatus.isPublic;

  ShopProduct copyWith({
    String? name,
    int? consumerPrice,
    int? professionalPrice,
    bool? active,
    String? blurb,
    String? durationLabel,
    String? coverUrl,
    ProductListingKind? listingKind,
    ProductPublishStatus? publishStatus,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewNote,
  }) {
    return ShopProduct(
      id: id,
      shopId: shopId,
      name: name ?? this.name,
      consumerPrice: consumerPrice ?? this.consumerPrice,
      professionalPrice: professionalPrice ?? this.professionalPrice,
      active: active ?? this.active,
      blurb: blurb ?? this.blurb,
      durationLabel: durationLabel ?? this.durationLabel,
      coverUrl: coverUrl ?? this.coverUrl,
      listingKind: listingKind ?? this.listingKind,
      publishStatus: publishStatus ?? this.publishStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'consumer_price': consumerPrice,
      'professional_price': professionalPrice,
      'active': active,
      'blurb': blurb,
      'duration_label': durationLabel,
      if (coverUrl.isNotEmpty) 'cover_url': coverUrl,
      'listing_kind': listingKind.firestoreValue,
      'publish_status': publishStatus.firestoreValue,
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (reviewNote.isNotEmpty) 'review_note': reviewNote,
    };
  }

  static DateTime? _readTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    // cloud_firestore Timestamp
    try {
      return (value as dynamic).toDate() as DateTime?;
    } catch (_) {
      return null;
    }
  }
}
