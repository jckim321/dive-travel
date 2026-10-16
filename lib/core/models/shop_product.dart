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

enum ProductCategory {
  resortPackage,
  liveaboard,
  funDive,
  course,
  dayTrip;

  static ProductCategory parse(dynamic value) {
    switch (value) {
      case 'liveaboard':
        return ProductCategory.liveaboard;
      case 'fun_dive':
        return ProductCategory.funDive;
      case 'course':
        return ProductCategory.course;
      case 'day_trip':
        return ProductCategory.dayTrip;
      default:
        return ProductCategory.resortPackage;
    }
  }

  String get firestoreValue {
    switch (this) {
      case ProductCategory.resortPackage:
        return 'resort_package';
      case ProductCategory.liveaboard:
        return 'liveaboard';
      case ProductCategory.funDive:
        return 'fun_dive';
      case ProductCategory.course:
        return 'course';
      case ProductCategory.dayTrip:
        return 'day_trip';
    }
  }
}

enum GuestRole {
  diver,
  nondiver,
  child,
  infant;

  static GuestRole parse(dynamic value) {
    switch (value) {
      case 'nondiver':
        return GuestRole.nondiver;
      case 'child':
        return GuestRole.child;
      case 'infant':
        return GuestRole.infant;
      default:
        return GuestRole.diver;
    }
  }

  String get firestoreValue {
    switch (this) {
      case GuestRole.diver:
        return 'diver';
      case GuestRole.nondiver:
        return 'nondiver';
      case GuestRole.child:
        return 'child';
      case GuestRole.infant:
        return 'infant';
    }
  }
}

enum ProductOptionKind {
  basePackage,
  addon,
  individual;

  static ProductOptionKind parse(dynamic value) {
    switch (value) {
      case 'base_package':
        return ProductOptionKind.basePackage;
      case 'individual':
        return ProductOptionKind.individual;
      default:
        return ProductOptionKind.addon;
    }
  }

  String get firestoreValue {
    switch (this) {
      case ProductOptionKind.basePackage:
        return 'base_package';
      case ProductOptionKind.addon:
        return 'addon';
      case ProductOptionKind.individual:
        return 'individual';
    }
  }
}

class ItineraryDay {
  const ItineraryDay({
    required this.day,
    this.title = '',
    this.body = '',
  });

  factory ItineraryDay.fromMap(Map<String, dynamic> data) {
    return ItineraryDay(
      day: (data['day'] as num?)?.toInt() ?? 0,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
    );
  }

  final int day;
  final String title;
  final String body;

  Map<String, dynamic> toMap() => {
    'day': day,
    'title': title,
    'body': body,
  };
}

class GuestRate {
  const GuestRate({
    required this.role,
    this.enabled = true,
    this.consumer = 0,
    this.professional = 0,
  });

  factory GuestRate.fromMap(Map<String, dynamic> data) {
    return GuestRate(
      role: GuestRole.parse(data['role']),
      enabled: data['enabled'] != false,
      consumer: (data['consumer'] as num?)?.toInt() ?? 0,
      professional: (data['professional'] as num?)?.toInt() ?? 0,
    );
  }

  final GuestRole role;
  final bool enabled;
  final int consumer;
  final int professional;

  Map<String, dynamic> toMap() => {
    'role': role.firestoreValue,
    'enabled': enabled,
    'consumer': consumer,
    'professional': professional,
  };

  GuestRate copyWith({
    bool? enabled,
    int? consumer,
    int? professional,
  }) {
    return GuestRate(
      role: role,
      enabled: enabled ?? this.enabled,
      consumer: consumer ?? this.consumer,
      professional: professional ?? this.professional,
    );
  }
}

/// Add-on / package line item (room type, tank count, gear, transfer, …).
class ShopProductOption {
  const ShopProductOption({
    required this.id,
    required this.name,
    this.description = '',
    this.consumerPrice = 0,
    this.professionalPrice = 0,
    this.kind = ProductOptionKind.addon,
    this.bookable = true,
    this.guestRole = GuestRole.diver,
  });

  factory ShopProductOption.fromMap(Map<String, dynamic> data) {
    return ShopProductOption(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      consumerPrice: (data['consumer_price'] as num?)?.toInt() ?? 0,
      professionalPrice: (data['professional_price'] as num?)?.toInt() ?? 0,
      kind: ProductOptionKind.parse(data['kind']),
      bookable: data['bookable'] != false,
      guestRole: GuestRole.parse(data['guest_role']),
    );
  }

  final String id;
  final String name;
  final String description;
  final int consumerPrice;
  final int professionalPrice;
  final ProductOptionKind kind;
  final bool bookable;
  final GuestRole guestRole;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'consumer_price': consumerPrice,
      'professional_price': professionalPrice,
      'kind': kind.firestoreValue,
      'bookable': bookable,
      'guest_role': guestRole.firestoreValue,
    };
  }

  ShopProductOption copyWith({
    String? name,
    String? description,
    int? consumerPrice,
    int? professionalPrice,
    ProductOptionKind? kind,
    bool? bookable,
    GuestRole? guestRole,
  }) {
    return ShopProductOption(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      consumerPrice: consumerPrice ?? this.consumerPrice,
      professionalPrice: professionalPrice ?? this.professionalPrice,
      kind: kind ?? this.kind,
      bookable: bookable ?? this.bookable,
      guestRole: guestRole ?? this.guestRole,
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
    this.category = ProductCategory.resortPackage,
    this.detail = '',
    this.photoUrls = const [],
    this.itineraryDays = const [],
    this.guestRates = const [],
    this.focPayCount = 0,
    this.focFreeCount = 0,
    this.focAppliesTo = GuestRole.diver,
    this.listingKind = ProductListingKind.exploreOnly,
    this.publishStatus = ProductPublishStatus.approved,
    this.submittedAt,
    this.featuredAt,
    this.reviewedAt,
    this.reviewNote = '',
    this.submittedByUid = '',
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
      category: ProductCategory.parse(data['category']),
      detail: data['detail'] as String? ?? '',
      photoUrls: _stringList(data['photo_urls']),
      itineraryDays: _days(data['itinerary_days']),
      guestRates: _rates(data['guest_rates']),
      focPayCount: (data['foc_pay_count'] as num?)?.toInt() ?? 0,
      focFreeCount: (data['foc_free_count'] as num?)?.toInt() ?? 0,
      focAppliesTo: GuestRole.parse(data['foc_applies_to']),
      listingKind: ProductListingKind.parse(data['listing_kind']),
      publishStatus: ProductPublishStatus.parse(data['publish_status']),
      submittedAt: _readTime(data['submitted_at']),
      featuredAt: _readTime(data['featured_at']),
      reviewedAt: _readTime(data['reviewed_at']),
      reviewNote: data['review_note'] as String? ?? '',
      submittedByUid: data['submitted_by_uid'] as String? ?? '',
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
  final ProductCategory category;
  final String detail;
  final List<String> photoUrls;
  final List<ItineraryDay> itineraryDays;
  final List<GuestRate> guestRates;
  final int focPayCount;
  final int focFreeCount;
  final GuestRole focAppliesTo;
  final ProductListingKind listingKind;
  final ProductPublishStatus publishStatus;
  final DateTime? submittedAt;
  /// When an admin last assigned this product to a home shelf.
  final DateTime? featuredAt;
  final DateTime? reviewedAt;
  final String reviewNote;
  /// Diver/partner who submitted this trip for approval.
  final String submittedByUid;

  bool get isPendingApproval =>
      publishStatus == ProductPublishStatus.pending;

  bool get isListedPublicly => active && publishStatus.isPublic;

  bool get usesBookingWorkbench {
    return guestRates.isNotEmpty ||
        options.any((o) => o.kind != ProductOptionKind.addon) ||
        focPayCount > 0;
  }

  List<GuestRate> get resolvedGuestRates {
    GuestRate? saved(GuestRole role) {
      for (final rate in guestRates) {
        if (rate.role == role) {
          return rate;
        }
      }
      return null;
    }

    return [
      saved(GuestRole.diver) ??
          GuestRate(
            role: GuestRole.diver,
            consumer: consumerPrice,
            professional: professionalPrice,
          ),
      saved(GuestRole.nondiver) ??
          const GuestRate(role: GuestRole.nondiver, enabled: true),
      saved(GuestRole.child) ??
          const GuestRate(role: GuestRole.child, enabled: true),
      if (saved(GuestRole.infant)?.enabled == true) saved(GuestRole.infant)!,
    ];
  }

  String get derivedDurationLabel {
    if (itineraryDays.isEmpty) {
      return durationLabel;
    }
    final n = itineraryDays.length;
    if (n <= 1) {
      return durationLabel.isNotEmpty ? durationLabel : '1일';
    }
    return '${n - 1}박 $n일';
  }

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
    ProductCategory? category,
    String? detail,
    List<String>? photoUrls,
    List<ItineraryDay>? itineraryDays,
    List<GuestRate>? guestRates,
    int? focPayCount,
    int? focFreeCount,
    GuestRole? focAppliesTo,
    ProductListingKind? listingKind,
    ProductPublishStatus? publishStatus,
    DateTime? submittedAt,
    Object? featuredAt = _unset,
    DateTime? reviewedAt,
    String? reviewNote,
    String? submittedByUid,
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
      category: category ?? this.category,
      detail: detail ?? this.detail,
      photoUrls: photoUrls ?? this.photoUrls,
      itineraryDays: itineraryDays ?? this.itineraryDays,
      guestRates: guestRates ?? this.guestRates,
      focPayCount: focPayCount ?? this.focPayCount,
      focFreeCount: focFreeCount ?? this.focFreeCount,
      focAppliesTo: focAppliesTo ?? this.focAppliesTo,
      listingKind: listingKind ?? this.listingKind,
      publishStatus: publishStatus ?? this.publishStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      featuredAt: identical(featuredAt, _unset)
          ? this.featuredAt
          : featuredAt as DateTime?,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNote: reviewNote ?? this.reviewNote,
      submittedByUid: submittedByUid ?? this.submittedByUid,
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
      'category': category.firestoreValue,
      if (detail.isNotEmpty) 'detail': detail,
      if (photoUrls.isNotEmpty) 'photo_urls': photoUrls,
      if (itineraryDays.isNotEmpty)
        'itinerary_days': [for (final day in itineraryDays) day.toMap()],
      if (guestRates.isNotEmpty)
        'guest_rates': [for (final rate in guestRates) rate.toMap()],
      if (focPayCount > 0) 'foc_pay_count': focPayCount,
      if (focFreeCount > 0) 'foc_free_count': focFreeCount,
      if (focPayCount > 0) 'foc_applies_to': focAppliesTo.firestoreValue,
      'listing_kind': listingKind.firestoreValue,
      'publish_status': publishStatus.firestoreValue,
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
      if (featuredAt != null) 'featured_at': featuredAt!.toIso8601String(),
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (reviewNote.isNotEmpty) 'review_note': reviewNote,
      if (submittedByUid.isNotEmpty) 'submitted_by_uid': submittedByUid,
    };
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  static List<ItineraryDay> _days(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <ItineraryDay>[];
    for (final item in raw) {
      final map = mapFrom(item);
      if (map != null) {
        out.add(ItineraryDay.fromMap(map));
      }
    }
    return out;
  }

  static List<GuestRate> _rates(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <GuestRate>[];
    for (final item in raw) {
      final map = mapFrom(item);
      if (map != null) {
        out.add(GuestRate.fromMap(map));
      }
    }
    return out;
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
