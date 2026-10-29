import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/home/presentation/home_screen.dart';
import 'package:dive_travel_app/features/home/presentation/home_stay_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('같은 배 점은 예약 좌석과 정원으로만 그린다', () {
    expect(homeWon(140000), '₩140,000');
    expect(homeNameInitial('테스트 다이버'), '테');
    const shop = DiveShop(
      id: 'hull',
      name: '리조트',
      location: '바다',
      country: '한국',
      continent: 'asia',
      sites: [],
      productName: '상품',
      stars: 0,
      rating: 0,
      reviewCount: 0,
      amenities: [],
      consumerPrice: 1,
      professionalPrice: 1,
    );
    final facts = homeBoatFacts(
      shop,
      ShopProduct(
        id: 'p',
        shopId: 'hull',
        name: '상품',
        consumerPrice: 1,
        professionalPrice: 1,
        capacity: 4,
        bookedSeats: 3,
        departureStart: DateTime(2026, 11, 2),
      ),
    );
    expect(facts.dots, '●●●○');
    expect(facts.seatsLeft, 1);
    expect(
      homeBoatFacts(
        shop,
        ShopProduct(
          id: 'empty',
          shopId: 'hull',
          name: '상품',
          consumerPrice: 1,
          professionalPrice: 1,
        ),
      ).dots,
      isEmpty,
    );
    expect(
      homeCaptainIdentity(
        submittedByUid: '',
        viewerUid: 'test-user',
        viewerName: '테스트 다이버',
        viewerGrade: MemberGrade.diamond,
        members: const [],
      ),
      isNull,
    );
  });

  testWidgets('같은 배·기획·캡틴 카드와 탑승권·빈 지도 문구', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final repo = MemoryDiverRepository.forTest();
    final depart = DateTime(2026, 11, 2);
    final tour = DateTime(2026, 11, 7);
    await repo.saveShopProduct(
      shopId: 'dahab-bluehole',
      product: ShopProduct(
        id: 'boat',
        shopId: 'dahab-bluehole',
        name: '쇼어 2탱크',
        consumerPrice: 140000,
        professionalPrice: 90000,
        publishStatus: ProductPublishStatus.approved,
        active: true,
        listingKind: ProductListingKind.nextDeparture,
        capacity: 4,
        bookedSeats: 3,
        departureStart: depart,
      ),
    );
    await repo.saveShopProduct(
      shopId: 'similan-liveaboard',
      product: ShopProduct(
        id: 'special',
        shopId: 'similan-liveaboard',
        name: '시밀란 스페셜',
        consumerPrice: 240000,
        professionalPrice: 160000,
        publishStatus: ProductPublishStatus.approved,
        active: true,
        listingKind: ProductListingKind.curated,
      ),
    );
    await repo.saveShopProduct(
      shopId: 'palau-rock-islands',
      product: ShopProduct(
        id: 'crew',
        shopId: 'palau-rock-islands',
        name: '크루 팔라우',
        consumerPrice: 320000,
        professionalPrice: 200000,
        publishStatus: ProductPublishStatus.approved,
        active: true,
        listingKind: ProductListingKind.diverPlanned,
        submittedByUid: 'test-user',
      ),
    );
    await repo.setMemberGrade(uid: 'test-user', grade: MemberGrade.diamond);
    await repo.clearGradeCelebration('test-user');
    await repo.createBooking(
      uid: 'test-user',
      shopId: 'bohol-hideout',
      shopName: '보홀 오션 하이드아웃',
      productName: '2탱크 펀다이빙',
      price: 180000,
      tourDate: tour,
    );

    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
    await store.refreshShopStats();
    await tester.pump();
    await tester.pump();

    tester.view.physicalSize = const Size(900, 1100);
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

    expect(find.text(l10n.homeMapEmptyPrompt), findsOneWidget);
    expect(find.byKey(const Key('home-for-you')), findsOneWidget);
    expect(find.byKey(const Key('home-shelf-chips')), findsNothing);
    expect(find.byKey(const Key('home-chip-same-boat')), findsNothing);
    expect(find.byKey(const Key('home-chip-captain')), findsNothing);
    expect(find.text('보홀 오션 하이드아웃'), findsOneWidget);
    expect(find.text('2탱크 펀다이빙'), findsOneWidget);
    expect(
      find.text(l10n.homeBoardingUntil(TravelStyleAnalyzer.daysUntil(tour))),
      findsOneWidget,
    );
    final ticket = tester.widget<Text>(
      find.byKey(const Key('for-you-boarding-days')),
    );
    expect(ticket.style?.color, Colors.white);

    expect(find.text('쇼어 2탱크'), findsOneWidget);
    expect(find.text(homeDayLabel(depart)), findsOneWidget);
    expect(find.text('●●●○'), findsOneWidget);
    final countdown = tester.widget<Text>(
      find.byKey(const Key('home-same-boat-countdown-dahab-bluehole')),
    );
    expect(
      countdown.data,
      l10n.homeSameBoatCountdown(TravelStyleAnalyzer.daysUntil(depart), 1),
    );
    expect(countdown.style?.color, homeCoral);
    expect(find.text('₩140,000'), findsOneWidget);

    final curated = find.byKey(const Key('home-curated-card-similan-liveaboard'));
    expect(tester.getSize(curated).width, HomeCuratedCard.width);
    expect(tester.getSize(curated).height, HomeCuratedCard.height);
    // Phone content width leaves a sliver of the next card, not a second full card.
    const phoneContent = 390.0 - 40;
    expect(HomeCuratedCard.width + 12, lessThan(phoneContent));
    expect(phoneContent - HomeCuratedCard.width, lessThan(HomeCuratedCard.width));
    final cardTop = tester.getTopLeft(curated).dy;
    final photoBottom = cardTop + HomeCuratedCard.width / HomeCuratedCard.photoAspect;
    expect(
      tester.getTopLeft(find.byKey(const Key('home-curated-kicker-similan-liveaboard'))).dy,
      lessThan(cardTop + 24),
    );
    expect(tester.getTopLeft(find.text('시밀란 스페셜')).dy, greaterThan(photoBottom - 1));
    expect(find.text(l10n.homeApdiSpecial), findsOneWidget);
    expect(find.text('시밀란 스페셜'), findsOneWidget);
    expect(find.byKey(const Key('home-curated-line-similan-liveaboard')), findsOneWidget);
    final price = tester.widget<Text>(
      find.byKey(const Key('home-curated-price-similan-liveaboard')),
    );
    expect(price.data, '₩240,000');
    expect(price.style?.color, AppTheme.gold);

    expect(find.text('크루 팔라우'), findsOneWidget);
    final captainCard = find.byKey(
      const Key('home-captain-card-palau-rock-islands'),
    );
    expect(tester.getSize(captainCard).width, HomeCaptainCard.width);
    expect(tester.getSize(captainCard).height, HomeCaptainCard.height);
    expect(HomeCaptainCard.width, 260);
    final captainTop = tester.getTopLeft(captainCard).dy;
    final captainPhotoBottom =
        captainTop + HomeCaptainCard.width / HomeCaptainCard.photoAspect;
    expect(
      tester
          .getTopLeft(
            find.byKey(const Key('home-captain-initial-palau-rock-islands')),
          )
          .dy,
      lessThan(captainTop + 24),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('home-captain-initial-palau-rock-islands'))).data,
      '테',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('home-captain-grade-palau-rock-islands'))).data,
      l10n.profileGradeDiamond,
    );
    expect(find.byKey(const Key('home-captain-name-palau-rock-islands')), findsNothing);
    expect(tester.getTopLeft(find.text('크루 팔라우')).dy, greaterThan(captainPhotoBottom - 1));
    expect(
      tester.getTopLeft(find.text(l10n.homeCrewRecruiting)).dy,
      greaterThan(captainPhotoBottom - 1),
    );
    final captainPrice = tester.widget<Text>(
      find.byKey(const Key('home-captain-price-palau-rock-islands')),
    );
    expect(captainPrice.data, '₩320,000');
    expect(captainPrice.style?.color, AppTheme.gold);
    expect(
      tester.getTopLeft(find.byKey(const Key('home-section-captain'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('home-for-you'))).dy),
    );
  });

  testWidgets('강사 목록 카드는 저장된 강사 우대가를 보이고 30% 할인을 쓰지 않는다', (
    tester,
  ) async {
    const shop = DiveShop(
      id: 'pro-card',
      name: '리프',
      location: '팔라우',
      country: '팔라우',
      continent: 'pacific',
      sites: [],
      productName: '펀다이빙',
      stars: 0,
      rating: 0,
      reviewCount: 0,
      amenities: [],
      consumerPrice: 100000,
      professionalPrice: 80000,
    );
    final repo = MemoryDiverRepository.forTest(isInstructor: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeCuratedCard(shop: shop, onDetails: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final price = tester.widget<Text>(
      find.byKey(const Key('home-curated-price-pro-card')),
    );
    expect(price.data, '₩80,000');
  });
}
