import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

ShopProduct _trip({
  required String id,
  required bool open,
  DateTime? departure,
  DateTime? flag,
  DateTime? opened,
  int capacity = 3,
  int booked = 0,
}) {
  return ShopProduct(
    id: id,
    shopId: 's',
    name: id,
    consumerPrice: 1,
    professionalPrice: 1,
    openEmptySeats: open,
    sameBoatStatus: open ? SameBoatStatus.approved : SameBoatStatus.closed,
    sameBoatOpenedAt: opened,
    capacity: open ? capacity : 0,
    bookedSeats: booked,
    departureStart: departure,
    flagClosesAt: flag,
  );
}

void main() {
  test('board lists open seats newest first and skips closed', () {
    final older = _trip(
      id: 'older',
      open: true,
      departure: DateTime(2026, 12, 20),
      opened: DateTime(2026, 10, 1),
    );
    final newer = _trip(
      id: 'newer',
      open: true,
      departure: DateTime(2026, 11, 10),
      opened: DateTime(2026, 10, 20),
    );
    final closed = _trip(
      id: 'explore',
      open: false,
      departure: DateTime(2026, 11, 1),
    );
    final listed = SameBoatBoard.sorted([closed, older, newer]);
    expect([for (final item in listed) item.id], ['newer', 'older']);
  });

  test('past departure and sold-out leave the list without a status write', () {
    final now = DateTime(2026, 10, 27, 9);
    final past = _trip(
      id: 'past',
      open: true,
      departure: DateTime(2026, 10, 26),
      opened: DateTime(2026, 10, 1),
    );
    final today = _trip(
      id: 'today',
      open: true,
      departure: DateTime(2026, 10, 27),
      opened: DateTime(2026, 10, 2),
    );
    final sold = _trip(
      id: 'sold',
      open: true,
      departure: DateTime(2026, 12, 1),
      opened: DateTime(2026, 10, 3),
      capacity: 3,
      booked: 3,
    );
    final open = _trip(
      id: 'open',
      open: true,
      departure: DateTime(2026, 12, 1),
      opened: DateTime(2026, 10, 4),
      capacity: 4,
      booked: 1,
    );
    final listed = SameBoatBoard.offers(
      [past, today, sold, open],
      now: now,
    );
    expect([for (final item in listed) item.product.id], ['open', 'today']);
    expect(past.sameBoatStatus, SameBoatStatus.approved);
    expect(sold.sameBoatStatus, SameBoatStatus.approved);
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

  test('results keep departed, sold-out, and closed seats', () {
    final now = DateTime(2026, 10, 27, 9);
    ShopProduct seat({
      required String id,
      required SameBoatStatus status,
      required DateTime departure,
      DateTime? opened,
      int booked = 0,
      int capacity = 4,
      bool open = true,
    }) {
      return ShopProduct(
        id: id,
        shopId: 's',
        name: id,
        consumerPrice: 1,
        professionalPrice: 1,
        openEmptySeats: open,
        sameBoatStatus: status,
        sameBoatOpenedAt: opened,
        capacity: capacity,
        bookedSeats: booked,
        departureStart: departure,
      );
    }

    final past = seat(
      id: 'past',
      status: SameBoatStatus.approved,
      departure: DateTime(2026, 10, 26),
      opened: DateTime(2026, 10, 1),
    );
    final sold = seat(
      id: 'sold',
      status: SameBoatStatus.approved,
      departure: DateTime(2026, 12, 1),
      opened: DateTime(2026, 10, 3),
      booked: 4,
    );
    final closed = seat(
      id: 'closed',
      status: SameBoatStatus.closed,
      departure: DateTime(2026, 12, 1),
      opened: DateTime(2026, 10, 4),
      open: false,
    );
    final today = seat(
      id: 'today',
      status: SameBoatStatus.approved,
      departure: DateTime(2026, 10, 27),
      opened: DateTime(2026, 10, 5),
    );
    final hidden = seat(
      id: 'hidden',
      status: SameBoatStatus.hidden,
      departure: DateTime(2026, 10, 20),
      opened: DateTime(2026, 10, 2),
    );
    final rejected = seat(
      id: 'rejected',
      status: SameBoatStatus.rejected,
      departure: DateTime(2026, 10, 20),
      opened: DateTime(2026, 10, 6),
    );
    final never = seat(
      id: 'never',
      status: SameBoatStatus.closed,
      departure: DateTime(2026, 12, 1),
      open: false,
    );
    final listed = SameBoatBoard.results(
      [past, sold, closed, today, hidden, rejected, never],
      now: now,
    );
    expect(
      [for (final item in listed) item.product.id],
      ['closed', 'sold', 'past'],
    );
  });
}
