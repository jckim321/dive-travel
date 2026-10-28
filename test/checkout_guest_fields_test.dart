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

  testWidgets('프로필 값이 있으면 글씨만 보이고, 빈 칸을 채워야 결제가 켜진다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await pumpCheckout(tester, MemoryDiverRepository.forTest());
    await tester.scrollUntilVisible(find.text(l10n.checkoutGuestName), 400);

    expect(find.byKey(const Key('checkout-guest-name')), findsNothing);
    expect(find.text('테스트 다이버'), findsOneWidget);
    expect(find.byKey(const Key('checkout-guest-birth')), findsOneWidget);
    expect(find.byKey(const Key('checkout-guest-contact')), findsOneWidget);
    expect(find.text(l10n.exploreWontChargeYet), findsNothing);
    expect(find.text(l10n.explorePayAmount('100,000')), findsOneWidget);
    expect(find.textContaining('환불'), findsWidgets);
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

  testWidgets('프로필에 셋이 있으면 입력칸 없이 결제 버튼이 켜진다', (tester) async {
    await pumpCheckout(
      tester,
      MemoryDiverRepository.forTest(
        birthDate: '1988-03-04',
        phone: '010-9999-0000',
      ),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.scrollUntilVisible(find.text(l10n.checkoutGuestName), 400);

    expect(find.byKey(const Key('checkout-guest-name')), findsNothing);
    expect(find.byKey(const Key('checkout-guest-birth')), findsNothing);
    expect(find.byKey(const Key('checkout-guest-contact')), findsNothing);
    expect(find.text('테스트 다이버'), findsOneWidget);
    expect(find.text('1988-03-04'), findsOneWidget);
    expect(find.text('010-9999-0000'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('explore-checkout-pay')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('제휴파트너와 관리자는 결제 버튼이 꺼지고 안내가 보인다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    for (final repo in [
      MemoryDiverRepository.forTest(isAdmin: true, birthDate: '1988-03-04', phone: '010-9999-0000'),
      MemoryDiverRepository.forTest(isBusiness: true, birthDate: '1988-03-04', phone: '010-9999-0000'),
    ]) {
      await pumpCheckout(tester, repo);
      expect(find.text(l10n.staffCannotBuy), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('explore-checkout-pay')))
            .onPressed,
        isNull,
      );
    }
  });
}
