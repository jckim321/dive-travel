import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('신규 회원 기본 등급은 회원이다', () {
    expect(MemberGrade.parse(null), MemberGrade.member);
    expect(
      MemberGrade.suggested(
        totalLogCount: 0,
        uniqueRegionsCount: 0,
        isInstructor: false,
      ),
      MemberGrade.member,
    );
    expect(
      MemberGrade.suggested(
        totalLogCount: 12,
        uniqueRegionsCount: 1,
        isInstructor: false,
      ),
      MemberGrade.special,
    );
  });

  test('관리자는 회원 등급만 바꾼다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final before = await repo.watchMembers().first;
    expect(before, isNotEmpty);

    await repo.setMemberGrade(
      uid: 'pending-instructor',
      grade: MemberGrade.vip,
    );
    final after = await repo.watchMembers().first;
    expect(
      after.firstWhere((item) => item.uid == 'pending-instructor').grade,
      MemberGrade.vip,
    );
  });

  testWidgets('관리자 대시보드에 회원 관리 메뉴가 있다', (tester) async {
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(isAdmin: true),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-admin-mode')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin-pin-field')),
      AppConstants.adminPin,
    );
    await tester.tap(find.byKey(const Key('admin-pin-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-menu-members')), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-menu-members')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.adminMembersTitle), findsWidgets);
    expect(find.text('대기 강사'), findsOneWidget);
  });
}
