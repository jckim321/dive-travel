import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/home/presentation/home_screen.dart';
import 'package:dive_travel_app/features/home/presentation/home_stay_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('별 등급은 배지에 금색 별 글자로만 적는다', () {
    expect(homeDiveStarMarks(3), '★★★');
    expect(homeDiveStarMarks(2), '★★');
    expect(homeDiveStarMarks(1), '★');
    expect(homeDiveStarMarks(0), '');
    expect(homeDiveStarMarks(4), '★★★');
  });

  testWidgets('Dive Star와 뜨는 스팟만 카드 모양이 다르고 가격 문구는 없다', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final repo = MemoryDiverRepository.forTest();
    Future<void> shelf(
      String shopId,
      ProductListingKind kind,
      DateTime at,
    ) {
      return repo.saveShopProduct(
        shopId: shopId,
        product: ShopProduct(
          id: 'shelf-$shopId',
          shopId: shopId,
          name: '상품 $shopId',
          consumerPrice: 100000,
          professionalPrice: 80000,
          publishStatus: ProductPublishStatus.approved,
          active: true,
          listingKind: kind,
          submittedAt: at,
        ),
      );
    }

    await shelf('bohol-hideout', ProductListingKind.diveStar, DateTime(2026, 4, 2));
    await shelf('malta-gozo', ProductListingKind.diveStar, DateTime(2026, 4, 1));
    await shelf('dahab-bluehole', ProductListingKind.hotSpot, DateTime(2026, 5, 3));
    await shelf('kerama-okinawa', ProductListingKind.hotSpot, DateTime(2026, 5, 2));
    await shelf('similan-liveaboard', ProductListingKind.hotSpot, DateTime(2026, 5, 1));
    await shelf(
      'palau-rock-islands',
      ProductListingKind.nextDeparture,
      DateTime(2026, 6, 1),
    );

    Future<void> profile(String shopId) {
      final hull = DiveShopCatalog.shops.firstWhere((shop) => shop.id == shopId);
      return repo.saveShopProfile(
        shopId: shopId,
        name: hull.name,
        location: hull.location,
        productName: '상품 $shopId',
        consumerPrice: 100000,
        professionalPrice: 80000,
      );
    }

    for (final id in [
      'bohol-hideout',
      'malta-gozo',
      'dahab-bluehole',
      'kerama-okinawa',
      'similan-liveaboard',
      'palau-rock-islands',
    ]) {
      await profile(id);
    }
    final reviewed = DateTime.utc(2026, 1, 1);
    final expires = DateTime.utc(2027, 1, 1);
    await repo.setDiveStarGrade(
      shopId: 'bohol-hideout',
      grade: 3,
      reviewedAt: reviewed,
      expiresAt: expires,
    );
    await repo.setDiveStarGrade(
      shopId: 'malta-gozo',
      grade: 2,
      reviewedAt: reviewed,
      expiresAt: expires,
    );

    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
    await store.refreshShopStats();
    await tester.pump();
    await tester.pump();

    tester.view.physicalSize = const Size(900, 4600);
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

    expect(find.text(l10n.homeDiveStarShelfHint), findsOneWidget);
    expect(find.text(l10n.homeHotSpotSubtitle), findsOneWidget);

    final diveCard = find.byKey(const Key('home-dive-star-card-bohol-hideout'));
    expect(tester.getSize(diveCard).width, HomeDiveStarCard.width);
    final navy = tester.widget<DecoratedBox>(diveCard).decoration as BoxDecoration;
    expect(navy.color, AppTheme.navy);
    expect(find.text('보홀 오션 하이드아웃'), findsOneWidget);
    expect(find.text('필리핀 보홀'), findsOneWidget);
    final three = tester.widget<Text>(
      find.byKey(const Key('home-dive-star-marks-bohol-hideout')),
    );
    expect(three.data, '★★★');
    expect(three.style?.color, AppTheme.gold);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('home-dive-star-marks-malta-gozo')))
          .data,
      '★★',
    );

    final rank = tester.widget<Text>(find.byKey(const Key('home-hot-rank-1')));
    expect(rank.data, '1');
    expect(rank.style?.color, Colors.white);
    expect(rank.style?.fontSize, greaterThanOrEqualTo(32));
    expect(rank.style?.shadows, isNotEmpty);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('다합 블루홀 다이브 센터'), findsOneWidget);
    expect(find.text('이집트 다합'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('home-hot-card-dahab-bluehole'))).dx,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('home-hot-card-kerama-okinawa'))).dx,
      ),
    );

    final diveStar = find.byKey(const Key('home-section-dive-star'));
    final hot = find.byKey(const Key('home-section-hot'));
    final sameBoat = find.byKey(const Key('home-section-same-boat'));
    expect(
      find.descendant(of: diveStar, matching: find.textContaining('100000')),
      findsNothing,
    );
    expect(
      find.descendant(of: hot, matching: find.textContaining('100000')),
      findsNothing,
    );
    expect(
      find.descendant(of: diveStar, matching: find.byType(HomeStayCard)),
      findsNothing,
    );
    expect(
      find.descendant(of: hot, matching: find.byType(HomeStayCard)),
      findsNothing,
    );
    expect(
      find.descendant(of: sameBoat, matching: find.byType(HomeSameBoatCard)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sameBoat, matching: find.byKey(const Key('home-hot-rank-1'))),
      findsNothing,
    );
  });
}
