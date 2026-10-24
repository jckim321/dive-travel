import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/price_revision.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

ShopProduct _approvedProduct({
  int consumer = 100_000,
  int pro = 80_000,
  List<ShopProductOption> options = const [],
  PriceRevision? priceRevision,
}) {
  return ShopProduct(
    id: 'p1',
    shopId: 'shop-1',
    name: 'Trip',
    consumerPrice: consumer,
    professionalPrice: pro,
    publishStatus: ProductPublishStatus.approved,
    active: true,
    options: options,
    priceRevision: priceRevision,
  );
}

ShopProductOption _option({
  String id = 'opt-1',
  int consumer = 10_000,
  int pro = 8_000,
  int bookedSeats = 0,
  List<SeatHold> holds = const [],
  ProductOptionKind kind = ProductOptionKind.addon,
  String parentOptionId = '',
}) {
  return ShopProductOption(
    id: id,
    name: 'Addon $id',
    description: '',
    consumerPrice: consumer,
    professionalPrice: pro,
    kind: kind,
    bookedSeats: bookedSeats,
    flagHolds: holds,
    parentOptionId: parentOptionId,
  );
}

void main() {
  test('stage: price change keeps live price, sets pending revision', () {
    final previous = _approvedProduct(
      consumer: 100_000,
      options: [_option(id: 'a', consumer: 5_000)],
    );
    final draft = previous.copyWith(
      consumerPrice: 120_000,
      options: [_option(id: 'a', consumer: 7_000)],
    );
    final result = stageApprovedPartnerSave(previous: previous, draft: draft);
    expect(result.stagedPriceOrNewOptions, isTrue);
    expect(result.product.consumerPrice, 100_000);
    expect(result.product.priceRevision, isNotNull);
    expect(result.product.priceRevision!.consumerPrice, 120_000);
    expect(result.product.priceRevision!.status, PriceRevisionStatus.pending);
    expect(result.product.options.single.consumerPrice, 5_000);
  });

  test('stage: new option goes to pending_options not live', () {
    final previous = _approvedProduct(options: [_option(id: 'live')]);
    final draft = previous.copyWith(
      options: [
        _option(id: 'live'),
        _option(id: 'new-opt', consumer: 3_000),
      ],
    );
    final result = stageApprovedPartnerSave(previous: previous, draft: draft);
    expect(result.stagedPriceOrNewOptions, isTrue);
    expect(result.product.options.map((o) => o.id), ['live']);
    expect(result.product.priceRevision!.pendingOptions.single.id, 'new-opt');
  });

  test('stage: cancel when prices match live', () {
    final previous = _approvedProduct(
      priceRevision: PriceRevision(
        status: PriceRevisionStatus.pending,
        consumerPrice: 200_000,
      ),
    );
    final draft = previous.copyWith(consumerPrice: 100_000, blurb: 'updated');
    final result = stageApprovedPartnerSave(previous: previous, draft: draft);
    expect(result.stagedPriceOrNewOptions, isFalse);
    expect(result.cancelledRevision, isTrue);
    expect(result.product.priceRevision, isNull);
    expect(result.product.blurb, 'updated');
    expect(result.product.publishStatus, ProductPublishStatus.approved);
  });

  test('apply: merges prices + appends pending + clears revision + syncs base_package',
      () {
    final base = _option(
      id: 'base',
      kind: ProductOptionKind.basePackage,
      consumer: 100_000,
      pro: 80_000,
    );
    final live = _approvedProduct(
      consumer: 100_000,
      options: [base, _option(id: 'addon', consumer: 5_000)],
      priceRevision: PriceRevision(
        status: PriceRevisionStatus.pending,
        consumerPrice: 110_000,
        professionalPrice: 88_000,
        optionPriceUpdates: [
          OptionPriceUpdate(
            id: 'addon',
            consumerPrice: 6_000,
            professionalPrice: 5_000,
          ),
        ],
        pendingOptions: [_option(id: 'pending-new', consumer: 1_000)],
      ),
    );
    final applied = applyPriceRevisionToLive(live);
    expect(applied.priceRevision, isNull);
    expect(applied.consumerPrice, 110_000);
    expect(applied.professionalPrice, 88_000);
    final addon = applied.options.firstWhere((o) => o.id == 'addon');
    expect(addon.consumerPrice, 6_000);
    expect(applied.options.any((o) => o.id == 'pending-new'), isTrue);
    final basePkg = applied.options.firstWhere(
      (o) => o.kind == ProductOptionKind.basePackage,
    );
    expect(basePkg.consumerPrice, 110_000);
    expect(basePkg.professionalPrice, 88_000);
  });

  test('apply: skips missing option_price_updates ids', () {
    final live = _approvedProduct(
      options: [_option(id: 'exists')],
      priceRevision: PriceRevision(
        status: PriceRevisionStatus.pending,
        optionPriceUpdates: [
          OptionPriceUpdate(
            id: 'missing',
            consumerPrice: 9,
            professionalPrice: 8,
          ),
        ],
      ),
    );
    final applied = applyPriceRevisionToLive(live);
    expect(applied.options.single.consumerPrice, 10_000);
  });

  test('prune orphans', () {
    final pruned = pruneOrphanPendingOptions(
      liveOptionIds: ['parent'],
      pendingOptions: [
        _option(id: 'ok', parentOptionId: 'parent'),
        _option(id: 'orphan', parentOptionId: 'gone'),
      ],
    );
    expect(pruned.map((o) => o.id), ['ok']);
  });

  test('freshness guard stale', () {
    final revision = PriceRevision(
      status: PriceRevisionStatus.pending,
      submittedAt: DateTime.utc(2026, 1, 1, 12),
      consumerPrice: 1,
    );
    expect(
      () => PriceRevisionGuard.ensureFreshPending(
        revision: revision,
        expectedFreshness: 'wrong-token',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('optionHasSeatCommitment', () {
    final now = DateTime(2026, 6, 1);
    expect(_option(bookedSeats: 1).bookedSeats > 0, isTrue);
    expect(
      optionHasSeatCommitment(_option(bookedSeats: 2), now: now),
      isTrue,
    );
    expect(
      optionHasSeatCommitment(
        _option(
          holds: [
            SeatHold(
              seats: 1,
              expiresAt: now.add(const Duration(hours: 1)),
              uid: 'u',
            ),
          ],
        ),
        now: now,
      ),
      isTrue,
    );
    expect(
      optionHasSeatCommitment(
        _option(
          holds: [
            SeatHold(
              seats: 1,
              expiresAt: now.subtract(const Duration(hours: 1)),
              uid: 'u',
            ),
          ],
        ),
        now: now,
      ),
      isFalse,
    );
  });
}
