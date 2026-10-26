import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/constants/nationality.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('국가 목록은 한국이 맨 앞이고 없는 코드는 저장하지 않는다', () {
    expect(nationalityChoices().first.code, 'KR');
    expect(normalizeNationalityCode(''), isNull);
    expect(normalizeNationalityCode('zz'), isNull);
    expect(normalizeNationalityCode('kr'), 'KR');
  });

  test('선택 안 함은 국적과 동의 시각을 만들지 않는다', () async {
    final repo = MemoryDiverRepository();
    const email = 'skip@users.dive-travel.app';
    await repo.signUp(
      email: email,
      password: 'secret12',
      displayName: '건너뜀',
      loginId: 'skipuser',
    );
    final snap = await repo.watchDiver('memory-${email.hashCode}').first;
    expect(snap.stats.nationality, isEmpty);
    expect(snap.stats.nationalityConsentAt, isNull);
  });

  test('국적을 고르면 코드와 동의 시각을 같이 저장하고 지우면 둘 다 없다', () async {
    final repo = MemoryDiverRepository();
    const email = 'korea@users.dive-travel.app';
    final uid = 'memory-${email.hashCode}';
    await repo.signUp(
      email: email,
      password: 'secret12',
      displayName: '한국',
      loginId: 'koreauser',
      nationality: 'KR',
    );
    final saved = await repo.watchDiver(uid).first;
    expect(saved.stats.nationality, 'KR');
    expect(saved.stats.nationalityConsentAt, isNotNull);

    await repo.signIn(email: email, password: 'secret12');
    final still = await repo.watchDiver(uid).first;
    expect(still.stats.nationality, 'KR');
    expect(still.stats.nationalityConsentAt, isNotNull);

    await repo.clearNationality(uid);
    final cleared = await repo.watchDiver(uid).first;
    expect(cleared.stats.nationality, isEmpty);
    expect(cleared.stats.nationalityConsentAt, isNull);

    await repo.setNationality(uid: uid, code: 'JP');
    final changed = await repo.watchDiver(uid).first;
    expect(changed.stats.nationality, 'JP');
    expect(changed.stats.nationalityConsentAt, isNotNull);
  });

  testWidgets('가입 화면은 이름표와 비밀번호만 받고 국적 동의를 묻지 않는다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository(),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    expect(find.text(l10n.authFirstVisit), findsOneWidget);
    expect(find.byKey(const Key('auth-nationality')), findsNothing);
    expect(find.text(nationalityConsentKo), findsNothing);

    await tester.enterText(find.byKey(const Key('auth-login-id')), '바다');
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret12');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.profileNationalityNeedConsent), findsNothing);
    expect(find.byKey(const Key('auth-submit')), findsNothing);
  });
}
