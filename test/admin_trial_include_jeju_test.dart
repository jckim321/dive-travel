import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/trial_data_cleanup.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_trial_data_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Widget _app(DiverStore store) {
  return DiverStoreScope(
    store: store,
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AdminConsoleTheme.dark,
      home: const AdminTrialDataScreen(),
    ),
  );
}

void main() {
  testWidgets('제주 오렌지 스위치는 꺼져 있고, 켤 때만 확인 창이 나온다', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    repo.seedShopName('jeju-orange-1', kJejuOrangeShopName);
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    await tester.pumpWidget(_app(store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final sw = find.byKey(const Key('admin-trial-include-jeju'));
    expect(sw, findsOneWidget);
    expect(tester.widget<SwitchListTile>(sw).value, isFalse);

    await tester.tap(sw);
    await tester.pump();
    expect(find.byKey(const Key('admin-trial-include-jeju-dialog')), findsOneWidget);
    expect(find.text('제주 오렌지도 지울까요?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-trial-include-jeju-cancel')));
    await tester.pump();
    expect(find.byKey(const Key('admin-trial-include-jeju-dialog')), findsNothing);
    expect(tester.widget<SwitchListTile>(sw).value, isFalse);

    await tester.tap(sw);
    await tester.pump();
    await tester.tap(find.byKey(const Key('admin-trial-include-jeju-confirm')));
    await tester.pump();
    expect(tester.widget<SwitchListTile>(sw).value, isTrue);
  });
}
