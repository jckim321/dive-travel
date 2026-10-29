import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/ops_product_workbench.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _shopId = 'pro-reef';

Finder _byPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return widget is TextField &&
        key is ValueKey<String> &&
        key.value.startsWith(prefix);
  });
}

Future<DiverStore> _pumpAdminForm(
  WidgetTester tester, {
  ShopProduct? existing,
}) async {
  tester.view.physicalSize = const Size(1100, 2800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = DiverStore(MemoryDiverRepository.forTest(isAdmin: true));
  addTearDown(store.dispose);
  await tester.pumpWidget(
    DiverStoreScope(
      store: store,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: AppConstants.defaultLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TravelProductRegistrationScreen(
          lockedShopId: _shopId,
          startEditing: true,
          existing: existing,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return store;
}

Future<void> _fillBase(
  WidgetTester tester, {
  required String consumer,
  String? professional,
}) async {
  await tester.ensureVisible(find.byKey(const Key('admin-product-name')));
  await tester.enterText(find.byKey(const Key('admin-product-name')), '펀다이빙');
  await tester.ensureVisible(find.byKey(const Key('workbench-diver-price')));
  await tester.enterText(find.byKey(const Key('workbench-diver-price')), consumer);
  if (professional != null) {
    await tester.enterText(
      find.byKey(const Key('workbench-diver-pro-price')),
      professional,
    );
  }
}

void main() {
  test('빈 강사 우대가는 소비자가와 같고, 예약은 그 값이지 30% 할인이 아니다', () {
    expect(
      instructorPriceDraft(consumer: 100000, professional: 100000),
      isEmpty,
    );
    expect(
      instructorPriceDraft(consumer: 100000, professional: 80000),
      '80000',
    );

    const product = ShopProduct(
      id: 'trip',
      shopId: _shopId,
      name: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
      guestRates: [
        GuestRate(
          role: GuestRole.diver,
          consumer: 100000,
          professional: 80000,
        ),
      ],
      options: [
        ShopProductOption(
          id: 'night',
          name: '나이트',
          consumerPrice: 20000,
          professionalPrice: 15000,
        ),
      ],
    );
    final booking = BookingQuote.compute(
      product: product,
      professional: true,
      divers: 1,
      nondivers: 0,
      children: 0,
      infants: 0,
      bookPackage: true,
      selectedOptionIds: const {'night'},
    );
    expect(booking.total, 80000 + 15000);

    const shop = DiveShop(
      id: _shopId,
      name: '리프',
      location: '팔라우',
      country: '팔라우',
      continent: 'pacific',
      sites: [],
      productName: '펀다이빙',
      stars: 0,
      rating: 0,
      reviewCount: 0,
      amenities: [],
      consumerPrice: 100000,
      professionalPrice: 80000,
    );
    final card = TourPricePolicy.quote(
      shop,
      isInstructor: true,
      discount: InstructorDiscount.standard,
    );
    expect(card.amount, 70000);
    expect(card.isProfessional, isTrue);

    final charge = CheckoutCharge.resolve(
      fromFlag: false,
      product: product,
      professional: true,
      divers: 1,
      bookPackage: true,
      selectedOptionIds: const {'night'},
      quoteAmount: card.amount,
    );
    expect(charge.total, 95000);
  });

  testWidgets('관리자 등록에서 강사 우대가를 비우면 소비자가로 저장된다', (tester) async {
    final store = await _pumpAdminForm(tester);
    expect(find.byKey(const Key('workbench-diver-pro-price')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('workbench-diver-pro-price')))
          .controller
          ?.text,
      isEmpty,
    );
    expect(_byPrefix('addon-pro-'), findsOneWidget);

    await _fillBase(tester, consumer: '100000');
    await tester.enterText(_byPrefix('addon-name-'), '나이트');
    await tester.enterText(_byPrefix('addon-price-'), '20000');
    await tester.ensureVisible(find.byKey(const Key('admin-product-submit')));
    await tester.tap(find.byKey(const Key('admin-product-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final saved = store.productsForShop(_shopId).single;
    expect(saved.consumerPrice, 100000);
    expect(saved.professionalPrice, 100000);
    expect(
      saved.guestRates
          .where((rate) => rate.role == GuestRole.diver)
          .single
          .professional,
      100000,
    );
    final addon = saved.options.where((option) => option.name == '나이트').single;
    expect(addon.consumerPrice, 20000);
    expect(addon.professionalPrice, 20000);
  });

  testWidgets('적어 둔 강사 우대가가 기본 상품과 옵션에 저장되고 다시 열린다', (tester) async {
    final store = await _pumpAdminForm(tester);
    await _fillBase(tester, consumer: '100000', professional: '80000');
    await tester.enterText(_byPrefix('addon-name-'), '나이트');
    await tester.enterText(_byPrefix('addon-price-'), '20000');
    await tester.enterText(_byPrefix('addon-pro-'), '15000');
    await tester.ensureVisible(find.byKey(const Key('partner-form-add-individual')));
    await tester.tap(find.byKey(const Key('partner-form-add-individual')));
    await tester.pump();
    await tester.enterText(_byPrefix('individual-name-'), '단독');
    await tester.enterText(_byPrefix('partner-form-individual-price-'), '300000');
    await tester.enterText(_byPrefix('individual-pro-'), '240000');
    await tester.ensureVisible(find.byKey(const Key('admin-product-submit')));
    await tester.tap(find.byKey(const Key('admin-product-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final saved = store.productsForShop(_shopId).single;
    expect(saved.professionalPrice, 80000);
    expect(
      saved.options.where((option) => option.name == '나이트').single.professionalPrice,
      15000,
    );
    expect(
      saved.options.where((option) => option.name == '단독').single.professionalPrice,
      240000,
    );

    await _pumpAdminForm(tester, existing: saved);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('workbench-diver-pro-price')))
          .controller
          ?.text,
      '80000',
    );
    expect(tester.widget<TextField>(_byPrefix('addon-pro-')).controller?.text, '15000');
    expect(
      tester.widget<TextField>(_byPrefix('individual-pro-')).controller?.text,
      '240000',
    );
  });
}
