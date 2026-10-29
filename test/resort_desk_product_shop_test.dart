import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_menu_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _palau = 'palau-reef';
const _bohol = 'bohol-hideout';

Future<MemoryDiverRepository> _seeded() async {
  final repo = MemoryDiverRepository.forTest(isAdmin: true);
  await repo.saveShopProduct(
    shopId: _palau,
    product: const ShopProduct(
      id: 'palau-fun',
      shopId: _palau,
      name: '팔라우 펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
    ),
  );
  await repo.saveShopProduct(
    shopId: _bohol,
    product: const ShopProduct(
      id: 'bohol-fun',
      shopId: _bohol,
      name: '보홀 펀다이빙',
      consumerPrice: 90000,
      professionalPrice: 70000,
    ),
  );
  return repo;
}

Future<void> _openDesk(WidgetTester tester, DiverStore store, String shopId) async {
  await tester.pumpWidget(
    DiverStoreScope(
      store: store,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: AppConstants.defaultLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ResortDeskScreen(shopId: shopId),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('partner-product-form')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('관리자가 편집 중인 리조트의 상품 메뉴·목록·빈자리·등록을 연다', (tester) async {
    tester.view.physicalSize = const Size(900, 4800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = await _seeded();
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    await _openDesk(tester, store, _palau);
    expect(find.byKey(const Key('partner-product-menu')), findsOneWidget);

    await tester.tap(find.byKey(const Key('partner-menu-list')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('팔라우 펀다이빙'), findsWidgets);
    expect(find.text('보홀 펀다이빙'), findsNothing);
    expect(find.byKey(const Key('partner-products-empty')), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('partner-menu-seats')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('팔라우 펀다이빙'), findsWidgets);
    expect(find.text('보홀 펀다이빙'), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('partner-menu-register')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester.widget<Text>(find.byKey(const Key('partner-product-shop'))).data,
      _palau,
    );
  });

  testWidgets('제휴파트너 메뉴는 연결 리조트 상품을 그대로 보여 준다', (tester) async {
    tester.view.physicalSize = const Size(900, 4800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: _palau,
    );
    await repo.saveShopProduct(
      shopId: _palau,
      product: const ShopProduct(
        id: 'palau-fun',
        shopId: _palau,
        name: '팔라우 펀다이빙',
        consumerPrice: 100000,
        professionalPrice: 80000,
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
          home: const PartnerProductMenuScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('partner-menu-list')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('팔라우 펀다이빙'), findsWidgets);
  });
}
