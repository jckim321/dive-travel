import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
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

  test('권역·나라·해역·검색이 모두 맞아야 보인다', () {
    final bohol = shop(id: 'bohol', country: '필리핀', location: '필리핀 보홀');
    final dahab = shop(id: 'dahab', country: '이집트', location: '이집트 다합');
    final lost = shop(id: 'lost', country: '없는나라', location: '없는바다');
    final zone = shop(id: 'zone', country: '미크로네시아');

    expect(
      exploreShopMatches(
        shop: bohol,
        regionId: TravelRegionId.asia,
        countryId: 'philippines',
        seaId: TravelSea.red,
        needle: '보홀',
      ),
      isFalse,
    );
    expect(
      exploreShopMatches(
        shop: dahab,
        regionId: TravelRegionId.africa,
        countryId: 'egypt',
        seaId: TravelSea.red,
        needle: '다합',
      ),
      isTrue,
    );
    expect(
      exploreShopMatches(
        shop: lost,
        regionId: TravelRegionId.all,
        seaId: exploreSeaUnmatched,
      ),
      isTrue,
    );
    expect(
      exploreShopMatches(
        shop: bohol,
        regionId: TravelRegionId.all,
        seaId: exploreSeaUnmatched,
      ),
      isFalse,
    );
    expect(travelCountryForShop(zone), isNull);
    expect(travelRegionForShop(zone), TravelRegionId.pacific);
    expect(
      exploreShopMatches(
        shop: zone,
        regionId: TravelRegionId.pacific,
        seaId: exploreSeaUnmatched,
      ),
      isTrue,
    );
  });

  testWidgets('나라 드롭다운과 해역 칩이 상품을 함께 거른다', (tester) async {
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
    expect(find.byKey(const Key('explore-sea-rail')), findsOneWidget);
    expect(find.text(l10n.exploreSeaIndian), findsOneWidget);
    expect(find.text(l10n.exploreSeaRed), findsOneWidget);
    expect(find.text(l10n.exploreSeaCaribbean), findsOneWidget);
    expect(find.text(l10n.exploreSeaSouthPacific), findsOneWidget);
    expect(find.byKey(const Key('explore-country-menu')), findsNothing);

    await tester.tap(find.byKey(const Key('continent-filter-asia')));
    await tester.pump();

    expect(find.byKey(const Key('explore-country-philippines')), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('explore-country-dim-korea')))
          .opacity,
      0.38,
    );
    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('explore-country-korea')))
          .onTap,
      isNull,
    );

    await tester.tap(find.byKey(const Key('explore-country-philippines')));
    await tester.pump();
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsOneWidget);
    expect(find.byKey(const Key('shop-card-kerama-okinawa')), findsNothing);

    await tester.tap(find.byKey(const Key('explore-country-philippines')));
    await tester.pump();
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsOneWidget);
    expect(find.byKey(const Key('shop-card-kerama-okinawa')), findsOneWidget);

    await tester.tap(find.byKey(const Key('continent-filter-pacific')));
    await tester.pump();
    final menuScroll = find.descendant(
      of: find.byKey(const Key('explore-country-menu')),
      matching: find.byType(Scrollable),
    );
    for (final zone in [
      TravelZone.micronesia,
      TravelZone.melanesia,
      TravelZone.polynesia,
      TravelZone.other,
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(Key('explore-zone-$zone')),
        120,
        scrollable: menuScroll,
      );
      expect(find.byKey(Key('explore-zone-$zone')), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.byKey(const Key('explore-country-newZealand')),
      80,
      scrollable: menuScroll,
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const Key('explore-country-dim-newZealand')),
          )
          .opacity,
      0.38,
    );
    expect(find.byKey(const Key('shop-card-palau-rock-islands')), findsOneWidget);
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsNothing);

    await tester.tap(find.byKey(const Key('continent-filter-all')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('explore-sea-red')));
    await tester.pump();
    expect(find.byKey(const Key('shop-card-dahab-bluehole')), findsOneWidget);
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsNothing);

    await tester.enterText(find.byKey(const Key('explore-search')), '보홀');
    await tester.pump();
    expect(find.byKey(const Key('shop-card-dahab-bluehole')), findsNothing);
    expect(find.text(l10n.exploreNoResults), findsOneWidget);

    await tester.enterText(find.byKey(const Key('explore-search')), '다합');
    await tester.pump();
    expect(find.byKey(const Key('shop-card-dahab-bluehole')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('explore-search')), '');
    await tester.pump();
    await tester.tap(find.byKey(const Key('explore-sea-red')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('continent-filter-asia')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('explore-sea-indian')));
    await tester.pump();
    expect(find.byKey(const Key('shop-card-maldives-ari')), findsOneWidget);
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsNothing);

    await tester.tap(find.byKey(const Key('explore-sea-indian')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('continent-filter-all')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('explore-sea-unmatched')));
    await tester.pump();
    expect(find.byKey(const Key('shop-card-bohol-hideout')), findsNothing);
    expect(find.text(l10n.exploreNoResults), findsOneWidget);
  });
}
