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

/// Leftover-seat listing for the same-boat board (separate from Explore publish).
enum SameBoatStatus {
  closed,
  pending,
  approved,
  rejected;

  static SameBoatStatus parse(dynamic value, {bool openEmptySeats = false}) {
    switch (value) {
      case 'pending':
        return SameBoatStatus.pending;
      case 'approved':
        return SameBoatStatus.approved;
      case 'rejected':
        return SameBoatStatus.rejected;
      case 'closed':
        return SameBoatStatus.closed;
      default:
        // Legacy docs with open seats and no status stay live on the board.
        return openEmptySeats
            ? SameBoatStatus.approved
            : SameBoatStatus.closed;
    }
  }

  String get firestoreValue {
    switch (this) {
      case SameBoatStatus.closed:
        return 'closed';
      case SameBoatStatus.pending:
        return 'pending';
      case SameBoatStatus.approved:
        return 'approved';
      case SameBoatStatus.rejected:
        return 'rejected';
    }
  }

  bool get isBoardLive => this == SameBoatStatus.approved;
  bool get isPendingReview => this == SameBoatStatus.pending;
}

/// Where a saved product should sit after the writer finishes the brief.
enum ProductSaveIntent {
  /// Keep the words, leave it off the guest list.
  keepEditing,

  /// Hand it to the admin queue.
  submitForReview,

  /// Admin puts it on the public trip list.
  publish,

  /// Leave the words and the approval, hide it from guests.
  takeDown,

  /// Keep Explore publish/active as-is (same-boat seat patches only).
  preserveListing,
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
  const ItineraryDay({required this.day, this.title = '', this.body = ''});

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

  Map<String, dynamic> toMap() => {'day': day, 'title': title, 'body': body};
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

  GuestRate copyWith({bool? enabled, int? consumer, int? professional}) {
    return GuestRate(
      role: role,
      enabled: enabled ?? this.enabled,
      consumer: consumer ?? this.consumer,
      professional: professional ?? this.professional,
    );
  }
}

class SeatHold {
  const SeatHold({required this.seats, required this.expiresAt, this.uid = ''});

  final int seats;
  final DateTime expiresAt;
  final String uid;

  Map<String, dynamic> toMap() {
    return {
      'seats': seats,
      'expires_at': expiresAt.toIso8601String(),
      if (uid.isNotEmpty) 'uid': uid,
    };
  }

  static SeatHold? fromMap(Map<String, dynamic> data) {
    final seats = (data['seats'] as num?)?.toInt() ?? 0;
    final raw = data['expires_at'];
    final expires = raw is String ? DateTime.tryParse(raw) : null;
    if (seats <= 0 || expires == null) {
      return null;
    }
    return SeatHold(
      seats: seats,
      expiresAt: expires,
      uid: data['uid'] as String? ?? '',
    );
  }
}

enum SeatFlagPlant { planted, alreadyHeld, unavailable }

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
    this.openEmptySeats = false,
    this.capacity = 0,
    this.bookedSeats = 0,
    this.flagHolds = const [],
    this.departureStart,
    this.flagClosesAt,
    this.parentOptionId = '',
    this.sameBoatStatus = SameBoatStatus.closed,
  });

  factory ShopProductOption.fromMap(Map<String, dynamic> data) {
    final open = data['open_empty_seats'] == true;
    return ShopProductOption(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      consumerPrice: (data['consumer_price'] as num?)?.toInt() ?? 0,
      professionalPrice: (data['professional_price'] as num?)?.toInt() ?? 0,
      kind: ProductOptionKind.parse(data['kind']),
      bookable: data['bookable'] != false,
      guestRole: GuestRole.parse(data['guest_role']),
      openEmptySeats: open,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      bookedSeats: (data['booked_seats'] as num?)?.toInt() ?? 0,
      flagHolds: _optionHolds(data['flag_holds']),
      departureStart: _optionTime(data['departure_start']),
      flagClosesAt: _optionTime(data['flag_closes_at']),
      parentOptionId: data['parent_option_id'] as String? ?? '',
      sameBoatStatus: SameBoatStatus.parse(
        data['same_boat_status'],
        openEmptySeats: open,
      ),
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
  final bool openEmptySeats;
  final int capacity;
  final int bookedSeats;
  final List<SeatHold> flagHolds;
  final DateTime? departureStart;
  final DateTime? flagClosesAt;

  /// When set, this addon belongs to an individual SKU (not the base package).
  final String parentOptionId;
  final SameBoatStatus sameBoatStatus;

  bool get listsOnSameBoat {
    return openEmptySeats &&
        capacity > 0 &&
        departureStart != null &&
        sameBoatStatus.isBoardLive;
  }

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
      'open_empty_seats': openEmptySeats,
      'same_boat_status': sameBoatStatus.firestoreValue,
      if (capacity > 0) 'capacity': capacity,
      if (bookedSeats > 0) 'booked_seats': bookedSeats,
      if (flagHolds.isNotEmpty)
        'flag_holds': [for (final hold in flagHolds) hold.toMap()],
      if (departureStart != null)
        'departure_start': departureStart!.toIso8601String(),
      if (flagClosesAt != null)
        'flag_closes_at': flagClosesAt!.toIso8601String(),
      if (parentOptionId.isNotEmpty) 'parent_option_id': parentOptionId,
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
    bool? openEmptySeats,
    int? capacity,
    int? bookedSeats,
    List<SeatHold>? flagHolds,
    DateTime? departureStart,
    DateTime? flagClosesAt,
    String? parentOptionId,
    SameBoatStatus? sameBoatStatus,
    bool clearDates = false,
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
      openEmptySeats: openEmptySeats ?? this.openEmptySeats,
      capacity: capacity ?? this.capacity,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      flagHolds: flagHolds ?? this.flagHolds,
      departureStart: clearDates
          ? null
          : (departureStart ?? this.departureStart),
      flagClosesAt: clearDates ? null : (flagClosesAt ?? this.flagClosesAt),
      parentOptionId: parentOptionId ?? this.parentOptionId,
      sameBoatStatus: sameBoatStatus ?? this.sameBoatStatus,
    );
  }

  static List<SeatHold> _optionHolds(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <SeatHold>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        final hold = SeatHold.fromMap(item);
        if (hold != null) {
          out.add(hold);
        }
      } else if (item is Map) {
        final hold = SeatHold.fromMap(Map<String, dynamic>.from(item));
        if (hold != null) {
          out.add(hold);
        }
      }
    }
    return out;
  }

  static DateTime? _optionTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
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
    this.openEmptySeats = false,
    this.capacity = 0,
    this.bookedSeats = 0,
    this.flagHolds = const [],
    this.departureStart,
    this.flagClosesAt,
    this.sameBoatStatus = SameBoatStatus.closed,
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
      openEmptySeats: data['open_empty_seats'] == true,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      bookedSeats: (data['booked_seats'] as num?)?.toInt() ?? 0,
      flagHolds: _holds(data['flag_holds']),
      departureStart: _readTime(data['departure_start']),
      flagClosesAt: _readTime(data['flag_closes_at']),
      sameBoatStatus: SameBoatStatus.parse(
        data['same_boat_status'],
        openEmptySeats: data['open_empty_seats'] == true,
      ),
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
  final bool openEmptySeats;
  final int capacity;
  final int bookedSeats;
  final List<SeatHold> flagHolds;
  final DateTime? departureStart;
  final DateTime? flagClosesAt;
  final SameBoatStatus sameBoatStatus;
  final ProductListingKind listingKind;
  final ProductPublishStatus publishStatus;
  final DateTime? submittedAt;

  /// When an admin last assigned this product to a home shelf.
  final DateTime? featuredAt;
  final DateTime? reviewedAt;
  final String reviewNote;

  /// Diver/partner who submitted this trip for approval.
  final String submittedByUid;

  bool get isPendingApproval => publishStatus == ProductPublishStatus.pending;

  bool get isListedPublicly => active && publishStatus.isPublic;

  /// Same-boat board only. Regular Explore listings ignore this.
  bool get listsOnSameBoat {
    return isListedPublicly &&
        openEmptySeats &&
        capacity > 0 &&
        departureStart != null &&
        sameBoatStatus.isBoardLive;
  }

  bool get hasPendingSameBoat {
    if (sameBoatStatus.isPendingReview) {
      return true;
    }
    for (final option in options) {
      if (option.sameBoatStatus.isPendingReview) {
        return true;
      }
    }
    return false;
  }

  bool get hasAnySameBoatOpen {
    if (openEmptySeats || sameBoatStatus != SameBoatStatus.closed) {
      return true;
    }
    for (final option in options) {
      if (option.openEmptySeats ||
          option.sameBoatStatus != SameBoatStatus.closed) {
        return true;
      }
    }
    return false;
  }

  int get flaggedSeats => flaggedSeatsAt(DateTime.now());

  int flaggedSeatsAt(DateTime now) {
    var total = 0;
    for (final hold in flagHolds) {
      if (hold.expiresAt.isAfter(now)) {
        total += hold.seats;
      }
    }
    return total;
  }

  int get remainingSeats => remainingSeatsAt(DateTime.now());

  int remainingSeatsAt(DateTime now) {
    final left = capacity - bookedSeats - flaggedSeatsAt(now);
    if (left < 0) {
      return 0;
    }
    return left;
  }

  static DateTime personalFlagUntil(
    DateTime plantedAt,
    DateTime? boatDeadline,
  ) {
    final day = plantedAt.add(const Duration(hours: 24));
    if (boatDeadline != null && boatDeadline.isBefore(day)) {
      return boatDeadline;
    }
    return day;
  }

  /// Board order: the earlier of departure and flag close.
  DateTime? get sameBoatSortAt {
    final start = departureStart;
    final flag = flagClosesAt;
    if (start == null) {
      return flag;
    }
    if (flag == null) {
      return start;
    }
    return start.isBefore(flag) ? start : flag;
  }

  bool memberHasLiveFlag(String uid, DateTime now, {String optionId = ''}) {
    if (uid.isEmpty) {
      return false;
    }
    final holds = _holdsFor(optionId);
    for (final hold in holds) {
      if (hold.uid == uid && hold.expiresAt.isAfter(now)) {
        return true;
      }
    }
    return false;
  }

  int bookedSeatsFor(String optionId) {
    if (optionId.isEmpty) {
      return bookedSeats;
    }
    return _option(optionId)?.bookedSeats ?? bookedSeats;
  }

  int bookableSeatsFor(String uid, DateTime now, {String optionId = ''}) {
    final holds = [
      for (final hold in _holdsFor(optionId))
        if (hold.expiresAt.isAfter(now)) hold,
    ];
    final booked = optionId.isEmpty
        ? bookedSeats
        : _option(optionId)?.bookedSeats ?? 0;
    final cap = optionId.isEmpty ? capacity : _option(optionId)?.capacity ?? 0;
    var own = 0;
    var flagged = 0;
    for (final hold in holds) {
      flagged += hold.seats;
      if (uid.isEmpty || hold.uid == uid) {
        own += hold.seats;
      }
    }
    final left = cap - booked - flagged + own;
    return left < 0 ? 0 : left;
  }

  ShopProduct plantFlag({
    required int partySize,
    required DateTime now,
    String uid = '',
    String optionId = '',
  }) {
    if (optionId.isNotEmpty) {
      return _mapOption(optionId, (option) {
        final planted = _plantHolds(
          open: option.openEmptySeats && option.sameBoatStatus.isBoardLive,
          capacity: option.capacity,
          booked: option.bookedSeats,
          holds: option.flagHolds,
          partySize: partySize,
          now: now,
          flagClosesAt: option.flagClosesAt,
          uid: uid,
        );
        return option.copyWith(flagHolds: planted);
      });
    }
    return copyWith(
      flagHolds: _plantHolds(
        open: openEmptySeats && sameBoatStatus.isBoardLive,
        capacity: capacity,
        booked: bookedSeats,
        holds: flagHolds,
        partySize: partySize,
        now: now,
        flagClosesAt: flagClosesAt,
        uid: uid,
      ),
    );
  }

  ShopProduct capturePayment(
    int partySize,
    DateTime now, {
    String uid = '',
    String optionId = '',
  }) {
    if (optionId.isNotEmpty) {
      return _mapOption(optionId, (option) {
        if (!_canCapture(
          open: option.openEmptySeats && option.sameBoatStatus.isBoardLive,
          capacity: option.capacity,
          booked: option.bookedSeats,
          holds: option.flagHolds,
          partySize: partySize,
          now: now,
          uid: uid,
        )) {
          return option;
        }
        final next = _consumeHolds(option.flagHolds, partySize, now, uid);
        return option.copyWith(
          flagHolds: next,
          bookedSeats: option.bookedSeats + partySize,
        );
      });
    }
    if (!_canCapture(
      open: openEmptySeats && sameBoatStatus.isBoardLive,
      capacity: capacity,
      booked: bookedSeats,
      holds: flagHolds,
      partySize: partySize,
      now: now,
      uid: uid,
    )) {
      return copyWith(flagHolds: _liveHolds(now));
    }
    return copyWith(
      flagHolds: _consumeHolds(flagHolds, partySize, now, uid),
      bookedSeats: bookedSeats + partySize,
    );
  }

  ShopProductOption? _option(String optionId) {
    for (final option in options) {
      if (option.id == optionId) {
        return option;
      }
    }
    return null;
  }

  List<SeatHold> _holdsFor(String optionId) {
    if (optionId.isEmpty) {
      return flagHolds;
    }
    return _option(optionId)?.flagHolds ?? const [];
  }

  ShopProduct _mapOption(
    String optionId,
    ShopProductOption Function(ShopProductOption option) update,
  ) {
    return copyWith(
      options: [
        for (final option in options)
          if (option.id == optionId) update(option) else option,
      ],
    );
  }

  List<SeatHold> _plantHolds({
    required bool open,
    required int capacity,
    required int booked,
    required List<SeatHold> holds,
    required int partySize,
    required DateTime now,
    required DateTime? flagClosesAt,
    required String uid,
  }) {
    final live = [
      for (final hold in holds)
        if (hold.expiresAt.isAfter(now)) hold,
    ];
    if (!open || partySize <= 0) {
      return live;
    }
    if (uid.isNotEmpty && live.any((hold) => hold.uid == uid)) {
      return live;
    }
    final openSeats = capacity - booked - _countHolds(live);
    if (openSeats <= 0) {
      return live;
    }
    final take = partySize > openSeats ? openSeats : partySize;
    return [
      ...live,
      SeatHold(
        seats: take,
        expiresAt: personalFlagUntil(now, flagClosesAt),
        uid: uid,
      ),
    ];
  }

  bool _canCapture({
    required bool open,
    required int capacity,
    required int booked,
    required List<SeatHold> holds,
    required int partySize,
    required DateTime now,
    required String uid,
  }) {
    if (!open || partySize <= 0) {
      return false;
    }
    final live = [
      for (final hold in holds)
        if (hold.expiresAt.isAfter(now)) hold,
    ];
    var own = 0;
    var flagged = 0;
    for (final hold in live) {
      flagged += hold.seats;
      if (uid.isEmpty || hold.uid == uid) {
        own += hold.seats;
      }
    }
    final room = capacity - booked - flagged + own;
    return partySize <= room;
  }

  List<SeatHold> _consumeHolds(
    List<SeatHold> holds,
    int partySize,
    DateTime now,
    String uid,
  ) {
    final live = [
      for (final hold in holds)
        if (hold.expiresAt.isAfter(now)) hold,
    ];
    var left = partySize;
    final next = <SeatHold>[];
    for (final hold in live) {
      final mine = uid.isEmpty || hold.uid == uid;
      if (!mine || left <= 0) {
        next.add(hold);
        continue;
      }
      if (hold.seats <= left) {
        left -= hold.seats;
        continue;
      }
      next.add(
        SeatHold(
          seats: hold.seats - left,
          expiresAt: hold.expiresAt,
          uid: hold.uid,
        ),
      );
      left = 0;
    }
    return next;
  }

  List<SeatHold> _liveHolds(DateTime now) {
    return [
      for (final hold in flagHolds)
        if (hold.expiresAt.isAfter(now)) hold,
    ];
  }

  int _countHolds(List<SeatHold> holds) {
    var total = 0;
    for (final hold in holds) {
      total += hold.seats;
    }
    return total;
  }

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
    bool? openEmptySeats,
    int? capacity,
    int? bookedSeats,
    List<SeatHold>? flagHolds,
    Object? departureStart = _unset,
    Object? flagClosesAt = _unset,
    SameBoatStatus? sameBoatStatus,
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
      openEmptySeats: openEmptySeats ?? this.openEmptySeats,
      capacity: capacity ?? this.capacity,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      flagHolds: flagHolds ?? this.flagHolds,
      departureStart: identical(departureStart, _unset)
          ? this.departureStart
          : departureStart as DateTime?,
      flagClosesAt: identical(flagClosesAt, _unset)
          ? this.flagClosesAt
          : flagClosesAt as DateTime?,
      sameBoatStatus: sameBoatStatus ?? this.sameBoatStatus,
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
      'open_empty_seats': openEmptySeats,
      'same_boat_status': sameBoatStatus.firestoreValue,
      if (capacity > 0) 'capacity': capacity,
      if (bookedSeats > 0) 'booked_seats': bookedSeats,
      if (flagHolds.isNotEmpty)
        'flag_holds': [for (final hold in flagHolds) hold.toMap()],
      if (departureStart != null)
        'departure_start': departureStart!.toIso8601String(),
      if (flagClosesAt != null)
        'flag_closes_at': flagClosesAt!.toIso8601String(),
      'listing_kind': listingKind.firestoreValue,
      'publish_status': publishStatus.firestoreValue,
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
      if (featuredAt != null) 'featured_at': featuredAt!.toIso8601String(),
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (reviewNote.isNotEmpty) 'review_note': reviewNote,
      if (submittedByUid.isNotEmpty) 'submitted_by_uid': submittedByUid,
    };
  }

  static List<SeatHold> _holds(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <SeatHold>[];
    for (final item in raw) {
      final map = mapFrom(item);
      if (map != null) {
        final hold = SeatHold.fromMap(map);
        if (hold != null) {
          out.add(hold);
        }
      }
    }
    return out;
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
