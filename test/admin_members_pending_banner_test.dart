import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Widget _app(DiverStore store, {VoidCallback? onOpenInstructors}) {
  return DiverStoreScope(
    store: store,
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AdminConsoleTheme.dark,
      home: AdminMembersScreen(onOpenInstructors: onOpenInstructors),
    ),
  );
}

void main() {
  testWidgets('대기가 있으면 배너로 승인 화면을 열고 그 줄에 인증 대기를 표시한다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    var opened = 0;

    await tester.pumpWidget(_app(store, onOpenInstructors: () => opened += 1));
    await tester.pump();
    await store.ensureAdminInboxLoaded();
    await tester.pump();

    expect(find.text('강사 인증 대기 1건 ›'), findsOneWidget);
    expect(find.byKey(const Key('admin-member-pending-pending-instructor')), findsOneWidget);
    expect(find.byKey(const Key('admin-member-pending-test-user')), findsNothing);

    await tester.tap(find.byKey(const Key('admin-members-pending-banner')));
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('대기가 없으면 배너와 인증 대기 표시를 숨긴다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.approveInstructor('pending-instructor');
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    await tester.pumpWidget(_app(store, onOpenInstructors: () {}));
    await tester.pump();
    await store.ensureAdminInboxLoaded();
    await tester.pump();

    expect(store.pendingInstructors, isEmpty);
    expect(find.byKey(const Key('admin-members-pending-banner')), findsNothing);
    expect(find.textContaining('강사 인증 대기'), findsNothing);
    expect(find.byKey(const Key('admin-member-pending-pending-instructor')), findsNothing);
  });
}
