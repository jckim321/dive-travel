import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
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
  }) {
    return DiveShop(
      id: id,
      name: id,
      location: location,
      country: country,
      continent: ContinentId.asia,
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

  test('상품이 많은 나라 순이고 못 찾은 상품은 맨 아래 기타다', () {
    final groups = exploreRegionGroups(
      [
        ...DiveShopCatalog.shops,
        shop(id: 'lost', location: '없는바다', country: '없는나라'),
      ],
      otherLabel: '기타',
    );

    expect(groups.first.title, '인도네시아');
    expect(
      groups.first.shops.map((item) => item.id).toList(),
      ['komodo-comel', 'raja-ampat'],
    );
    expect(groups.last.id, exploreOtherRegionId);
    expect(groups.last.title, '기타');
    expect(groups.last.shops.single.id, 'lost');
    expect(groups.any((group) => group.shops.isEmpty), isFalse);
    expect(
      groups.map((group) => group.title).where((title) => title == '한국'),
      isEmpty,
    );
    final philippines = groups.singleWhere((group) => group.title == '필리핀');
    expect(philippines.shops.single.id, 'bohol-hideout');
    expect(
      groups.indexWhere((group) => group.title == '인도네시아'),
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
    final row = find.byKey(const Key('explore-region-row-asia|인도네시아'));
    expect(find.text('인도네시아'), findsOneWidget);
    expect(find.text(l10n.exploreSeeMore), findsWidgets);
    expect(find.text('한국'), findsNothing);
    expect(find.text(l10n.exploreOtherRegion), findsNothing);
    expect(
      find.descendant(
        of: row,
        matching: find.byKey(const Key('shop-card-komodo-comel')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.byKey(const Key('shop-card-raja-ampat')),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('shop-card-komodo-comel'))).width,
      closeTo(176, 1),
    );

    await tester.tap(find.byKey(const Key('explore-region-more-asia|인도네시아')));
    await tester.pumpAndSettle();

    final screen = find.byKey(const Key('explore-region-screen'));
    expect(screen, findsOneWidget);
    expect(
      find.descendant(
        of: screen,
        matching: find.byKey(const Key('shop-card-komodo-comel')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: screen,
        matching: find.byKey(const Key('shop-card-raja-ampat')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: screen,
        matching: find.byKey(const Key('shop-card-bohol-hideout')),
      ),
      findsNothing,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('explore-region-screen')), findsNothing);
    expect(find.byKey(const Key('explore-search')), findsOneWidget);
  });
}
