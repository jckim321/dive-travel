import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/core/auth/device_pin_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

import 'support/device_pin_test_helpers.dart';

void main() {
  Future<AppLocalizations> loadKo() {
    return AppLocalizations.delegate.load(const Locale('ko'));
  }

  Future<void> openAdmin(WidgetTester tester) async {
    final l10n = await loadKo();
    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-profile-settings')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('profile-settings-scroll')),
      const Offset(0, -560),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-admin-mode')));
    await tester.tap(find.byKey(const Key('open-admin-mode')));
    await tester.pumpAndSettle();
    await completeDevicePinIfAsked(tester);
  }

  testWidgets('wide layout reaches new hubs and H8 promote controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(isAdmin: true),
        devicePinStore: MemoryDevicePinStore(),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await loadKo();
    await openAdmin(tester);

    expect(find.byKey(const Key('admin-layout-wide')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-members')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-shops')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-dive-star')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-bookings')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-contracts')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-settlement')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-sales')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-stats')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-reports')), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-menu-members')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-sub-divers')), findsOneWidget);
    expect(find.byKey(const Key('admin-sub-partners')), findsOneWidget);
    expect(find.byKey(const Key('admin-members-search')), findsOneWidget);

    expect(find.textContaining('역할'), findsWidgets);
    await tester.ensureVisible(
      find.byKey(const Key('admin-member-menu-pending-instructor')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-member-menu-pending-instructor')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('admin-member-promote-pending-instructor')),
      findsOneWidget,
    );
    Navigator.of(
      tester.element(find.byKey(const Key('admin-member-promote-pending-instructor'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin-menu-settlement')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-menu-pricing')), findsOneWidget);
    expect(
      find.byKey(const Key('admin-sub-settlement-history')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('admin-menu-sales')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-sales-kpi-gross')), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-menu-dive-star')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-sub-dive-star-apps')), findsOneWidget);
    expect(find.byKey(const Key('admin-sub-dive-star-review')), findsOneWidget);
    expect(find.byKey(const Key('admin-sub-dive-star-forms')), findsOneWidget);
    expect(find.text(l10n.adminShopMonitor), findsNothing);

    expect(find.text(l10n.weatherAdminTitle), findsNothing);
    expect(find.text(l10n.adminPostsTitle), findsNothing);
    expect(find.text(l10n.adminPostsCommunityShort), findsNothing);
    expect(find.text(l10n.adminContractsSubTerms), findsNothing);
    expect(find.text(l10n.adminContractsSubInbox), findsNothing);

    await tester.tap(find.byKey(const Key('admin-nav-tools')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-nav-more-sheet')), findsOneWidget);
    expect(find.byKey(const Key('admin-tool-trial-data')), findsOneWidget);
    for (final key in const [
      'admin-more-dive-star',
      'admin-more-contracts',
      'admin-more-settlement',
      'admin-more-sales',
      'admin-more-stats',
      'admin-more-reports',
      'admin-tool-trial-data',
    ]) {
      final title = tester.widget<Text>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(Text),
        ),
      );
      expect(title.style?.color, AdminConsoleTheme.ice);
      expect(title.style?.fontSize, greaterThanOrEqualTo(15));
    }
    expect(find.byKey(const Key('admin-tool-shops')), findsNothing);
    expect(find.byKey(const Key('admin-menu-weather')), findsNothing);
    expect(find.byKey(const Key('admin-tool-posts')), findsNothing);
    expect(find.byKey(const Key('admin-sub-contracts-terms')), findsNothing);
    expect(find.byKey(const Key('admin-sub-contracts-inbox')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('admin-tool-trial-data')));
    await tester.tap(find.byKey(const Key('admin-tool-trial-data')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-sub-trial-data')), findsOneWidget);
    expect(find.byKey(const Key('admin-sub-shops')), findsNothing);
    expect(find.byKey(const Key('admin-sub-posts')), findsNothing);
    expect(find.text(l10n.adminTrialDataTab), findsWidgets);
  });

  testWidgets('narrow layout shows bottom 5 and more sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(isAdmin: true),
        devicePinStore: MemoryDevicePinStore(),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await loadKo();
    await openAdmin(tester);

    expect(find.byKey(const Key('admin-layout-narrow')), findsOneWidget);
    expect(find.byKey(const Key('admin-bottom-nav')), findsOneWidget);
    expect(find.text(l10n.adminNavMore), findsOneWidget);

    await tester.tap(find.text(l10n.adminTabBookings));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-sub-bookings')), findsOneWidget);

    await tester.tap(find.text(l10n.adminNavMore));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-nav-more-sheet')), findsOneWidget);
    expect(find.byKey(const Key('admin-tool-shops')), findsNothing);
    expect(find.byKey(const Key('admin-menu-weather')), findsNothing);
    expect(find.byKey(const Key('admin-tool-posts')), findsNothing);
    expect(find.byKey(const Key('admin-sub-contracts-terms')), findsNothing);
    expect(find.byKey(const Key('admin-sub-contracts-inbox')), findsNothing);
    expect(find.text(l10n.weatherAdminTitle), findsNothing);
    expect(find.text(l10n.adminPostsTitle), findsNothing);
    await tester.tap(find.byKey(const Key('admin-more-dive-star')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-sub-dive-star-apps')), findsOneWidget);
    expect(find.byKey(const Key('admin-sub-dive-star-review')), findsOneWidget);
  });
}
