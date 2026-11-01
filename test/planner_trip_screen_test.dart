import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/models/story_block.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/storage/dive_video_picker.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_trip_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/story_block_editor.dart';
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

  test('예전 일정 글은 문단 블록 하나가 된다', () {
    final blocks = StoryBlock.seed(
      stored: const [],
      legacySchedule: '아침 고래',
    );
    expect(blocks.single.kind, StoryBlockKind.paragraph);
    expect(blocks.single.text, '아침 고래');
    final photo = StoryBlock.fromMap({
      'kind': 'photo',
      'url': 'https://cdn.example/whale.jpg',
      'caption': '옆에서 본 고래',
    });
    expect(photo.kind, StoryBlockKind.photo);
    expect(photo.url, 'https://cdn.example/whale.jpg');
    expect(photo.toMap(), {
      'kind': 'photo',
      'url': 'https://cdn.example/whale.jpg',
      'caption': '옆에서 본 고래',
    });
    expect(StoryBlock.photoCount([photo, photo]), 2);
    final video = StoryBlock.fromMap({
      'kind': 'video',
      'url': 'https://cdn.example/whale.mp4',
      'caption': '배 위에서',
    });
    expect(video.kind, StoryBlockKind.video);
    expect(video.toMap()['kind'], 'video');
    expect(video.toMap()['url'], 'https://cdn.example/whale.mp4');
    expect(
      StoryBlock.videoRejectReason(name: 'clip.mov', size: 10),
      'mp4 파일만 올릴 수 있습니다.',
    );
    expect(
      StoryBlock.videoRejectReason(
        name: 'clip.mp4',
        size: StoryBlock.maxVideoBytes + 1,
      ),
      '동영상은 100MB 이하만 올릴 수 있습니다.',
    );
    expect(
      StoryBlock.videoRejectReason(name: 'clip.mp4', size: StoryBlock.maxVideoBytes),
      isNull,
    );
    final place = StoryBlock.fromMap({
      'kind': 'map',
      'name': '팡라오 비치',
      'address': '보홀',
    });
    expect(place.kind, StoryBlockKind.map);
    expect(place.toMap(), {
      'kind': 'map',
      'name': '팡라오 비치',
      'address': '보홀',
    });
    expect(place.mapSearchUri, googleMapsSearchUri('팡라오 비치 보홀'));
    expect(
      StoryBlock.seed(
        stored: const [
          StoryBlock(kind: StoryBlockKind.heading, text: '제목'),
        ],
        legacySchedule: '무시',
      ).single.kind,
      StoryBlockKind.heading,
    );
    final spans = storyInlineSpans('**굵게** *기울임* ++밑줄++', const TextStyle());
    expect(spans, hasLength(5));
  });

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
    Future<PickedPhoto?> Function()? pickStoryPhoto,
    Future<PickedVideo?> Function()? pickStoryVideo,
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
          home: PlannerTripScreen(
            pickCover: pickCover,
            pickStoryPhoto: pickStoryPhoto,
            pickStoryVideo: pickStoryVideo,
          ),
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
    expect(find.byKey(const Key('planner-trip-open')), findsOneWidget);
    expect(find.text('열림'), findsOneWidget);
    expect(find.textContaining('손님 목록·홈·같은배'), findsWidgets);
    expect(find.textContaining('바로 올라갑니다'), findsNothing);
    expect(find.byKey(const Key('planner-story-bold')), findsOneWidget);
    expect(find.byKey(const Key('planner-story-italic')), findsOneWidget);
    expect(find.byKey(const Key('planner-story-more')), findsNothing);

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
    expect(find.byKey(const Key('planner-story-bold')), findsOneWidget);
    expect(find.byKey(const Key('planner-story-heading')), findsOneWidget);
    expect(find.byKey(const Key('planner-story-list')), findsOneWidget);
    expect(find.byKey(const Key('planner-story-more')), findsOneWidget);
    expect(find.byKey(const Key('planner-story-italic')), findsNothing);
    expect(find.byKey(const Key('planner-story-photo')), findsNothing);
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
    expect(doc.storyBlocks.single.kind, StoryBlockKind.paragraph);
    expect(doc.storyBlocks.single.text, '아침 포인트에서 고래가 왔다');
    expect(doc.storyBlocks.single.toMap()['kind'], 'paragraph');
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

  testWidgets('기존 curated 기획 상품을 고쳐도 같은 샵이고 열림 상태는 유지된다', (tester) async {
    tester.view.physicalSize = const Size(1100, 6400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const shopId = 'curated-whale';
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: shopId,
      name: '고래를 만나는 여행',
      location: '몰디브 · 아리환',
      country: '몰디브',
      productName: '고래 리조트',
      consumerPrice: 890000,
      professionalPrice: 890000,
      curated: true,
    );
    final existing = ShopProduct(
      id: 'whale-1',
      shopId: shopId,
      name: '고래 리조트',
      consumerPrice: 890000,
      professionalPrice: 890000,
      blurb: '세 번',
      schedule: '아침 고래',
      durationLabel: '12박 13일',
      departureStart: DateTime(2026, 11, 18),
      includes: '보트',
      listingKind: ProductListingKind.curated,
      publishStatus: ProductPublishStatus.approved,
      active: true,
      options: const [
        ShopProductOption(
          id: 'adult',
          name: '성인 1인',
          consumerPrice: 120000,
          professionalPrice: 120000,
        ),
      ],
    );
    await repo.saveShopProduct(shopId: shopId, product: existing);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();
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

    expect(find.text('고래를 만나는 여행'), findsWidgets);
    expect(find.text('몰디브 · 아리환'), findsWidgets);
    expect(find.text('아침 고래'), findsWidgets);
    expect(find.text('2026.11.18'), findsWidgets);
    expect(find.text('2026.11.30'), findsWidgets);
    expect(find.text('성인 1인'), findsWidgets);

    await tester.enterText(find.byKey(const Key('planner-trip-story')), '저녁에도 고래');
    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final curated = (await repo.fetchShopStats())
        .where((shop) => shop.shopId.startsWith('curated-'))
        .toList();
    expect(curated, hasLength(1));
    expect(curated.single.shopId, shopId);
    final doc = curated.single.documentProducts!.single;
    expect(doc.id, 'whale-1');
    expect(doc.schedule, '저녁에도 고래');
    expect(doc.storyBlocks.single.kind, StoryBlockKind.paragraph);
    expect(doc.storyBlocks.single.text, '저녁에도 고래');
    expect(doc.publishStatus, ProductPublishStatus.approved);
    expect(doc.active, isTrue);
    expect(doc.listingKind, ProductListingKind.curated);
    expect(doc.options.single.id, 'adult');
  });

  testWidgets('인용은 블록으로 저장된다', (tester) async {
    final opened = await open(tester);
    await tester.tap(find.byKey(const Key('planner-story-quote')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('planner-trip-title')), '고래 여행');
    await tester.enterText(find.byKey(const Key('planner-product-price')), '1000');
    await tester.enterText(find.byKey(const Key('planner-trip-story')), '숙소의 식사');
    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final doc = (await opened.repo.fetchShopStats())
        .where((shop) => shop.shopId.startsWith('curated-'))
        .single
        .documentProducts!
        .single;
    expect(doc.storyBlocks.single.kind, StoryBlockKind.quote);
    expect(doc.storyBlocks.single.text, '숙소의 식사');
    expect(doc.schedule, '숙소의 식사');
  });

  testWidgets('폰의 더보기 지도도 현재 줄 아래에 붙는다', (tester) async {
    await open(tester, size: const Size(400, 6400));
    await tester.tap(find.byKey(const Key('planner-story-more')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('기울임'), findsOneWidget);
    expect(find.text('동영상'), findsOneWidget);
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, '지도'));
    await tester.pump();
    expect(find.byKey(const Key('planner-story-map-block-1')), findsOneWidget);
    expect(find.text('준비 중'), findsNothing);
  });

  PickedPhoto _storyPhoto() {
    return PickedPhoto(
      bytes: Uint8List.fromList(const [1, 2, 3]),
      fileName: 'whale.jpg',
      contentType: 'image/jpeg',
    );
  }

  testWidgets('사진은 현재 줄 아래에 올라가고 설명과 함께 저장된다', (tester) async {
    final opened = await open(
      tester,
      pickStoryPhoto: () async => _storyPhoto(),
    );
    await tester.enterText(find.byKey(const Key('planner-trip-story')), '저녁에도 고래');
    await tester.tap(find.byKey(const Key('planner-story-photo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('planner-story-photo-block-1')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('planner-story-photo-caption-1')),
      '옆에서 본 고래',
    );
    await tester.tap(find.byKey(const Key('planner-story-photo-up-1')));
    await tester.pump();
    expect(find.byKey(const Key('planner-story-photo-block-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('planner-story-photo-down-0')));
    await tester.pump();
    expect(find.byKey(const Key('planner-story-photo-block-1')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('planner-trip-title')), '고래 여행');
    await tester.enterText(find.byKey(const Key('planner-product-price')), '1000');
    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final doc = (await opened.repo.fetchShopStats())
        .where((shop) => shop.shopId.startsWith('curated-'))
        .single
        .documentProducts!
        .single;
    final photo = doc.storyBlocks.singleWhere((block) => block.kind == StoryBlockKind.photo);
    expect(photo.url, startsWith('memory://story-photo-'));
    expect(photo.caption, '옆에서 본 고래');
    expect(photo.toMap()['kind'], 'photo');
    expect(photo.toMap()['caption'], '옆에서 본 고래');
    expect(doc.storyBlocks.first.kind, StoryBlockKind.paragraph);
    expect(doc.schedule, '저녁에도 고래\n옆에서 본 고래');
  });

  testWidgets('사진 블록은 지울 수 있다', (tester) async {
    await open(tester, pickStoryPhoto: () async => _storyPhoto());
    await tester.tap(find.byKey(const Key('planner-story-photo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('planner-story-photo-block-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('planner-story-photo-delete-1')));
    await tester.pump();
    expect(find.byKey(const Key('planner-story-photo-block-1')), findsNothing);
  });

  testWidgets('폰의 더보기 사진도 현재 줄 아래에 붙는다', (tester) async {
    await open(
      tester,
      size: const Size(400, 6400),
      pickStoryPhoto: () async => _storyPhoto(),
    );
    await tester.tap(find.byKey(const Key('planner-story-more')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, '사진'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('planner-story-photo-block-1')), findsOneWidget);
    expect(find.text('준비 중'), findsNothing);
  });

  testWidgets('사진은 30장까지만 올린다', (tester) async {
    tester.view.physicalSize = const Size(900, 20000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var picked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryBlockEditor(
            initial: [
              for (var i = 0; i < StoryBlock.maxPhotos; i++)
                StoryBlock(kind: StoryBlockKind.photo, url: 'memory://p$i'),
            ],
            onChanged: (_) {},
            pickPhoto: () async {
              picked = true;
              return _storyPhoto();
            },
            uploadPhoto: (_) async => 'memory://extra',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('planner-story-photo')));
    await tester.pump();
    expect(find.text('사진은 30장까지 올릴 수 있습니다.'), findsOneWidget);
    expect(picked, isFalse);
    expect(find.byKey(const Key('planner-story-photo-block-30')), findsNothing);
  });

  PickedVideo _storyVideo({String name = 'whale.mp4', int? declaredSize}) {
    return PickedVideo(
      bytes: Uint8List.fromList(const [1, 2, 3, 4]),
      fileName: name,
      declaredSize: declaredSize,
    );
  }

  testWidgets('동영상은 현재 줄 아래에 붙고 설명과 함께 저장된다', (tester) async {
    final opened = await open(
      tester,
      pickStoryVideo: () async => _storyVideo(),
    );
    await tester.enterText(find.byKey(const Key('planner-trip-story')), '저녁에도 고래');
    await tester.tap(find.byKey(const Key('planner-story-video')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('planner-story-video-block-1')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('planner-story-video-caption-1')),
      '배 위에서 본 고래',
    );
    await tester.tap(find.byKey(const Key('planner-story-video-up-1')));
    await tester.pump();
    expect(find.byKey(const Key('planner-story-video-block-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('planner-story-video-down-0')));
    await tester.pump();
    expect(find.byKey(const Key('planner-story-video-block-1')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('planner-trip-title')), '고래 여행');
    await tester.enterText(find.byKey(const Key('planner-product-price')), '1000');
    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final doc = (await opened.repo.fetchShopStats())
        .where((shop) => shop.shopId.startsWith('curated-'))
        .single
        .documentProducts!
        .single;
    final video = doc.storyBlocks.singleWhere((block) => block.kind == StoryBlockKind.video);
    expect(video.url, startsWith('memory://story-video-'));
    expect(video.caption, '배 위에서 본 고래');
    expect(video.toMap()['kind'], 'video');
    expect(video.toMap()['caption'], '배 위에서 본 고래');
    expect(doc.storyBlocks.first.kind, StoryBlockKind.paragraph);
  });

  testWidgets('동영상 올리기는 진행률을 보여 준다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryBlockEditor(
            initial: const [StoryBlock(kind: StoryBlockKind.paragraph)],
            onChanged: (_) {},
            pickVideo: () async => _storyVideo(),
            uploadVideo: (video, onProgress) async {
              onProgress(0.4);
              await gate.future;
              onProgress(1);
              return 'memory://story-video-clip';
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('planner-story-video')));
    await tester.pump();
    await tester.pump();
    expect(find.text('올리는 중 40%'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('planner-story-video-progress')),
    );
    expect(bar.value, 0.4);
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('planner-story-video-block-1')), findsOneWidget);
    expect(find.byKey(const Key('planner-story-video-progress')), findsNothing);
  });

  testWidgets('동영상 블록은 지울 수 있다', (tester) async {
    await open(tester, pickStoryVideo: () async => _storyVideo());
    await tester.tap(find.byKey(const Key('planner-story-video')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('planner-story-video-delete-1')));
    await tester.pump();
    expect(find.byKey(const Key('planner-story-video-block-1')), findsNothing);
  });

  testWidgets('mp4가 아니거나 100MB를 넘거나 3개를 넘으면 올리지 않는다', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var uploads = 0;
    Future<void> pumpEditor({
      required List<StoryBlock> initial,
      required Future<PickedVideo?> Function() pick,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: Scaffold(
            body: StoryBlockEditor(
              initial: initial,
              onChanged: (_) {},
              pickVideo: pick,
              uploadVideo: (_, _) async {
                uploads += 1;
                return 'memory://story-video-extra';
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('planner-story-video')));
      await tester.pump();
      await tester.pump();
    }

    await pumpEditor(
      initial: const [StoryBlock(kind: StoryBlockKind.paragraph)],
      pick: () async => _storyVideo(name: 'clip.mov'),
    );
    expect(find.text('mp4 파일만 올릴 수 있습니다.'), findsOneWidget);
    expect(uploads, 0);

    await pumpEditor(
      initial: const [StoryBlock(kind: StoryBlockKind.paragraph)],
      pick: () async => _storyVideo(declaredSize: StoryBlock.maxVideoBytes + 1),
    );
    expect(find.text('동영상은 100MB 이하만 올릴 수 있습니다.'), findsOneWidget);
    expect(uploads, 0);

    var picked = false;
    await pumpEditor(
      initial: [
        for (var i = 0; i < StoryBlock.maxVideos; i++)
          StoryBlock(kind: StoryBlockKind.video, url: 'memory://v$i'),
      ],
      pick: () async {
        picked = true;
        return _storyVideo();
      },
    );
    expect(find.text('동영상은 3개까지 올릴 수 있습니다.'), findsOneWidget);
    expect(picked, isFalse);
    expect(uploads, 0);
  });

  testWidgets('폰의 더보기 동영상도 현재 줄 아래에 붙는다', (tester) async {
    await open(
      tester,
      size: const Size(400, 6400),
      pickStoryVideo: () async => _storyVideo(),
    );
    await tester.tap(find.byKey(const Key('planner-story-more')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, '동영상'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('planner-story-video-block-1')), findsOneWidget);
    expect(find.text('준비 중'), findsNothing);
  });

  testWidgets('지도는 현재 줄 아래에 붙고 이름과 주소로 저장된다', (tester) async {
    final opened = await open(tester);
    await tester.enterText(find.byKey(const Key('planner-trip-story')), '저녁에도 고래');
    await tester.tap(find.byKey(const Key('planner-story-map')));
    await tester.pump();
    expect(find.byKey(const Key('planner-story-map-block-1')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('planner-story-map-name-1')), '팡라오 비치');
    await tester.enterText(find.byKey(const Key('planner-story-map-address-1')), '보홀');
    await tester.tap(find.byKey(const Key('planner-story-map-up-1')));
    await tester.pump();
    expect(find.byKey(const Key('planner-story-map-block-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('planner-story-map-down-0')));
    await tester.pump();
    expect(find.byKey(const Key('planner-story-map-block-1')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('planner-trip-title')), '고래 여행');
    await tester.enterText(find.byKey(const Key('planner-product-price')), '1000');
    await tester.tap(find.byKey(const Key('planner-trip-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final doc = (await opened.repo.fetchShopStats())
        .where((shop) => shop.shopId.startsWith('curated-'))
        .single
        .documentProducts!
        .single;
    final place = doc.storyBlocks.singleWhere((block) => block.kind == StoryBlockKind.map);
    expect(place.toMap(), {
      'kind': 'map',
      'name': '팡라오 비치',
      'address': '보홀',
    });
    expect(place.mapSearchUri, googleMapsSearchUri('팡라오 비치 보홀'));
    expect(doc.storyBlocks.first.kind, StoryBlockKind.paragraph);
    expect(doc.schedule, '저녁에도 고래\n팡라오 비치\n보홀');
  });

  testWidgets('지도 검색은 장소 이름과 주소로 연다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryBlockEditor(
            initial: const [StoryBlock(kind: StoryBlockKind.paragraph)],
            onChanged: (_) {},
            openMap: (uri) async {
              opened = uri;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('planner-story-map')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('planner-story-map-search-1')));
    await tester.pump();
    expect(find.text('주소를 입력한 뒤 지도 검색을 누르세요.'), findsOneWidget);
    expect(opened, isNull);
    await tester.enterText(find.byKey(const Key('planner-story-map-name-1')), '팡라오 비치');
    await tester.enterText(find.byKey(const Key('planner-story-map-address-1')), '보홀');
    await tester.tap(find.byKey(const Key('planner-story-map-search-1')));
    await tester.pump();
    expect(opened, googleMapsSearchUri('팡라오 비치 보홀'));
  });

  testWidgets('지도 블록은 지울 수 있다', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('planner-story-map')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('planner-story-map-delete-1')));
    await tester.pump();
    expect(find.byKey(const Key('planner-story-map-block-1')), findsNothing);
  });

  testWidgets('지도는 5개까지만 넣는다', (tester) async {
    tester.view.physicalSize = const Size(900, 8000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryBlockEditor(
            initial: [
              for (var i = 0; i < StoryBlock.maxMaps; i++)
                StoryBlock(kind: StoryBlockKind.map, placeName: '장소 $i', text: '주소 $i'),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('planner-story-map')));
    await tester.pump();
    expect(find.text('지도는 5개까지 넣을 수 있습니다.'), findsOneWidget);
    expect(find.byKey(const Key('planner-story-map-block-5')), findsNothing);
  });
}
