import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/home/presentation/home_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<({DiverStore store, SessionController session})> openStore(
    WidgetTester tester, {
    MemberGrade grade = MemberGrade.silver,
    bool withLog = false,
    Map<String, ProductListingKind> shelves = const {},
  }) async {
    final repo = MemoryDiverRepository.forTest();
    for (final entry in shelves.entries) {
      await repo.saveShopProduct(
        shopId: entry.key,
        product: ShopProduct(
          id: 'shelf-${entry.value.name}',
          shopId: entry.key,
          name: entry.value.name,
          consumerPrice: 100000,
          professionalPrice: 80000,
          publishStatus: ProductPublishStatus.approved,
          active: true,
          listingKind: entry.value,
        ),
      );
    }
    if (grade != MemberGrade.silver) {
      await repo.setMemberGrade(uid: 'test-user', grade: grade);
      await repo.clearGradeCelebration('test-user');
    }
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
    await store.refreshShopStats();
    await tester.pump();
    await tester.pump();
    if (withLog) {
      await repo.addLog(
        uid: 'test-user',
        siteName: '보홀',
        divedAt: DateTime(2026, 1, 2),
        memo: '로그',
      );
      await tester.pump();
    }
    expect(store.uid, 'test-user');
    expect(store.stats.memberGrade, grade);
    return (store: store, session: session);
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    required DiverStore store,
    required SessionController session,
  }) async {
    tester.view.physicalSize = const Size(900, 4200);
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
          home: const HomeScreen(),
        ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  double top(WidgetTester tester, Finder finder) {
    return tester.getTopLeft(finder).dy;
  }

  testWidgets('홈 구역은 Dive Star, 같은 배, 스팟, 스페셜, 캡틴, 다음 바다 순이다', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final opened = await openStore(
      tester,
      withLog: true,
      shelves: const {
        'bohol-hideout': ProductListingKind.diveStar,
        'dahab-bluehole': ProductListingKind.nextDeparture,
        'kerama-okinawa': ProductListingKind.hotSpot,
        'similan-liveaboard': ProductListingKind.curated,
        'palau-rock-islands': ProductListingKind.diverPlanned,
      },
    );
    await pumpHome(tester, store: opened.store, session: opened.session);
    expect(opened.store.regions, isNotEmpty);

    final diveStar = find.byKey(const Key('home-section-dive-star'));
    final sameBoat = find.byKey(const Key('home-section-same-boat'));
    final hot = find.byKey(const Key('home-section-hot'));
    final curated = find.byKey(const Key('home-section-curated'));
    final captain = find.byKey(const Key('home-section-captain'));
    final forYou = find.text(l10n.homeForYouTitle);

    expect(top(tester, diveStar), lessThan(top(tester, sameBoat)));
    expect(top(tester, sameBoat), lessThan(top(tester, hot)));
    expect(top(tester, hot), lessThan(top(tester, curated)));
    expect(top(tester, curated), lessThan(top(tester, captain)));
    expect(top(tester, captain), lessThan(top(tester, forYou)));
    expect(find.text(l10n.homeShelfEmpty), findsNothing);
    expect(find.text(l10n.homeDiverPlannedSubtitle), findsOneWidget);
    expect(find.byKey(const Key('home-captain-needs-gold')), findsOneWidget);
    expect(find.byKey(const Key('home-become-captain')), findsNothing);
  });

  testWidgets('빈 홈 선반은 숨기고 골드 캡틴 구역은 버튼과 함께 남는다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final silver = await openStore(tester);
    await pumpHome(tester, store: silver.store, session: silver.session);
    expect(find.byKey(const Key('home-section-captain')), findsNothing);
    expect(find.byKey(const Key('home-section-dive-star')), findsNothing);
    expect(find.text(l10n.homeShelfEmpty), findsNothing);

    final gold = await openStore(tester, grade: MemberGrade.gold);
    await pumpHome(tester, store: gold.store, session: gold.session);
    expect(find.byKey(const Key('home-section-captain')), findsOneWidget);
    expect(find.text(l10n.homeFavoritesTitle), findsOneWidget);
    expect(find.text(l10n.homeDiverPlannedSubtitle), findsOneWidget);
    expect(find.byKey(const Key('home-captain-needs-gold')), findsNothing);
    expect(find.text(l10n.homeShelfEmpty), findsNothing);
    expect(
      tester.widget(find.byKey(const Key('home-become-captain'))),
      isA<FilledButton>(),
    );

    await tester.tap(find.byKey(const Key('home-become-captain')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.profileCaptainTripTitle), findsOneWidget);
  });
}
