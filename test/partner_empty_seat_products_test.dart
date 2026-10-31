import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  const shopId = 'empty-seat-shop';

  testWidgets('empty-seat boxes sit under regular products and keep their marker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: shopId,
    );
    await repo.saveShopProfile(
      shopId: shopId,
      name: '보홀 리조트',
      location: '팡라오',
      country: '필리핀',
      productName: '리조트 상품',
      consumerPrice: 90000,
      professionalPrice: 70000,
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: const ShopProduct(
        id: 'fun-1',
        shopId: shopId,
        name: '일반 펀다이빙',
        consumerPrice: 150000,
        professionalPrice: 120000,
      ),
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: ShopProduct(
        id: 'seat-1',
        shopId: shopId,
        name: '빈자리 펀다이빙',
        consumerPrice: 80000,
        professionalPrice: 70000,
        openEmptySeats: true,
        capacity: 4,
        bookedSeats: 1,
        durationLabel: '3박 4일',
        departureStart: DateTime(2026, 11, 2),
        sameBoatStatus: SameBoatStatus.closed,
      ),
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: const ShopProduct(
        id: 'seat-free',
        shopId: shopId,
        name: '기간 없는 빈자리',
        consumerPrice: 60000,
        professionalPrice: 50000,
        openEmptySeats: true,
        durationLabel: '3일',
        capacity: 2,
      ),
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ResortDeskScreen(shopId: shopId, partnerMode: true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('상품 박스 추가'), findsOneWidget);
    expect(find.text('+ 상품 박스 추가'), findsNothing);
    expect(find.text('빈자리 상품 추가'), findsOneWidget);
    expect(find.text('+ 빈자리 상품 추가'), findsNothing);
    expect(find.text('③ 빈자리 상품 (선택)'), findsOneWidget);
    expect(find.text('일반 펀다이빙'), findsOneWidget);
    expect(find.text('빈자리 펀다이빙'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('partner-empty-seat-products')));
    await tester.pump();
    final regularTop = tester.getTopLeft(
      find.byKey(const Key('partner-regular-products')),
    ).dy;
    final emptyTop = tester.getTopLeft(
      find.byKey(const Key('partner-empty-seat-products')),
    ).dy;
    expect(regularTop, lessThan(emptyTop));

    await tester.ensureVisible(find.byKey(const Key('partner-empty-expand-seat-1')));
    await tester.tap(find.byKey(const Key('partner-empty-expand-seat-1')));
    await tester.pump();

    expect(find.text('빈자리 펀다이빙'), findsWidgets);
    expect(
      find.byKey(const Key('empty-seat-1-shop-product-box-date')),
      findsOneWidget,
    );
    expect(
      tester.widget(find.byKey(const Key('partner-empty-return-seat-1'))),
      isA<Text>(),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('partner-empty-return-seat-1'))).data,
      '2026-11-05',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('partner-empty-remaining-seat-1')))
          .controller
          ?.text,
      '3',
    );

    await tester.ensureVisible(find.byKey(const Key('partner-empty-open-seat-1')));
    await tester.tap(find.byKey(const Key('partner-empty-open-seat-1')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('partner-empty-remaining-seat-1')),
    );
    await tester.enterText(
      find.byKey(const Key('partner-empty-remaining-seat-1')),
      '5',
    );
    await tester.ensureVisible(
      find.byKey(const Key('empty-seat-1-shop-product-box-date')),
    );
    await tester.enterText(
      find.byKey(const Key('empty-seat-1-shop-product-box-date')),
      '2026-11-05',
    );
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('partner-empty-return-seat-1'))).data,
      '2026-11-08',
    );

    await tester.ensureVisible(find.byKey(const Key('partner-empty-expand-seat-free')));
    await tester.tap(find.byKey(const Key('partner-empty-expand-seat-free')));
    await tester.pump();
    expect(find.text('기간을 먼저 입력하세요'), findsOneWidget);
    expect(find.text('돌아오는 날'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('partner-empty-save')));
    await tester.tap(find.byKey(const Key('partner-empty-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    final products = store.liveStatsFor(shopId)!.products;
    final saved = products.firstWhere((product) => product.id == 'seat-1');
    final regular = products.firstWhere((product) => product.id == 'fun-1');
    expect(saved.openEmptySeats, isTrue);
    expect(saved.sameBoatStatus, SameBoatStatus.approved);
    expect(saved.capacity, 6);
    expect(saved.bookedSeats, 1);
    expect(saved.departureStart?.year, 2026);
    expect(saved.departureStart?.month, 11);
    expect(saved.departureStart?.day, 5);
    expect(saved.durationLabel, '3박 4일');
    expect(saved.toMap().containsKey('return_date'), isFalse);
    expect(saved.toMap().containsKey('departure_end'), isFalse);
    expect(regular.name, '일반 펀다이빙');
    expect(regular.openEmptySeats, isFalse);
    expect(regular.consumerPrice, 150000);
  });
}
