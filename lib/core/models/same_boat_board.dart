import 'package:dive_travel_app/core/models/shop_product.dart';

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
