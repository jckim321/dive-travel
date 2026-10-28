import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/bookings/presentation/booking_voucher_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  const price = 100000;

  Future<MemoryDiverRepository> openBoat({bool held = false}) async {
    final repo = MemoryDiverRepository.forTest(
      birthDate: '1990-01-01',
      phone: '01012345678',
    );
    final now = DateTime.now();
    await repo.saveShopProduct(
      shopId: 'seat-shop',
      product: ShopProduct(
        id: 'seat-prod',
        shopId: 'seat-shop',
        name: '인원 시험 상품',
        consumerPrice: price,
        professionalPrice: 80000,
        openEmptySeats: true,
        capacity: 4,
        sameBoatStatus: SameBoatStatus.approved,
        departureStart: now.add(const Duration(days: 10)),
        flagClosesAt: now.add(const Duration(days: 3)),
      ),
    );
    if (held) {
      await repo.plantSeatFlag(
        shopId: 'seat-shop',
        productId: 'seat-prod',
        partySize: 1,
        now: now,
        uid: 'test-user',
        lockedPrice: price,
      );
    }
    return repo;
  }

  Future<void> chooseParty(WidgetTester tester, int party) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.tap(find.text(l10n.navCommunity));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('same-boat-flag-seat-prod-')),
    );
    await tester.tap(find.byKey(const Key('same-boat-flag-seat-prod-')));
    await tester.pumpAndSettle();
    while (tester.widget<Text>(find.byKey(const Key('same-boat-party-count'))).data !=
        '$party') {
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('same-boat-plant-pay')));
    await tester.pumpAndSettle();
  }

  Future<void> pay(WidgetTester tester) async {
    final payButton = find.byKey(const Key('explore-checkout-pay'));
    await tester.ensureVisible(payButton);
    await tester.tap(payButton);
    await tester.pumpAndSettle();
  }

  Future<void> expectPartyOfThree(MemoryDiverRepository repo, WidgetTester tester) async {
    final booking = (await repo.watchBookings('test-user').first).single;
    expect(booking.partySize, 3);
    expect(booking.divers, 3);
    expect(booking.price, price * 3);
    final stats = await repo.fetchShopStat('seat-shop');
    expect(stats!.products.single.bookedSeats, 3);

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.byType(BookingVoucherScreen), findsOneWidget);
    expect(
      find.text(l10n.bookingPartySummary(3, 0, 0, 0)),
      findsOneWidget,
    );
    expect(find.text(l10n.explorePriceWon('300,000')), findsWidgets);
  }

  testWidgets('깃발 3명은 결제·예약확인서·좌석이 모두 3이다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = await openBoat();
    await tester.pumpWidget(DiveTravelApp(firebaseReady: true, repository: repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await chooseParty(tester, 3);
    expect(find.text(l10n.communityFlagPartyLocked(3)), findsOneWidget);
    expect(find.text(l10n.explorePriceWon('300,000')), findsWidgets);
    await pay(tester);
    await expectPartyOfThree(repo, tester);
  });

  testWidgets('1명 깃발을 3명으로 바꾸면 결제·예약확인서·좌석이 3이다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = await openBoat(held: true);
    await tester.pumpWidget(DiveTravelApp(firebaseReady: true, repository: repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await chooseParty(tester, 3);
    expect(find.text(l10n.communityFlagResizeAsk(1, 3)), findsOneWidget);
    expect(find.byType(BookingVoucherScreen), findsNothing);
    await tester.tap(find.byKey(const Key('flag-resize-confirm')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.communityFlagPartyLocked(3)), findsOneWidget);
    expect(find.text(l10n.explorePriceWon('300,000')), findsWidgets);
    await pay(tester);
    await expectPartyOfThree(repo, tester);
  });
}
