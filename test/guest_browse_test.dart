import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_sign_in_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('로그인 시트 뒤에 누르던 동작이 이어진다', (tester) async {
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
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth-credentials-form')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('auth-login-id')), '바다');
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret12');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.text('continued'), findsOneWidget);
    expect(find.byKey(const Key('auth-credentials-form')), findsNothing);
    expect(session.isSignedIn, isTrue);
    expect(find.text(l10n.authStart), findsNothing);
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
