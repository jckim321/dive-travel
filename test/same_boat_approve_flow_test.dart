import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seat_open_fields.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_hub_screen.dart';

ShopProduct _product({
  SameBoatStatus status = SameBoatStatus.closed,
  bool open = false,
  int capacity = 0,
  int booked = 0,
  DateTime? departure,
  ProductPublishStatus publish = ProductPublishStatus.approved,
  bool active = true,
  List<ShopProductOption> options = const [],
}) {
  return ShopProduct(
    id: 'p1',
    shopId: 'shop-a',
    name: 'Trip',
    consumerPrice: 100000,
    professionalPrice: 80000,
    openEmptySeats: open,
    sameBoatStatus: status,
    capacity: capacity,
    bookedSeats: booked,
    departureStart: departure,
    publishStatus: publish,
    active: active,
    options: options,
  );
}

ShopProductOption _option({
  required String id,
  SameBoatStatus status = SameBoatStatus.closed,
  bool open = false,
  int capacity = 0,
  int booked = 0,
  DateTime? departure,
}) {
  return ShopProductOption(
    id: id,
    name: id,
    description: '',
    openEmptySeats: open,
    sameBoatStatus: status,
    capacity: capacity,
    bookedSeats: booked,
    departureStart: departure,
  );
}

void main() {
  final departure = DateTime(2026, 11, 1);

  test('partner product open goes live immediately (H1a)', () {
    final closed = _product();
    final controller = SameBoatSeatOpenController(
      existing: closed,
      optionSlots: const [],
      isAdmin: false,
    );
    controller.openPackage = true;
    controller.packageCapacity.text = '10';
    controller.packageBooked.text = '4';
    controller.packageDeparture = departure;
    controller.packageFlagClose = DateTime(2026, 10, 28);
    final next = controller.applyToProduct(closed);
    controller.dispose();

    expect(next.sameBoatStatus, SameBoatStatus.approved);
    expect(next.openEmptySeats, isTrue);
    expect(next.capacity, 10);
    expect(next.bookedSeats, 4);
    expect(next.departureStart, departure);
    expect(next.publishStatus, ProductPublishStatus.approved);
    expect(next.active, isTrue);
    expect(next.hasPendingSameBoat, isFalse);
    expect(next.listsOnSameBoat, isTrue);
  });

  test('partner option-only open goes live immediately (H1a)', () {
    final cabin = _option(id: 'cabin');
    final product = _product(options: [cabin]);
    final controller = SameBoatSeatOpenController(
      existing: product,
      optionSlots: const [SameBoatOptionSeatSlot(id: 'cabin', name: 'Cabin')],
      isAdmin: false,
    );
    controller.options['cabin']!.open = true;
    controller.options['cabin']!.capacity.text = '2';
    controller.options['cabin']!.booked.text = '0';
    controller.options['cabin']!.departure = departure;
    controller.options['cabin']!.flagClose = DateTime(2026, 10, 28);
    final next = controller.applyToProduct(product);
    controller.dispose();

    expect(next.sameBoatStatus, SameBoatStatus.closed);
    expect(next.options.single.sameBoatStatus, SameBoatStatus.approved);
    expect(next.options.single.openEmptySeats, isTrue);
    expect(next.options.single.capacity, 2);
    expect(next.options.single.departureStart, departure);
    expect(next.hasPendingSameBoat, isFalse);
    expect(next.hasLiveSameBoatOffer, isTrue);
  });

  test('legacy pending re-save stays pending for partner (admin can still approve)', () {
    final pending = _product(
      open: true,
      status: SameBoatStatus.pending,
      capacity: 10,
      booked: 2,
      departure: departure,
    );
    final controller = SameBoatSeatOpenController(
      existing: pending,
      optionSlots: const [],
      isAdmin: false,
    );
    controller.openPackage = true;
    controller.packageCapacity.text = '10';
    final next = controller.applyToProduct(pending);
    controller.dispose();
    expect(next.sameBoatStatus, SameBoatStatus.pending);
  });

  test('blocksPartnerRequest while pending or live', () {
    final pending = _product(
      open: true,
      status: SameBoatStatus.pending,
      capacity: 10,
      departure: departure,
    );
    final live = pending.copyWith(sameBoatStatus: SameBoatStatus.approved);
    final closed = _product();
    expect(SameBoatSeatOpenLogic.blocksPartnerRequest(pending), isTrue);
    expect(SameBoatSeatOpenLogic.blocksPartnerRequest(live), isTrue);
    expect(SameBoatSeatOpenLogic.blocksPartnerRequest(closed), isFalse);
  });

  test('admin approve keeps seat fields and lists on board', () {
    final pending = _product(
      open: true,
      status: SameBoatStatus.pending,
      capacity: 10,
      booked: 4,
      departure: departure,
    );
    final approved = pending.copyWith(sameBoatStatus: SameBoatStatus.approved);
    expect(approved.capacity, 10);
    expect(approved.bookedSeats, 4);
    expect(approved.departureStart, departure);
    expect(approved.openEmptySeats, isTrue);
    expect(approved.listsOnSameBoat, isTrue);
    expect(SameBoatBoard.offers([approved]), isNotEmpty);
  });

  test('incomplete pending cannot be approved', () {
    final incomplete = _product(
      open: true,
      status: SameBoatStatus.pending,
      capacity: 0,
      departure: null,
    );
    final complete = _product(
      open: true,
      status: SameBoatStatus.pending,
      capacity: 8,
      departure: departure,
    );
    expect(SameBoatSeatOpenLogic.canApprovePending(incomplete), isFalse);
    expect(SameBoatSeatOpenLogic.canApprovePending(complete), isTrue);
  });

  test('incomplete option pending blocks approve', () {
    final product = _product(
      options: [
        _option(
          id: 'cabin',
          open: true,
          status: SameBoatStatus.pending,
          capacity: 0,
        ),
      ],
    );
    expect(product.hasPendingSameBoat, isTrue);
    expect(SameBoatSeatOpenLogic.canApprovePending(product), isFalse);

    final ready = _product(
      options: [
        _option(
          id: 'cabin',
          open: true,
          status: SameBoatStatus.pending,
          capacity: 2,
          departure: departure,
        ),
      ],
    );
    expect(SameBoatSeatOpenLogic.canApprovePending(ready), isTrue);
  });

  test('rejected stays off the board', () {
    final rejected = _product(
      open: true,
      status: SameBoatStatus.rejected,
      capacity: 10,
      departure: departure,
    );
    expect(rejected.listsOnSameBoat, isFalse);
    expect(SameBoatBoard.offers([rejected]), isEmpty);
    expect(rejected.hasRejectedSameBoat, isTrue);
  });

  test('hub pending filter includes option-only pending', () {
    final optionPending = _product(
      options: [
        _option(
          id: 'cabin',
          open: true,
          status: SameBoatStatus.pending,
          capacity: 2,
          departure: departure,
        ),
      ],
    );
    final listed = filterSameBoatHubProducts(
      products: [optionPending],
      status: SameBoatHubStatusFilter.pending,
    );
    expect(listed.map((p) => p.id), ['p1']);
  });
}
