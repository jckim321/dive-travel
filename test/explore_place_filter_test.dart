import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_place_filters.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_shop_query.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  DiveShop shop({
    required String id,
    required String country,
    String location = '',
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

  test('권역·나라·검색이 맞아야 보이고 못 찾은 상품은 거르지 않는다', () {
    final bohol = shop(id: 'bohol', country: '필리핀', location: '필리핀 보홀');
    final dahab = shop(id: 'dahab', country: '이집트', location: '이집트 다합');
    final lost = shop(id: 'lost', country: '없는나라', location: '없는바다');
    final zone = shop(id: 'zone', country: '미크로네시아');

    expect(
      exploreShopMatches(
        shop: bohol,
        regionId: TravelRegionId.asia,
        countryId: 'egypt',
        needle: '보홀',
      ),
      isFalse,
    );
    expect(
      exploreShopMatches(
        shop: dahab,
        regionId: TravelRegionId.africa,
        countryId: 'egypt',
        needle: '다합',
      ),
      isTrue,
    );
    expect(
      exploreShopMatches(shop: lost, regionId: TravelRegionId.all),
      isTrue,
    );
    expect(
      exploreShopMatches(shop: lost, regionId: TravelRegionId.asia),
      isFalse,
    );
    expect(travelCountryForShop(zone), isNull);
    expect(travelRegionForShop(zone), TravelRegionId.pacific);
    expect(
      exploreShopMatches(shop: zone, regionId: TravelRegionId.pacific),
      isTrue,
    );
  });

  testWidgets('원은 권역 전체만 고르고 ▾와 나라 메뉴는 꺼져 있다', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
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

    final l10n = AppLocalizations.of(tester.element(find.byType(ExploreScreen)));
    expect(find.byKey(const Key('explore-sea-rail')), findsNothing);
    expect(find.byKey(const Key('explore-country-menu')), findsNothing);
    expect(find.byKey(const Key('continent-chevron-asia')), findsNothing);
    expect(find.text('▾'), findsNothing);
    expect(find.byKey(const Key('explore-region-row-asia')), findsNothing);
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsNothing);
    expect(find.byKey(const Key('explore-empty')), findsOneWidget);
    expect(find.text(l10n.exploreNoPublicProducts), findsOneWidget);
    expect(find.text(l10n.exploreNoResults), findsNothing);
    expect(find.text(l10n.exploreCountryEmpty), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('continent-atlas-rail')),
        matching: find.text('아시아'),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('explore-country-menu')), findsNothing);
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsNothing);
    expect(find.text('보홀 오션 하이드아웃'), findsNothing);

    await tester.tap(find.byKey(const Key('continent-filter-all')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('explore-search')), '보홀');
    await tester.pump();
    expect(find.byKey(const Key('explore-country-menu')), findsNothing);
    expect(
      tester.widget<TextField>(find.byKey(const Key('explore-search'))).controller?.text,
      '보홀',
    );
    expect(find.byKey(const Key('explore-no-results')), findsOneWidget);
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsNothing);
    expect(find.text('보홀 오션 하이드아웃'), findsNothing);
  });

  testWidgets('나라 드롭다운 코드는 켜면 주요 나라만 거른다', (tester) async {
    exploreFeaturedMenuEnabled = true;
    addTearDown(() => exploreFeaturedMenuEnabled = false);

    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest();
    await _seedPublicShop(
      repo,
      id: 'bohol-hideout',
      name: '보홀 오션 하이드아웃',
      location: '필리핀 보홀',
      country: '필리핀',
      continent: ContinentId.asia,
    );
    await _seedPublicShop(
      repo,
      id: 'kerama-okinawa',
      name: '케라마 아일랜드 다이브',
      location: '일본 오키나와',
      country: '일본',
      continent: ContinentId.asia,
    );
    final store = DiverStore(repo);
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
    await tester.pump(const Duration(milliseconds: 50));

    final l10n = AppLocalizations.of(tester.element(find.byType(ExploreScreen)));

    await tester.tap(find.byKey(const Key('continent-chevron-asia')));
    await tester.pump();
    expect(find.byKey(const Key('explore-country-menu')), findsOneWidget);
    expect(find.byKey(const Key('explore-featured-philippines-필리핀')), findsOneWidget);
    expect(find.byKey(const Key('explore-featured-japan-일본')), findsOneWidget);
    expect(find.byKey(const Key('explore-featured-korea-한국')), findsNothing);
    expect(find.byKey(const Key('explore-zone-micronesia')), findsNothing);
    expect(find.text(l10n.exploreZoneMicronesia), findsNothing);

    await tester.tap(find.byKey(const Key('explore-featured-philippines-필리핀')));
    await tester.pump();
    final philippines = find.byKey(const Key('explore-region-row-philippines'));
    expect(philippines, findsOneWidget);
    expect(find.descendant(of: philippines, matching: find.text('필리핀')), findsOneWidget);
    expect(
      find.descendant(
        of: philippines,
        matching: find.byKey(const Key('shop-card-bohol-hideout')),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('shop-card-kerama-okinawa')), findsNothing);
    expect(find.byKey(const Key('explore-region-row-asia')), findsNothing);

    await tester.tap(find.byKey(const Key('explore-featured-philippines-필리핀')));
    await tester.pump();
    expect(find.byKey(const Key('explore-region-row-philippines')), findsNothing);
    expect(find.byKey(const Key('explore-region-row-asia')), findsOneWidget);
    expect(
      find.byKey(const Key('shop-card-kerama-okinawa'), skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('continent-chevron-asia')));
    await tester.pump();
    expect(find.byKey(const Key('explore-country-menu')), findsNothing);

    await tester.tap(find.byKey(const Key('continent-chevron-pacific')));
    await tester.pump();
    final saipan = find.byKey(const Key('explore-featured-northernMariana-사이판'));
    final rota = find.byKey(const Key('explore-featured-northernMariana-로타'));
    expect(saipan, findsOneWidget);
    expect(rota, findsOneWidget);
    expect(find.byKey(const Key('explore-zone-micronesia')), findsNothing);
    await tester.tap(saipan);
    await tester.pump();
    expect(_chipColor(tester, saipan), AppTheme.navy);
    expect(find.byKey(const Key('explore-country-empty')), findsOneWidget);
    await tester.tap(rota);
    await tester.pump();
    expect(_chipColor(tester, rota), AppTheme.navy);
    expect(_chipColor(tester, saipan), Colors.white);
    expect(find.byKey(const Key('explore-country-empty')), findsOneWidget);
    await tester.tap(find.byKey(const Key('continent-filter-all')));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(const Key('continent-chevron-northAmerica')),
      120,
      scrollable: find.descendant(
        of: find.byKey(const Key('continent-atlas-rail')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('continent-chevron-northAmerica')));
    await tester.pump();
    final bahamas = find.byKey(const Key('explore-featured-bahamas-바하마'));
    expect(bahamas, findsOneWidget);
    expect(
      tester.widget<Opacity>(
        find.byKey(const Key('explore-featured-dim-bahamas-바하마')),
      ).opacity,
      0.38,
    );
    expect(tester.widget<InkWell>(bahamas).onTap, isNotNull);
    await tester.tap(bahamas);
    await tester.pump();
    expect(find.byKey(const Key('explore-country-empty')), findsOneWidget);
    expect(find.text(l10n.exploreCountryEmpty), findsOneWidget);
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsNothing);

    await tester.enterText(find.byKey(const Key('explore-search')), '보홀');
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('continent-filter-all')),
      -120,
      scrollable: find.descendant(
        of: find.byKey(const Key('continent-atlas-rail')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('continent-filter-all')));
    await tester.pump();
    expect(find.byKey(const Key('explore-country-menu')), findsNothing);
    expect(find.byKey(const Key('explore-country-empty')), findsNothing);
    expect(
      tester.widget<TextField>(find.byKey(const Key('explore-search'))).controller?.text,
      '보홀',
    );
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsOneWidget);
    expect(find.byKey(const Key('shop-card-palau-rock-islands')), findsNothing);

  });
}

Future<void> _seedPublicShop(
  MemoryDiverRepository repo, {
  required String id,
  required String name,
  required String location,
  required String country,
  required String continent,
}) async {
  await repo.saveShopProfile(
    shopId: id,
    name: name,
    location: location,
    country: country,
    continent: continent,
    productName: '펀다이빙',
    consumerPrice: 100000,
    professionalPrice: 80000,
  );
  await repo.saveShopProduct(
    shopId: id,
    product: ShopProduct(
      id: 'p-$id',
      shopId: id,
      name: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
      publishStatus: ProductPublishStatus.approved,
      active: true,
    ),
  );
}

Color _chipColor(WidgetTester tester, Finder chip) {
  return tester.widget<Material>(
    find.ancestor(of: chip, matching: find.byType(Material)).first,
  ).color!;
}
