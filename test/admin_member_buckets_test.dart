import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/app_user.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> _add({
  required MemoryDiverRepository repo,
  required String uid,
  required String name,
  MemberGrade grade = MemberGrade.silver,
  bool instructor = false,
  bool partner = false,
}) async {
  await repo.ensureUserDocument(
    AppUser(uid: uid, email: '$uid@dive.test', displayName: name),
  );
  if (grade != MemberGrade.silver) {
    await repo.setMemberGrade(uid: uid, grade: grade);
  }
  if (instructor) {
    await repo.approveInstructor(uid);
  }
  if (partner) {
    await repo.promoteMemberToPartner(
      uid: uid,
      shopId: 'shop-$uid',
      actorUid: 'test-user',
      actorName: '테스트',
    );
  }
}

int _cardCount(WidgetTester tester, String filter) {
  final card = find.byKey(Key('admin-member-filter-$filter'));
  final count = tester.widget<Text>(
    find.descendant(of: card, matching: find.byType(Text)).first,
  );
  return int.parse(count.data!);
}

void main() {
  testWidgets('카드 합이 전체와 같고 겹치는 사람은 한 칸에만 나온다', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.approveInstructor('test-user');
    await _add(repo: repo, uid: 'silver-partner', name: '은빛파트너', partner: true);
    await _add(repo: repo, uid: 'gold-diver', name: '골드다이버', grade: MemberGrade.gold);
    await _add(
      repo: repo,
      uid: 'teach-gold',
      name: '골드강사',
      grade: MemberGrade.gold,
      instructor: true,
    );
    await _add(repo: repo, uid: 'gem', name: '다이아', grade: MemberGrade.diamond);
    await _add(repo: repo, uid: 'top', name: '플래티넘', grade: MemberGrade.platinum);
    await _add(repo: repo, uid: 'closed', name: '차단회원');
    await repo.setAccountBlocked(
      uid: 'closed',
      blocked: true,
      actorUid: 'test-user',
    );

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
    await store.ensureAdminInboxLoaded();
    await tester.pump();

    const filters = [
      'silver',
      'gold',
      'diamond',
      'platinum',
      'instructor',
      'partner',
      'admin',
    ];
    final total = _cardCount(tester, 'all');
    final sum = filters.fold<int>(0, (sum, filter) => sum + _cardCount(tester, filter));
    expect(total, 7);
    expect(sum, total);
    expect(find.byKey(const Key('admin-member-name-closed')), findsNothing);

    const expected = {
      'all': [
        'test-user',
        'pending-instructor',
        'silver-partner',
        'gold-diver',
        'teach-gold',
        'gem',
        'top',
      ],
      'silver': ['pending-instructor'],
      'gold': ['gold-diver'],
      'diamond': ['gem'],
      'platinum': ['top'],
      'instructor': ['teach-gold'],
      'partner': ['silver-partner'],
      'admin': ['test-user'],
    };

    for (final entry in expected.entries) {
      await tester.tap(find.byKey(Key('admin-member-filter-${entry.key}')));
      await tester.pump();
      expect(_cardCount(tester, entry.key == 'all' ? 'all' : entry.key), entry.value.length);
      for (final uid in expected['all']!) {
        final row = find.byKey(Key('admin-member-name-$uid'));
        expect(
          row,
          entry.value.contains(uid) ? findsOneWidget : findsNothing,
          reason: '${entry.key} / $uid',
        );
      }
    }
  });

  testWidgets('회원 위 탭은 회원, 제휴 리조트, 제휴 신청이다', (tester) async {
    late AppLocalizations ko;
    late AppLocalizations en;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            ko = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            en = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(ko.adminMembersSubGeneral, '회원');
    expect(ko.adminMembersSubPartners, '제휴 리조트');
    expect(ko.partnerApplyTitle, '제휴 신청');
    expect(en.adminMembersSubGeneral, 'Members');
    expect(en.adminMembersSubPartners, 'Partner resorts');
  });
}
