import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/auth/auth_identity.dart';
import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_credentials_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('아이디 폼은 로그인 탭이 기본이고 기존 아이디 매핑을 유지한다', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    AuthCredentials? submitted;
    await tester.pumpWidget(
      MaterialApp(
        locale: AppConstants.defaultLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AuthCredentialsForm(
            onSubmit: (credentials) async {
              submitted = credentials;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.authWelcomeBack), findsWidgets);
    expect(find.byKey(const Key('auth-submit')), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('auth-keep-signed-in')))
          .value,
      isTrue,
    );

    await tester.enterText(find.byKey(const Key('auth-login-id')), 'admin');
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret12');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();
    expect(find.text(l10n.authErrorLoginIdReserved), findsOneWidget);
    expect(submitted, isNull);

    await tester.tap(find.byKey(const Key('auth-keep-signed-in')));
    await tester.enterText(find.byKey(const Key('auth-login-id')), 'Jong_01');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();
    expect(submitted, isNotNull);
    expect(submitted!.signUp, isFalse);
    expect(submitted!.keepSignedIn, isFalse);
    expect(submitted!.loginId, 'jong_01');
    expect(
      submitted!.authEmail,
      'jong_01@${AuthIdentity.syntheticDomain}',
    );

    submitted = null;
    await tester.enterText(find.byKey(const Key('auth-login-id')), '바다');
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret12');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pump();
    expect(submitted!.signUp, isFalse);
    expect(submitted!.authEmail.startsWith('u_'), isTrue);
    expect(submitted!.authEmail.contains('바다'), isFalse);
    expect(submitted!.loginId, '바다');
  });

  Future<void> pumpForm(WidgetTester tester, {Locale? locale, SessionController? session}) async {
    final form = AuthCredentialsForm(onSubmit: (_) async {});
    await tester.pumpWidget(
      MaterialApp(
        locale: locale ?? AppConstants.defaultLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: session == null
              ? form
              : SessionScope(session: session, child: form),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('로그인 칸 문구와 비밀번호 찾기', (tester) async {
    await pumpForm(tester);
    expect(find.text('이메일 또는 아이디'), findsWidgets);
    expect(find.text('비밀번호 찾기'), findsOneWidget);

    await tester.tap(find.byKey(const Key('auth-forgot-password')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('auth-reset-email')), 'sea');
    await tester.tap(find.byKey(const Key('auth-reset-send')));
    await tester.pump();
    expect(
      find.text('아이디로 가입하신 계정은 help@divetravel.com으로 문의해 주세요.'),
      findsOneWidget,
    );
  });

  testWidgets('골뱅이가 있으면 안내 메일을 보냈다고 한다', (tester) async {
    final repo = MemoryDiverRepository.forTest();
    final session = SessionController(repo);
    addTearDown(session.dispose);
    await pumpForm(tester, session: session);
    await tester.tap(find.byKey(const Key('auth-forgot-password')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('auth-reset-email')),
      'diver@dive.test',
    );
    await tester.tap(find.byKey(const Key('auth-reset-send')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.text('가입한 이메일이라면 안내 메일을 보냈어요. 스팸함도 확인해 보세요.'),
      findsOneWidget,
    );
  });

  testWidgets('english login field says Email or ID', (tester) async {
    await pumpForm(tester, locale: const Locale('en'));
    expect(find.text('Email or ID'), findsWidgets);
    expect(find.text('Forgot password'), findsOneWidget);
  });
}
