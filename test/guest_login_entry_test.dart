import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/auth/guest_browse_store.dart';
import 'package:dive_travel_app/core/auth/known_member_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
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

  testWidgets('둘러보기 중 로그인은 시트, 로그아웃하면 전체 로그인으로 돌아간다', (
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

    Future<void> pumpFrames([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // Cold start → full auth gate.
    expect(find.byKey(const Key('auth-full-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('auth-browse-first')));
    await pumpFrames();
    expect(find.byKey(const Key('home-auth-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-auth-button')));
    await pumpFrames();
    expect(find.byKey(const Key('auth-sign-in-sheet')), findsOneWidget);
    expect(find.byKey(const Key('auth-full-screen')), findsNothing);
    expect(find.byKey(const Key('home-auth-button')), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await pumpFrames(12);
    expect(find.byKey(const Key('auth-sign-in-sheet')), findsNothing);
    expect(find.byKey(const Key('home-auth-button')), findsOneWidget);

    await tester.tap(find.text(l10n.navProfile));
    await pumpFrames();
    expect(find.byKey(const Key('profile-guest-login')), findsOneWidget);
    await tester.tap(find.byKey(const Key('profile-guest-login-button')));
    await pumpFrames();
    expect(find.byKey(const Key('auth-sign-in-sheet')), findsOneWidget);
    expect(find.byKey(const Key('auth-full-screen')), findsNothing);
    expect(find.byKey(const Key('profile-guest-login')), findsOneWidget);

    await tester.tap(find.byKey(const Key('auth-tab-signup')));
    await pumpFrames(12);
    expect(find.byKey(const Key('auth-signup-fields')), findsOneWidget);
    expect(find.byKey(const Key('auth-signup-screen')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('auth-signup-login-id')),
      '바다',
    );
    await tester.enterText(
      find.byKey(const Key('auth-signup-password')),
      'secret12',
    );
    await tester.tap(find.byKey(const Key('auth-consent-terms')));
    await tester.tap(find.byKey(const Key('auth-consent-privacy')));
    await tester.ensureVisible(find.byKey(const Key('auth-signup-submit')));
    await tester.tap(find.byKey(const Key('auth-signup-submit')));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('auth-signup-screen')).evaluate().isEmpty &&
          find.byKey(const Key('auth-full-screen')).evaluate().isEmpty) {
        break;
      }
    }
    expect(find.byKey(const Key('profile-guest-login')), findsNothing);
    expect(find.byKey(const Key('profile-departure-desk')), findsOneWidget);
    expect(await deviceKnownMember.isKnown(), isTrue);

    await tester.tap(find.byKey(const Key('open-profile-settings')));
    await pumpFrames();
    await tester.tap(find.byKey(const Key('profile-sign-out')));
    await pumpFrames(20);

    // Sign-out clears browse and returns to the full-screen gate.
    expect(find.byKey(const Key('auth-full-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('auth-browse-first')));
    await pumpFrames();
    expect(find.byKey(const Key('home-auth-button')), findsOneWidget);

    // Returning device → compact sheet.
    await tester.tap(find.byKey(const Key('home-auth-button')));
    await pumpFrames();
    expect(find.byKey(const Key('auth-sign-in-sheet')), findsOneWidget);
    expect(find.byKey(const Key('auth-full-screen')), findsNothing);
  });
}
