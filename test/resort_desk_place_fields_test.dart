import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('관리자 다크 테마에서도 샵 이름·국가·지역을 고치고 바로 반영한다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const shopId = 'reef-desk';
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: shopId,
      name: '푸른 리프',
      location: '보홀',
      country: '필리핀',
      continent: TravelRegionId.asia,
      productName: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
      intro: '옛 소개',
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(store: store, child: const SizedBox()),
    );
    await store.refreshShopStats();
    await tester.pump();

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AdminConsoleTheme.dark,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ResortDeskScreen(shopId: shopId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final name = tester.widget<TextField>(
      find.byKey(const Key('resort-name-field')),
    );
    final region = tester.widget<TextField>(
      find.byKey(const Key('resort-region-field')),
    );
    final country = tester.widget<TextField>(
      find.byKey(const Key('resort-country-field')),
    );
    expect(name.readOnly, isFalse);
    expect(region.readOnly, isFalse);
    expect(country.readOnly, isFalse);
    expect(name.style?.color, AppTheme.navy);
    expect(region.style?.color, AppTheme.navy);
    expect(country.style?.color, AppTheme.navy);
    expect(name.decoration?.fillColor, Colors.white);
    expect(name.controller?.text, '푸른 리프');
    expect(country.controller?.text, '필리핀');
    expect(region.controller?.text, '보홀');

    await tester.enterText(find.byKey(const Key('resort-name-field')), '새 리프');
    await tester.enterText(
      find.byKey(const Key('resort-country-field')),
      '팔라우',
    );
    await tester.enterText(
      find.byKey(const Key('resort-region-field')),
      '코로르',
    );
    await tester.enterText(
      find.byKey(const Key('resort-intro-field')),
      '새 소개',
    );
    await tester.tap(find.byKey(const Key('resort-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final live = store.liveStatsFor(shopId);
    expect(live?.name, '새 리프');
    expect(live?.country, '팔라우');
    expect(live?.location, '코로르');
    expect(live?.continent, TravelRegionId.pacific);
    expect(live?.intro, '새 소개');
    expect(
      tester.widget<TextField>(find.byKey(const Key('resort-name-field')))
          .controller
          ?.text,
      '새 리프',
    );
  });

  testWidgets('샵 목록이 늦게 도착해도 빈 이름·국가·지역을 저장된 값으로 채운다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const shopId = 'late-reef';
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(store: store, child: const SizedBox()),
    );
    await store.refreshShopStats();
    await tester.pump();

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AdminConsoleTheme.dark,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ResortDeskScreen(shopId: shopId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    String textOf(Key key) {
      return tester.widget<TextField>(find.byKey(key)).controller?.text ?? '';
    }

    expect(textOf(const Key('resort-name-field')), isEmpty);
    expect(textOf(const Key('resort-country-field')), isEmpty);
    expect(textOf(const Key('resort-region-field')), isEmpty);

    await tester.enterText(
      find.byKey(const Key('resort-name-field')),
      '직접 입력',
    );

    await repo.saveShopProfile(
      shopId: shopId,
      name: '푸른 리프',
      location: '보홀',
      country: '필리핀',
      continent: TravelRegionId.asia,
      productName: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
      intro: '옛 소개',
    );
    await store.refreshShopStats();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(textOf(const Key('resort-name-field')), '직접 입력');
    expect(textOf(const Key('resort-country-field')), '필리핀');
    expect(textOf(const Key('resort-region-field')), '보홀');
  });

  testWidgets('아직 입력하지 않은 이름도 저장된 샵 이름으로 채워진다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const shopId = 'late-name';
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(store: store, child: const SizedBox()),
    );
    await store.refreshShopStats();
    await tester.pump();

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AdminConsoleTheme.dark,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ResortDeskScreen(shopId: shopId),
        ),
      ),
    );
    await tester.pump();

    await repo.saveShopProfile(
      shopId: shopId,
      name: '푸른 리프',
      location: '보홀',
      country: '필리핀',
      continent: TravelRegionId.asia,
      productName: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
      intro: '옛 소개',
    );
    await store.refreshShopStats();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    String textOf(Key key) {
      return tester.widget<TextField>(find.byKey(key)).controller?.text ?? '';
    }

    expect(textOf(const Key('resort-name-field')), '푸른 리프');
    expect(textOf(const Key('resort-country-field')), '필리핀');
    expect(textOf(const Key('resort-region-field')), '보홀');
  });
}
