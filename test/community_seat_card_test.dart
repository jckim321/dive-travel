import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('빈자리 카드는 상세로 가고, 깃발 시트는 상세를 닫아도 인원을 유지한다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest();
    final now = DateTime.now();
    await repo.saveShopProduct(
      shopId: 'seat-shop',
      product: ShopProduct(
        id: 'seat-prod',
        shopId: 'seat-shop',
        name: '시트 시험 상품',
        consumerPrice: 100000,
        professionalPrice: 80000,
        blurb: '한 줄 소개',
        guestRating: 4.5,
        guestReviewCount: 1,
        openEmptySeats: true,
        capacity: 4,
        bookedSeats: 1,
        sameBoatStatus: SameBoatStatus.approved,
        departureStart: now.add(const Duration(days: 10)),
        flagClosesAt: now.add(const Duration(days: 3)),
        flagHolds: [
          SeatHold(seats: 1, expiresAt: now.add(const Duration(hours: 5))),
        ],
      ),
    );

    await tester.pumpWidget(
      DiveTravelApp(firebaseReady: true, repository: repo),
    );
    await tester.pump();
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.tap(find.text(l10n.navCommunity));
    await tester.pumpAndSettle();

    expect(find.text('시트 시험 상품'), findsWidgets);
    expect(find.text('한 줄 소개'), findsOneWidget);
    expect(find.text('₩100,000~'), findsOneWidget);
    expect(find.text('★ 4.5'), findsOneWidget);
    expect(
      find.text(
        '${l10n.communitySeatPaid(1)} · ${l10n.communitySeatHeld(1)} · ${l10n.communitySeatOpen(2)}',
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.communityFlagButton), findsOneWidget);

    await tester.tap(find.byKey(const Key('same-boat-seat-prod-')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('same-boat-detail')), findsOneWidget);
    expect(find.byKey(const Key('same-boat-detail-plant-pay')), findsOneWidget);
    expect(find.text(l10n.communityFlagPlantAndPay), findsOneWidget);
    expect(find.text(l10n.communityFlagPayByShortened), findsNothing);
    expect(find.textContaining('결제 기한:'), findsOneWidget);

    await tester.tap(find.byKey(const Key('same-boat-detail-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('same-boat-detail')), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('same-boat-flag-seat-prod-')),
    );
    await tester.tap(find.byKey(const Key('same-boat-flag-seat-prod-')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('same-boat-flag-sheet')), findsOneWidget);
    expect(find.text(l10n.communityFlagPlantAndPay), findsOneWidget);
    expect(find.textContaining('결제 기한:'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsWidgets);
    expect(find.text(l10n.communityFlagPartyTotal('₩200,000')), findsOneWidget);

    await tester.tap(find.byKey(const Key('same-boat-see-product')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('same-boat-detail')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('same-boat-detail-party-count'))).data,
      '2',
    );

    await tester.tap(find.byKey(const Key('same-boat-detail-party-minus')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('same-boat-detail-party-count'))).data,
      '1',
    );
    expect(
      find.text(l10n.communityFlagPartyTotal('₩100,000')),
      findsWidgets,
    );

    await tester.tap(find.byKey(const Key('same-boat-detail-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('same-boat-flag-sheet')), findsOneWidget);
    expect(find.byKey(const Key('same-boat-party-count')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('same-boat-party-count'))).data,
      '1',
    );
    expect(find.text(l10n.communityFlagPartyTotal('₩100,000')), findsOneWidget);
  });
}
