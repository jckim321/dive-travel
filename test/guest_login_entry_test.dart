import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('홈·마이페이지 로그인 입구가 시트를 열고, 로그아웃하면 홈으로 간다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository();
    await tester.pumpWidget(
      DiveTravelApp(firebaseReady: true, repository: repo),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    expect(find.byKey(const Key('home-auth-button')), findsOneWidget);
    expect(find.text(l10n.authLogin), findsWidgets);

    await tester.tap(find.byKey(const Key('home-auth-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth-credentials-form')), findsOneWidget);
    Navigator.of(
      tester.element(find.byKey(const Key('auth-credentials-form'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-guest-login')), findsOneWidget);
    expect(find.text(l10n.profileGuestLoginPrompt), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile-guest-login-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth-credentials-form')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('auth-login-id')), '바다');
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret12');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth-credentials-form')), findsNothing);
    expect(find.byKey(const Key('profile-guest-login')), findsNothing);
    expect(find.byKey(const Key('profile-departure-desk')), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-profile-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-sign-out')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-scroll')), findsOneWidget);
    expect(find.byKey(const Key('home-auth-button')), findsOneWidget);
    expect(find.text(l10n.authLogin), findsWidgets);
  });
}
