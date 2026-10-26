import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/community/presentation/same_boat_search_bar.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

SameBoatOffer _offer({
  required String id,
  required DateTime departure,
  int capacity = 4,
  int booked = 0,
  List<SeatHold> holds = const [],
  int price = 800000,
  DateTime? opened,
  DateTime? flag,
  String continent = '',
}) {
  return SameBoatOffer(
    product: ShopProduct(
      id: id,
      shopId: 's',
      name: id,
      consumerPrice: price,
      professionalPrice: price,
      openEmptySeats: true,
      sameBoatStatus: SameBoatStatus.approved,
      sameBoatOpenedAt: opened,
      capacity: capacity,
      bookedSeats: booked,
      flagHolds: holds,
      departureStart: departure,
      flagClosesAt: flag,
      continent: continent,
    ),
  );
}

void main() {
  final now = DateTime(2026, 10, 27, 9);
  const place = SameBoatPlace();

  test('party passes only when remaining seats cover the party', () {
    final offer = _offer(
      id: 'seats',
      departure: DateTime(2026, 12, 1),
      capacity: 6,
      booked: 2,
      holds: [
        SeatHold(seats: 1, expiresAt: DateTime(2026, 10, 28), uid: 'u'),
      ],
    );
    expect(offer.remainingSeatsAt(now), 3);
    final two = const SameBoatSearch(party: 2);
    final four = const SameBoatSearch(party: 4);
    final five = const SameBoatSearch(party: SameBoatSearch.partyFivePlus);
    expect(
      two.matches(offer, now: now, pricePerPerson: 1, place: place),
      isTrue,
    );
    expect(
      four.matches(offer, now: now, pricePerPerson: 1, place: place),
      isFalse,
    );
    expect(
      five.matches(offer, now: now, pricePerPerson: 1, place: place),
      isFalse,
    );

    final wide = _offer(
      id: 'wide',
      departure: DateTime(2026, 12, 1),
      capacity: 8,
      booked: 1,
    );
    expect(
      five.matches(wide, now: now, pricePerPerson: 1, place: place),
      isTrue,
    );
  });

  test('when, budget, and region narrow the newest-first list', () {
    final older = _offer(
      id: 'older',
      departure: DateTime(2026, 10, 30),
      price: 400000,
      opened: DateTime(2026, 10, 1),
      continent: '팔라우',
    );
    final newer = _offer(
      id: 'newer',
      departure: DateTime(2026, 11, 15),
      price: 1500000,
      opened: DateTime(2026, 10, 20),
    );
    final later = _offer(
      id: 'later',
      departure: DateTime(2027, 3, 1),
      price: 900000,
      opened: DateTime(2026, 10, 18),
    );
    final offers = [newer, later, older];

    final thisMonth = const SameBoatSearch(when: SameBoatWhen.thisMonth);
    expect(
      thisMonth.apply(offers, now: now, priceOf: (_) => 1, placeOf: (_) => place)
          .map((offer) => offer.product.id),
      ['older'],
    );

    final nextMonth = const SameBoatSearch(when: SameBoatWhen.nextMonth);
    expect(
      nextMonth.apply(offers, now: now, priceOf: (_) => 1, placeOf: (_) => place)
          .map((offer) => offer.product.id),
      ['newer'],
    );

    final three = const SameBoatSearch(
      when: SameBoatWhen.withinThreeMonths,
    );
    expect(
      three.apply(offers, now: now, priceOf: (_) => 1, placeOf: (_) => place)
          .map((offer) => offer.product.id),
      ['newer', 'older'],
    );

    final budget = const SameBoatSearch(budgetMax: SameBoatSearch.budget100);
    expect(
      budget
          .apply(
            offers,
            now: now,
            priceOf: (offer) => offer.product.consumerPrice,
            placeOf: (_) => place,
          )
          .map((offer) => offer.product.id),
      ['later', 'older'],
    );

    const palau = DiveRegion(
      id: 'palau',
      name: '팔라우',
      latitude: 7.5,
      longitude: 134.5,
      logCount: 0,
      continent: ContinentId.oceania,
    );
    expect(
      placeHitsRegion(palau, const SameBoatPlace(location: '팔라우')),
      isTrue,
    );
    expect(
      placeHitsRegion(palau, const SameBoatPlace(continent: 'asia')),
      isFalse,
    );
    final region = const SameBoatSearch(regionIds: {'palau'});
    expect(
      region
          .apply(
            offers,
            now: now,
            priceOf: (_) => 1,
            placeOf: (offer) => SameBoatPlace(
              continent: offer.product.continent,
              location: offer.product.continent,
            ),
          )
          .map((offer) => offer.product.id),
      ['older'],
    );
  });

  test('more filters use the flag window and keep newest-first order', () {
    final newer = _offer(
      id: 'newer',
      departure: DateTime(2026, 12, 20),
      flag: DateTime(2026, 11, 1),
      opened: DateTime(2026, 10, 20),
    );
    final quiet = _offer(
      id: 'quiet',
      departure: DateTime(2026, 12, 20),
      flag: DateTime(2026, 12, 10),
      opened: DateTime(2026, 10, 18),
    );
    final older = _offer(
      id: 'older',
      departure: DateTime(2026, 12, 20),
      flag: DateTime(2026, 11, 2),
      opened: DateTime(2026, 10, 2),
    );
    final search = const SameBoatSearch(lastCall: true);
    expect(
      search
          .apply(
            [newer, quiet, older],
            now: now,
            priceOf: (_) => 1,
            placeOf: (_) => place,
          )
          .map((offer) => offer.product.id),
      ['newer', 'older'],
    );
  });

  testWidgets('chips stay expanded and the summary names the active filters', (
    tester,
  ) async {
    const search = SameBoatSearch(regionIds: {'palau'}, party: 2);
    const regions = [
      SameBoatRegionChoice(id: 'palau', name: '팔라우', count: 1),
    ];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SameBoatSearchBar(
            search: search,
            expanded: false,
            resultCount: 1,
            regions: regions,
            countFor: (_) => 1,
            onChanged: (_) {},
            onExpand: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('same-boat-search-summary')), findsOneWidget);
    expect(find.text('팔라우 · 2명'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SameBoatSearchBar(
            search: const SameBoatSearch(),
            expanded: true,
            resultCount: 3,
            regions: regions,
            countFor: (_) => 3,
            onChanged: (_) {},
            onExpand: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('same-boat-chip-when')), findsOneWidget);
    expect(find.byKey(const Key('same-boat-chip-where')), findsOneWidget);
    expect(find.byKey(const Key('same-boat-chip-party')), findsOneWidget);
    expect(find.byKey(const Key('same-boat-chip-budget')), findsOneWidget);
    expect(find.byKey(const Key('same-boat-chip-more')), findsOneWidget);
    expect(find.text('새로 올라온 순'), findsOneWidget);
  });
}
