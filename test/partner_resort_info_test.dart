import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  test('map search opens a Google Maps query for the address', () {
    final uri = googleMapsSearchUri('보홀 팡라오');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters['query'], '보홀 팡라오');
    expect(uri.queryParameters['api'], '1');
  });

  testWidgets('partner resort info keeps the product block and drops the map URL field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 6400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const shopId = 'partner-resort-info';
    const mapUrl = 'https://maps.google.com/maps?q=bohol';
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: shopId,
    );
    await repo.saveShopProfile(
      shopId: shopId,
      name: '보홀 리조트',
      location: '팡라오',
      country: '필리핀',
      productName: '펀다이빙',
      consumerPrice: 120000,
      professionalPrice: 90000,
      intro: '옛 소개',
      address: '알로나 비치',
      mapUrl: mapUrl,
    );
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
          home: const ResortDeskScreen(shopId: shopId, partnerMode: true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('partner-resort-info')), findsOneWidget);
    expect(find.text('기본정보'), findsOneWidget);
    expect(find.text('소개'), findsOneWidget);
    expect(find.text('교통편'), findsOneWidget);
    expect(find.text('편의시설'), findsOneWidget);
    expect(find.text('부대시설'), findsOneWidget);
    expect(find.text('주변 관광'), findsOneWidget);
    expect(find.text('다이빙 환경과 조건'), findsOneWidget);
    expect(find.text('사진'), findsOneWidget);
    expect(find.text('목록 미리보기'), findsOneWidget);
    expect(find.byKey(const Key('partner-resort-map-search')), findsOneWidget);
    expect(find.text('구글·네이버·카카오 지도 링크'), findsNothing);
    expect(find.byKey(const Key('partner-regular-products')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('resort-intro-field')),
      '새 소개',
    );
    await tester.tap(find.byKey(const Key('partner-resort-temp-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final live = store.liveStatsFor(shopId);
    expect(live?.intro, '새 소개');
    expect(live?.mapUrl, mapUrl);
    expect(live?.consumerPrice, 120000);
    expect(live?.name, '보홀 리조트');
  });
}
