import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/explore/presentation/product_offer_box.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  const schedule = '첫째 날 체크다이브\n둘째 날 2탱크';

  ShopProduct product() {
    return const ShopProduct(
      id: 'trip-1',
      shopId: 'curated-1',
      name: '블루홀',
      consumerPrice: 100000,
      professionalPrice: 80000,
      durationLabel: '2박 3일',
      meetingPoint: '리조트 로비',
      schedule: schedule,
      includes: '보트\n탱크',
      excludes: '장비 렌탈',
      cancellationNote: '7일 전 전액',
    );
  }

  Future<void> pumpBox(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryDiverRepository.forTest();
    final store = DiverStore(repo);
    final session = SessionController(repo);
    addTearDown(store.dispose);
    addTearDown(session.dispose);
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
        home: Scaffold(
          body: ProductOfferBox(
            shop: const DiveShop(
              id: 'curated-1--trip-1',
              name: '블루홀',
              location: '팔라완',
              country: '필리핀',
              continent: 'asia',
              sites: [],
              productName: '블루홀',
              stars: 0,
              rating: 0,
              reviewCount: 0,
              amenities: [],
              consumerPrice: 100000,
              professionalPrice: 80000,
              blurb: '한 줄 소개',
            ),
            product: product(),
            quote: const TourPriceQuote(amount: 100000, isProfessional: false),
            recommended: false,
            lightest: true,
            openRooms: 0,
            onBook: (_) {},
          ),
        ),
      ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('자세히 보기를 열면 일정 줄바꿈과 집합·포함·취소·박수가 보인다', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await pumpBox(tester);

    expect(find.text('리조트 로비'), findsNothing);
    expect(find.text('한 줄 소개'), findsOneWidget);
    expect(find.byType(MarkdownBody), findsNothing);

    await tester.tap(find.byKey(const Key('product-offer-details-trip-1')));
    await tester.pump();

    expect(find.text(l10n.productOfferNights), findsOneWidget);
    expect(find.text('2박 3일'), findsOneWidget);
    expect(find.text('리조트 로비'), findsOneWidget);
    expect(find.text('보트\n탱크'), findsOneWidget);
    expect(find.text('장비 렌탈'), findsOneWidget);
    expect(find.text('7일 전 전액'), findsOneWidget);
    final markdown = tester.widget<MarkdownBody>(
      find.descendant(
        of: find.byKey(const Key('product-offer-schedule-trip-1')),
        matching: find.byType(MarkdownBody),
      ),
    );
    expect(markdown.data, schedule);
    expect(markdown.softLineBreak, isTrue);
  });

  testWidgets('강사 상세는 저장된 강사 우대가를 보이고 빈 옵션은 소비자가로 보인다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const shop = DiveShop(
      id: 'curated-1--trip-1',
      name: '블루홀',
      location: '팔라완',
      country: '필리핀',
      continent: 'asia',
      sites: [],
      productName: '블루홀',
      stars: 0,
      rating: 0,
      reviewCount: 0,
      amenities: [],
      consumerPrice: 100000,
      professionalPrice: 80000,
    );
    const product = ShopProduct(
      id: 'trip-1',
      shopId: 'curated-1',
      name: '블루홀',
      consumerPrice: 100000,
      professionalPrice: 80000,
      options: [
        ShopProductOption(
          id: 'night',
          name: '나이트',
          consumerPrice: 20000,
          professionalPrice: 15000,
        ),
        ShopProductOption(
          id: 'gear',
          name: '장비',
          consumerPrice: 30000,
          professionalPrice: 0,
        ),
      ],
    );
    final quote = TourPricePolicy.quote(shop, isInstructor: true);
    final repo = MemoryDiverRepository.forTest();
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductOfferBox(
              shop: shop,
              product: product,
              quote: quote,
              recommended: false,
              lightest: false,
              openRooms: 0,
              onBook: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(quote.amount, 80000);
    expect(find.text('80,000원'), findsOneWidget);
    expect(find.text('15,000원'), findsOneWidget);
    expect(find.text('30,000원'), findsOneWidget);
    expect(find.text('70,000원'), findsNothing);
  });
}
