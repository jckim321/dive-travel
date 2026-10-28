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
  test('도장 색은 지도와 같은 횟수 단계다', () {
    expect(regionNeonColor(0), regionNeonTeal);
    expect(regionNeonColor(1), regionNeonTeal);
    expect(regionNeonColor(9), regionNeonTeal);
    expect(regionNeonColor(10), regionNeonBrightTeal);
    expect(regionNeonColor(49), regionNeonBrightTeal);
    expect(regionNeonColor(50), regionNeonGold);
    expect(regionNeonColor(199), regionNeonGold);
    expect(regionNeonHasDoubleRing(199), isFalse);
    expect(regionNeonHasDoubleRing(200), isTrue);
    expect(regionNeonHasGlow(999), isFalse);
    expect(regionNeonHasDoubleRing(1000), isTrue);
    expect(regionNeonHasGlow(1000), isTrue);
    expect(regionNeonColor(1000), regionNeonGold);
    expect(regionNeonTier(50), RegionNeonTier.gold);
    expect(AppRegionThresholds.goldenLogCount, 50);
    expect(divingPassportCountLabel(999), '999');
    expect(divingPassportCountLabel(1000), '1k');
    expect(divingPassportCountLabel(1200), '1.2k');
    expect(divingPassportCountLabel(15000), '15k');
    expect(divingPassportDiveTotal(7500), '7,500');
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
    expect(
      divingPassportMysteryCount([
        for (var i = 0; i < 12; i++)
          DiveRegion(
            id: 'r$i',
            name: '바다$i',
            latitude: 0,
            longitude: 0,
            logCount: 1,
            continent: 'asia',
          ),
      ]),
      0,
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
    expect(find.text(l10n.profileDivingPassportDives('0')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('profile-passport-dive-total')))
          .style
          ?.fontSize,
      22,
    );
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
    expect(find.text(l10n.profileDivingPassportDives('4')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('profile-passport-stamp-bohol'))).dx,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('profile-passport-stamp-palau'))).dx,
      ),
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
    expect(boholInk, regionNeonTeal);
    expect(palauInk, regionNeonTeal);
    expect(find.byKey(const Key('profile-passport-show-all')), findsNothing);
    expect(find.byKey(const Key('profile-passport-mystery-0')), findsOneWidget);
    expect(find.byKey(const Key('profile-passport-mystery-1')), findsOneWidget);
    expect(find.byKey(const Key('profile-passport-mystery-2')), findsOneWidget);
    expect(find.byKey(const Key('profile-passport-mystery-3')), findsNothing);
    expect(find.text('?'), findsNWidgets(3));
  });

  Future<void> pumpCard(WidgetTester tester, List<DiveRegion> regions) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DivingPassportCard(regions: regions)),
      ),
    );
    await tester.pump();
  }

  DiveRegion stamp(String id, int count) {
    return DiveRegion(
      id: id,
      name: id,
      latitude: 0,
      longitude: 0,
      logCount: count,
      continent: 'asia',
    );
  }

  BoxDecoration tierBox(WidgetTester tester, String id) {
    return tester
            .widget<DecoratedBox>(find.byKey(Key('profile-passport-tier-$id')))
            .decoration
        as BoxDecoration;
  }

  testWidgets('12개를 넘기면 횟수 순으로 접고 물음표는 숨긴다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final regions = [
      for (var count = 1; count <= 13; count++) stamp('r$count', count),
    ];
    await pumpCard(tester, regions);

    expect(find.byKey(const Key('profile-passport-stamp-r13')), findsOneWidget);
    expect(find.byKey(const Key('profile-passport-stamp-r2')), findsOneWidget);
    expect(find.byKey(const Key('profile-passport-stamp-r1')), findsNothing);
    expect(find.byKey(const Key('profile-passport-mystery-0')), findsNothing);
    expect(find.text(l10n.profileDivingPassportShowAll(13)), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('profile-passport-stamp-r13'))).dx,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('profile-passport-stamp-r12'))).dx,
      ),
    );

    tester
        .widget<TextButton>(find.byKey(const Key('profile-passport-show-all')))
        .onPressed
        ?.call();
    await tester.pump();

    expect(find.byKey(const Key('profile-passport-stamp-r1')), findsOneWidget);
    expect(find.text(l10n.profileDivingPassportShowLess), findsOneWidget);
    expect(find.byKey(const Key('profile-passport-mystery-0')), findsNothing);
  });

  testWidgets('높은 단계는 이중 테두리와 빛, 1000회는 1.2k다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await pumpCard(tester, [
      stamp('teal', 5),
      stamp('bright', 20),
      stamp('gold', 80),
      stamp('ring', 250),
      stamp('glow', 1200),
    ]);

    expect(find.text(l10n.profileDivingPassportDives('1,555')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-passport-count-glow'))).data,
      '1.2k',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('profile-passport-count-ring'))).data,
      '250',
    );

    Color ink(String id) {
      final box = tester.widget<DecoratedBox>(
        find.byKey(Key('profile-passport-stamp-$id')),
      );
      return ((box.decoration as BoxDecoration).border! as Border).top.color;
    }

    expect(ink('teal'), regionNeonTeal);
    expect(ink('bright'), regionNeonBrightTeal);
    expect(ink('gold'), regionNeonGold);
    expect(ink('ring'), regionNeonGold);
    expect(ink('glow'), regionNeonGold);
    expect(tierBox(tester, 'gold').border, isNull);
    expect(tierBox(tester, 'gold').boxShadow, isNull);
    expect(tierBox(tester, 'ring').border, isNotNull);
    expect(tierBox(tester, 'ring').boxShadow, isNull);
    expect(tierBox(tester, 'glow').border, isNotNull);
    expect(tierBox(tester, 'glow').boxShadow, isNotEmpty);
    expect(find.byKey(const Key('profile-passport-show-all')), findsNothing);
    expect(find.byKey(const Key('profile-passport-mystery-0')), findsOneWidget);
  });
}
