import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

MemberAccount _member({
  required String uid,
  String name = '이름',
  String email = '',
  String loginId = '',
  DateTime? createdAt,
  DateTime? lastSeenAt,
}) {
  return MemberAccount(
    uid: uid,
    email: email,
    displayName: name,
    grade: MemberGrade.silver,
    loginId: loginId,
    createdAt: createdAt,
    lastSeenAt: lastSeenAt,
  );
}

void main() {
  test('최근 로그인이 앞이고, 없으면 가입이 늦은 순이다', () {
    final recent = _member(uid: 'recent', lastSeenAt: DateTime(2026, 10, 20));
    final olderLogin = _member(
      uid: 'older-login',
      lastSeenAt: DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 10, 25),
    );
    final newerSignup = _member(uid: 'newer-signup', createdAt: DateTime(2026, 10, 26));
    final olderSignup = _member(uid: 'older-signup', createdAt: DateTime(2026, 1, 1));
    final undated = _member(uid: 'undated');

    final list = [undated, olderSignup, newerSignup, olderLogin, recent]
      ..sort(compareMembersByRecentLogin);

    expect(
      list.map((member) => member.uid),
      ['recent', 'older-login', 'newer-signup', 'older-signup', 'undated'],
    );
  });

  test('저장된 회원 목록도 최근 로그인 순이다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.touchLastSeen('test-user');
    final members = await repo.fetchMembers();
    expect(members.first.uid, 'test-user');
    expect(members[1].uid, 'pending-instructor');
  });

  testWidgets('이름 아래 아이디를 보여주고 이름·아이디·이메일·UID로 찾는다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.ensureUserDocument(
      const AppUser(uid: 'named-sea', email: 'sea.kim@dive.test', displayName: '김바다'),
      loginId: 'SeaLog',
    );
    await repo.ensureUserDocument(
      const AppUser(uid: 'plain-diver', email: 'plain@dive.test', displayName: '다이버'),
      loginId: 'reefkid',
    );
    await repo.ensureUserDocument(
      const AppUser(uid: 'blank-name', email: 'only.mail@dive.test', displayName: ''),
    );
    await repo.touchLastSeen('test-user');

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

    expect(
      tester.widget<Text>(find.byKey(const Key('admin-member-name-named-sea'))).data,
      '김바다',
    );
    final login = tester.widget<Text>(find.byKey(const Key('admin-member-login-named-sea')));
    expect(login.data, 'sealog');
    expect(login.style?.fontSize, 11);
    expect(login.style?.color, AdminConsoleTheme.muted);

    expect(
      tester.widget<Text>(find.byKey(const Key('admin-member-name-plain-diver'))).data,
      'reefkid',
    );
    expect(find.byKey(const Key('admin-member-login-plain-diver')), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('admin-member-name-blank-name'))).data,
      'only.mail',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('admin-member-login-test-user'))).data,
      'test',
    );

    final order = tester
        .widgetList<Text>(
          find.byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> && key.value.startsWith('admin-member-name-');
          }),
        )
        .map((text) => (text.key! as ValueKey<String>).value)
        .toList();
    expect(order, [
      'admin-member-name-test-user',
      'admin-member-name-pending-instructor',
      'admin-member-name-blank-name',
      'admin-member-name-named-sea',
      'admin-member-name-plain-diver',
    ]);

    Future<void> search(String query, String visibleUid) async {
      await tester.enterText(find.byKey(const Key('admin-members-search')), query);
      await tester.pump();
      expect(find.byKey(Key('admin-member-name-$visibleUid')), findsOneWidget);
      expect(find.byKey(const Key('admin-member-name-test-user')), findsNothing);
    }

    await search('김바다', 'named-sea');
    await search('sealog', 'named-sea');
    await search('only.mail@dive.test', 'blank-name');
    await search('pending-instructor', 'pending-instructor');
  });
}
