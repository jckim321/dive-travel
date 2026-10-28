import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _shopId = 'bohol-hideout';
final _depart = DateTime(2026, 12, 20);
final _flag = DateTime(2026, 12, 1);

ShopProduct _product({
  required String id,
  required String submittedByUid,
  required ProductPublishStatus publishStatus,
  String name = '보홀 여행',
  int consumerPrice = 180000,
  bool active = true,
}) {
  return ShopProduct(
    id: id,
    shopId: _shopId,
    name: name,
    consumerPrice: consumerPrice,
    professionalPrice: 120000,
    blurb: '일정 그대로',
    active: active,
    publishStatus: publishStatus,
    submittedByUid: submittedByUid,
    options: const [
      ShopProductOption(
        id: 'nitrox',
        name: '나이트록스',
        consumerPrice: 30000,
        professionalPrice: 20000,
        kind: ProductOptionKind.individual,
      ),
    ],
  );
}

ShopProduct _seatPatch(ShopProduct product) {
  final opened = DateTime(2026, 10, 28);
  return product.copyWith(
    name: '바꿔치기',
    consumerPrice: 1,
    publishStatus: ProductPublishStatus.pending,
    active: false,
    openEmptySeats: true,
    capacity: 6,
    departureStart: _depart,
    flagClosesAt: _flag,
    sameBoatStatus: SameBoatStatus.approved,
    sameBoatOpenedAt: opened,
    options: [
      for (final option in product.options)
        option.copyWith(
          name: '이름 바꾸기',
          consumerPrice: 1,
          openEmptySeats: true,
          capacity: 2,
          departureStart: _depart,
          flagClosesAt: _flag,
          sameBoatStatus: SameBoatStatus.approved,
          sameBoatOpenedAt: opened,
        ),
    ],
  );
}

void main() {
  Future<DiverStore> signedInStore(MemoryDiverRepository repo) async {
    final store = DiverStore(repo);
    await pumpEventQueue();
    expect(store.uid, 'test-user');
    return store;
  }

  test('캡틴 본인 승인 상품은 좌석만 열리고 재승인되지 않는다', () async {
    final repo = MemoryDiverRepository.forTest();
    final stored = _product(
      id: 'mine',
      submittedByUid: 'test-user',
      publishStatus: ProductPublishStatus.approved,
      name: '관리자가 고친 이름',
    );
    await repo.saveShopProduct(shopId: _shopId, product: stored);
    final store = await signedInStore(repo);
    addTearDown(store.dispose);

    await store.openCreatorSeats(product: _seatPatch(stored));

    final saved = store.productsForShop(_shopId).single;
    expect(saved.publishStatus, ProductPublishStatus.approved);
    expect(saved.active, isTrue);
    expect(saved.name, '관리자가 고친 이름');
    expect(saved.consumerPrice, 180000);
    expect(saved.blurb, '일정 그대로');
    expect(saved.submittedByUid, 'test-user');
    expect(saved.openEmptySeats, isTrue);
    expect(saved.capacity, 6);
    expect(saved.departureStart, _depart);
    expect(saved.flagClosesAt, _flag);
    expect(saved.sameBoatStatus, SameBoatStatus.approved);
    expect(saved.listsOnSameBoat, isTrue);
    final option = saved.options.single;
    expect(option.name, '나이트록스');
    expect(option.consumerPrice, 30000);
    expect(option.openEmptySeats, isTrue);
    expect(option.capacity, 2);
    expect(option.sameBoatStatus, SameBoatStatus.approved);
  });

  test('남의 상품과 미승인 상품과 로그아웃은 빈자리 열기를 거부한다', () async {
    final repo = MemoryDiverRepository.forTest();
    final foreign = _product(
      id: 'theirs',
      submittedByUid: 'other-user',
      publishStatus: ProductPublishStatus.approved,
    );
    final pending = _product(
      id: 'pending',
      submittedByUid: 'test-user',
      publishStatus: ProductPublishStatus.pending,
      active: false,
    );
    await repo.saveShopProduct(shopId: _shopId, product: foreign);
    await repo.saveShopProduct(shopId: _shopId, product: pending);

    final signedOut = DiverStore(repo);
    addTearDown(signedOut.dispose);
    expect(signedOut.uid, isNull);
    await expectLater(
      signedOut.openCreatorSeats(product: _seatPatch(pending)),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Not allowed to edit this shop product',
        ),
      ),
    );

    final store = await signedInStore(repo);
    addTearDown(store.dispose);
    for (final product in [foreign, pending]) {
      await expectLater(
        store.openCreatorSeats(product: _seatPatch(product)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Not allowed to edit this shop product',
          ),
        ),
      );
    }

    final rows = store.productsForShop(_shopId);
    expect(rows, hasLength(2));
    for (final row in rows) {
      expect(row.openEmptySeats, isFalse);
      expect(row.capacity, 0);
      expect(row.sameBoatStatus, SameBoatStatus.closed);
      expect(row.name, '보홀 여행');
    }
    expect(
      rows.singleWhere((row) => row.id == 'pending').publishStatus,
      ProductPublishStatus.pending,
    );
    expect(
      rows.singleWhere((row) => row.id == 'theirs').publishStatus,
      ProductPublishStatus.approved,
    );
  });

  testWidgets('캡틴 화면은 빈자리 열기이고 성공 스낵바가 남는다', (tester) async {
    final repo = MemoryDiverRepository.forTest();
    final product = _product(
      id: 'screen',
      submittedByUid: 'test-user',
      publishStatus: ProductPublishStatus.approved,
      name: '보홀 오션',
    ).copyWith(
      openEmptySeats: true,
      capacity: 4,
      departureStart: _depart,
      flagClosesAt: _flag,
    );
    await repo.saveShopProduct(shopId: _shopId, product: product);
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => SameBoatSeatsScreen(product: product),
                    ),
                  );
                },
                child: const Text('open-seats'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(store.uid, 'test-user');
    await tester.tap(find.text('open-seats'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('빈자리 열기'), findsNWidgets(2));
    expect(find.text('승인 요청'), findsNothing);
    await tester.tap(find.byKey(const Key('same-boat-seats-submit')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SameBoatSeatsScreen), findsNothing);
    expect(find.text('빈자리를 열었어요. 같은배에서 바로 보여요'), findsOneWidget);
    final saved = store.productsForShop(_shopId).single;
    expect(saved.publishStatus, ProductPublishStatus.approved);
    expect(saved.name, '보홀 오션');
    expect(saved.sameBoatStatus, SameBoatStatus.approved);
    expect(saved.listsOnSameBoat, isTrue);
  });
}
