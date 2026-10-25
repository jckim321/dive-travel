import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('partnerLiveCopy shows open button not approval request', (
    tester,
  ) async {
    final product = ShopProduct(
      id: 'p1',
      shopId: AppConstants.defaultPartnerShopId,
      name: '패키지',
      consumerPrice: 100000,
      professionalPrice: 100000,
      active: true,
      publishStatus: ProductPublishStatus.approved,
    );
    final store = DiverStore(MemoryDiverRepository.forTest());
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: PartnerTheme.wrap(
          MaterialApp(
            theme: AppTheme.light,
            locale: AppConstants.defaultLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SameBoatSeatsScreen(
              product: product,
              basePackageOnly: true,
              partnerLiveCopy: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('same-boat-seats-submit')),
        matching: find.text(l10n.partnerSeatsOpenButton),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.sameBoatSeatsSubmit), findsNothing);
    expect(find.text(l10n.partnerSeatsOpenHint), findsOneWidget);
    expect(find.text(l10n.sameBoatSeatsHint), findsNothing);
  });
}
