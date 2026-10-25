import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

double _contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  testWidgets('PartnerBackButton icon uses PartnerTheme.text on dark bg', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.pumpWidget(
      PartnerTheme.wrap(
        MaterialApp(
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(
              leading: const PartnerBackButton(),
              title: Text(l10n.partnerProductMenuTitle),
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('partner-back')),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.color, PartnerTheme.text);
    expect(
      _contrastRatio(PartnerTheme.text, PartnerTheme.bg),
      greaterThan(4.5),
    );
    expect(find.byTooltip(l10n.partnerExit), findsOneWidget);
  });

  testWidgets('partner home exit chevron uses PartnerTheme.text', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.pumpWidget(
      PartnerTheme.wrap(
        MaterialApp(
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: IconButton(
              key: const Key('partner-home-exit'),
              icon: const Icon(
                Icons.chevron_left,
                color: PartnerTheme.text,
                size: 28,
              ),
              tooltip: l10n.partnerExit,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('partner-home-exit')),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.color, PartnerTheme.text);
    expect(
      _contrastRatio(PartnerTheme.text, PartnerTheme.bg),
      greaterThan(4.5),
    );
  });
}
