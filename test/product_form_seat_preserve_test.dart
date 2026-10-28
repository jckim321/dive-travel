import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  const shopId = AppConstants.defaultPartnerShopId;

  testWidgets('양식 연 뒤 예약이 늘어도 저장하면 예약 수가 유지된다', (tester) async {
    tester.view.physicalSize = const Size(900, 4200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    const productId = 'seat-keep';
    final opened = ShopProduct(
      id: productId,
      shopId: shopId,
      name: '열린 상품',
      consumerPrice: 100000,
      professionalPrice: 80000,
      bookedSeats: 1,
      capacity: 8,
      openEmptySeats: true,
      sameBoatStatus: SameBoatStatus.approved,
      departureStart: DateTime(2026, 11, 1),
      publishStatus: ProductPublishStatus.approved,
    );
    await repo.saveShopProduct(shopId: shopId, product: opened);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TravelProductRegistrationScreen(
            existing: opened,
            startEditing: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final booked = await repo.createBooking(
      uid: 'buyer',
      shopId: shopId,
      shopName: '샵',
      productName: opened.name,
      productId: productId,
      price: opened.consumerPrice,
      partySize: 1,
    );
    expect(booked, isNotNull);

    await tester.enterText(
      find.byKey(const Key('admin-product-name')),
      '이름만 고침',
    );
    await tester.pump();
    final save = find.byKey(const Key('admin-product-submit'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final after = (await repo.fetchShopStat(shopId))!
        .products
        .singleWhere((product) => product.id == productId);
    expect(after.name, '이름만 고침');
    expect(after.bookedSeats, 2);
    expect(after.capacity, 8);
    expect(after.openEmptySeats, isTrue);
    expect(after.sameBoatStatus, SameBoatStatus.approved);
    expect(after.departureStart, DateTime(2026, 11, 1));
  });
}
