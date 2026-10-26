import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/auth/guest_browse_store.dart';
import 'package:dive_travel_app/core/auth/known_member_store.dart';
import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_sign_in_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  late KnownMemberStore previous;

  setUp(() {
    previous = deviceKnownMember;
    guestBrowse.reset();
  });

  tearDown(() {
    deviceKnownMember = previous;
    guestBrowse.reset();
  });

  testWidgets('새 방문자는 전체 로그인 화면으로 이어진다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    deviceKnownMember = MemoryKnownMemberStore();
    final repo = MemoryDiverRepository();
    final session = SessionController(repo);
    addTearDown(session.dispose);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(
      SessionScope(
        session: session,
        child: MaterialApp(
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _GateProbe(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('waiting'), findsOneWidget);
    await tester.tap(find.byKey(const Key('gated-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('auth-full-screen')), findsOneWidget);
    expect(find.byKey(const Key('auth-sign-in-sheet')), findsNothing);
    expect(find.text(l10n.authWelcomeBack), findsWidgets);

    await tester.tap(find.byKey(const Key('auth-tab-signup')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('auth-signup-screen')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('auth-signup-login-id')),
      '바다',
    );
    await tester.enterText(
      find.byKey(const Key('auth-signup-password')),
      'secret12',
    );
    await tester.ensureVisible(find.byKey(const Key('auth-consent-terms')));
    await tester.tap(find.byKey(const Key('auth-consent-terms')));
    await tester.ensureVisible(find.byKey(const Key('auth-consent-privacy')));
    await tester.tap(find.byKey(const Key('auth-consent-privacy')));
    await tester.ensureVisible(find.byKey(const Key('auth-signup-submit')));
    await tester.tap(find.byKey(const Key('auth-signup-submit')));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (session.isSignedIn &&
          find.byKey(const Key('auth-full-screen')).evaluate().isEmpty) {
        break;
      }
    }

    expect(session.isSignedIn, isTrue);
    expect(find.byKey(const Key('auth-full-screen')), findsNothing);
    expect(find.text('continued'), findsOneWidget);
    expect(await deviceKnownMember.isKnown(), isTrue);
  });

  testWidgets('이미 가입한 기기는 간단 로그인 시트 뒤에 누르던 동작이 이어진다', (
    tester,
  ) async {
    deviceKnownMember = MemoryKnownMemberStore(known: true);
    final repo = MemoryDiverRepository();
    final session = SessionController(repo);
    addTearDown(session.dispose);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(
      SessionScope(
        session: session,
        child: MaterialApp(
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _GateProbe(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('gated-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth-sign-in-sheet')), findsOneWidget);
    expect(find.byKey(const Key('auth-full-screen')), findsNothing);
    expect(find.text(l10n.authWelcomeBack), findsWidgets);

    await tester.enterText(find.byKey(const Key('auth-login-id')), '바다');
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret12');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.text('continued'), findsOneWidget);
    expect(find.byKey(const Key('auth-credentials-form')), findsNothing);
    expect(session.isSignedIn, isTrue);
  });
}

class _GateProbe extends StatefulWidget {
  const _GateProbe();

  @override
  State<_GateProbe> createState() => _GateProbeState();
}

class _GateProbeState extends State<_GateProbe> {
  var _label = 'waiting';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_label),
          FilledButton(
            key: const Key('gated-action'),
            onPressed: () async {
              final ok = await ensureSignedIn(context);
              if (!ok || !mounted) return;
              setState(() => _label = 'continued');
            },
            child: const Text('go'),
          ),
        ],
      ),
    );
  }
}
