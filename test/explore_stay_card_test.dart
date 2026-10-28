import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/ccard_product_frame.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/features/home/presentation/home_stay_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  DiveShop shop({
    required String id,
    required String name,
    int stars = 0,
    double rating = 0,
    int reviewCount = 0,
    DateTime? diveStarExpiresAt,
    int consumerPrice = 180000,
  }) {
    return DiveShop(
      id: id,
      name: name,
      location: '필리핀 보홀',
      country: '필리핀',
      continent: 'asia',
      sites: const ['발리카삭'],
      productName: '펀다이빙',
      stars: stars,
      rating: rating,
      reviewCount: reviewCount,
      amenities: const [],
      consumerPrice: consumerPrice,
      professionalPrice: 126000,
      diveStarExpiresAt: diveStarExpiresAt,
    );
  }

  Future<void> pumpCards(WidgetTester tester, List<Widget> cards) async {
    final store = DiverStore(MemoryDiverRepository.forTest());
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  for (final card in cards)
                    SizedBox(width: 180, child: card),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('여행상품 카드는 하늘색 띠에 이름·지역·후기를 넣고 가격은 없다', (tester) async {
    tester.view.physicalSize = const Size(400, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await pumpCards(tester, [
      HomeStayCard(
        shop: shop(
          id: 'starred',
          name: '보홀 오션 하이드아웃',
          stars: 3,
          rating: 4.8,
          reviewCount: 23,
        ),
        travelTab: true,
        onDetails: () {},
      ),
      HomeStayCard(
        shop: shop(id: 'plain', name: '팔라우 패키지'),
        travelTab: true,
        onDetails: () {},
      ),
      HomeStayCard(
        shop: shop(
          id: 'expired',
          name: '만료 리조트',
          stars: 2,
          diveStarExpiresAt: DateTime.utc(2020, 1, 1),
        ),
        travelTab: true,
        onDetails: () {},
      ),
    ]);

    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio).first).aspectRatio,
      closeTo(ListingCover.aspectRatio / ListingCover.travelPhotoScale, 0.001),
    );
    expect(
      find.descendant(
        of: find.byType(CCardProductFrame),
        matching: find.byKey(const Key('explore-card-band')),
      ),
      findsNWidgets(3),
    );
    expect(find.text('보홀 오션 하이드아웃'), findsOneWidget);
    expect(find.text('필리핀 보홀'), findsWidgets);
    final review = tester.widget<Text>(find.text('★ 4.8 · 후기 23'));
    expect(review.style?.color, AppTheme.gold);
    expect(find.text(l10n.reviewNoReviewsYet), findsWidgets);
    expect(find.text(l10n.exploreCardDiveStar('★★★')), findsOneWidget);
    expect(find.text(l10n.exploreCardPartner), findsOneWidget);
    final renew = find.text(l10n.exploreCardDiveStarRenew);
    expect(renew, findsOneWidget);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(of: renew, matching: find.byType(Opacity)).first,
          )
          .opacity,
      0.45,
    );
    expect(find.textContaining('180,000'), findsNothing);
    expect(find.textContaining('126,000'), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(3));
  });

  testWidgets('홈 기본 카드는 사진 아래 흰 설명을 유지한다', (tester) async {
    await pumpCards(tester, [
      HomeStayCard(
        shop: shop(id: 'home', name: '홈 카드', reviewCount: 4, rating: 4.2),
        onDetails: () {},
      ),
    ]);

    expect(find.byKey(const Key('explore-card-band')), findsNothing);
    expect(find.text('홈 카드'), findsOneWidget);
    expect(find.text('★ 4.2 (후기 4개)'), findsOneWidget);
    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
      ListingCover.aspectRatio,
    );
  });
}
