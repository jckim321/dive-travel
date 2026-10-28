import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/theme/region_neon.dart';
import 'package:dive_travel_app/features/profile/presentation/diving_passport_card.dart';
import 'package:dive_travel_app/features/profile/presentation/profile_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('도장 색은 20회에서 지도의 금색 기준에 닿는다', () {
    expect(regionNeonColor(0), regionNeonTeal);
    expect(regionNeonColor(1), isNot(regionNeonTeal));
    expect(regionNeonColor(1), isNot(regionNeonGold));
    expect(
      regionNeonColor(AppRegionThresholds.goldenLogCount),
      regionNeonGold,
    );
    expect(regionNeonColor(40), regionNeonGold);
    expect(divingPassportMysteryCount(const []), 0);
    expect(
      divingPassportMysteryCount(const [
        DiveRegion(
          id: 'bohol',
          name: '보홀',
          latitude: 0,
          longitude: 0,
          logCount: 1,
          continent: 'asia',
        ),
      ]),
      3,
    );
  });

  Future<void> pumpProfile(
    WidgetTester tester, {
    required MemoryDiverRepository repo,
  }) async {
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: SessionScope(
          session: session,
          child: MaterialApp(
            theme: AppTheme.light,
            locale: AppConstants.defaultLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProfileScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('지역이 없으면 여권은 첫 바다 안내만 보여 준다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await pumpProfile(tester, repo: MemoryDiverRepository.forTest());

    expect(find.text(l10n.profileDivingPassportTitle), findsOneWidget);
    expect(find.text(l10n.profileDivingPassportRegions(0)), findsOneWidget);
    expect(find.text(l10n.homeMapEmptyPrompt), findsOneWidget);
    expect(find.byKey(const Key('profile-passport-mystery-0')), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const Key('profile-diving-passport'))).dy,
      greaterThan(
        tester.getBottomLeft(find.byKey(const Key('departure-desk-header'))).dy -
            1,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('profile-diving-passport'))).dy,
      lessThan(tester.getTopLeft(find.text(l10n.profileTripScheduleTitle)).dy),
    );
  });

  testWidgets('기록한 지역은 둥근 도장이고 안 간 곳은 물음표 3칸이다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final repo = MemoryDiverRepository.forTest();
    await pumpProfile(tester, repo: repo);
    for (var i = 0; i < 3; i++) {
      await repo.addLog(
        uid: 'test-user',
        siteName: '보홀',
        divedAt: DateTime(2026, 1, i + 1),
        memo: '',
      );
    }
    await repo.addLog(
      uid: 'test-user',
      siteName: '팔라우',
      divedAt: DateTime(2026, 2, 1),
      memo: '',
    );
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('profile-passport-region-count'))).data,
      l10n.profileDivingPassportRegions(2),
    );
    expect(find.byKey(const Key('profile-passport-empty')), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-passport-name-bohol'))).data,
      '보홀',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-passport-count-bohol'))).data,
      '3',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-passport-count-palau'))).data,
      '1',
    );
    final bohol = tester.widget<DecoratedBox>(
      find.byKey(const Key('profile-passport-stamp-bohol')),
    );
    final palau = tester.widget<DecoratedBox>(
      find.byKey(const Key('profile-passport-stamp-palau')),
    );
    final boholInk = ((bohol.decoration as BoxDecoration).border! as Border).top.color;
    final palauInk = ((palau.decoration as BoxDecoration).border! as Border).top.color;
    expect(boholInk, regionNeonColor(3));
    expect(palauInk, regionNeonColor(1));
    expect(boholInk, isNot(palauInk));
    expect(find.byKey(const Key('profile-passport-mystery-0')), findsOneWidget);
    expect(find.byKey(const Key('profile-passport-mystery-1')), findsOneWidget);
    expect(find.byKey(const Key('profile-passport-mystery-2')), findsOneWidget);
    expect(find.byKey(const Key('profile-passport-mystery-3')), findsNothing);
    expect(find.text('?'), findsNWidgets(3));
  });
}
