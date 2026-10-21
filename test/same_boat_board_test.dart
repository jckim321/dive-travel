import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

ShopProduct _trip({
  required String id,
  required bool open,
  DateTime? departure,
  DateTime? flag,
}) {
  return ShopProduct(
    id: id,
    shopId: 's',
    name: id,
    consumerPrice: 1,
    professionalPrice: 1,
    openEmptySeats: open,
    sameBoatStatus: open ? SameBoatStatus.approved : SameBoatStatus.closed,
    capacity: open ? 3 : 0,
    departureStart: departure,
    flagClosesAt: flag,
  );
}

void main() {
  test('board keeps only opted-in products and sorts by the sooner date', () {
    final soonFlag = _trip(
      id: 'flag',
      open: true,
      departure: DateTime(2026, 12, 20),
      flag: DateTime(2026, 11, 2),
    );
    final soonDepart = _trip(
      id: 'depart',
      open: true,
      departure: DateTime(2026, 11, 10),
      flag: DateTime(2026, 12, 1),
    );
    final closed = _trip(
      id: 'explore',
      open: false,
      departure: DateTime(2026, 11, 1),
    );
    final listed = SameBoatBoard.sorted([closed, soonDepart, soonFlag]);
    expect([for (final item in listed) item.id], ['flag', 'depart']);
  });

  test('last-call filter uses the flag window', () {
    final now = DateTime(2026, 10, 19);
    final closing = _trip(
      id: 'close',
      open: true,
      departure: DateTime(2026, 12, 1),
      flag: DateTime(2026, 10, 25),
    );
    final later = _trip(
      id: 'later',
      open: true,
      departure: DateTime(2026, 12, 20),
      flag: DateTime(2026, 12, 10),
    );
    final listed = SameBoatBoard.filtered(
      [later, closing],
      SameBoatFilter.lastCall,
      now,
    );
    expect([for (final item in listed) item.id], ['close']);
  });
}
