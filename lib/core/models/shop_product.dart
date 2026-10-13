/// Explore-only vs home shelf placement for an approved product.
enum ProductListingKind {
  /// Registered / approved but not pushed to any home shelf.
  exploreOnly,
  diveStar,
  diverPlanned,
  hotSpot,
  nextDeparture,
  curated;

  static const homeShelves = <ProductListingKind>[
    diveStar,
    diverPlanned,
    hotSpot,
    nextDeparture,
    curated,
  ];

  static const homeShelfLimit = 10;

  bool get isHomeShelf => this != ProductListingKind.exploreOnly;

  static ProductListingKind parse(dynamic value) {
    switch (value) {
      case 'explore_only':
      case 'none':
        return ProductListingKind.exploreOnly;
      case 'favorites':
      case 'diver_planned':
        return ProductListingKind.diverPlanned;
      case 'popular':
      case 'hot_spot':
        return ProductListingKind.hotSpot;
      case 'next_departure':
        return ProductListingKind.nextDeparture;
      case 'curated':
        return ProductListingKind.curated;
      case 'dive_star':
        return ProductListingKind.diveStar;
      default:
        // Legacy products without listing_kind stayed on Dive Star.
        return ProductListingKind.diveStar;
    }
  }

  String get firestoreValue {
    switch (this) {
      case ProductListingKind.exploreOnly:
        return 'explore_only';
      case ProductListingKind.diveStar:
        return 'dive_star';
      case ProductListingKind.diverPlanned:
        return 'diver_planned';
      case ProductListingKind.hotSpot:
        return 'hot_spot';
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

/// Add-on / package line item (room type, tank count, gear, transfer, …).
class ShopProductOption {
  const ShopProductOption({
    required this.id,
    required this.name,
    this.description = '',
    this.consumerPrice = 0,
    this.professionalPrice = 0,
  });

  factory ShopProductOption.fromMap(Map<String, dynamic> data) {
    return ShopProductOption(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      consumerPrice: (data['consumer_price'] as num?)?.toInt() ?? 0,
      professionalPrice: (data['professional_price'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String description;
  final int consumerPrice;
  final int professionalPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'consumer_price': consumerPrice,
      'professional_price': professionalPrice,
    };
  }

  ShopProductOption copyWith({
    String? name,
    String? description,
    int? consumerPrice,
    int? professionalPrice,
  }) {
    return ShopProductOption(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      consumerPrice: consumerPrice ?? this.consumerPrice,
      professionalPrice: professionalPrice ?? this.professionalPrice,
    );
  }
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
    this.continent = '',
    this.meetingPoint = '',
    this.schedule = '',
    this.includes = '',
    this.excludes = '',
    this.difficulty = '',
    this.minGuests = 0,
    this.maxGuests = 0,
    this.cancellationNote = '',
    this.options = const [],
    this.listingKind = ProductListingKind.exploreOnly,
    this.publishStatus = ProductPublishStatus.approved,
    this.submittedAt,
    this.featuredAt,
    this.reviewedAt,
    this.reviewNote = '',
  });

  static const Object _unset = Object();

  factory ShopProduct.fromMap(String shopId, Map<String, dynamic> data) {
    final rawOptions = data['options'];
    final options = <ShopProductOption>[];
    if (rawOptions is List) {
      for (final item in rawOptions) {
        if (item is Map<String, dynamic>) {
          options.add(ShopProductOption.fromMap(item));
        } else if (item is Map) {
          options.add(
            ShopProductOption.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
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
      continent: data['continent'] as String? ?? '',
      meetingPoint: data['meeting_point'] as String? ?? '',
      schedule: data['schedule'] as String? ?? '',
      includes: data['includes'] as String? ?? '',
      excludes: data['excludes'] as String? ?? '',
      difficulty: data['difficulty'] as String? ?? '',
      minGuests: (data['min_guests'] as num?)?.toInt() ?? 0,
      maxGuests: (data['max_guests'] as num?)?.toInt() ?? 0,
      cancellationNote: data['cancellation_note'] as String? ?? '',
      options: options,
      listingKind: ProductListingKind.parse(data['listing_kind']),
      publishStatus: ProductPublishStatus.parse(data['publish_status']),
      submittedAt: _readTime(data['submitted_at']),
      featuredAt: _readTime(data['featured_at']),
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
  final String continent;
  final String meetingPoint;
  final String schedule;
  final String includes;
  final String excludes;
  final String difficulty;
  final int minGuests;
  final int maxGuests;
  final String cancellationNote;
  final List<ShopProductOption> options;
  final ProductListingKind listingKind;
  final ProductPublishStatus publishStatus;
  final DateTime? submittedAt;
  /// When an admin last assigned this product to a home shelf.
  final DateTime? featuredAt;
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
    String? continent,
    String? meetingPoint,
    String? schedule,
    String? includes,
    String? excludes,
    String? difficulty,
    int? minGuests,
    int? maxGuests,
    String? cancellationNote,
    List<ShopProductOption>? options,
    ProductListingKind? listingKind,
    ProductPublishStatus? publishStatus,
    DateTime? submittedAt,
    Object? featuredAt = _unset,
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
      continent: continent ?? this.continent,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      schedule: schedule ?? this.schedule,
      includes: includes ?? this.includes,
      excludes: excludes ?? this.excludes,
      difficulty: difficulty ?? this.difficulty,
      minGuests: minGuests ?? this.minGuests,
      maxGuests: maxGuests ?? this.maxGuests,
      cancellationNote: cancellationNote ?? this.cancellationNote,
      options: options ?? this.options,
      listingKind: listingKind ?? this.listingKind,
      publishStatus: publishStatus ?? this.publishStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      featuredAt: identical(featuredAt, _unset)
          ? this.featuredAt
          : featuredAt as DateTime?,
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
      if (continent.isNotEmpty) 'continent': continent,
      if (meetingPoint.isNotEmpty) 'meeting_point': meetingPoint,
      if (schedule.isNotEmpty) 'schedule': schedule,
      if (includes.isNotEmpty) 'includes': includes,
      if (excludes.isNotEmpty) 'excludes': excludes,
      if (difficulty.isNotEmpty) 'difficulty': difficulty,
      if (minGuests > 0) 'min_guests': minGuests,
      if (maxGuests > 0) 'max_guests': maxGuests,
      if (cancellationNote.isNotEmpty) 'cancellation_note': cancellationNote,
      if (options.isNotEmpty)
        'options': [for (final option in options) option.toMap()],
      'listing_kind': listingKind.firestoreValue,
      'publish_status': publishStatus.firestoreValue,
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
      if (featuredAt != null) 'featured_at': featuredAt!.toIso8601String(),
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

  /// Firestore nested maps are often `Map<Object?, Object?>` on mobile.
  /// Narrow `Map<String, dynamic>` checks silently drop whole products.
  static Map<String, dynamic>? mapFrom(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static List<ShopProduct> listFrom(String shopId, dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final byId = <String, ShopProduct>{};
    for (final item in raw) {
      final map = mapFrom(item);
      if (map == null) {
        continue;
      }
      final product = ShopProduct.fromMap(shopId, map);
      if (product.id.isEmpty) {
        continue;
      }
      byId[product.id] = product;
    }
    return byId.values.toList();
  }
}
