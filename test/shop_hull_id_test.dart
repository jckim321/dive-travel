import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_hull_id.dart';

void main() {
  test('slug is one hull and drops --', () {
    expect(shopHullSlug('Ocean Dive'), 'ocean-dive');
    expect(shopHullSlug('a--b'), 'a-b');
    expect(shopHullSlug('제주 오렌지'), 'shop');
    expect(shopHullSlug('ocean-dive').contains('--'), isFalse);
  });

  test('one same-name doc uses its hull and does not create', () {
    final decision = decideShopHull(
      name: 'Blue',
      sameName: const [
        ShopHullChoice(documentId: 'blue--fun', name: 'Blue'),
      ],
      documentExists: (id) => id == 'blue',
      collisionSuffix: 'abc',
    );
    expect(decision.hullId, 'blue');
    expect(decision.createId, isNull);
    expect(decision.choices, isEmpty);
  });

  test('one same-name listing id creates the hull doc only when missing', () {
    final decision = decideShopHull(
      name: 'Blue',
      sameName: const [
        ShopHullChoice(documentId: 'blue--fun', name: 'Blue'),
      ],
      documentExists: (_) => false,
      collisionSuffix: 'abc',
    );
    expect(decision.createId, 'blue');
    expect(decision.createId!.contains('--'), isFalse);
  });

  test('several same-name docs ask for a choice and do not create', () {
    final decision = decideShopHull(
      name: 'Blue',
      sameName: const [
        ShopHullChoice(documentId: 'blue', name: 'Blue'),
        ShopHullChoice(documentId: 'blue-2', name: 'Blue'),
      ],
      documentExists: (_) => false,
      collisionSuffix: 'abc',
    );
    expect(decision.createId, isNull);
    expect(decision.choices, hasLength(2));
  });

  test('a new name avoids an id that already belongs to another shop', () {
    final id = freshShopHullId(
      name: '한글샵',
      documentExists: (candidate) => candidate == 'shop',
      collisionSuffix: 'abc',
    );
    expect(id, 'shop-abc');
    expect(id.contains('--'), isFalse);
  });

  test('memory ensure creates one hull and keeps an existing name', () async {
    final repo = MemoryDiverRepository.forTest();
    final created = await repo.ensureShopHull(name: 'Ocean Dive');
    expect(created.created, isTrue);
    expect(created.hullId, 'ocean-dive');
    expect(created.hullId.contains('--'), isFalse);
    expect(repo.createdShopName('ocean-dive'), 'Ocean Dive');

    repo.seedShopName('ocean-dive', 'Keep Me');
    final again = await repo.ensureShopHull(name: 'Keep Me');
    expect(again.needsChoice, isFalse);
    expect(again.created, isFalse);
    expect(again.hullId, 'ocean-dive');
    expect(repo.createdShopName('ocean-dive'), 'Keep Me');
  });

  test('memory ensure does not create when several shops share a name', () async {
    final repo = MemoryDiverRepository.forTest();
    repo.seedShopName('blue', 'Blue');
    repo.seedShopName('blue-west', 'Blue');
    final result = await repo.ensureShopHull(name: 'Blue');
    expect(result.needsChoice, isTrue);
    expect(result.created, isFalse);
    expect(result.hullId, isEmpty);
    expect(repo.createdShopName('blue'), 'Blue');
    expect(repo.createdShopName('blue-west'), 'Blue');
  });

  test('memory ensure turns hull--product into a hull without renaming it', () async {
    final repo = MemoryDiverRepository.forTest();
    repo.seedShopName('blue--fun', 'Blue');
    final result = await repo.ensureShopHull(name: 'Blue');
    expect(result.created, isTrue);
    expect(result.hullId, 'blue');
    expect(repo.createdShopName('blue'), 'Blue');
    expect(repo.createdShopName('blue--fun'), 'Blue');
  });

  test('memory ensure does not overwrite a different shop on id collision', () async {
    final repo = MemoryDiverRepository.forTest();
    repo.seedShopName('shop', 'Other');
    final result = await repo.ensureShopHull(name: '한글샵');
    expect(result.created, isTrue);
    expect(result.hullId, isNot('shop'));
    expect(result.hullId.startsWith('shop-'), isTrue);
    expect(result.hullId.contains('--'), isFalse);
    expect(repo.createdShopName('shop'), 'Other');
    expect(repo.createdShopName(result.hullId), '한글샵');
  });

  test('empty shop name is rejected', () async {
    final repo = MemoryDiverRepository.forTest();
    expect(
      () => repo.ensureShopHull(name: '  '),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'SHOP_NAME_REQUIRED',
        ),
      ),
    );
  });
}
