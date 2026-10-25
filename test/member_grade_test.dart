import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('활동 AND 조건으로 등급이 정해진다', () {
    expect(MemberGrade.parse(null), MemberGrade.silver);
    expect(
      MemberGrade.fromActivity(paidPurchases: 0, reviews: 0),
      MemberGrade.silver,
    );
    expect(
      MemberGrade.fromActivity(paidPurchases: 3, reviews: 0),
      MemberGrade.silver,
    );
    expect(
      MemberGrade.fromActivity(paidPurchases: 3, reviews: 1),
      MemberGrade.gold,
    );
    expect(
      MemberGrade.fromActivity(paidPurchases: 10, reviews: 5),
      MemberGrade.diamond,
    );
    expect(
      MemberGrade.fromActivity(paidPurchases: 30, reviews: 15),
      MemberGrade.platinum,
    );
  });

  test('관리자는 회원 등급만 바꾼다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final before = await repo.watchMembers().first;
    expect(before, isNotEmpty);

    await repo.setMemberGrade(
      uid: 'pending-instructor',
      grade: MemberGrade.diamond,
    );
    final after = await repo.watchMembers().first;
    final member = after.firstWhere((item) => item.uid == 'pending-instructor');
    expect(member.grade, MemberGrade.diamond);
    expect(member.gradeLocked, isTrue);
  });

  testWidgets('관리자 대시보드에 회원 관리 메뉴가 있다', (tester) async {
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
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

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

  test('표시 등급은 저장된 회원 등급을 따른다', () {
    expect(
      ProfileDisplayGrade.fromMember(
        grade: MemberGrade.silver,
        isInstructor: false,
      ),
      ProfileDisplayGrade.silver,
    );
    expect(
      ProfileDisplayGrade.fromMember(
        grade: MemberGrade.gold,
        isInstructor: false,
      ),
      ProfileDisplayGrade.gold,
    );
    expect(
      ProfileDisplayGrade.fromMember(
        grade: MemberGrade.silver,
        isInstructor: true,
      ),
      ProfileDisplayGrade.instructor,
    );
  });
}
