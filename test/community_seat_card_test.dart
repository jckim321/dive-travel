import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/explore/presentation/tour_checkout_sheet.dart';
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

  testWidgets('깃발 꽂고 결제하러 가기는 깃발 심은 뒤 결제 화면까지 이어진다', (
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
        openEmptySeats: true,
        capacity: 4,
        bookedSeats: 1,
        sameBoatStatus: SameBoatStatus.approved,
        departureStart: now.add(const Duration(days: 10)),
        flagClosesAt: now.add(const Duration(days: 3)),
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

    expect(find.text(l10n.communityDesignPreview), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('same-boat-flag-seat-prod-')),
    );
    await tester.tap(find.byKey(const Key('same-boat-flag-seat-prod-')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('same-boat-plant-pay')));
    await tester.pumpAndSettle();
    expect(find.byType(TourCheckoutSheet), findsOneWidget);
    expect(
      find.byKey(const Key('checkout-review-cta')).evaluate().isNotEmpty ||
          find.byKey(const Key('checkout-pay-same-boat')).evaluate().isNotEmpty ||
          find.byKey(const Key('explore-checkout-pay')).evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('빈자리가 없으면 샘플 카드만 보이고 깃발은 안내만 한다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      DiveTravelApp(
        firebaseReady: true,
        repository: MemoryDiverRepository.forTest(),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.tap(find.text(l10n.navCommunity));
    await tester.pumpAndSettle();

    expect(find.text(l10n.communityDesignPreview), findsOneWidget);
    expect(find.text(l10n.communityFlagButton), findsWidgets);
    await tester.tap(find.text(l10n.communityFlagButton).first);
    await tester.pump();
    expect(find.text(l10n.communityDesignPreviewFlag), findsOneWidget);
    expect(find.byKey(const Key('same-boat-flag-sheet')), findsNothing);
  });

  testWidgets('제휴파트너와 관리자는 깃발 꽂기 버튼이 꺼지고 안내가 보인다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    for (final repo in [
      MemoryDiverRepository.forTest(isAdmin: true),
      MemoryDiverRepository.forTest(isBusiness: true),
    ]) {
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
          openEmptySeats: true,
          capacity: 4,
          bookedSeats: 1,
          sameBoatStatus: SameBoatStatus.approved,
          departureStart: now.add(const Duration(days: 10)),
          flagClosesAt: now.add(const Duration(days: 3)),
        ),
      );
      await tester.pumpWidget(
        DiveTravelApp(firebaseReady: true, repository: repo),
      );
      await tester.pump();
      await tester.pump();
      for (var i = 0; i < 3 && find.text(l10n.navCommunity).evaluate().isEmpty; i++) {
        final poppable = tester
            .stateList<NavigatorState>(find.byType(Navigator))
            .where((nav) => nav.canPop());
        if (poppable.isEmpty) {
          break;
        }
        poppable.first.pop();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(l10n.navCommunity));
      await tester.pumpAndSettle();

      final flag = find.byKey(const Key('same-boat-flag-seat-prod-'));
      expect(flag, findsOneWidget);
      expect(tester.widget<FilledButton>(flag).onPressed, isNull);
      expect(find.text(l10n.staffCannotBuy), findsWidgets);

      await tester.tap(find.byKey(const Key('same-boat-seat-prod-')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('same-boat-detail-plant-pay')),
            )
            .onPressed,
        isNull,
      );
      expect(find.text(l10n.staffCannotBuy), findsWidgets);
    }
  });
}
