import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/partner_product_card.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  ShopProduct listedProduct() {
    return ShopProduct(
      id: 'p1',
      shopId: AppConstants.defaultPartnerShopId,
      name: '패키지',
      consumerPrice: 100000,
      professionalPrice: 100000,
      active: true,
      publishStatus: ProductPublishStatus.approved,
      openEmptySeats: true,
      capacity: 4,
      bookedSeats: 1,
      sameBoatStatus: SameBoatStatus.approved,
    );
  }

  testWidgets('non-partner SameBoatSeatsScreen keeps light scaffold bg', (
    tester,
  ) async {
    final store = DiverStore(MemoryDiverRepository.forTest());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SameBoatSeatsScreen(
            product: listedProduct(),
            basePackageOnly: true,
          ),
        ),
      ),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, isNull);
    expect(find.byType(PartnerBackButton), findsNothing);
  });

  testWidgets('partnerLiveCopy SameBoatSeatsScreen uses PartnerTheme.bg', (
    tester,
  ) async {
    final store = DiverStore(MemoryDiverRepository.forTest());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PartnerTheme.wrap(
            SameBoatSeatsScreen(
              product: listedProduct(),
              basePackageOnly: true,
              partnerLiveCopy: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, PartnerTheme.bg);
  });

  testWidgets('partner discard dialog uses dark ColorScheme', (tester) async {
    final store = DiverStore(
      MemoryDiverRepository.forTest(
        isBusiness: true,
        ownedShopId: AppConstants.defaultPartnerShopId,
      ),
    );
    addTearDown(store.dispose);
    final product = ShopProduct(
      id: 'p1',
      shopId: AppConstants.defaultPartnerShopId,
      name: '패키지',
      consumerPrice: 100000,
      professionalPrice: 100000,
      active: true,
      publishStatus: ProductPublishStatus.approved,
      options: [
        ShopProductOption(
          id: 'ind-1',
          name: '원데이',
          kind: ProductOptionKind.individual,
          consumerPrice: 80000,
          professionalPrice: 80000,
        ),
      ],
    );

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PartnerTheme.wrap(
            Scaffold(
              body: SingleChildScrollView(
                child: PartnerProductCard(
                  product: product,
                  shopId: AppConstants.defaultPartnerShopId,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('partner-option-discard-ind-1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('partner-option-discard-confirm-ind-1')),
      findsOneWidget,
    );
    final dialogContext = tester.element(
      find.byKey(const Key('partner-option-discard-confirm-ind-1')),
    );
    expect(Theme.of(dialogContext).brightness, Brightness.dark);
    expect(Theme.of(dialogContext).colorScheme.primary, PartnerTheme.accent);
  });
}
