import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/explore/presentation/tour_checkout_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  const shop = DiveShop(
    id: 'hull',
    name: '샵',
    location: '세부',
    country: 'PH',
    continent: 'asia',
    sites: ['샵'],
    productName: '펀다이빙',
    stars: 0,
    rating: 0,
    reviewCount: 0,
    amenities: [],
    consumerPrice: 100000,
    professionalPrice: 80000,
  );

  Future<void> pumpCheckout(
    WidgetTester tester,
    MemoryDiverRepository repo,
  ) async {
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
          home: const TourCheckoutSheet(
            shop: shop,
            quote: TourPriceQuote(amount: 100000, isProfessional: false),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('프로필 값이 있으면 채우고, 비어 있으면 결제 버튼이 꺼진다', (tester) async {
    await pumpCheckout(tester, MemoryDiverRepository.forTest());

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('checkout-guest-name')))
          .controller!
          .text,
      '테스트 다이버',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('checkout-guest-birth')))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('explore-checkout-pay')))
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('checkout-guest-birth')),
      '1990-01-02',
    );
    await tester.enterText(
      find.byKey(const Key('checkout-guest-contact')),
      '010-1111-2222',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('explore-checkout-pay')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('생년월일과 연락처가 프로필에 있으면 결제 버튼이 켜진다', (tester) async {
    await pumpCheckout(
      tester,
      MemoryDiverRepository.forTest(
        birthDate: '1988-03-04',
        phone: '010-9999-0000',
      ),
    );

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('checkout-guest-birth')))
          .controller!
          .text,
      '1988-03-04',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('checkout-guest-contact')))
          .controller!
          .text,
      '010-9999-0000',
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('explore-checkout-pay')))
          .onPressed,
      isNotNull,
    );
  });
}
