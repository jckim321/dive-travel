import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_region_groups.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  DiveShop shop({
    required String id,
    required String location,
    required String country,
    String continent = '',
  }) {
    return DiveShop(
      id: id,
      name: id,
      location: location,
      country: country,
      continent: continent,
      sites: const [],
      productName: '펀다이빙',
      stars: 0,
      rating: 0,
      reviewCount: 0,
      amenities: const [],
      consumerPrice: 1,
      professionalPrice: 1,
    );
  }

  String label(String id) {
    return switch (id) {
      TravelRegionId.asia => '아시아',
      TravelRegionId.pacific => '태평양·오세아니아',
      TravelRegionId.europe => '유럽',
      TravelRegionId.africa => '아프리카·홍해',
      TravelRegionId.northAmerica => '북·중미',
      TravelRegionId.southAmerica => '남미',
      _ => id,
    };
  }

  test('상품이 많은 대륙 순이고 별칭은 대륙으로, 못 찾은 상품은 기타다', () {
    final groups = exploreRegionGroups(
      [
        ...DiveShopCatalog.shops,
        shop(id: 'lost', location: '없는바다', country: '없는나라'),
        shop(
          id: 'micro',
          location: '마이크로네시아',
          country: '마이크로네시아',
          continent: ContinentId.asia,
        ),
        shop(
          id: 'micro-ko',
          location: '',
          country: '미크로네시아',
        ),
        shop(id: 'peru', location: '페루 리마', country: '페루'),
      ],
      otherLabel: '기타',
      continentLabel: label,
    );

    expect(groups.first.id, TravelRegionId.asia);
    expect(groups.first.title, '아시아');
    expect(groups.first.shops.map((item) => item.id), contains('bohol-hideout'));
    expect(groups.first.shops.map((item) => item.id), contains('komodo-comel'));
    expect(groups.first.shops.map((item) => item.id), isNot(contains('micro')));
    expect(
      groups.map((group) => group.title),
      isNot(contains('인도네시아')),
    );
    expect(groups.any((group) => group.shops.isEmpty), isFalse);
    final pacific = groups.singleWhere((group) => group.id == TravelRegionId.pacific);
    expect(pacific.title, '태평양·오세아니아');
    expect(
      pacific.shops.map((item) => item.id),
      containsAll(['palau-rock-islands', 'cairns-gbr', 'micro', 'micro-ko']),
    );
    final south = groups.singleWhere((group) => group.id == TravelRegionId.southAmerica);
    expect(south.title, '남미');
    expect(south.shops.single.id, 'peru');
    expect(groups.last.id, exploreOtherRegionId);
    expect(groups.last.title, '기타');
    expect(groups.last.shops.single.id, 'lost');
    expect(
      groups.indexWhere((group) => group.id == TravelRegionId.asia),
      lessThan(groups.indexWhere((group) => group.id == exploreOtherRegionId)),
    );
  });

  testWidgets('지역 줄은 같은 폭의 카드가 가로로 놓이고 더보기는 그 지역만 연다', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = DiverStore(MemoryDiverRepository.forTest());
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ExploreScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ExploreScreen)),
    );
    final row = find.byKey(const Key('explore-region-row-asia'));
    expect(
      find.descendant(of: row, matching: find.text('아시아')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('인도네시아')),
      findsNothing,
    );
    expect(find.text(l10n.exploreSeeMore), findsWidgets);
    expect(find.byKey(const Key('explore-region-row-other')), findsNothing);
    expect(find.byKey(const Key('explore-sea-unmatched')), findsNothing);
    expect(find.byKey(const Key('explore-sea-rail')), findsNothing);
    expect(
      find.descendant(
        of: row,
        matching: find.byKey(const Key('shop-card-bohol-hideout')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.text('필리핀 보홀'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('shop-card-bohol-hideout'))).width,
      closeTo(176, 1),
    );

    await tester.tap(find.byKey(const Key('explore-region-more-asia')));
    await tester.pumpAndSettle();

    final screen = find.byKey(const Key('explore-region-screen'));
    expect(screen, findsOneWidget);
    expect(find.descendant(of: screen, matching: find.text('아시아')), findsWidgets);
    final onScreen = find.descendant(
      of: screen,
      matching: find.byKey(const Key('shop-card-bohol-hideout')),
    );
    await tester.scrollUntilVisible(
      onScreen,
      400,
      scrollable: find.descendant(
        of: screen,
        matching: find.byType(Scrollable),
      ),
    );
    expect(onScreen, findsOneWidget);
    expect(
      find.descendant(
        of: screen,
        matching: find.byKey(const Key('shop-card-dahab-bluehole')),
      ),
      findsNothing,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('explore-region-screen')), findsNothing);
    expect(find.byKey(const Key('explore-search')), findsOneWidget);
  });
}
