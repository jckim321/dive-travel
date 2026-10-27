import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpCreator(
    WidgetTester tester, {
    ShopProduct? existing,
  }) async {
    tester.view.physicalSize = const Size(900, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          home: TravelProductRegistrationScreen(
            creatorMode: true,
            existing: existing,
            startEditing: existing != null,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('새 여행 짜기 샵은 직접 기획 한 항목이고 고르면 접힌다', (tester) async {
    await pumpCreator(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(find.byKey(const Key('admin-product-name')), findsNothing);
    expect(find.text(l10n.productFormDirectSelect), findsNothing);
    expect(find.text(DiveShopCatalog.shops.first.name), findsNothing);

    await tester.tap(find.byKey(const Key('creator-product-shop')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.productFormCreatorShop), findsOneWidget);
    expect(find.text(l10n.productFormDirectSelect), findsNothing);
    expect(find.text(DiveShopCatalog.shops.first.name), findsNothing);

    await tester.tap(find.text(l10n.productFormCreatorShop));
    await tester.pump();
    expect(find.byKey(const Key('creator-product-shop')), findsNothing);
    expect(find.byKey(const Key('creator-shop-picked')), findsOneWidget);
    expect(find.byKey(const Key('creator-resort-fields')), findsOneWidget);
    expect(find.byKey(const Key('admin-product-name')), findsNothing);
  });

  testWidgets('리조트 이름·국가·지역이 채워지면 한 줄로 접히고 탭하면 펼쳐진다', (
    tester,
  ) async {
    await pumpCreator(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.tap(find.byKey(const Key('creator-product-shop')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(l10n.productFormCreatorShop));
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('product-curated-resort')),
      '블루홀',
    );
    await tester.enterText(
      find.byKey(const Key('product-curated-country')),
      '필리핀',
    );
    await tester.enterText(
      find.byKey(const Key('product-curated-region')),
      '보홀',
    );
    await tester.pump();

    expect(find.byKey(const Key('creator-resort-fields')), findsNothing);
    expect(find.text('블루홀 · 필리핀 · 보홀'), findsOneWidget);

    await tester.tap(find.byKey(const Key('creator-resort-summary')));
    await tester.pump();
    expect(find.byKey(const Key('creator-resort-fields')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('product-curated-resort')))
          .controller
          ?.text,
      '블루홀',
    );
  });

  testWidgets('이미 만든 직접 기획은 샵이 접혀 있고 상품명이 리조트 이름이다', (tester) async {
    await pumpCreator(
      tester,
      existing: const ShopProduct(
        id: 'crafted-1',
        shopId: 'curated-1',
        name: '블루홀',
        consumerPrice: 100000,
        professionalPrice: 80000,
      ),
    );
    expect(find.byKey(const Key('creator-product-shop')), findsNothing);
    expect(find.byKey(const Key('creator-shop-picked')), findsOneWidget);
    expect(find.byKey(const Key('admin-product-name')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('product-curated-resort')))
          .controller
          ?.text,
      '블루홀',
    );
  });
}
