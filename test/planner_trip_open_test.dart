import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_products_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_trip_screen.dart';
import 'package:dive_travel_app/features/profile/presentation/my_crafted_trips_section.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<({DiverStore store, MemoryDiverRepository repo})> openPlanner(
    WidgetTester tester, {
    required bool admin,
    ShopProduct? existing,
    MemoryDiverRepository? repo,
  }) async {
    tester.view.physicalSize = const Size(1100, 6400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final memory = repo ?? MemoryDiverRepository.forTest(isAdmin: admin);
    final store = DiverStore(memory);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlannerTripScreen(existing: existing),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return (store: store, repo: memory);
  }

  Future<void> fillTrip(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('planner-trip-title')), '고래를 만나는 5박');
    await tester.enterText(find.byKey(const Key('planner-trip-region')), '몰디브');
    await tester.enterText(find.byKey(const Key('planner-product-price')), '890000');
    tester.widget<TextField>(find.byKey(const Key('shop-product-box-date'))).controller!
        .text = formatPlannerDay(DateTime(2026, 11, 18));
    tester.widget<TextField>(find.byKey(const Key('shop-product-box-end-date'))).controller!
        .text = formatPlannerDay(DateTime(2026, 11, 23));
    await tester.enterText(find.byKey(const Key('planner-same-boat-capacity')), '8');
    await tester.enterText(find.byKey(const Key('planner-same-boat-booked')), '2');
    await tester.pump();
  }

  testWidgets('열림을 켜면 손님 목록·홈·같은배에 나오고 끄면 내려간다', (tester) async {
    final opened = await openPlanner(tester, admin: false);
    final store = opened.store;
    final repo = opened.repo;

    await tester.tap(find.byKey(const Key('planner-trip-open')));
    await tester.pump();
    await fillTrip(tester);
    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('손님 목록·홈·같은배'), findsWidgets);

    final curated = (await repo.fetchShopStats())
        .where((shop) => shop.shopId.startsWith('curated-'))
        .toList();
    expect(curated, hasLength(1));
    final doc = curated.single.documentProducts!.single;
    expect(doc.publishStatus, ProductPublishStatus.approved);
    expect(doc.active, isTrue);
    expect(doc.listingKind, ProductListingKind.curated);
    expect(doc.openEmptySeats, isTrue);
    expect(doc.capacity, 8);
    expect(doc.bookedSeats, 2);
    expect(doc.sameBoatStatus, SameBoatStatus.approved);
    expect(doc.listsOnSameBoat, isTrue);
    expect(doc.isListedPublicly, isTrue);
    expect(
      DiveShopCatalog.withLiveStats(await repo.fetchShopStats())
          .where((shop) => shop.id.startsWith('curated-')),
      isNotEmpty,
    );
    expect(store.resortsFeaturedAs(ProductListingKind.curated), isNotEmpty);
    expect(
      store
          .sameBoatOffers(SameBoatFilter.all, now: DateTime(2026, 11, 1))
          .where((offer) => offer.product.id == doc.id),
      isNotEmpty,
    );

    await tester.tap(find.byKey(const Key('planner-trip-open')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final closed = (await repo.fetchShopStats())
        .where((shop) => shop.shopId.startsWith('curated-'))
        .single
        .documentProducts!
        .single;
    expect(closed.publishStatus, ProductPublishStatus.draft);
    expect(closed.active, isFalse);
    expect(closed.listsOnSameBoat, isFalse);
    expect(closed.isListedPublicly, isFalse);
    expect(store.resortsFeaturedAs(ProductListingKind.curated), isEmpty);
    expect(
      store.sameBoatOffers(SameBoatFilter.all, now: DateTime(2026, 11, 1)),
      isEmpty,
    );
    expect(
      DiveShopCatalog.withLiveStats(await repo.fetchShopStats())
          .where((shop) => shop.id.startsWith('curated-')),
      isEmpty,
    );
  });

  testWidgets('관리자 숨김은 손님에게 안 보이고 만든 분은 해제할 수 없다', (tester) async {
    tester.view.physicalSize = const Size(1100, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const shopId = 'curated-whale';
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: shopId,
      name: '고래를 만나는 여행',
      location: '몰디브',
      country: '몰디브',
      productName: '고래 리조트',
      consumerPrice: 890000,
      professionalPrice: 890000,
      curated: true,
      creatorUid: 'test-user',
    );
    final live = ShopProduct(
      id: 'whale-1',
      shopId: shopId,
      name: '고래 리조트',
      consumerPrice: 890000,
      professionalPrice: 890000,
      listingKind: ProductListingKind.curated,
      publishStatus: ProductPublishStatus.approved,
      active: true,
      openEmptySeats: true,
      capacity: 4,
      departureStart: DateTime(2026, 11, 18),
      sameBoatStatus: SameBoatStatus.approved,
      featuredAt: DateTime(2026, 11, 1),
      submittedByUid: 'test-user',
    );
    await repo.saveShopProduct(shopId: shopId, product: live);
    await repo.saveShopProfile(
      shopId: 'reef',
      name: '리프',
      location: '세부',
      productName: '펀다이브',
      consumerPrice: 10000,
      professionalPrice: 8000,
    );
    await repo.saveShopProduct(
      shopId: 'reef',
      product: ShopProduct(
        id: 'fun-1',
        shopId: 'reef',
        name: '펀다이브',
        consumerPrice: 10000,
        professionalPrice: 8000,
      ),
    );

    final admin = DiverStore(repo);
    addTearDown(admin.dispose);
    await admin.refreshShopStats();
    await tester.pumpWidget(
      DiverStoreScope(
        store: admin,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminProductsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(admin.resortsFeaturedAs(ProductListingKind.curated), isNotEmpty);

    await tester.scrollUntilVisible(
      find.byKey(const Key('admin-planner-hide-whale-1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const Key('admin-planner-hide-fun-1'), skipOffstage: false),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('admin-planner-hide-whale-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final hidden = (await repo.fetchShopStat(shopId))!.documentProducts!.single;
    expect(hidden.sameBoatStatus, SameBoatStatus.hidden);
    expect(hidden.isListedPublicly, isFalse);
    expect(hidden.listsOnSameBoat, isFalse);
    expect(admin.resortsFeaturedAs(ProductListingKind.curated), isEmpty);
    expect(
      admin.sameBoatOffers(SameBoatFilter.all, now: DateTime(2026, 11, 1)),
      isEmpty,
    );
    expect(
      DiveShopCatalog.withLiveStats(await repo.fetchShopStats())
          .where((shop) => shop.id == shopId),
      isEmpty,
    );
    expect(find.byKey(const Key('admin-planner-unhide-whale-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-planner-unhide-whale-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final shown = (await repo.fetchShopStat(shopId))!.documentProducts!.single;
    expect(shown.sameBoatStatus, SameBoatStatus.approved);
    expect(shown.isListedPublicly, isTrue);
    expect(shown.listsOnSameBoat, isTrue);
    expect(admin.resortsFeaturedAs(ProductListingKind.curated), isNotEmpty);
    expect(
      admin.sameBoatOffers(SameBoatFilter.all, now: DateTime(2026, 11, 1)),
      isNotEmpty,
    );

    await tester.tap(find.byKey(const Key('admin-planner-hide-whale-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      (await repo.fetchShopStat(shopId))!.documentProducts!.single.sameBoatStatus,
      SameBoatStatus.hidden,
    );
  });

  testWidgets('숨긴 기획 여행은 만든 분 화면에 표시되고 스위치가 잠긴다', (tester) async {
    const shopId = 'curated-whale';
    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProfile(
      shopId: shopId,
      name: '고래를 만나는 여행',
      location: '몰디브',
      country: '몰디브',
      productName: '고래 리조트',
      consumerPrice: 890000,
      professionalPrice: 890000,
      curated: true,
      creatorUid: 'test-user',
    );
    final hidden = ShopProduct(
      id: 'whale-1',
      shopId: shopId,
      name: '고래 리조트',
      consumerPrice: 890000,
      professionalPrice: 890000,
      listingKind: ProductListingKind.curated,
      publishStatus: ProductPublishStatus.draft,
      active: false,
      openEmptySeats: true,
      capacity: 4,
      durationLabel: '5박 6일',
      departureStart: DateTime(2026, 11, 18),
      sameBoatStatus: SameBoatStatus.hidden,
      submittedByUid: 'test-user',
    );
    await repo.saveShopProduct(shopId: shopId, product: hidden);

    final opened = await openPlanner(
      tester,
      admin: false,
      existing: hidden,
      repo: repo,
    );
    expect(find.text('관리자가 잠시 숨김'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);

    await tester.enterText(find.byKey(const Key('planner-trip-story')), '저녁에도 고래');
    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final doc = (await repo.fetchShopStat(shopId))!.documentProducts!.single;
    expect(doc.schedule, '저녁에도 고래');
    expect(doc.sameBoatStatus, SameBoatStatus.hidden);
    expect(doc.isListedPublicly, isFalse);
    expect(
      opened.store.resortsFeaturedAs(ProductListingKind.curated),
      isEmpty,
    );
    await expectLater(
      opened.store.setPlannedTripOpen(
        shopId: shopId,
        productId: hidden.id,
        open: true,
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      opened.store.setSameBoatStatus(
        shopId: shopId,
        productId: hidden.id,
        status: SameBoatStatus.approved,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      (await repo.fetchShopStat(shopId))!.documentProducts!.single.sameBoatStatus,
      SameBoatStatus.hidden,
    );
  });

  testWidgets('만든 분 목록에는 관리자가 잠시 숨김이라고 나온다', (tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.pumpWidget(
      MaterialApp(
        locale: AppConstants.defaultLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MyCraftedTripsSection(
            products: [
              ShopProduct(
                id: 'whale-1',
                shopId: 'curated-whale',
                name: '고래 리조트',
                consumerPrice: 1,
                professionalPrice: 1,
                sameBoatStatus: SameBoatStatus.hidden,
                publishStatus: ProductPublishStatus.approved,
                active: true,
              ),
            ],
            memberGrade: MemberGrade.gold,
            viewerUid: 'test-user',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('관리자가 잠시 숨김'), findsOneWidget);
    expect(find.text(l10n.profileCraftStatusLive), findsNothing);
  });
}
