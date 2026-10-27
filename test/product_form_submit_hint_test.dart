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
  void expectReadableSubmit(WidgetTester tester, Key key) {
    final button = tester.widget<FilledButton>(find.byKey(key));
    expect(
      button.style?.foregroundColor?.resolve(const <WidgetState>{}),
      PartnerTheme.bg,
    );
    expect(
      button.style?.foregroundColor?.resolve({WidgetState.disabled}),
      PartnerTheme.text,
    );
    expect(
      button.style?.backgroundColor?.resolve({WidgetState.disabled}),
      PartnerTheme.borderStrong,
    );
  }

  Future<void> pumpForm(
    WidgetTester tester, {
    required bool creatorMode,
    required bool partnerMode,
    required bool admin,
  }) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = DiverStore(
      MemoryDiverRepository.forTest(
        isAdmin: admin,
        isBusiness: partnerMode,
        ownedShopId: partnerMode ? AppConstants.defaultPartnerShopId : null,
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
          home: TravelProductRegistrationScreen(
            creatorMode: creatorMode,
            partnerMode: partnerMode,
            lockedShopId: partnerMode ? AppConstants.defaultPartnerShopId : null,
            startEditing: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('승인·게시 버튼은 막혀도 글자가 읽힌다', (tester) async {
    await pumpForm(tester, creatorMode: true, partnerMode: false, admin: false);
    expectReadableSubmit(tester, const Key('partner-product-save'));

    await pumpForm(tester, creatorMode: false, partnerMode: false, admin: true);
    expectReadableSubmit(tester, const Key('admin-product-submit'));

    await pumpForm(tester, creatorMode: false, partnerMode: true, admin: false);
    expectReadableSubmit(tester, const Key('partner-product-save'));
  });

  testWidgets('개별 상품 가격이 비면 그 칸으로 가고 입력을 안내한다', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          home: const TravelProductRegistrationScreen(
            partnerMode: true,
            lockedShopId: AppConstants.defaultPartnerShopId,
            startEditing: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(
      find.byKey(const Key('partner-product-name')),
      '개별 가격',
    );
    await tester.enterText(
      find.byKey(const Key('workbench-diver-price')),
      '120000',
    );
    final add = find.byKey(const Key('partner-form-add-individual'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.enterText(
      find.widgetWithText(TextField, l10n.bookingEntryIndividualName),
      '펀다이브',
    );
    await tester.pump();

    tester.view.physicalSize = const Size(400, 520);
    await tester.pump();

    final price = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('partner-form-individual-price-');
    });
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const Key('partner-product-form-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    scrollable.position.jumpTo(0);
    await tester.pump();
    expect(tester.getTopLeft(price).dy, greaterThan(520));

    await tester.tap(find.byKey(const Key('partner-product-save')));
    await tester.pump();
    await tester.pump();

    expect(find.text('1인 기준 가격을 입력해 주세요'), findsWidgets);
    expect(
      tester.widget<TextField>(price).decoration?.errorText,
      '1인 기준 가격을 입력해 주세요',
    );
    final dy = tester.getTopLeft(price).dy;
    expect(dy, greaterThanOrEqualTo(0));
    expect(dy, lessThan(520));
  });
}
