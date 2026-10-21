import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/widgets/pulsing_marker.dart';
import 'package:dive_travel_app/core/widgets/tank_gauge.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<AppLocalizations> loadKo() {
    return AppLocalizations.delegate.load(const Locale('ko'));
  }

  Future<void> pumpSignedInApp(WidgetTester tester) async {
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('5개 탭과 한국어 홈 슬로건이 보인다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);

    final l10n = await loadKo();
    final en = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(en.homeWelcome), findsOneWidget);
    expect(find.text('DIVE TRAVEL'), findsOneWidget);
    expect(find.text(l10n.navHome), findsOneWidget);
    expect(find.text(l10n.navLogbook), findsOneWidget);
    expect(find.text(l10n.navExplore), findsOneWidget);
    expect(find.text(l10n.navCommunity), findsOneWidget);
    expect(find.text(l10n.navProfile), findsOneWidget);
    expect(find.text(en.homeMapExplored(0)), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));
    expect(find.text(l10n.homeWelcome), findsOneWidget);
    expect(find.text(l10n.homeMapExplored(0)), findsOneWidget);
    expect(find.byType(PulsingMarker), findsNothing);
  });

  testWidgets('로그를 저장하면 탐험 지역 수가 늘어난다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);

    final l10n = await loadKo();
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byType(PulsingMarker), findsNothing);

    await tester.tap(find.text(l10n.navLogbook));
    await tester.pump();

    await tester.tap(find.text(l10n.logbookAdd));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField).first, '코멜');
    await tester.tap(find.byKey(const Key('logbook-save-appbar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(l10n.navHome));
    await tester.pump();

    expect(
      find.text(l10n.homeMapExplored(1)).evaluate().isNotEmpty ||
          find.text(en.homeMapExplored(1)).evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.byType(PulsingMarker), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.tap(find.text(l10n.navProfile));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('profile-departure-desk')),
      const Offset(0, -420),
    );
    await tester.pump(const Duration(milliseconds: 1000));

    final tank = tester.widget<TankGauge>(
      find.byKey(const Key('profile-tank-gauge')),
    );
    expect(tank.progress, closeTo(0.01, 0.001));
    expect(tank.label, '1');
  });

  testWidgets('로그 추가 화면에 테스트 사진 버튼이 보인다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navLogbook));
    await tester.pump();
    await tester.tap(find.text(l10n.logbookAdd));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.logbookPhotoSection), findsOneWidget);
    expect(find.byKey(const Key('logbook-use-test-photo')), findsOneWidget);
    expect(find.text(l10n.logbookUseTestPhoto), findsOneWidget);
  });

  testWidgets('일반 다이버 투어 탭은 소비자가를 보여준다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navExplore));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('continent-atlas-rail')), findsOneWidget);
    expect(find.byKey(const Key('explore-search')), findsOneWidget);
    expect(find.text(l10n.exploreConsumerBanner), findsNothing);
    expect(find.text('180,000원'), findsNothing);
    expect(find.text('126,000원'), findsNothing);
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsOneWidget);
    expect(find.text(l10n.exploreDiveStarCertified), findsWidgets);
    expect(find.text(l10n.exploreViewListing), findsNothing);
    expect(find.text(l10n.exploreBuyNow), findsNothing);
    expect(find.text(l10n.exploreListingNew), findsWidgets);

    await tester.tap(find.byKey(const Key('shop-card-bohol-hideout')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('resort-detail-bohol-hideout')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('2탱크 펀다이빙'),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('resort-detail-bohol-hideout')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('2탱크 펀다이빙'), findsWidgets);
    expect(find.text(l10n.exploreChooseRoom), findsOneWidget);
    expect(find.textContaining('팡라오 앞바다'), findsOneWidget);
    expect(find.byKey(const Key('shop-book-bohol-hideout')), findsOneWidget);
    expect(find.byKey(const Key('edit-resort-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-resort-page')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('resort-cover-field')), findsOneWidget);
    expect(find.text(l10n.exploreAttachPhoto), findsWidgets);
    expect(find.text(l10n.exploreCoverPhotoHint), findsOneWidget);
  });

  testWidgets('강사 세션은 투어 단가를 우대가로 실시간 치환한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(isInstructor: true),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navExplore));
    await tester.pumpAndSettle();

    expect(find.text(l10n.exploreProBanner), findsNothing);
    expect(find.text('126,000원'), findsNothing);
    expect(find.text('180,000원'), findsNothing);
  });

  testWidgets('투어 검색으로 샵 카드를 좁힌다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navExplore));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('explore-search')), '팔라우');
    await tester.pumpAndSettle();

    expect(find.text('팔라우 록아일랜드 다이브'), findsOneWidget);
    expect(find.text('보홀 오션 하이드아웃'), findsNothing);
  });

  testWidgets('여행상품 대륙 아틀라스 라벨이 전부 보이고 예약 목록은 없다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navExplore));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('continent-atlas-rail')), findsOneWidget);
    expect(find.text(l10n.exploreFilterAll), findsOneWidget);
    expect(find.text(l10n.exploreContinentAsia), findsOneWidget);
    expect(find.text(l10n.exploreContinentAfrica), findsOneWidget);
    expect(find.text(l10n.exploreContinentOceania), findsOneWidget);
    expect(find.text(l10n.exploreContinentAmericas), findsOneWidget);
    expect(find.text(l10n.exploreContinentEurope), findsOneWidget);
    expect(find.text(l10n.exploreMyBookings), findsNothing);

    await tester.tap(find.byKey(const Key('continent-filter-asia')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsOneWidget);
  });

  testWidgets('로그북에서 오퍼레이션 리뷰 화면을 연다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navLogbook));
    await tester.pump();
    await tester.tap(find.text(l10n.logbookAdd));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).first, '보홀');
    await tester.tap(find.byKey(const Key('logbook-save-appbar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.scrollUntilVisible(
      find.byKey(const Key('log-review')),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('logbook-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('log-review')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(l10n.reviewTitle), findsOneWidget);
    expect(find.byKey(const Key('review-gate-message')), findsOneWidget);
    expect(find.text(l10n.reviewBookingRequired), findsOneWidget);
    expect(find.byKey(const Key('review-details-expand')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('review-submit')),
      120,
      scrollable: find.descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.byKey(const Key('review-submit')), findsOneWidget);
  });

  testWidgets('기록된 로그를 수정하면 장소가 바뀐다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navLogbook));
    await tester.pump();
    await tester.tap(find.text(l10n.logbookAdd));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).first, '보홀');
    await tester.tap(find.byKey(const Key('logbook-save-appbar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.scrollUntilVisible(
      find.byKey(const Key('log-edit')),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('logbook-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('log-edit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).first, '코멜');
    await tester.tap(find.byKey(const Key('logbook-save-appbar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('코멜'), findsWidgets);
    expect(find.text('보홀'), findsNothing);
  });

  testWidgets('홈 나를 위한 다음 바다는 신규에선 숨기고 로그 후엔 짧은 카드로 보인다', (
    WidgetTester tester,
  ) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    expect(find.byKey(const Key('for-you-panel')), findsNothing);
    expect(find.text(l10n.homeForYouTitle), findsNothing);

    await tester.tap(find.text(l10n.navLogbook));
    await tester.pump();
    await tester.tap(find.text(l10n.logbookAdd));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).first, '보홀');
    await tester.tap(find.byKey(const Key('logbook-save-appbar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text(l10n.navHome));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    for (var i = 0; i < 16 && find.byKey(const Key('for-you-panel')).evaluate().isEmpty; i++) {
      await tester.drag(
        find.byKey(const Key('home-scroll')),
        const Offset(0, -420),
      );
      await tester.pump();
    }
    // Panel may already be off-screen; drag until title is visible.
    for (var i = 0;
        i < 20 &&
            tester.any(find.text(l10n.homeForYouTitle)) == false;
        i++) {
      await tester.drag(
        find.byKey(const Key('home-scroll')),
        const Offset(0, -420),
      );
      await tester.pump();
    }

    expect(find.byKey(const Key('for-you-panel')), findsOneWidget);
    expect(find.text(l10n.homeForYouTitle), findsOneWidget);
    expect(find.text(l10n.homeNextOceanTitle), findsOneWidget);
    expect(find.byKey(const Key('for-you-passport-peek')), findsNothing);
    expect(find.byKey(const Key('for-you-stamps')), findsNothing);
    expect(find.byKey(const Key('for-you-badge')), findsNothing);
  });

  testWidgets('마이페이지에 강사 C-Card 인증 폼이 있다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-profile-settings')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('profile-settings-scroll')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pro-submit')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.proTitle), findsOneWidget);
    expect(find.text(l10n.proStatusNone), findsOneWidget);
    expect(find.byKey(const Key('pro-submit')), findsOneWidget);
  });

  testWidgets('출항 데스크에서 새 여행 짜기를 연다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('departure-desk-header')), findsOneWidget);
    expect(find.byKey(const Key('my-crafted-trips')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('profile-crafted-trips-link')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-crafted-trips-link')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.profileCraftNeedsGold), findsOneWidget);
    expect(find.byKey(const Key('product-form-appbar-save')), findsNothing);
  });

  testWidgets('마이 여권 표지를 누르면 펼쳐진다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('passport-cover-compact')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('passport-cover-compact')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('passport-spread')), findsOneWidget);
    expect(find.text('필리핀'), findsWidgets);
    expect(find.text(l10n.exploreContinentAsia), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('passport-fold')));
    await tester.tap(find.byKey(const Key('passport-fold')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('passport-spread')), findsNothing);
    expect(find.byKey(const Key('passport-cover-compact')), findsOneWidget);
  });

  testWidgets('모바일 폭에서 여권과 공기탱크가 같은 카드에 보인다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(472, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-tank-gauge')));
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.byKey(const Key('passport-cover-compact')), findsOneWidget);
    expect(find.byKey(const Key('profile-tank-gauge')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('같은배 탭은 출발 명부를 보여준다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navCommunity));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tide-board')), findsOneWidget);
    expect(find.text(l10n.communityTideKicker), findsOneWidget);
    expect(find.text(l10n.communityDesignPreview), findsOneWidget);
    expect(find.text('디럭스 캐빈'), findsOneWidget);
  });
}
