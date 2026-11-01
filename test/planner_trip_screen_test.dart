import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_trip_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Finder _labeled(String label) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration is InputDecoration &&
          (widget.decoration! as InputDecoration).labelText == label,
    );
  }

  test('기간은 시작일과 종료일로 박·일을 만든다', () {
    expect(plannerDurationLabel('', ''), isEmpty);
    expect(plannerDurationLabel('2026.11.18', '2026.11.30'), '12박 13일');
    expect(plannerDurationLabel('2026-11-18', '2026.11.18 (수)'), '1일');
    expect(plannerDurationLabel('2026.12.01', '2026.11.18'), isEmpty);
  });

  Future<({DiverStore store, MemoryDiverRepository repo})> open(
    WidgetTester tester, {
    Size size = const Size(1100, 6400),
    Future<PickedPhoto?> Function()? pickCover,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlannerTripScreen(pickCover: pickCover),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return (store: store, repo: repo);
  }

  Future<void> dismissSnack(WidgetTester tester) async {
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
        .hideCurrentSnackBar();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('기획 여행 화면은 기본사항, 이야기, 날짜 있는 상품 박스 순이다', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('planner-trip-screen')), findsOneWidget);
    expect(find.text('기획 여행 만들기'), findsOneWidget);
    expect(find.textContaining('손님 화면에는 아직'), findsWidgets);
    expect(find.textContaining('바로 올라갑니다'), findsNothing);
    expect(find.byIcon(Icons.format_bold), findsNothing);

    final basics = tester.getTopLeft(find.byKey(const Key('planner-section-basics'))).dy;
    final story = tester.getTopLeft(find.byKey(const Key('planner-section-story'))).dy;
    final product = tester.getTopLeft(find.byKey(const Key('planner-section-product'))).dy;
    final save = tester.getTopLeft(find.byKey(const Key('planner-trip-save'))).dy;
    expect(basics, lessThan(story));
    expect(story, lessThan(product));
    expect(product, lessThan(save));

    expect(find.byKey(const Key('shop-product-box')), findsOneWidget);
    expect(find.byKey(const Key('shop-product-box-date')), findsOneWidget);
    expect(find.byKey(const Key('shop-product-box-end-date')), findsOneWidget);
    expect(find.text('기간은 날짜로 자동'), findsOneWidget);
    expect(find.text('상품 박스 하나'), findsOneWidget);

    final title = tester.getTopLeft(find.byKey(const Key('planner-trip-title')));
    final region = tester.getTopLeft(find.byKey(const Key('planner-trip-region')));
    expect(region.dx, greaterThan(title.dx));
    expect((region.dy - title.dy).abs(), lessThan(8));

    await tester.enterText(find.byKey(const Key('shop-product-box-date')), '2026.11.18');
    await tester.enterText(find.byKey(const Key('shop-product-box-end-date')), '2026.11.30');
    await tester.pump();
    expect(find.text('12박 13일'), findsOneWidget);
  });

  testWidgets('좁은 화면에서는 제목과 지역이 위아래로 놓인다', (tester) async {
    await open(tester, size: const Size(400, 6400));
    final title = tester.getTopLeft(find.byKey(const Key('planner-trip-title')));
    final region = tester.getTopLeft(find.byKey(const Key('planner-trip-region')));
    expect(region.dy, greaterThan(title.dy + 20));
    final start = tester.getTopLeft(find.byKey(const Key('shop-product-box-date')));
    final end = tester.getTopLeft(find.byKey(const Key('shop-product-box-end-date')));
    expect(end.dy, greaterThan(start.dy + 20));
  });

  testWidgets('저장은 보이지 않는 curated 샵과 상품 문서 하나만 만든다', (tester) async {
    final opened = await open(
      tester,
      pickCover: () async => PickedPhoto(
        bytes: Uint8List.fromList(const [1, 2, 3]),
        fileName: 'reef.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final store = opened.store;
    final repo = opened.repo;

    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('여행 제목을 입력하세요.'), findsOneWidget);
    expect(
      (await repo.fetchShopStats()).where((shop) => shop.shopId.startsWith('curated-')),
      isEmpty,
    );
    await dismissSnack(tester);

    await tester.enterText(find.byKey(const Key('planner-trip-title')), '고래를 만나는 5박');
    await tester.enterText(find.byKey(const Key('planner-trip-region')), '몰디브 · 아리환');
    await tester.enterText(find.byKey(const Key('planner-trip-blurb')), '세 번 만났다');
    await tester.enterText(find.byKey(const Key('planner-trip-story')), '아침 포인트에서 고래가 왔다');
    await tester.enterText(find.byKey(const Key('planner-product-name')), '고래 리조트 5박');
    await tester.enterText(find.byKey(const Key('shop-product-box-date')), '2026.11.18');
    await tester.enterText(find.byKey(const Key('shop-product-box-end-date')), '2026.11.30');
    await tester.enterText(find.byKey(const Key('planner-includes')), '숙박, 보트');
    await tester.enterText(find.byKey(const Key('planner-excludes')), '항공');
    await tester.pump();

    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('기본 가격을 0원보다'), findsOneWidget);
    expect(
      (await repo.fetchShopStats()).where((shop) => shop.shopId.startsWith('curated-')),
      isEmpty,
    );
    await dismissSnack(tester);

    await tester.enterText(find.byKey(const Key('planner-product-price')), '890000');
    await tester.tap(find.byKey(const Key('planner-add-option')));
    await tester.pump();
    await tester.enterText(_labeled('옵션 이름'), '성인 1인');
    await tester.enterText(_labeled('가격'), '120000');
    await tester.tap(find.byKey(const Key('planner-trip-cover-pick')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('저장했습니다'), findsOneWidget);

    final curated = (await repo.fetchShopStats())
        .where((shop) => shop.shopId.startsWith('curated-'))
        .toList();
    expect(curated, hasLength(1));
    final shop = curated.single;
    expect(shop.curated, isTrue);
    expect(shop.name, '고래를 만나는 5박');
    expect(shop.location, '몰디브 · 아리환');
    expect(shop.coverUrl, 'memory://shop-cover-${shop.shopId}');
    final doc = shop.documentProducts!.single;
    expect(doc.name, '고래 리조트 5박');
    expect(doc.consumerPrice, 890000);
    expect(doc.blurb, '세 번 만났다');
    expect(doc.schedule, '아침 포인트에서 고래가 왔다');
    expect(doc.durationLabel, '12박 13일');
    expect(doc.departureStart, DateTime(2026, 11, 18));
    expect(doc.includes, '숙박, 보트');
    expect(doc.excludes, '항공');
    expect(doc.options.single.name, '성인 1인');
    expect(doc.options.single.consumerPrice, 120000);
    expect(doc.listingKind, ProductListingKind.curated);
    expect(doc.publishStatus, ProductPublishStatus.draft);
    expect(doc.active, isFalse);
    expect(doc.isListedPublicly, isFalse);
    expect(
      DiveShopCatalog.withLiveStats(await repo.fetchShopStats())
          .where((item) => item.id.startsWith('curated-')),
      isEmpty,
    );
    expect(store.resortsFeaturedAs(ProductListingKind.curated), isEmpty);
    await dismissSnack(tester);

    await tester.enterText(find.byKey(const Key('planner-trip-title')), '고래를 만나는 6박');
    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final again = (await repo.fetchShopStats())
        .where((item) => item.shopId.startsWith('curated-'))
        .toList();
    expect(again, hasLength(1));
    expect(again.single.shopId, shop.shopId);
    expect(again.single.name, '고래를 만나는 6박');
    expect(again.single.documentProducts, hasLength(1));
  });

  testWidgets('임시 저장은 가격이 없어도 같은 숨은 샵을 만든다', (tester) async {
    final opened = await open(tester, size: const Size(900, 6400));
    final repo = opened.repo;
    await tester.enterText(find.byKey(const Key('planner-trip-title')), '초안 여행');
    await tester.tap(find.byKey(const Key('planner-trip-temp-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('임시 저장했습니다'), findsOneWidget);
    final curated = (await repo.fetchShopStats())
        .where((shop) => shop.shopId.startsWith('curated-'))
        .toList();
    expect(curated, hasLength(1));
    expect(curated.single.documentProducts!.single.publishStatus, ProductPublishStatus.draft);
    expect(curated.single.documentProducts!.single.consumerPrice, 0);
    expect(curated.single.documentProducts!.single.isListedPublicly, isFalse);
  });
}
