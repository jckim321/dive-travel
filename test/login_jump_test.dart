import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/auth/guest_browse_store.dart';
import 'package:dive_travel_app/core/auth/known_member_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_dashboard_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  late KnownMemberStore previous;

  setUp(() {
    previous = deviceKnownMember;
    deviceKnownMember = MemoryKnownMemberStore();
    guestBrowse.reset();
  });

  tearDown(() {
    deviceKnownMember = previous;
    guestBrowse.reset();
  });

  Future<void> signInOn(WidgetTester tester, Key idKey) async {
    await tester.ensureVisible(find.byKey(idKey));
    await tester.enterText(find.byKey(idKey), 'owner@dive.test');
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret12');
    await tester.ensureVisible(find.byKey(const Key('auth-submit')));
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('둘러보기 시트 로그인은 파트너 콘솔을 열지 않고 화면을 유지한다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isBusiness: true);
    await repo.signOut();
    await tester.pumpWidget(DiveTravelApp(firebaseReady: true, repository: repo));
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.tap(find.byKey(const Key('auth-browse-first')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-auth-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth-sign-in-sheet')), findsOneWidget);

    await signInOn(tester, const Key('auth-login-id'));

    expect(find.byType(PartnerDashboardScreen), findsNothing);
    expect(find.text(l10n.navHome), findsOneWidget);
    expect(find.byKey(const Key('auth-sign-in-sheet')), findsNothing);
  });

  testWidgets('전체화면 게이트에서 로그인한 파트너는 콘솔이 열린다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isBusiness: true);
    await repo.signOut();
    await tester.pumpWidget(DiveTravelApp(firebaseReady: true, repository: repo));
    await tester.pump();

    expect(find.byKey(const Key('auth-full-screen')), findsOneWidget);
    await signInOn(tester, const Key('auth-login-id'));

    expect(find.byType(PartnerDashboardScreen), findsOneWidget);
  });

  testWidgets('승급 축하창은 마이 탭이 앞에 있을 때만 한 번 뜬다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest();
    await tester.pumpWidget(DiveTravelApp(firebaseReady: true, repository: repo));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grade-celebration-dialog')), findsNothing);

    final nav = Navigator.of(
      tester.element(find.byKey(const Key('profile-departure-desk'))),
    );
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('cover')),
      ),
    );
    await tester.pumpAndSettle();
    await repo.setMemberGrade(uid: 'test-user', grade: MemberGrade.gold);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grade-celebration-dialog')), findsNothing);

    nav.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('grade-celebration-dialog')), findsOneWidget);
  });
}
