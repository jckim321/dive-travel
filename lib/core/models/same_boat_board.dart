import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
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

  DateTime? get openedAt =>
      option?.sameBoatOpenedAt ?? product.sameBoatOpenedAt;

  DateTime? get listSortAt =>
      openedAt ?? product.submittedAt ?? departureStart;
}

enum SameBoatFilter { all, lastCall, departing }

abstract final class SameBoatBoard {
  static const window = Duration(days: 14);

  static List<ShopProduct> sorted(
    Iterable<ShopProduct> products, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final listed = [
      for (final product in products)
        if (product.listsOnSameBoat &&
            !SameBoatSeatOpenLogic.isFinishedListing(
              departure: product.departureStart,
              capacity: product.capacity,
              booked: product.bookedSeats,
              now: clock,
            ))
          product,
    ];
    listed.sort((a, b) => _newestFirst(
      a.sameBoatOpenedAt ?? a.submittedAt ?? a.departureStart,
      b.sameBoatOpenedAt ?? b.submittedAt ?? b.departureStart,
    ));
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

  static List<SameBoatOffer> offers(
    Iterable<ShopProduct> products, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final listed = <SameBoatOffer>[];
    for (final product in products) {
      if (!product.isListedPublicly) {
        continue;
      }
      // Product-level and option-level can both list at once.
      if (product.listsOnSameBoat) {
        final offer = SameBoatOffer(product: product);
        if (!_finished(offer, clock)) {
          listed.add(offer);
        }
      }
      for (final option in product.options) {
        if (option.listsOnSameBoat) {
          final offer = SameBoatOffer(product: product, option: option);
          if (!_finished(offer, clock)) {
            listed.add(offer);
          }
        }
      }
    }
    listed.sort((a, b) => _newestFirst(a.listSortAt, b.listSortAt));
    return listed;
  }

  /// Finished seats kept under the live board. Hidden and rejected stay off.
  static List<SameBoatOffer> results(
    Iterable<ShopProduct> products, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final listed = <SameBoatOffer>[];
    for (final product in products) {
      if (!product.isListedPublicly) {
        continue;
      }
      if (_isResult(
        status: product.sameBoatStatus,
        openEmptySeats: product.openEmptySeats,
        openedAt: product.sameBoatOpenedAt,
        capacity: product.capacity,
        booked: product.bookedSeats,
        departure: product.departureStart,
        now: clock,
      )) {
        listed.add(SameBoatOffer(product: product));
      }
      for (final option in product.options) {
        if (_isResult(
          status: option.sameBoatStatus,
          openEmptySeats: option.openEmptySeats,
          openedAt: option.sameBoatOpenedAt,
          capacity: option.capacity,
          booked: option.bookedSeats,
          departure: option.departureStart,
          now: clock,
        )) {
          listed.add(SameBoatOffer(product: product, option: option));
        }
      }
    }
    listed.sort((a, b) => _newestFirst(a.listSortAt, b.listSortAt));
    return listed;
  }

  static bool _isResult({
    required SameBoatStatus status,
    required bool openEmptySeats,
    required DateTime? openedAt,
    required int capacity,
    required int booked,
    required DateTime? departure,
    required DateTime now,
  }) {
    if (status == SameBoatStatus.hidden || status == SameBoatStatus.rejected) {
      return false;
    }
    if (capacity <= 0 || departure == null) {
      return false;
    }
    final wasOpened = openEmptySeats || openedAt != null || booked > 0;
    if (!wasOpened) {
      return false;
    }
    if (status == SameBoatStatus.closed) {
      return true;
    }
    return SameBoatSeatOpenLogic.isFinishedListing(
      departure: departure,
      capacity: capacity,
      booked: booked,
      now: now,
    );
  }

  static bool _finished(SameBoatOffer offer, DateTime now) {
    return SameBoatSeatOpenLogic.isFinishedListing(
      departure: offer.departureStart,
      capacity: offer.capacity,
      booked: offer.bookedSeats,
      now: now,
    );
  }

  static int _newestFirst(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }
    return b.compareTo(a);
  }

  static List<SameBoatOffer> filteredOffers(
    Iterable<ShopProduct> products,
    SameBoatFilter filter,
    DateTime now,
  ) {
    final listed = offers(products, now: now);
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
