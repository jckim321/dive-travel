import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_archive_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> _openMemberList(WidgetTester tester, DiverStore store, Widget home) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    DiverStoreScope(
      store: store,
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AdminConsoleTheme.dark,
        home: home,
      ),
    ),
  );
  await tester.pump();
  await store.ensureAdminInboxLoaded();
  await tester.pump();
}

int _archiveCount(WidgetTester tester, String filter) {
  final card = find.byKey(Key('admin-archive-filter-$filter'));
  final count = tester.widget<Text>(
    find.descendant(of: card, matching: find.byType(Text)).first,
  );
  return int.parse(count.data!);
}

void main() {
  test('남은 보관 일은 30일에서 줄어 0이 된다', () {
    final start = DateTime.utc(2026, 10, 1, 3);
    expect(memberPurgeDaysRemaining(start, start), 30);
    expect(
      memberPurgeDaysRemaining(start, start.add(const Duration(days: 29, hours: 1))),
      1,
    );
    expect(memberPurgeDaysRemaining(start, start.add(const Duration(days: 30))), 0);
  });

  testWidgets('보관함 카드는 차단, 탈퇴, 휴지통으로 나뉘고 합이 전체와 같다', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.ensureUserDocument(
      const AppUser(uid: 'blocked-1', email: 'b@dive.test', displayName: '차단됨'),
    );
    await repo.setAccountBlocked(
      uid: 'blocked-1',
      blocked: true,
      actorUid: 'test-user',
    );
    await repo.ensureUserDocument(
      const AppUser(uid: 'left-1', email: 'w@dive.test', displayName: '탈퇴함'),
    );
    await repo.withdrawMember(uid: 'left-1', actorUid: 'test-user');
    await repo.ensureUserDocument(
      const AppUser(uid: 'gone-1', email: 'd@dive.test', displayName: '삭제됨'),
    );
    await repo.softDeleteMember(uid: 'gone-1', actorUid: 'test-user');

    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await _openMemberList(tester, store, const AdminMembersArchiveScreen());

    expect(_archiveCount(tester, 'all'), 3);
    expect(
      _archiveCount(tester, 'blocked') +
          _archiveCount(tester, 'withdrawn') +
          _archiveCount(tester, 'trash'),
      3,
    );
    expect(find.byKey(const Key('admin-member-name-test-user')), findsNothing);

    await tester.tap(find.byKey(const Key('admin-archive-filter-trash')));
    await tester.pump();
    expect(find.byKey(const Key('admin-member-name-gone-1')), findsOneWidget);
    expect(find.byKey(const Key('admin-member-name-blocked-1')), findsNothing);
    expect(find.byKey(const Key('admin-member-name-left-1')), findsNothing);

    await tester.tap(find.byKey(const Key('admin-archive-row-gone-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('자동 삭제까지 30일'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('admin-member-restore-gone-1')));
    await tester.tap(find.byKey(const Key('admin-member-restore-gone-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('admin-member-name-gone-1')), findsNothing);
    expect(_archiveCount(tester, 'all'), 2);
    expect(_archiveCount(tester, 'trash'), 0);
  });

  testWidgets('활동 중 회원을 삭제하면 목록에서 빠지고 휴지통에 남는다', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.ensureUserDocument(
      const AppUser(uid: 'gold-1', email: 'g@dive.test', displayName: '골드'),
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await _openMemberList(tester, store, const AdminMembersScreen());

    await tester.ensureVisible(find.byKey(const Key('admin-member-name-gold-1')));
    await tester.tap(find.byKey(const Key('admin-member-name-gold-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('admin-member-delete-gold-1')));
    await tester.tap(find.byKey(const Key('admin-member-delete-gold-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('결제된 예약 기록은 남습니다.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-member-delete-confirm-gold-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('admin-member-name-gold-1')), findsNothing);

    final gone = (await repo.fetchMembers()).singleWhere((m) => m.uid == 'gold-1');
    expect(gone.deletedAt, isNotNull);
    expect(gone.displayName, '골드');
  });

  testWidgets('본인과 리조트가 연결된 회원은 삭제할 수 없다', (tester) async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.ensureUserDocument(
      const AppUser(uid: 'partner-1', email: 'p@dive.test', displayName: '파트너'),
    );
    await repo.promoteMemberToPartner(
      uid: 'partner-1',
      shopId: 'reef-shop',
      actorUid: 'test-user',
      actorName: 'admin',
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await _openMemberList(
      tester,
      store,
      const AdminMemberDetailScreen(uid: 'test-user'),
    );
    expect(find.byKey(const Key('admin-member-self-denied-test-user')), findsOneWidget);
    expect(
      tester.widget<ListTile>(find.byKey(const Key('admin-member-delete-test-user'))).onTap,
      isNull,
    );
    expect(
      tester.widget<ListTile>(find.byKey(const Key('admin-member-block-test-user'))).onTap,
      isNull,
    );

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AdminConsoleTheme.dark,
          home: const AdminMemberDetailScreen(uid: 'partner-1'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('admin-member-shop-linked-partner-1')), findsOneWidget);
    expect(
      tester.widget<ListTile>(find.byKey(const Key('admin-member-delete-partner-1'))).onTap,
      isNull,
    );
    expect(
      tester.widget<ListTile>(find.byKey(const Key('admin-member-withdraw-partner-1'))).onTap,
      isNull,
    );
    expect(
      tester.widget<ListTile>(find.byKey(const Key('admin-member-block-partner-1'))).onTap,
      isNotNull,
    );
  });
}
