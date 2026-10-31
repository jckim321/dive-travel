import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/explore/presentation/partner_empty_seat_products.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/tour_checkout_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _shopId = 'reef-book';

ShopProduct _stay(DateTime yesterday) {
  return ShopProduct(
    id: 'stay',
    shopId: _shopId,
    name: '2박 리조트',
    consumerPrice: 200000,
    professionalPrice: 160000,
    durationLabel: '2박 3일',
    departureStart: yesterday,
    publishStatus: ProductPublishStatus.approved,
    active: true,
  );
}

ShopProduct _dayTrip() {
  return const ShopProduct(
    id: 'day',
    shopId: _shopId,
    name: '당일 보트',
    consumerPrice: 90000,
    professionalPrice: 70000,
    durationLabel: '3일',
    publishStatus: ProductPublishStatus.approved,
    active: true,
  );
}

ShopProduct _emptySeat() {
  return ShopProduct(
    id: 'empty',
    shopId: _shopId,
    name: '빈자리 배',
    consumerPrice: 180000,
    professionalPrice: 140000,
    durationLabel: '3박 4일',
    openEmptySeats: true,
    sameBoatStatus: SameBoatStatus.approved,
    capacity: 4,
    departureStart: DateTime(2026, 12, 1),
    publishStatus: ProductPublishStatus.approved,
    active: true,
  );
}

Future<({DiverStore store, SessionController session})> _seed() async {
  final repo = MemoryDiverRepository.forTest(
    birthDate: '1990-01-02',
    phone: '010-1111-2222',
  );
  await repo.saveShopProfile(
    shopId: _shopId,
    name: '리프 리조트',
    location: '세부',
    productName: '리조트',
    consumerPrice: 200000,
    professionalPrice: 160000,
  );
  final yesterday = calendarDay(
    DateTime.now(),
  ).subtract(const Duration(days: 1));
  await repo.saveShopProduct(shopId: _shopId, product: _stay(yesterday));
  await repo.saveShopProduct(shopId: _shopId, product: _dayTrip());
  await repo.saveShopProduct(shopId: _shopId, product: _emptySeat());
  final store = DiverStore(repo);
  final session = SessionController(repo);
  await store.refreshShopStats();
  return (store: store, session: session);
}

Future<void> _pump(
  WidgetTester tester,
  DiverStore store,
  SessionController session,
  Widget home,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
          home: home,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

String _shown(WidgetTester tester, Key key) {
  return tester.widget<Text>(find.byKey(key)).data!;
}

void main() {
  test('박 수 없는 기간은 돌아오는 날을 만들지 않는다', () {
    final today = DateTime(2026, 11, 1);
    expect(
      buyerDepartureDay(now: today, preferred: DateTime(2026, 10, 31)),
      today,
    );
    expect(
      buyerDepartureDay(now: today, preferred: DateTime(2026, 11, 8)),
      DateTime(2026, 11, 8),
    );
    expect(
      buyerReturnDay(departure: today, durationLabel: '2박 3일'),
      DateTime(2026, 11, 3),
    );
    expect(buyerReturnDay(departure: today, durationLabel: '3일'), isNull);
  });

  testWidgets('일반 상품을 고르면 오늘 이후 출발일과 돌아오는 날이 예약에 남는다', (tester) async {
    final harness = await _seed();
    addTearDown(harness.store.dispose);
    addTearDown(harness.session.dispose);
    await _pump(
      tester,
      harness.store,
      harness.session,
      const ResortDetailScreen(hullId: _shopId),
    );

    expect(find.byKey(const Key('resort-book')), findsOneWidget);
    await tester.tap(find.byKey(const Key('resort-book')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('resort-book-products')), findsOneWidget);
    expect(find.byKey(const Key('resort-book-product-stay')), findsOneWidget);
    expect(find.byKey(const Key('resort-book-product-day')), findsOneWidget);
    expect(find.byKey(const Key('resort-book-product-empty')), findsNothing);
    expect(find.text('빈자리 배'), findsNothing);

    await tester.tap(find.byKey(const Key('resort-book-product-stay')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final today = calendarDay(DateTime.now());
    final day = DateFormat('yyyy.MM.dd');
    await tester.scrollUntilVisible(
      find.byKey(const Key('checkout-departure-date')),
      400,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('출발일'), findsOneWidget);
    expect(find.text('투어 날짜'), findsNothing);
    expect(_shown(tester, const Key('checkout-departure-value')), day.format(today));
    expect(
      _shown(tester, const Key('checkout-return-value')),
      day.format(today.add(const Duration(days: 2))),
    );

    final dateInk = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('checkout-departure-date')),
        matching: find.byType(InkWell),
      ),
    );
    expect(dateInk.onTap, isNotNull);

    await tester.tap(find.byKey(const Key('checkout-departure-date')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(calendarDay(picker.firstDate), today);
    await tester.tap(find.text('취소'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final birth = find.byKey(const Key('checkout-guest-birth'));
    final scrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .last;
    for (var i = 0; i < 10 && birth.evaluate().isEmpty; i++) {
      await tester.drag(scrollable, const Offset(0, -450));
      await tester.pump();
    }
    expect(birth, findsOneWidget);
    await tester.enterText(birth, '1990-01-02');
    await tester.enterText(
      find.byKey(const Key('checkout-guest-contact')),
      '010-1111-2222',
    );
    await tester.pump();

    final pay = tester.widget<FilledButton>(
      find.byKey(const Key('explore-checkout-pay')),
    );
    expect(harness.session.isSignedIn, isTrue);
    expect(pay.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('explore-checkout-pay')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(harness.store.bookings, isNotEmpty);
    expect(calendarDay(harness.store.bookings.first.tourDate!), today);
  });

  testWidgets('박 수가 없는 일반 상품은 돌아오는 날을 보여 주지 않는다', (tester) async {
    final harness = await _seed();
    addTearDown(harness.store.dispose);
    addTearDown(harness.session.dispose);
    final savedEmpty = harness.store
        .liveStatsFor(_shopId)!
        .products
        .firstWhere((product) => product.id == 'empty');
    expect(savedEmpty.openEmptySeats, isTrue);
    await _pump(
      tester,
      harness.store,
      harness.session,
      const ResortDetailScreen(hullId: _shopId),
    );

    await tester.tap(find.byKey(const Key('resort-book')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('resort-book-product-day')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.byKey(const Key('checkout-departure-date')));
    expect(find.text('출발일'), findsOneWidget);
    expect(find.byKey(const Key('checkout-return-date')), findsNothing);
    expect(find.text('기간을 먼저 입력하세요'), findsNothing);
  });

  testWidgets('빈자리 상품은 정해진 출발일을 잠근다', (tester) async {
    final repo = MemoryDiverRepository.forTest();
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
    final empty = _emptySeat();
    await _pump(
      tester,
      store,
      session,
      TourCheckoutSheet(
        shop: const DiveShop(
          id: _shopId,
          name: '리프 리조트',
          location: '세부',
          country: 'PH',
          continent: 'asia',
          sites: ['리프'],
          productName: '빈자리 배',
          stars: 0,
          rating: 0,
          reviewCount: 0,
          amenities: [],
          consumerPrice: 180000,
          professionalPrice: 140000,
        ),
        quote: const TourPriceQuote(amount: 180000, isProfessional: false),
        product: empty,
      ),
    );
    final tourDate = find.byKey(const Key('checkout-tour-date'));
    final scrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .last;
    for (var i = 0; i < 10 && tourDate.evaluate().isEmpty; i++) {
      await tester.drag(scrollable, const Offset(0, -450));
      await tester.pump();
    }
    expect(tourDate, findsOneWidget);
    expect(find.text('투어 날짜'), findsOneWidget);
    expect(find.text('출발일'), findsNothing);
    expect(find.byKey(const Key('checkout-return-date')), findsNothing);
    expect(_shown(tester, const Key('checkout-departure-value')), '2026.12.01');
    final locked = tester.widget<InkWell>(
      find.descendant(
        of: tourDate,
        matching: find.byType(InkWell),
      ),
    );
    expect(locked.onTap, isNull);
  });
}
