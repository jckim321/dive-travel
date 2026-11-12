import 'package:dive_travel_app/core/models/shop_product.dart';

class BookingLine {
  const BookingLine({
    required this.label,
    required this.amount,
  });

  final String label;
  final int amount;

  Map<String, dynamic> toMap() => {
        'label': label,
        'amount': amount,
      };

  static BookingLine? fromMap(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final data = Map<String, dynamic>.from(raw);
    final label = data['label'] as String? ?? '';
    if (label.isEmpty) {
      return null;
    }
    return BookingLine(
      label: label,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
    );
  }

  static List<BookingLine> listFrom(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw) ?fromMap(item),
    ];
  }
}

/// Per-role snapshot stored beside [BookingLine]s. Amounts are copies of
/// [BookingQuote.compute], not a second price.
class BookingPartyLine {
  const BookingPartyLine({
    required this.kind,
    required this.count,
    required this.unit,
    required this.amount,
  });

  static const kinds = <String>{
    'diver',
    'nondiver',
    'child',
    'infant',
    'foc',
    'single_room',
  };

  final String kind;
  final int count;
  final int unit;
  final int amount;

  Map<String, dynamic> toMap() => {
        'kind': kind,
        'count': count,
        'unit': unit,
        'amount': amount,
      };

  static BookingPartyLine? fromMap(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final data = Map<String, dynamic>.from(raw);
    final kind = data['kind'] as String? ?? '';
    if (!kinds.contains(kind)) {
      return null;
    }
    return BookingPartyLine(
      kind: kind,
      count: (data['count'] as num?)?.toInt() ?? 0,
      unit: (data['unit'] as num?)?.toInt() ?? 0,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
    );
  }

  static List<BookingPartyLine> listFrom(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw) ?fromMap(item),
    ];
  }
}

class BookingQuote {
  const BookingQuote({
    required this.lines,
    required this.total,
    required this.freeDivers,
    this.partyLines = const [],
  });

  final List<BookingLine> lines;
  final int total;
  final int freeDivers;
  final List<BookingPartyLine> partyLines;

  static int freeCount({
    required int guests,
    required int focPay,
    required int focFree,
  }) {
    if (guests <= 0 || focPay <= 0 || focFree <= 0) {
      return 0;
    }
    return (guests ~/ (focPay + focFree)) * focFree;
  }

  static int rolePrice({
    required ShopProduct product,
    required GuestRole role,
    required bool professional,
    DateTime? departure,
  }) {
    GuestRate? listed;
    for (final rate in product.resolvedGuestRates) {
      if (rate.role == role) {
        listed = rate;
        break;
      }
    }
    if (listed == null) {
      if (role == GuestRole.diver) {
        return professional ? product.professionalPrice : product.consumerPrice;
      }
      return 0;
    }
    final peak = _peakRoleRate(product, role, departure);
    final rate = peak ?? listed;
    if (!rate.enabled) {
      return 0;
    }
    return professional ? rate.professional : rate.consumer;
  }

  /// The season rate [ShopProduct.rateForRole] would return, or null when
  /// the day is outside a single peak window or that window has no [role].
  static GuestRate? _peakRoleRate(
    ShopProduct product,
    GuestRole role,
    DateTime? departure,
  ) {
    if (departure == null) {
      return null;
    }
    final target = DateTime(departure.year, departure.month, departure.day);
    PeakSeason? only;
    var matches = 0;
    for (final season in product.peakSeasons) {
      final start = PeakSeason.parseDay(season.start);
      final end = PeakSeason.parseDay(season.end);
      if (start == null || end == null || end.isBefore(start)) {
        continue;
      }
      if (!target.isBefore(start) && !target.isAfter(end)) {
        matches += 1;
        only = season;
      }
    }
    if (matches != 1 || only == null) {
      return null;
    }
    for (final rate in only.rates) {
      if (rate.role != role) {
        continue;
      }
      return product.rateForRole(departure, role);
    }
    return null;
  }

  static int optionUnit({
    required ShopProductOption option,
    required bool professional,
  }) {
    return professional ? option.professionalPrice : option.consumerPrice;
  }

  static int guestsForRole({
    required GuestRole role,
    required int divers,
    required int nondivers,
    required int children,
    required int infants,
  }) {
    switch (role) {
      case GuestRole.diver:
        return divers;
      case GuestRole.nondiver:
        return nondivers;
      case GuestRole.child:
        return children;
      case GuestRole.infant:
        return infants;
    }
  }

  static BookingQuote compute({
    required ShopProduct product,
    required bool professional,
    required int divers,
    required int nondivers,
    required int children,
    required int infants,
    required bool bookPackage,
    required Set<String> selectedOptionIds,
    Map<String, int>? optionQuantities,
    int singleRooms = 0,
    DateTime? departure,
  }) {
    final lines = <BookingLine>[];
    final partyLines = <BookingPartyLine>[];
    var total = 0;
    final freeDivers = product.focAppliesTo == GuestRole.diver
        ? freeCount(
            guests: divers,
            focPay: product.focPayCount,
            focFree: product.focFreeCount,
          )
        : 0;

    int billed(GuestRole role, int count) {
      var n = count;
      if (role == product.focAppliesTo) {
        n = count -
            freeCount(
              guests: count,
              focPay: product.focPayCount,
              focFree: product.focFreeCount,
            );
      }
      return n * rolePrice(
        product: product,
        role: role,
        professional: professional,
        departure: departure,
      );
    }

    int quantityFor(ShopProductOption option) {
      if (optionQuantities != null) {
        return optionQuantities[option.id] ?? 0;
      }
      return guestsForRole(
        role: option.guestRole,
        divers: divers,
        nondivers: nondivers,
        children: children,
        infants: infants,
      );
    }

    if (bookPackage) {
      final packageAmount = billed(GuestRole.diver, divers) +
          billed(GuestRole.nondiver, nondivers) +
          billed(GuestRole.child, children) +
          billed(GuestRole.infant, infants);
      lines.add(BookingLine(label: product.name, amount: packageAmount));
      total += packageAmount;
      for (final option in product.options) {
        if (!option.bookable ||
            option.kind != ProductOptionKind.addon ||
            option.parentOptionId.isNotEmpty ||
            !selectedOptionIds.contains(option.id)) {
          continue;
        }
        final qty = quantityFor(option);
        if (qty <= 0) {
          continue;
        }
        final amount =
            qty * optionUnit(option: option, professional: professional);
        lines.add(BookingLine(label: option.name, amount: amount));
        total += amount;
      }
      if (singleRooms >= 1 &&
          product.singleSupplement >= 1 &&
          product.nights >= 1) {
        final amount =
            singleRooms * product.singleSupplement * product.nights;
        lines.add(BookingLine(label: '1인 1실 추가', amount: amount));
        total += amount;
      }
      final roleLines = <BookingPartyLine>[];
      var roleSum = 0;
      void takeRole(GuestRole role, int heads, String kind) {
        if (heads <= 0) {
          return;
        }
        final free = role == product.focAppliesTo
            ? freeCount(
                guests: heads,
                focPay: product.focPayCount,
                focFree: product.focFreeCount,
              )
            : 0;
        final unit = rolePrice(
          product: product,
          role: role,
          professional: professional,
          departure: departure,
        );
        final billedCount = heads - free;
        final amount = billed(role, heads);
        if (billedCount > 0) {
          roleLines.add(
            BookingPartyLine(
              kind: kind,
              count: billedCount,
              unit: unit,
              amount: amount,
            ),
          );
          roleSum += amount;
        }
        if (free >= 1) {
          roleLines.add(
            BookingPartyLine(
              kind: 'foc',
              count: free,
              unit: 0,
              amount: 0,
            ),
          );
        }
      }

      takeRole(GuestRole.diver, divers, 'diver');
      takeRole(GuestRole.nondiver, nondivers, 'nondiver');
      takeRole(GuestRole.child, children, 'child');
      takeRole(GuestRole.infant, infants, 'infant');
      if (roleSum == packageAmount) {
        partyLines.addAll(roleLines);
        if (singleRooms >= 1 &&
            product.singleSupplement >= 1 &&
            product.nights >= 1) {
          partyLines.add(
            BookingPartyLine(
              kind: 'single_room',
              count: singleRooms,
              unit: product.singleSupplement * product.nights,
              amount: singleRooms * product.singleSupplement * product.nights,
            ),
          );
        }
      }
    } else {
      for (final option in product.options) {
        if (!option.bookable || !selectedOptionIds.contains(option.id)) {
          continue;
        }
        if (option.kind != ProductOptionKind.individual &&
            option.kind != ProductOptionKind.addon) {
          continue;
        }
        final qty = quantityFor(option);
        if (qty <= 0) {
          continue;
        }
        final amount =
            qty * optionUnit(option: option, professional: professional);
        lines.add(BookingLine(label: option.name, amount: amount));
        total += amount;
      }
    }

    return BookingQuote(
      lines: lines,
      total: total,
      freeDivers: freeDivers,
      partyLines: partyLines,
    );
  }
}
