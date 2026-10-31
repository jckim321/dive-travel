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
  const shopId = 'regular-boxes';

  Future<DiverStore> openDesk(WidgetTester tester) async {
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
      intro: '리조트 소개',
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: const ShopProduct(
        id: 'fun-1',
        shopId: shopId,
        name: '일반 펀다이빙',
        consumerPrice: 150000,
        professionalPrice: 120000,
        includes: '보트',
        options: [
          ShopProductOption(
            id: 'opt-tank',
            name: '탱크',
            consumerPrice: 10000,
            professionalPrice: 8000,
          ),
          ShopProductOption(
            id: 'ind-keep',
            name: '나이트 다이브',
            consumerPrice: 40000,
            professionalPrice: 30000,
            kind: ProductOptionKind.individual,
          ),
        ],
      ),
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: const ShopProduct(
        id: 'stay-2',
        shopId: shopId,
        name: '그대로 두는 상품',
        consumerPrice: 80000,
        professionalPrice: 60000,
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
    return store;
  }

  Future<void> reveal(WidgetTester tester, Finder finder) {
    return tester.ensureVisible(finder);
  }

  testWidgets('regular product boxes keep individual option ids and hide the date', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await openDesk(tester);

    expect(find.byKey(const Key('partner-resort-info')), findsOneWidget);
    expect(find.byKey(const Key('partner-regular-products')), findsOneWidget);
    expect(find.byKey(const Key('partner-regular-date-hint')), findsOneWidget);
    expect(find.text('구매자가 예약할 때 정해요'), findsWidgets);
    expect(find.text('일반 펀다이빙'), findsOneWidget);
    expect(find.text('옵션 2'), findsOneWidget);
    expect(find.byKey(const Key('shop-product-box-date')), findsNothing);
    expect(find.text('빈자리'), findsNothing);
    expect(find.byKey(const Key('partner-form-add-individual')), findsNothing);

    await reveal(tester, find.byKey(const Key('partner-regular-expand-fun-1')));
    await tester.tap(find.byKey(const Key('partner-regular-expand-fun-1')));
    await tester.pump();

    expect(
      find.byKey(const Key('partner-regular-individual-ind-keep')),
      findsOneWidget,
    );
    expect(find.textContaining('나이트 다이브'), findsOneWidget);

    await reveal(tester, find.byKey(const Key('partner-regular-name-fun-1')));
    await tester.enterText(
      find.byKey(const Key('partner-regular-name-fun-1')),
      '오후 펀다이빙',
    );
    await reveal(tester, find.byKey(const Key('partner-regular-visible-fun-1')));
    await tester.tap(find.byKey(const Key('partner-regular-visible-fun-1')));
    await tester.pump();

    await reveal(tester, find.byKey(const Key('partner-regular-save')));
    await tester.tap(find.byKey(const Key('partner-regular-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    final products = store.liveStatsFor(shopId)!.products;
    final saved = products.firstWhere((product) => product.id == 'fun-1');
    expect(saved.name, '오후 펀다이빙');
    expect(saved.active, isFalse);
    expect(saved.publishStatus, ProductPublishStatus.approved);
    expect(
      saved.options.map((option) => option.id),
      containsAll(['opt-tank', 'ind-keep']),
    );
    expect(
      saved.options.firstWhere((option) => option.id == 'ind-keep').kind,
      ProductOptionKind.individual,
    );
    expect(products.map((product) => product.id), contains('stay-2'));
    expect(store.liveStatsFor(shopId)!.intro, '리조트 소개');
    expect(store.liveStatsFor(shopId)!.name, '보홀 리조트');
  });

  testWidgets('a new regular box temp-saves without opening an empty-seat area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await openDesk(tester);
    await reveal(tester, find.byKey(const Key('partner-regular-add')));
    await tester.tap(find.byKey(const Key('partner-regular-add')));
    await tester.pump();

    final nameFields = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'partner-regular-name-p-',
          ),
    );
    expect(nameFields, findsOneWidget);
    await reveal(tester, nameFields);
    await tester.enterText(nameFields, '새 상품');
    final priceKey = (tester.widget<TextField>(nameFields).key! as ValueKey<String>)
        .value
        .replaceFirst('partner-regular-name-', 'partner-regular-price-');
    await tester.enterText(find.byKey(Key(priceKey)), '50000');

    await reveal(tester, find.byKey(const Key('partner-regular-temp-save')));
    await tester.tap(find.byKey(const Key('partner-regular-temp-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    final created = store
        .liveStatsFor(shopId)!
        .products
        .firstWhere((product) => product.name == '새 상품');
    expect(created.publishStatus, ProductPublishStatus.draft);
    expect(created.departureStart, isNull);
    expect(find.byKey(const Key('shop-product-box-date')), findsNothing);
    expect(find.text('빈자리'), findsNothing);
  });
}
