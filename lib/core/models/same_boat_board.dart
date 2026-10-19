import 'package:dive_travel_app/core/models/shop_product.dart';

class SameBoatOffer {
  const SameBoatOffer({required this.product, this.option});

  final ShopProduct product;
  final ShopProductOption? option;

  String get optionId => option?.id ?? '';

  String get optionName => option?.name ?? '';

  String get optionDescription => option?.description ?? '';

  DateTime? get departureStart =>
      option?.departureStart ?? product.departureStart;

  DateTime? get flagClosesAt => option?.flagClosesAt ?? product.flagClosesAt;

  int get capacity => option?.capacity ?? product.capacity;

  int get bookedSeats => option?.bookedSeats ?? product.bookedSeats;

  int remainingSeatsAt(DateTime now) {
    final holds = option?.flagHolds ?? product.flagHolds;
    var flagged = 0;
    for (final hold in holds) {
      if (hold.expiresAt.isAfter(now)) {
        flagged += hold.seats;
      }
    }
    final left = capacity - bookedSeats - flagged;
    return left < 0 ? 0 : left;
  }

  int get remainingSeats => remainingSeatsAt(DateTime.now());

  int flaggedSeatsAt(DateTime now) {
    final holds = option?.flagHolds ?? product.flagHolds;
    var total = 0;
    for (final hold in holds) {
      if (hold.expiresAt.isAfter(now)) {
        total += hold.seats;
      }
    }
    return total;
  }

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
}

enum SameBoatFilter { all, lastCall, departing }

abstract final class SameBoatBoard {
  static const window = Duration(days: 14);

  static List<ShopProduct> sorted(Iterable<ShopProduct> products) {
    final listed = [
      for (final product in products)
        if (product.listsOnSameBoat) product,
    ];
    listed.sort((a, b) {
      final aAt = a.sameBoatSortAt ?? DateTime.utc(9999);
      final bAt = b.sameBoatSortAt ?? DateTime.utc(9999);
      return aAt.compareTo(bAt);
    });
    return listed;
  }

  static bool isLastCall(ShopProduct product, DateTime now) {
    final flag = product.flagClosesAt ?? product.departureStart;
    if (flag == null) {
      return false;
    }
    return !flag.isAfter(now.add(window));
  }

  static bool isDepartingSoon(ShopProduct product, DateTime now) {
    final start = product.departureStart;
    if (start == null) {
      return false;
    }
    return !start.isAfter(now.add(window));
  }

  static List<SameBoatOffer> offers(Iterable<ShopProduct> products) {
    final listed = <SameBoatOffer>[];
    for (final product in products) {
      if (!product.isListedPublicly) {
        continue;
      }
      final opened = [
        for (final option in product.options)
          if (option.listsOnSameBoat) option,
      ];
      if (opened.isNotEmpty) {
        for (final option in opened) {
          listed.add(SameBoatOffer(product: product, option: option));
        }
      } else if (product.listsOnSameBoat) {
        listed.add(SameBoatOffer(product: product));
      }
    }
    listed.sort((a, b) {
      final aAt = a.sameBoatSortAt ?? DateTime.utc(9999);
      final bAt = b.sameBoatSortAt ?? DateTime.utc(9999);
      return aAt.compareTo(bAt);
    });
    return listed;
  }

  static List<SameBoatOffer> filteredOffers(
    Iterable<ShopProduct> products,
    SameBoatFilter filter,
    DateTime now,
  ) {
    final listed = offers(products);
    return switch (filter) {
      SameBoatFilter.all => listed,
      SameBoatFilter.lastCall => [
        for (final offer in listed)
          if (_soon(offer.flagClosesAt ?? offer.departureStart, now)) offer,
      ],
      SameBoatFilter.departing => [
        for (final offer in listed)
          if (_soon(offer.departureStart, now)) offer,
      ],
    };
  }

  static bool _soon(DateTime? at, DateTime now) {
    if (at == null) {
      return false;
    }
    return !at.isAfter(now.add(window));
  }

  static List<ShopProduct> filtered(
    Iterable<ShopProduct> products,
    SameBoatFilter filter,
    DateTime now,
  ) {
    final listed = sorted(products);
    return switch (filter) {
      SameBoatFilter.all => listed,
      SameBoatFilter.lastCall => [
        for (final product in listed)
          if (isLastCall(product, now)) product,
      ],
      SameBoatFilter.departing => [
        for (final product in listed)
          if (isDepartingSoon(product, now)) product,
      ],
    };
  }
}
