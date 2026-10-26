import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seat_open_fields.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

ShopProduct _base({
  bool open = false,
  SameBoatStatus status = SameBoatStatus.closed,
  int capacity = 0,
  int booked = 0,
  List<SeatHold> holds = const [],
  DateTime? departure,
  DateTime? flag,
  List<ShopProductOption> options = const [],
}) {
  return ShopProduct(
    id: 'p1',
    shopId: 's1',
    name: 'Trip',
    consumerPrice: 1,
    professionalPrice: 1,
    openEmptySeats: open,
    sameBoatStatus: status,
    capacity: capacity,
    bookedSeats: booked,
    flagHolds: holds,
    departureStart: departure ?? (open ? DateTime(2026, 11, 1) : null),
    flagClosesAt: flag,
    options: options,
    publishStatus: ProductPublishStatus.approved,
  );
}

void main() {
  test('10 + pre-booked 4 → meter black 4 + open 6; pending is listed', () {
    final pending = _base(
      open: true,
      status: SameBoatStatus.pending,
      capacity: 10,
      booked: 4,
      flag: DateTime(2026, 10, 28),
    );
    expect(pending.listsOnSameBoat, isTrue);
    expect(SameBoatBoard.offers([pending], now: DateTime(2026, 10, 20)), isNotEmpty);

    final live = pending.copyWith(sameBoatStatus: SameBoatStatus.approved);
    expect(live.listsOnSameBoat, isTrue);
    expect(SameBoatSeatOpenLogic.openPreviewSeats(capacity: 10, booked: 4), 6);
    final offer = SameBoatBoard.offers([live]).single;
    expect(offer.bookedSeats, 4);
    expect(offer.capacity, 10);
    expect(offer.remainingSeatsAt(DateTime(2026, 10, 20)), 6);
  });

  test('board lists product-level and option-level at once', () {
    final cabin = ShopProductOption(
      id: 'cabin',
      name: 'Cabin',
      description: '',
      openEmptySeats: true,
      sameBoatStatus: SameBoatStatus.approved,
      capacity: 2,
      departureStart: DateTime(2026, 11, 2),
    );
    final product = _base(
      open: true,
      status: SameBoatStatus.approved,
      capacity: 8,
      departure: DateTime(2026, 11, 1),
      options: [cabin],
    );
    final offers = SameBoatBoard.offers([product]);
    expect(offers.length, 2);
    expect(offers.any((o) => o.option == null), isTrue);
    expect(offers.any((o) => o.optionId == 'cabin'), isTrue);
  });

  test('(a) re-save keeps booked_seats and flag_holds', () {
    final now = DateTime(2026, 10, 20, 12);
    final hold = SeatHold(
      seats: 2,
      expiresAt: now.add(const Duration(hours: 24)),
      uid: 'u1',
    );
    final existing = _base(
      open: true,
      status: SameBoatStatus.approved,
      capacity: 10,
      booked: 4,
      holds: [hold],
      flag: DateTime(2026, 10, 28),
    );
    final controller = SameBoatSeatOpenController(
      existing: existing,
      optionSlots: const [],
      isAdmin: true,
    );
    // Form "already booked" text would lie if applied — must not overwrite.
    controller.packageBooked.text = '99';
    controller.packageCapacity.text = '10';
    final next = controller.applyToProduct(existing.copyWith(includes: '가이드'));
    expect(next.bookedSeats, 4);
    expect(next.flagHolds.length, 1);
    expect(next.flagHolds.single.uid, 'u1');
    expect(next.includes, '가이드');
    controller.dispose();
  });

  test('(b) capacity below booked + live holds is blocked', () {
    final now = DateTime(2026, 10, 20, 12);
    final hold = SeatHold(
      seats: 3,
      expiresAt: now.add(const Duration(hours: 12)),
      uid: 'u1',
    );
    final existing = _base(
      open: true,
      status: SameBoatStatus.approved,
      capacity: 10,
      booked: 4,
      holds: [hold],
      flag: DateTime(2026, 10, 28),
    );
    final controller = SameBoatSeatOpenController(
      existing: existing,
      optionSlots: const [],
      isAdmin: true,
    );
    controller.packageCapacity.text = '6'; // 4+3=7 occupied
    final l10n = lookupAppLocalizations(const Locale('ko'));
    final error = controller.validate(l10n, now: now);
    expect(error, isNotNull);
    expect(error, contains('4'));
    expect(error, contains('3'));
    controller.packageCapacity.text = '7';
    expect(controller.validate(l10n, now: now), isNull);
    controller.dispose();
  });

  test('(c) schedule lock follows booked seats and live flags', () {
    final now = DateTime(2026, 10, 27, 12);
    final booked = _base(
      open: true,
      status: SameBoatStatus.approved,
      capacity: 10,
      booked: 2,
      flag: DateTime(2026, 10, 28),
    );
    final partner = SameBoatSeatOpenController(
      existing: booked,
      optionSlots: const [],
      isAdmin: false,
      now: now,
    );
    final admin = SameBoatSeatOpenController(
      existing: booked,
      optionSlots: const [],
      isAdmin: true,
      now: now,
    );
    expect(partner.packageScheduleLocked, isTrue);
    expect(admin.packageScheduleLocked, isTrue);
    partner.dispose();
    admin.dispose();

    final clear = _base(
      open: true,
      status: SameBoatStatus.approved,
      capacity: 10,
    );
    final unlocked = SameBoatSeatOpenController(
      existing: clear,
      optionSlots: const [],
      isAdmin: false,
      now: now,
    );
    expect(unlocked.packageScheduleLocked, isFalse);
    unlocked.dispose();

    final liveHold = SeatHold(
      seats: 1,
      expiresAt: DateTime(2026, 10, 28),
      uid: 'u1',
    );
    final held = _base(
      open: true,
      status: SameBoatStatus.approved,
      capacity: 10,
      holds: [liveHold],
    );
    final lockedByFlag = SameBoatSeatOpenController(
      existing: held,
      optionSlots: const [],
      isAdmin: false,
      now: now,
    );
    expect(lockedByFlag.packageScheduleLocked, isTrue);
    lockedByFlag.dispose();

    final expired = SeatHold(
      seats: 1,
      expiresAt: DateTime(2026, 10, 26),
      uid: 'u1',
    );
    final stale = _base(
      open: true,
      status: SameBoatStatus.approved,
      capacity: 10,
      holds: [expired],
    );
    final unlockedFlag = SameBoatSeatOpenController(
      existing: stale,
      optionSlots: const [],
      isAdmin: false,
      now: now,
    );
    expect(unlockedFlag.packageScheduleLocked, isFalse);
    unlockedFlag.dispose();
  });

  test('(d) general simPayNotice unchanged; same-boat key is separate', () {
    final ko = lookupAppLocalizations(const Locale('ko'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(ko.simPayNotice, contains('지금은 결제하지 않습니다'));
    expect(en.simPayNotice.toLowerCase(), contains('no charge'));
    expect(ko.simPaySameBoatNotice, contains('확정'));
    expect(en.simPaySameBoatNotice.toLowerCase(), contains('confirm'));
    expect(ko.simPaySameBoatNotice, isNot(equals(ko.simPayNotice)));
  });

  test('first open writes form booked_seats; regular product stays closed', () {
    final fresh = _base();
    final controller = SameBoatSeatOpenController(
      existing: fresh,
      optionSlots: const [],
      isAdmin: true,
    );
    controller.openPackage = true;
    controller.packageCapacity.text = '10';
    controller.packageBooked.text = '4';
    controller.packageDeparture = DateTime(2026, 11, 1);
    controller.packageFlagClose = DateTime(2026, 10, 28);
    final opened = controller.applyToProduct(fresh);
    expect(opened.openEmptySeats, isTrue);
    expect(opened.bookedSeats, 4);
    expect(opened.capacity, 10);
    expect(opened.sameBoatStatus, SameBoatStatus.approved);
    controller.dispose();

    final off = SameBoatSeatOpenController(
      existing: fresh,
      optionSlots: const [],
      isAdmin: false,
    );
    expect(off.openPackage, isFalse);
    final closed = off.applyToProduct(fresh);
    expect(closed.openEmptySeats, isFalse);
    expect(closed.sameBoatStatus, SameBoatStatus.closed);
    off.dispose();
  });

  test('resolveBookedSeats only uses form on first open', () {
    expect(
      SameBoatSeatOpenLogic.resolveBookedSeats(
        nowOpen: true,
        wasAlreadyOpen: false,
        formBooked: 4,
        existingBooked: 0,
      ),
      4,
    );
    expect(
      SameBoatSeatOpenLogic.resolveBookedSeats(
        nowOpen: true,
        wasAlreadyOpen: true,
        formBooked: 99,
        existingBooked: 4,
      ),
      4,
    );
  });
}
