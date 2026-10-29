import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_shops_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_weather_screen.dart';
import 'package:dive_travel_app/features/reviews/presentation/operation_review_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';
import 'support/sample_dive_shops.dart';

Widget _app(DiverStore store, Widget home) {
  return DiverStoreScope(
    store: store,
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AdminConsoleTheme.dark,
      home: home,
    ),
  );
}

void main() {
  testWidgets('공개 상품이 없으면 관리자 샵 목록은 빈 안내만 보인다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = DiverStore(MemoryDiverRepository.forTest(isAdmin: true));
    addTearDown(store.dispose);
    await tester.pumpWidget(_app(store, const AdminShopsScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('admin-shops-empty')), findsOneWidget);
    expect(find.text(sampleDiveShops.first.name), findsNothing);
  });

  testWidgets('날씨 샵 선택은 DB 샵만 보여 준다', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: 'reef-live',
      name: '리프 라이브',
      location: '팔라우',
      country: '팔라우',
      productName: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await tester.pumpWidget(_app(store, const AdminWeatherScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('weather-shop')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('리프 라이브'), findsWidgets);
    expect(find.text('다합 블루홀 다이브 센터'), findsNothing);
  });

  testWidgets('운영 후기 샵 선택은 DB 샵만 보여 준다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProfile(
      shopId: 'reef-live',
      name: '리프 라이브',
      location: '팔라우',
      country: '팔라우',
      productName: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await tester.pumpWidget(_app(store, const OperationReviewScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('review-shop')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('리프 라이브'), findsWidgets);
    expect(find.text('다합 블루홀 다이브 센터'), findsNothing);
  });
}
