import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/auth/auth_identity.dart';
import 'package:dive_travel_app/core/constants/app_constants.dart';
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
}
