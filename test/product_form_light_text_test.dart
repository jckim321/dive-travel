import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpForm(
    WidgetTester tester, {
    required bool creatorMode,
    bool partnerMode = false,
  }) async {
    tester.view.physicalSize = const Size(900, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = DiverStore(
      MemoryDiverRepository.forTest(isAdmin: !creatorMode && !partnerMode),
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
          home: TravelProductRegistrationScreen(
            creatorMode: creatorMode,
            partnerMode: partnerMode,
            lockedShopId: partnerMode ? 'bohol-hideout' : null,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> expectLightOptionText(WidgetTester tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final addOption = find.byKey(const Key('partner-form-add-option'));
    await tester.ensureVisible(addOption);
    await tester.pump();
    final addContext = tester.element(addOption);
    expect(Theme.of(addContext).brightness, Brightness.dark);
    expect(
      Theme.of(addContext).textTheme.bodyLarge?.color,
      PartnerTheme.text,
    );
    expect(
      Theme.of(addContext).outlinedButtonTheme.style?.foregroundColor?.resolve(
        const <WidgetState>{},
      ),
      PartnerTheme.text,
    );

    await tester.tap(addOption);
    await tester.pump();
    final unset = find.text('미분류');
    expect(unset, findsWidgets);
    expect(
      DefaultTextStyle.of(tester.element(unset.first)).style.color,
      PartnerTheme.text,
    );

    final addIndividual = find.byKey(const Key('partner-form-add-individual'));
    await tester.ensureVisible(addIndividual);
    await tester.tap(addIndividual);
    await tester.pump();
    final optionsLabel = find.text(l10n.partnerFormIndividualOptions);
    await tester.ensureVisible(optionsLabel);
    expect(
      DefaultTextStyle.of(tester.element(optionsLabel)).style.color,
      PartnerTheme.accent,
    );
  }

  testWidgets('다이버 새 여행 짜기는 옵션 글자가 밝다', (tester) async {
    await pumpForm(tester, creatorMode: true);
    await expectLightOptionText(tester);
  });

  testWidgets('관리자 상품 등록도 옵션 글자가 밝다', (tester) async {
    await pumpForm(tester, creatorMode: false);
    await expectLightOptionText(tester);
  });
}
