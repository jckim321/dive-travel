import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/auth/password_change.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/features/profile/presentation/profile_settings_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('인증 오류 코드는 비밀번호 없이 이유만 나눈다', () {
    expect(
      passwordChangeCodeForAuth('wrong-password'),
      PasswordChangeException.wrong,
    );
    expect(
      passwordChangeCodeForAuth('invalid-credential'),
      PasswordChangeException.wrong,
    );
    expect(
      passwordChangeCodeForAuth('weak-password'),
      PasswordChangeException.tooShort,
    );
    expect(
      passwordChangeCodeForAuth('requires-recent-login'),
      PasswordChangeException.relogin,
    );
    expect(
      const PasswordChangeException(PasswordChangeException.wrong).toString(),
      'PasswordChangeException(WRONG_PASSWORD)',
    );
  });

  test('현재 비밀번호로 다시 확인한 뒤에만 바꾸고 프로필에는 남기지 않는다', () async {
    final repo = MemoryDiverRepository();
    const email = 'wave@users.dive-travel.app';
    const current = 'secret12';
    const next = 'nextpass';
    await repo.signUp(
      email: email,
      password: current,
      displayName: '웨이브',
      loginId: 'waveuser',
    );
    final writes = repo.debugEnsureCount;

    await expectLater(
      repo.changePassword(currentPassword: 'nope12', newPassword: next),
      throwsA(
        isA<PasswordChangeException>().having(
          (error) => error.code,
          'code',
          PasswordChangeException.wrong,
        ),
      ),
    );
    await expectLater(
      repo.changePassword(currentPassword: current, newPassword: 'abc'),
      throwsA(
        isA<PasswordChangeException>().having(
          (error) => error.code,
          'code',
          PasswordChangeException.tooShort,
        ),
      ),
    );

    repo.debugPasswordChangeCode = PasswordChangeException.relogin;
    await expectLater(
      repo.changePassword(currentPassword: current, newPassword: next),
      throwsA(
        isA<PasswordChangeException>().having(
          (error) => error.code,
          'code',
          PasswordChangeException.relogin,
        ),
      ),
    );

    await repo.changePassword(currentPassword: current, newPassword: next);
    expect(repo.debugEnsureCount, writes);
    await expectLater(
      repo.changePassword(currentPassword: current, newPassword: 'other12'),
      throwsA(
        isA<PasswordChangeException>().having(
          (error) => error.code,
          'code',
          PasswordChangeException.wrong,
        ),
      ),
    );
    await repo.changePassword(currentPassword: next, newPassword: 'other12');

    await repo.signOut();
    await expectLater(
      repo.changePassword(currentPassword: 'other12', newPassword: 'other13'),
      throwsA(
        isA<PasswordChangeException>().having(
          (error) => error.code,
          'code',
          PasswordChangeException.relogin,
        ),
      ),
    );
  });

  testWidgets('로그인 회원 설정에서 비밀번호를 바꾸면 안내 한 줄만 남는다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository();
    const current = 'secret12';
    const next = 'nextpass';
    await repo.signUp(
      email: 'wave@users.dive-travel.app',
      password: current,
      displayName: '웨이브',
      loginId: 'waveuser',
    );
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);

    await tester.pumpWidget(_settings(store, session));
    await tester.pump();
    await tester.pump();

    await _submit(tester, current: 'nope12', next: next, again: next);
    expect(find.text('현재 비밀번호가 틀려요'), findsOneWidget);

    await _submit(tester, current: current, next: 'abc', again: 'abc');
    expect(find.text('새 비밀번호는 6자 이상이어야 해요'), findsOneWidget);

    await _submit(tester, current: current, next: next, again: 'other12');
    expect(find.text('새 비밀번호가 서로 달라요'), findsOneWidget);

    await _submit(tester, current: current, next: next, again: next);
    expect(find.text('비밀번호를 바꿨어요'), findsOneWidget);
    expect(find.text(current), findsNothing);
    expect(find.text(next), findsNothing);
    expect(_fieldText(tester, 'profile-password-current'), isEmpty);
    expect(_fieldText(tester, 'profile-password-new'), isEmpty);
    expect(_fieldText(tester, 'profile-password-confirm'), isEmpty);

    await _submit(tester, current: current, next: 'other12', again: 'other12');
    expect(find.text('현재 비밀번호가 틀려요'), findsOneWidget);

    await _submit(tester, current: next, next: 'other12', again: 'other12');
    expect(find.text('비밀번호를 바꿨어요'), findsOneWidget);
  });

  testWidgets('관리자와 파트너 설정에도 비밀번호 변경이 있다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true, isBusiness: true);
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);

    await tester.pumpWidget(_settings(store, session));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('open-admin-mode')), findsOneWidget);
    expect(find.byKey(const Key('profile-password-title')), findsOneWidget);
    await _submit(tester, current: 'nope12', next: 'other12', again: 'other12');
    expect(find.text('다시 로그인해 주세요'), findsOneWidget);
  });
}

Widget _settings(DiverStore store, SessionController session) {
  return DiverStoreScope(
    store: store,
    child: SessionScope(
      session: session,
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfileSettingsScreen(),
      ),
    ),
  );
}

Future<void> _submit(
  WidgetTester tester, {
  required String current,
  required String next,
  required String again,
}) async {
  await tester.ensureVisible(find.byKey(const Key('profile-password-current')));
  await tester.enterText(find.byKey(const Key('profile-password-current')), current);
  await tester.enterText(find.byKey(const Key('profile-password-new')), next);
  await tester.enterText(find.byKey(const Key('profile-password-confirm')), again);
  await tester.ensureVisible(find.byKey(const Key('profile-password-submit')));
  await tester.tap(find.byKey(const Key('profile-password-submit')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

String _fieldText(WidgetTester tester, String key) {
  return tester.widget<TextField>(find.byKey(Key(key))).controller?.text ?? '';
}
