import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('basePackageOnly hides option seat slots', (tester) async {
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

    final repo = MemoryDiverRepository.forTest();
    final store = DiverStore(repo);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SameBoatSeatsScreen(
            product: product,
            basePackageOnly: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('패키지'), findsOneWidget);
    expect(find.text('원데이'), findsNothing);
  });
}
