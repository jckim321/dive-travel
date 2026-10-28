import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_country_field.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('글자를 치면 별칭이 걸러지고 고르면 권역·해역이 붙는다', (tester) async {
    final controller = TextEditingController();
    TravelCountry? picked;
    var custom = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: AppConstants.defaultLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TravelCountryField(
            controller: controller,
            fieldKey: const Key('product-curated-country'),
            decoration: const InputDecoration(labelText: '국가'),
            picked: picked,
            onPicked: (country) => picked = country,
            onCustom: () {
              custom += 1;
              picked = null;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('product-curated-country')),
      '트럭',
    );
    await tester.pump();
    expect(find.byKey(const Key('product-country-option-chuuk')), findsOneWidget);
    expect(find.text('트럭'), findsWidgets);
    expect(find.byKey(const Key('product-country-option-usa')), findsNothing);

    await tester.tap(find.byKey(const Key('product-country-option-chuuk')));
    await tester.pump();
    expect(controller.text, '추크');
    expect(picked?.id, 'chuuk');
    expect(picked?.regionId, TravelRegionId.pacific);
    expect(picked?.sea, isNull);
    expect(custom, 0);

    await tester.enterText(
      find.byKey(const Key('product-curated-country')),
      '없는나라',
    );
    await tester.pump();
    expect(find.byKey(const Key('product-country-option-chuuk')), findsNothing);
    await tester.tap(find.byKey(const Key('product-country-other')));
    await tester.pump();
    expect(controller.text, '없는나라');
    expect(custom, 1);
    expect(picked, isNull);
  });

  testWidgets('저장된 나라 글자는 다시 고르기 전까지 그대로다', (tester) async {
    final controller = TextEditingController(text: '하와이');
    var picks = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: AppConstants.defaultLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TravelCountryField(
            controller: controller,
            fieldKey: const Key('product-curated-country'),
            decoration: const InputDecoration(labelText: '국가'),
            onPicked: (_) => picks += 1,
            onCustom: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(controller.text, '하와이');
    expect(picks, 0);
    expect(find.byKey(const Key('product-country-assignment')), findsNothing);
    expect(find.byKey(const Key('product-country-menu')), findsNothing);
  });

  testWidgets('저장된 직접 기획은 나라·지역을 유지하고 다시 고르면 권역이 바뀐다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProfile(
      shopId: 'curated-9',
      name: '옛 리조트',
      location: '사이판',
      productName: '옛 리조트',
      consumerPrice: 100000,
      professionalPrice: 100000,
      country: '하와이',
      continent: 'oceania',
      curated: true,
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    Future<void> pumpForm() {
      return tester.pumpWidget(
        DiverStoreScope(
          store: store,
          child: MaterialApp(
            theme: AppTheme.light,
            locale: AppConstants.defaultLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TravelProductRegistrationScreen(
              creatorMode: true,
              startEditing: true,
              existing: ShopProduct(
                id: 'crafted-9',
                shopId: 'curated-9',
                name: '옛 리조트',
                consumerPrice: 100000,
                professionalPrice: 100000,
                continent: 'oceania',
              ),
            ),
          ),
        ),
      );
    }

    await pumpForm();
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.textContaining('하와이').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.textContaining('하와이'), findsWidgets);
    expect(find.textContaining('사이판'), findsWidgets);
    expect(find.byKey(const Key('product-country-assignment')), findsNothing);

    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('partner-product-save')));
    await tester.tap(find.byKey(const Key('partner-product-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final kept = (await repo.fetchShopStats())
        .where((shop) => shop.shopId == 'curated-9')
        .single;
    expect(kept.country, '하와이');
    expect(kept.continent, 'oceania');
    expect(kept.location, '사이판');
    expect(kept.products.single.continent, 'oceania');
  });

  testWidgets('목록에서 다시 고르면 나라·권역만 바뀌고 지역 글씨는 자유 입력이다', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProfile(
      shopId: 'curated-9',
      name: '옛 리조트',
      location: '사이판',
      productName: '옛 리조트',
      consumerPrice: 100000,
      professionalPrice: 100000,
      country: '하와이',
      continent: 'oceania',
      curated: true,
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TravelProductRegistrationScreen(
            creatorMode: true,
            startEditing: true,
            existing: ShopProduct(
              id: 'crafted-9',
              shopId: 'curated-9',
              name: '옛 리조트',
              consumerPrice: 100000,
              professionalPrice: 100000,
              continent: 'oceania',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.textContaining('하와이').evaluate().isNotEmpty) {
        break;
      }
    }
    if (find.byKey(const Key('creator-resort-summary')).evaluate().isNotEmpty) {
      await tester.ensureVisible(find.byKey(const Key('creator-resort-summary')));
      await tester.tap(find.byKey(const Key('creator-resort-summary')));
      await tester.pump();
    }
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('product-curated-country')))
          .controller
          ?.text,
      '하와이',
    );
    expect(find.byKey(const Key('product-country-assignment')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('product-curated-country')),
      '트럭',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('product-country-option-chuuk')),
    );
    await tester.tap(find.byKey(const Key('product-country-option-chuuk')));
    await tester.pump();
    expect(find.byKey(const Key('product-country-assignment')), findsOneWidget);
    expect(find.textContaining(l10n.exploreRegionPacific), findsOneWidget);
    expect(find.textContaining(l10n.productFormCountryNoSea), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('product-curated-region')),
      '웨노',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('partner-product-save')));
    await tester.tap(find.byKey(const Key('partner-product-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final picked = (await repo.fetchShopStats())
        .where((shop) => shop.shopId == 'curated-9')
        .single;
    expect(picked.country, '추크');
    expect(picked.continent, TravelRegionId.pacific);
    expect(picked.location, '웨노');
    expect(picked.products.single.continent, TravelRegionId.pacific);
  });

  testWidgets('파트너 등록도 같은 나라 검색이고 지역 칸은 없다', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = DiverStore(
      MemoryDiverRepository.forTest(
        isBusiness: true,
        ownedShopId: AppConstants.defaultPartnerShopId,
      ),
    );
    addTearDown(store.dispose);
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TravelProductRegistrationScreen(
            lockedShopId: AppConstants.defaultPartnerShopId,
            partnerMode: true,
            startEditing: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('product-curated-region')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('product-curated-country')))
          .controller
          ?.text,
      '필리핀',
    );
    expect(find.byKey(const Key('product-country-assignment')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('product-curated-country')),
      '몰디',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('product-country-option-maldives')));
    await tester.pump();
    expect(find.textContaining('인도양'), findsOneWidget);
  });
}
