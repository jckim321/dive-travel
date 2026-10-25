import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpDesk(
    WidgetTester tester, {
    required bool partnerMode,
  }) async {
    final store = DiverStore(
      MemoryDiverRepository.forTest(
        isBusiness: true,
        ownedShopId: AppConstants.defaultPartnerShopId,
      ),
    );
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ResortDeskScreen(
            shopId: AppConstants.defaultPartnerShopId,
            partnerMode: partnerMode,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('ResortDeskScreen partnerMode false keeps light canvas', (
    tester,
  ) async {
    await pumpDesk(tester, partnerMode: false);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppTheme.canvas);
    expect(find.byType(PartnerBackButton), findsNothing);
  });

  testWidgets('ResortDeskScreen partnerMode true uses PartnerTheme.bg + PBB', (
    tester,
  ) async {
    await pumpDesk(tester, partnerMode: true);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, PartnerTheme.bg);
    expect(find.byType(PartnerBackButton), findsOneWidget);
  });
}
