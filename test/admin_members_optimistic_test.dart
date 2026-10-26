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

  testWidgets('강사는 맨 위 등급이고 등급 카드에는 겹쳐 세지 않는다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.setMemberGrade(uid: 'pending-instructor', grade: MemberGrade.platinum);
    await repo.approveInstructor('pending-instructor');
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

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

    expect(_cardCount(tester, 'platinum'), '0');
    expect(_cardCount(tester, 'instructor'), '1');
    expect(_cardCount(tester, 'silver'), '1');
    expect(find.byKey(const Key('admin-member-badge-admin-test-user')), findsOneWidget);
    expect(find.byKey(const Key('admin-member-badge-partner-test-user')), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('admin-member-shown-grade-pending-instructor'))).data,
      l10n.profileGradeInstructor,
    );

    await tester.tap(find.byKey(const Key('admin-member-menu-pending-instructor')));
    await tester.pumpAndSettle();
    expect(find.text('강사 해제'), findsNothing);
    expect(find.text('역할'), findsWidgets);
    await tester.tap(find.byKey(const Key('admin-member-grade-instructor-pending-instructor')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('admin-member-shown-grade-pending-instructor'))).data,
      l10n.memberGradePlatinum,
    );
    expect(_cardCount(tester, 'instructor'), '0');
    expect(_cardCount(tester, 'platinum'), '1');
    final restored = (await repo.fetchMembers()).firstWhere((m) => m.uid == 'pending-instructor');
    expect(restored.isInstructor, isFalse);
    expect(restored.grade, MemberGrade.platinum);

    await tester.tap(find.byKey(const Key('admin-member-menu-test-user')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-member-grade-instructor-test-user')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('admin-member-shown-grade-test-user'))).data,
      l10n.profileGradeInstructor,
    );
    final promoted = (await repo.fetchMembers()).firstWhere((m) => m.uid == 'test-user');
    expect(promoted.isInstructor, isTrue);
    expect(promoted.grade, MemberGrade.silver);
    expect(_cardCount(tester, 'silver'), '0');
    expect(_cardCount(tester, 'instructor'), '1');
  });
}

String _cardCount(WidgetTester tester, String filter) {
  final texts = tester.widgetList<Text>(
    find.descendant(
      of: find.byKey(Key('admin-member-filter-$filter')),
      matching: find.byType(Text),
    ),
  );
  return texts.map((text) => text.data).firstWhere((data) => int.tryParse(data ?? '') != null)!;
}
