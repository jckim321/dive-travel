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
    required bool partnerMode,
    required bool admin,
  }) async {
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

  Color? iconColor(WidgetTester tester, Key key) {
    return tester
        .widget<IconButton>(find.byKey(key))
        .style
        ?.foregroundColor
        ?.resolve(const <WidgetState>{});
  }

  testWidgets('입력 커서는 청록이고 도구줄은 한 줄로 스크롤된다', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    const toolbarTeal = Color(0xFF0F766E);
    const modes = [
      (creator: true, partner: false, admin: false),
      (creator: false, partner: false, admin: true),
      (creator: false, partner: true, admin: false),
    ];
    for (final mode in modes) {
      await pumpForm(
        tester,
        creatorMode: mode.creator,
        partnerMode: mode.partner,
        admin: mode.admin,
      );
      final editor = find.byKey(const Key('product-detail-editor'));
      final theme = Theme.of(tester.element(editor));
      expect(theme.textSelectionTheme.cursorColor, PartnerTheme.accent);
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, isNotEmpty);
      for (final field in fields) {
        expect(
          field.cursorColor ?? theme.textSelectionTheme.cursorColor,
          PartnerTheme.accent,
        );
      }

      final toolbar = find.byKey(const Key('product-detail-toolbar'));
      await tester.ensureVisible(toolbar);
      await tester.pump();
      expect(
        tester.widget<SingleChildScrollView>(toolbar).scrollDirection,
        Axis.horizontal,
      );
      expect(tester.getSize(toolbar).height, 36);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: toolbar, matching: find.byType(Scrollable)),
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      final boldTop = tester
          .getTopLeft(find.byKey(const Key('product-detail-bold')))
          .dy;
      final previewTop = tester
          .getTopLeft(find.byKey(const Key('product-detail-preview')))
          .dy;
      expect((boldTop - previewTop).abs(), lessThan(2));

      expect(iconColor(tester, const Key('product-detail-bold')), AppTheme.navy);
      expect(
        iconColor(tester, const Key('product-detail-heading')),
        AppTheme.navy,
      );
      expect(iconColor(tester, const Key('product-detail-list')), AppTheme.navy);
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byKey(const Key('product-detail-bold')),
                matching: find.byType(Icon),
              ),
            )
            .size,
        greaterThanOrEqualTo(14),
      );
      final table = tester.widget<Text>(find.text(l10n.detailComposerTable));
      expect(table.style?.color, AppTheme.navy);
      expect(table.style?.fontSize, greaterThanOrEqualTo(14));
      final day = tester.widget<Text>(find.text(l10n.detailComposerDay));
      expect(day.style?.fontSize, greaterThanOrEqualTo(14));
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('product-detail-day')))
            .style
            ?.foregroundColor
            ?.resolve(const <WidgetState>{}),
        toolbarTeal,
      );
      final preview = tester.widget<Text>(find.text(l10n.detailComposerPreview));
      expect(preview.style?.fontSize, greaterThanOrEqualTo(14));
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('product-detail-preview')))
            .style
            ?.foregroundColor
            ?.resolve(const <WidgetState>{}),
        toolbarTeal,
      );
    }
  });
}
