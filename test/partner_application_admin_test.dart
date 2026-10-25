import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/partner_application.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_members_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_applications_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  PartnerApplication row({
    required String uid,
    required DateTime createdAt,
    PartnerApplicationStatus status = PartnerApplicationStatus.incoming,
    String link = '',
  }) {
    return PartnerApplication(
      applicantUid: uid,
      loginId: uid,
      shopName: '푸른 다이브',
      contactName: '김다이브',
      phone: '010',
      region: '제주',
      intro: '하우스 리프',
      link: link,
      consent: true,
      status: status,
      createdAt: createdAt,
    );
  }

  test('처리함은 승격 신청 수에 들어가지 않고 화면에서 최근 순으로 정렬한다', () {
    final rows = [
      row(uid: 'old', createdAt: DateTime.utc(2026, 1, 1)),
      row(
        uid: 'done',
        createdAt: DateTime.utc(2026, 3, 1),
        status: PartnerApplicationStatus.handled,
      ),
      row(uid: 'new', createdAt: DateTime.utc(2026, 2, 1)),
    ];
    expect(countIncomingPartnerApplications(rows), 2);
    expect(
      sortPartnerApplicationsNewestFirst(rows).map((item) => item.applicantUid),
      ['done', 'new', 'old'],
    );
  });

  test('처리함으로 바꾼 뒤에는 다시 바꿀 수 없고 회원 권한은 그대로다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.createPartnerApplication(
      applicantUid: 'pending-instructor',
      loginId: 'instructor',
      shopName: '푸른 다이브',
      contactName: '김다이브',
      phone: '010',
      region: '제주',
      intro: '하우스 리프',
      link: 'javascript:alert(1)',
      consent: true,
    );
    final listed = await repo.listPartnerApplications();
    expect(listed, hasLength(1));
    await repo.markPartnerApplicationHandled(
      applicantUid: 'pending-instructor',
      adminUid: 'test-user',
    );
    final after = await repo.listPartnerApplications();
    expect(after.single.status, PartnerApplicationStatus.handled);
    expect(
      () => repo.markPartnerApplicationHandled(
        applicantUid: 'pending-instructor',
        adminUid: 'test-user',
      ),
      throwsStateError,
    );
    final members = await repo.fetchMembers();
    final member = members.singleWhere(
      (item) => item.uid == 'pending-instructor',
    );
    expect(member.isBusiness, isFalse);
  });

  testWidgets('제휴 신청 카드는 필터 없이 링크를 열지 않고 회원 보기로 넘긴다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.createPartnerApplication(
      applicantUid: 'pending-instructor',
      loginId: 'instructor',
      shopName: '푸른 다이브',
      contactName: '김다이브',
      phone: '010',
      region: '제주',
      intro: '하우스 리프',
      link: 'javascript:alert(1)',
      consent: true,
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    String? opened;

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AdminConsoleTheme.dark,
          home: AdminPartnerApplicationsScreen(
            onOpenMember: (uid) => opened = uid,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byKey(const Key('admin-apply-card-pending-instructor')), findsOneWidget);
    expect(find.text('instructor'), findsOneWidget);
    expect(find.text('푸른 다이브'), findsOneWidget);
    expect(find.textContaining(l10n.adminApplyNew), findsOneWidget);
    expect(find.text('javascript:alert(1)'), findsOneWidget);
    expect(partnerApplicationHttpsUri('javascript:alert(1)'), isNull);
    expect(
      find.byKey(const Key('partner-application-link-copy')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('partner-application-link-text')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(opened, isNull);

    await tester.tap(find.byKey(const Key('admin-apply-open-pending-instructor')));
    await tester.pump();
    expect(opened, 'pending-instructor');

    await tester.tap(
      find.byKey(const Key('admin-apply-handle-pending-instructor')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(l10n.adminApplyHandled), findsOneWidget);
    expect(
      find.byKey(const Key('admin-apply-handle-pending-instructor')),
      findsNothing,
    );
    final saved = await repo.listPartnerApplications();
    expect(saved.single.status, PartnerApplicationStatus.handled);
    final members = await repo.fetchMembers();
    expect(
      members.singleWhere((item) => item.uid == 'pending-instructor').isBusiness,
      isFalse,
    );
  });

  testWidgets('이 회원 보기는 검색에 uid를 넣고 기존 승격 버튼을 보여 준다', (tester) async {
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
          home: const AdminMembersScreen(
            focusUid: 'pending-instructor',
            focusGeneration: 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('admin-members-search')),
    );
    expect(field.controller?.text, 'pending-instructor');
    await tester.ensureVisible(
      find.byKey(const Key('admin-member-promote-pending-instructor')),
    );
    expect(
      find.byKey(const Key('admin-member-promote-pending-instructor')),
      findsOneWidget,
    );
  });
}
