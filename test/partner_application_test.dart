import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/partner_application.dart';
import 'package:dive_travel_app/features/profile/presentation/partner_application_link_line.dart';
import 'package:dive_travel_app/features/profile/presentation/partner_application_screen.dart';
import 'package:dive_travel_app/features/profile/presentation/profile_settings_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<PartnerApplication> apply(MemoryDiverRepository repo) {
    return repo.createPartnerApplication(
      applicantUid: 'member-1',
      loginId: 'member1',
      shopName: '푸른 다이브',
      contactName: '김다이브',
      phone: '010-0000-0000',
      region: '제주',
      intro: '하우스 리프',
      link: 'javascript:alert(1)',
      consent: true,
    );
  }

  test('빈 소개나 동의 없음은 저장하지 않고 한 사람 한 건이다', () async {
    final repo = MemoryDiverRepository.forTest();
    expect(repo.applicationReadCount, 0);
    expect(
      () => repo.createPartnerApplication(
        applicantUid: 'member-1',
        loginId: 'member1',
        shopName: '푸른 다이브',
        contactName: '김다이브',
        phone: '010',
        region: '제주',
        intro: '   ',
        link: '',
        consent: true,
      ),
      throwsA(isA<PartnerApplicationInvalid>()),
    );
    expect(
      () => repo.createPartnerApplication(
        applicantUid: 'member-1',
        loginId: 'member1',
        shopName: '푸른 다이브',
        contactName: '김다이브',
        phone: '010',
        region: '제주',
        intro: '하우스 리프',
        link: '',
        consent: false,
      ),
      throwsA(isA<PartnerApplicationInvalid>()),
    );
    expect(await repo.getPartnerApplication('member-1'), isNull);

    final created = await apply(repo);
    expect(repo.applicationReadCount, 1);
    expect(
      () => apply(repo),
      throwsStateError,
    );
    expect(repo.applicationReadCount, 1);
    final saved = await repo.getPartnerApplication('member-1');
    expect(repo.applicationReadCount, 2);
    expect(saved?.applicantUid, created.applicantUid);
    expect(saved?.intro, '하우스 리프');
    expect(saved?.status, PartnerApplicationStatus.incoming);
  });

  test('신청을 저장한 뒤에는 다시 읽지 않는다', () async {
    final repo = MemoryDiverRepository.forTest();
    final created = await apply(repo);
    expect(repo.applicationReadCount, 0);
    expect(created.link, 'javascript:alert(1)');
    expect(created.consent, isTrue);
    final saved = await repo.getPartnerApplication('member-1');
    expect(repo.applicationReadCount, 1);
    expect(saved?.shopName, '푸른 다이브');
  });

  test('javascript 주소는 열 수 있는 주소가 아니다', () {
    expect(partnerApplicationHttpsUri('javascript:alert(1)'), isNull);
    expect(partnerApplicationHttpsUri(' JavaScript:alert(1)'), isNull);
    expect(partnerApplicationHttpsUri('data:text/html,hi'), isNull);
    expect(partnerApplicationHttpsUri('http://example.com'), isNull);
    expect(partnerApplicationHttpsUri(''), isNull);
    final https = partnerApplicationHttpsUri('https://example.com/shop');
    expect(https, isNotNull);
    expect(https!.scheme, 'https');
  });

  testWidgets('신청 링크는 글자와 복사만 있고 열리지 않는다', (tester) async {
    const raw = 'javascript:alert(1)';
    String? copied;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PartnerApplicationLinkLine(
            link: raw,
            onCopy: (value) => copied = value,
          ),
        ),
      ),
    );
    expect(find.text(raw), findsOneWidget);
    expect(find.byKey(const Key('partner-application-link-copy')), findsOneWidget);
    expect(partnerApplicationHttpsUri(raw), isNull);

    await tester.tap(find.byKey(const Key('partner-application-link-text')));
    await tester.pump();
    expect(copied, isNull);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('partner-application-link-copy')));
    await tester.pump();
    expect(copied, raw);
  });

  testWidgets('동의한 뒤 보내면 접수 문구만 남는다', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryDiverRepository.forTest();
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PartnerApplicationScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('partner-apply-form')), findsOneWidget);
    final send = tester.widget<FilledButton>(
      find.byKey(const Key('partner-apply-send')),
    );
    expect(send.onPressed, isNull);

    await tester.enterText(find.byKey(const Key('partner-apply-shop')), '푸른 다이브');
    await tester.enterText(find.byKey(const Key('partner-apply-contact')), '김다이브');
    await tester.enterText(find.byKey(const Key('partner-apply-phone')), '010');
    await tester.enterText(find.byKey(const Key('partner-apply-region')), '제주');
    await tester.enterText(find.byKey(const Key('partner-apply-intro')), '하우스 리프');
    await tester.enterText(
      find.byKey(const Key('partner-apply-link')),
      'javascript:alert(1)',
    );
    await tester.tap(find.byKey(const Key('partner-apply-consent')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('partner-apply-send')));
    await tester.tap(find.byKey(const Key('partner-apply-send')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.partnerApplySent), findsOneWidget);
    expect(find.byKey(const Key('partner-apply-send')), findsNothing);
    expect(find.text('javascript:alert(1)'), findsOneWidget);
    final saved = await repo.getPartnerApplication('test-user');
    expect(saved?.shopName, '푸른 다이브');
    expect(saved?.status, PartnerApplicationStatus.incoming);
  });

  testWidgets('이미 신청이 있으면 내용만 보여주고 보내기는 없다', (tester) async {
    final repo = MemoryDiverRepository.forTest();
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await repo.createPartnerApplication(
      applicantUid: 'test-user',
      loginId: 'test',
      shopName: '푸른 다이브',
      contactName: '김다이브',
      phone: '010',
      region: '제주',
      intro: '하우스 리프',
      link: 'javascript:alert(1)',
      consent: true,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PartnerApplicationScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('partner-apply-readonly')), findsOneWidget);
    expect(find.textContaining('푸른 다이브'), findsOneWidget);
    expect(find.text('javascript:alert(1)'), findsOneWidget);
    expect(find.byKey(const Key('partner-apply-send')), findsNothing);
    expect(find.text(l10n.partnerApplySent), findsNothing);
    expect(find.byKey(const Key('partner-application-link-copy')), findsOneWidget);
  });

  testWidgets('일반회원 설정에만 제휴 신청이 있다', (tester) async {
    Future<void> pumpSettings(MemoryDiverRepository repo) async {
      final store = DiverStore(repo);
      final session = SessionController(repo);
      addTearDown(store.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(
        DiverStoreScope(
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
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    await pumpSettings(MemoryDiverRepository.forTest());
    expect(find.byKey(const Key('profile-partner-apply')), findsOneWidget);

    await pumpSettings(MemoryDiverRepository.forTest(isBusiness: true));
    expect(find.byKey(const Key('profile-partner-apply')), findsNothing);

    await pumpSettings(MemoryDiverRepository.forTest(isAdmin: true));
    expect(find.byKey(const Key('profile-partner-apply')), findsNothing);
  });
}
