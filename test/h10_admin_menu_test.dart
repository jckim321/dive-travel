import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

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
    if (find.byKey(const Key('admin-pin-field')).evaluate().isNotEmpty) {
      await tester.enterText(
        find.byKey(const Key('admin-pin-field')),
        AppConstants.adminPin,
      );
      await tester.tap(find.byKey(const Key('admin-pin-submit')));
      await tester.pumpAndSettle();
    }
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

    // H8: promote control still on member cards after menu reshape.
    final promote = find.byKey(
      const Key('admin-member-promote-pending-instructor'),
    );
    await tester.ensureVisible(promote);
    expect(promote, findsOneWidget);
    expect(find.textContaining('역할'), findsWidgets);

    await tester.tap(find.byKey(const Key('admin-menu-settlement')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-menu-pricing')), findsOneWidget);
    expect(find.byKey(const Key('admin-sub-settlement-history')), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-menu-sales')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.adminContractsComingSoon), findsWidgets);

    await tester.tap(find.byKey(const Key('admin-nav-tools')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-nav-more-sheet')), findsOneWidget);
    expect(find.byKey(const Key('admin-tool-shops')), findsOneWidget);
    expect(find.byKey(const Key('admin-menu-weather')), findsOneWidget);
    expect(find.byKey(const Key('admin-tool-posts')), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-tool-shops')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-sub-shops')), findsOneWidget);
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
    await tester.tap(find.byKey(const Key('admin-more-dive-star')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-sub-dive-star-apps')), findsOneWidget);
  });
}
