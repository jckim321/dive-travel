import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('등급은 바로 바뀌고, 진행 중이던 재조회 결과는 쓰지 않는다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await pumpEventQueue();
    await store.ensureAdminInboxLoaded();

    const uid = 'test-user';
    expect(
      store.members.firstWhere((member) => member.uid == uid).grade,
      MemberGrade.silver,
    );

    final gate = Completer<void>();
    var fetches = 0;
    repo.debugDelayFetchMembers = () async {
      fetches += 1;
      if (fetches == 1) {
        await gate.future;
      }
    };
    final stale = store.refreshAdminInbox();
    await pumpEventQueue();

    final grades = <MemberGrade>[];
    store.addListener(() {
      grades.add(
        store.members.firstWhere((member) => member.uid == uid).grade,
      );
    });

    final write = store.setMemberGrade(uid: uid, grade: MemberGrade.gold);
    await pumpEventQueue();
    expect(
      store.members.firstWhere((member) => member.uid == uid).grade,
      MemberGrade.gold,
    );

    gate.complete();
    await stale;
    await write;
    for (var i = 0; i < 10 && fetches < 2; i++) {
      await pumpEventQueue();
    }

    expect(fetches, greaterThanOrEqualTo(2));
    expect(
      store.members.firstWhere((member) => member.uid == uid).grade,
      MemberGrade.gold,
    );
    expect(grades, isNot(contains(MemberGrade.silver)));
  });

  test('실패한 관리자 해제는 목록을 되돌린다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await pumpEventQueue();
    await store.ensureAdminInboxLoaded();

    const uid = 'test-user';
    final flags = <bool>[];
    store.addListener(() {
      flags.add(
        store.members.firstWhere((member) => member.uid == uid).isAdmin,
      );
    });
    await expectLater(
      store.setMemberAdmin(uid: uid, admin: false),
      throwsA(isA<StateError>()),
    );
    expect(
      store.members.firstWhere((member) => member.uid == uid).isAdmin,
      isTrue,
    );
    expect(flags, contains(false));
    expect(flags.last, isTrue);
  });

  testWidgets('아바타를 누르면 상세가 열리고 줄은 52px 이상이다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AdminConsoleTheme.dark,
          home: const AdminMembersScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final open = find.byKey(const Key('admin-member-open-test-user'));
    expect(open, findsOneWidget);
    expect(tester.getSize(open).height, greaterThanOrEqualTo(52));
    await tester.tap(
      find.descendant(of: open, matching: find.byType(CircleAvatar)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-member-detail')), findsOneWidget);
  });
}
