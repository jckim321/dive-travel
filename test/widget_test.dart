import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/widgets/pulsing_marker.dart';
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
    expect(find.text(l10n.profileSignOut), findsWidgets);
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

    expect(find.byKey(const Key('explore-search')), findsOneWidget);
    expect(find.text(l10n.exploreConsumerBanner), findsOneWidget);
    expect(find.text(l10n.exploreConsumerPrice), findsWidgets);
    expect(find.text('180,000원'), findsOneWidget);
    expect(find.text('126,000원'), findsNothing);
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsOneWidget);
    expect(find.text(l10n.exploreDiveStarCertified), findsWidgets);
    expect(find.text(l10n.exploreViewListing), findsWidgets);
    expect(find.text(l10n.exploreBuyNow), findsWidgets);
    expect(find.text(l10n.exploreListingNew), findsWidgets);

    await tester.tap(find.byKey(const Key('shop-card-bohol-hideout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('resort-detail-bohol-hideout')), findsOneWidget);
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

    expect(find.text(l10n.exploreProBanner), findsOneWidget);
    expect(find.text(l10n.exploreProPrice), findsWidgets);
    expect(find.text('126,000원'), findsOneWidget);
    expect(find.text(l10n.exploreOriginalPrice('180,000')), findsOneWidget);
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
    expect(find.text(l10n.reviewSafety), findsOneWidget);
    expect(find.text(l10n.reviewGuide), findsOneWidget);
    expect(find.text(l10n.reviewBoat), findsOneWidget);
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

  testWidgets('마이페이지에 강사 C-Card 인증 폼이 있다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();

    expect(find.text(l10n.proTitle), findsOneWidget);
    expect(find.text(l10n.proStatusNone), findsOneWidget);
    expect(find.byKey(const Key('pro-submit')), findsOneWidget);
  });

  testWidgets('마이 여권 표지를 누르면 펼쳐진다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('passport-cover')),
      280,
    );
    await tester.tap(find.byKey(const Key('passport-cover')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('passport-spread')), findsOneWidget);
    expect(find.text('필리핀'), findsWidgets);
    expect(find.text(l10n.exploreContinentAsia), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('passport-fold')));
    await tester.tap(find.byKey(const Key('passport-fold')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('passport-spread')), findsNothing);
    expect(find.byKey(const Key('passport-cover')), findsOneWidget);
  });

  testWidgets('같은배 탭은 출발 명부를 보여준다', (WidgetTester tester) async {
    await pumpSignedInApp(tester);
    final l10n = await loadKo();

    await tester.tap(find.text(l10n.navCommunity));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tide-board')), findsOneWidget);
    expect(find.text(l10n.communityTideKicker), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('tide-board')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tide-card-seed-buddy-dahab')), findsOneWidget);
    expect(find.text(l10n.communityKindLast), findsWidgets);

    await tester.tap(find.byKey(const Key('tide-card-seed-buddy-dahab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('raise-tide-flag')), findsOneWidget);
    await tester.tap(find.byKey(const Key('raise-tide-flag')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.communityRaiseFlagDone), findsOneWidget);
    expect(find.byKey(const Key('explore-checkout-pay')), findsOneWidget);
    expect(find.text(l10n.explorePay), findsWidgets);
    expect(find.byKey(const Key('explore-checkout-pay')), findsOneWidget);
    expect(find.text(l10n.explorePay), findsWidgets);
  });
}
