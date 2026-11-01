import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_products_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_same_boat_monitor_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_trip_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_menu_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_products_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _resortId = 'reef-desk';

ShopProduct _resortProduct() {
  return const ShopProduct(
    id: 'reef-fun',
    shopId: _resortId,
    name: '리프 펀다이빙',
    consumerPrice: 120000,
    professionalPrice: 90000,
  );
}

ShopProduct _plannedTrip() {
  return const ShopProduct(
    id: 'malta-plan',
    shopId: 'curated-malta',
    name: '기획 몰타',
    consumerPrice: 200000,
    professionalPrice: 160000,
    listingKind: ProductListingKind.curated,
  );
}

ShopProduct _craftedTrip() {
  return const ShopProduct(
    id: 'my-dahab',
    shopId: 'diy-holder',
    name: '내가 짜는 다합',
    consumerPrice: 80000,
    professionalPrice: 60000,
    listingKind: ProductListingKind.diverPlanned,
  );
}

ShopProduct _emptySeat() {
  return ShopProduct(
    id: 'reef-seat',
    shopId: _resortId,
    name: '리프 빈자리',
    consumerPrice: 150000,
    professionalPrice: 120000,
    openEmptySeats: true,
    sameBoatStatus: SameBoatStatus.approved,
    capacity: 4,
    departureStart: DateTime(2026, 12, 1),
  );
}

Future<void> _pump(WidgetTester tester, DiverStore store, Widget home) async {
  await tester.binding.setSurfaceSize(const Size(900, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    DiverStoreScope(
      store: store,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: AppConstants.defaultLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('파트너 상품 메뉴·목록·카드는 리조트 편집 화면을 연다', (tester) async {
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: _resortId,
    );
    await repo.saveShopProduct(shopId: _resortId, product: _resortProduct());
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();

    await _pump(tester, store, const PartnerProductMenuScreen());
    await tester.tap(find.byKey(const Key('partner-menu-register')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    var desk = tester.widget<ResortDeskScreen>(find.byType(ResortDeskScreen));
    expect(desk.shopId, _resortId);
    expect(desk.partnerMode, isTrue);
    expect(find.byType(TravelProductRegistrationScreen), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('partner-menu-list')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('partner-product-edit-reef-fun')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    desk = tester.widget<ResortDeskScreen>(find.byType(ResortDeskScreen));
    expect(desk.shopId, _resortId);
    expect(desk.partnerMode, isTrue);
  });

  testWidgets('빈 상품 목록의 등록은 리조트 편집 화면을 연다', (tester) async {
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: _resortId,
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await _pump(tester, store, const PartnerProductsScreen(shopId: _resortId));
    await tester.tap(find.byKey(const Key('partner-products-empty-cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final desk = tester.widget<ResortDeskScreen>(find.byType(ResortDeskScreen));
    expect(desk.shopId, _resortId);
    expect(desk.partnerMode, isTrue);
    expect(find.byType(TravelProductRegistrationScreen), findsNothing);
  });

  testWidgets('관리자 상품 관리는 리조트 상품만 편집 화면으로 연다', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProduct(shopId: _resortId, product: _resortProduct());
    await repo.saveShopProduct(shopId: 'curated-malta', product: _plannedTrip());
    await repo.saveShopProduct(shopId: 'diy-holder', product: _craftedTrip());
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();
    await _pump(tester, store, const AdminProductsScreen());

    await tester.tap(find.text('리프 펀다이빙'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final desk = tester.widget<ResortDeskScreen>(find.byType(ResortDeskScreen));
    expect(desk.shopId, _resortId);
    expect(desk.partnerMode, isFalse);
    expect(find.byType(TravelProductRegistrationScreen), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('기획 몰타'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(PlannerTripScreen), findsOneWidget);
    expect(find.text('기획 몰타'), findsWidgets);
    expect(find.byType(TravelProductRegistrationScreen), findsNothing);
    expect(find.byType(ResortDeskScreen), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('내가 짜는 다합'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(PlannerTripScreen), findsOneWidget);
    expect(find.text('내가 짜는 다합'), findsWidgets);
    expect(find.byType(TravelProductRegistrationScreen), findsNothing);
    expect(find.byType(ResortDeskScreen), findsNothing);
  });

  testWidgets('같은배 모니터의 리조트 상품은 편집 화면으로 연다', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProduct(shopId: _resortId, product: _emptySeat());
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();
    await _pump(tester, store, const AdminSameBoatMonitorScreen());

    await tester.tap(find.text('리프 빈자리'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final desk = tester.widget<ResortDeskScreen>(find.byType(ResortDeskScreen));
    expect(desk.shopId, _resortId);
    expect(desk.partnerMode, isFalse);
    expect(find.byType(TravelProductRegistrationScreen), findsNothing);
  });
}
