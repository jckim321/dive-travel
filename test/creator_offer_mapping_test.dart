import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<MemoryDiverRepository> pumpCreator(
    WidgetTester tester, {
    ShopProduct? existing,
    bool admin = false,
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryDiverRepository.forTest(isAdmin: admin);
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
          home: TravelProductRegistrationScreen(
            creatorMode: !admin,
            existing: existing,
            startEditing: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return repo;
  }

  Future<void> fillPlace(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.byKey(const Key('creator-product-shop')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(l10n.productFormCreatorShop).last);
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('product-curated-resort')),
      '없는 리조트',
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
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('workbench-diver-price')));
    await tester.enterText(
      find.byKey(const Key('workbench-diver-price')),
      '180000',
    );
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
  }

  Finder stepFields() {
    return find.descendant(
      of: find.byKey(const Key('creator-wizard-step-4')),
      matching: find.byType(TextField),
    );
  }

  Finder keyed(String fragment) {
    return find.byWidgetPredicate(
      (widget) => widget.key?.toString().contains(fragment) ?? false,
    );
  }

  testWidgets('따로 구매는 individual, 여행에 더하기는 addon, 이름은 그룹이 된다', (
    tester,
  ) async {
    final repo = await pumpCreator(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await fillPlace(tester, l10n);

    await tester.tap(find.byKey(const Key('creator-offer-add')));
    await tester.pump();
    await tester.enterText(stepFields().at(0), '골프');
    await tester.enterText(keyed('creator-offer-price-').first, '50000');
    await tester.tap(keyed('creator-offer-individual-'));
    await tester.pump();
    await tester.ensureVisible(keyed('creator-offer-details-'));
    await tester.tap(keyed('creator-offer-details-'));
    await tester.pump();
    await tester.enterText(stepFields().at(2), '오후 라운드');
    await tester.enterText(stepFields().at(3), '카트');
    await tester.enterText(stepFields().at(4), '캐디');
    await tester.ensureVisible(keyed('creator-offer-nested-add-'));
    await tester.tap(keyed('creator-offer-nested-add-'));
    await tester.pump();
    await tester.enterText(stepFields().at(5), '슈트');
    await tester.enterText(keyed('creator-offer-nested-price-'), '10000');
    await tester.ensureVisible(find.byKey(const Key('creator-offer-add')));
    await tester.tap(find.byKey(const Key('creator-offer-add')));
    await tester.pump();
    await tester.enterText(stepFields().at(7), '스파');
    await tester.enterText(keyed('creator-offer-price-').last, '30000');

    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('partner-product-save')));
    await tester.tap(find.byKey(const Key('partner-product-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final stats = await repo.fetchShopStats();
    final curated = stats.where((shop) => shop.shopId.startsWith('curated-'));
    expect(curated, isNotEmpty);
    final options = curated.single.products.single.options;
    final golf = options.where((option) => option.name == '골프').single;
    final suit = options.where((option) => option.name == '슈트').single;
    final spa = options.where((option) => option.name == '스파').single;
    expect(golf.kind, ProductOptionKind.individual);
    expect(golf.group, 'activity');
    expect(golf.parentOptionId, isEmpty);
    expect(golf.description, contains('오후 라운드'));
    expect(golf.description, contains('포함:\n카트'));
    expect(golf.description, contains('불포함:\n캐디'));
    expect(suit.kind, ProductOptionKind.addon);
    expect(suit.group, 'gear');
    expect(suit.parentOptionId, golf.id);
    expect(spa.kind, ProductOptionKind.addon);
    expect(spa.group, 'activity');
    expect(spa.parentOptionId, isEmpty);
  });

  testWidgets('따로 구매를 여행에 더하기로 바꾸면 하위 옵션이 같은 단계 카드가 된다', (
    tester,
  ) async {
    final repo = await pumpCreator(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await fillPlace(tester, l10n);

    await tester.tap(find.byKey(const Key('creator-offer-add')));
    await tester.pump();
    await tester.enterText(stepFields().at(0), '골프');
    await tester.enterText(keyed('creator-offer-price-'), '50000');
    await tester.tap(keyed('creator-offer-individual-'));
    await tester.pump();
    await tester.tap(keyed('creator-offer-details-'));
    await tester.pump();
    await tester.tap(keyed('creator-offer-nested-add-'));
    await tester.pump();
    await tester.enterText(stepFields().at(5), '슈트');
    await tester.enterText(keyed('creator-offer-nested-price-'), '10000');
    await tester.tap(keyed('creator-offer-addon-'));
    await tester.pump();

    expect(keyed('creator-offer-card-'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('partner-product-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final stats = await repo.fetchShopStats();
    final options = stats
        .where((shop) => shop.shopId.startsWith('curated-'))
        .single
        .products
        .single
        .options;
    final golf = options.where((option) => option.name == '골프').single;
    final suit = options.where((option) => option.name == '슈트').single;
    expect(golf.kind, ProductOptionKind.addon);
    expect(golf.group, 'activity');
    expect(golf.parentOptionId, isEmpty);
    expect(suit.kind, ProductOptionKind.addon);
    expect(suit.group, 'gear');
    expect(suit.parentOptionId, isEmpty);
  });

  testWidgets('표시 없는 설명은 자세히의 설명 칸으로 다시 열린다', (tester) async {
    await pumpCreator(
      tester,
      existing: const ShopProduct(
        id: 'crafted-1',
        shopId: 'curated-1',
        name: '메모',
        consumerPrice: 100000,
        professionalPrice: 100000,
        options: [
          ShopProductOption(
            id: 'memo',
            name: '메모',
            description: '오후만',
            consumerPrice: 20000,
            kind: ProductOptionKind.individual,
          ),
        ],
      ),
    );
    for (var step = 0; step < 3; step++) {
      await tester.tap(find.byKey(const Key('creator-wizard-next')));
      await tester.pump();
    }
    await tester.tap(keyed('creator-offer-details-'));
    await tester.pump();
    expect(stepFields().at(2), findsOneWidget);
    expect(tester.widget<TextField>(stepFields().at(2)).controller?.text, '오후만');
    expect(tester.widget<TextField>(stepFields().at(3)).controller?.text, '');
    expect(keyed('option-group-'), findsNothing);
  });

  testWidgets('빈 필수 항목을 누르면 그 단계로 간다', (tester) async {
    await pumpCreator(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    for (var step = 0; step < 4; step++) {
      await tester.tap(find.byKey(const Key('creator-wizard-next')));
      await tester.pump();
    }
    expect(find.text(l10n.creatorWizardMissing), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('creator-wizard-gap-resort')));
    await tester.tap(find.byKey(const Key('creator-wizard-gap-resort')));
    await tester.pump();
    expect(find.byKey(const Key('creator-wizard-step-1')), findsOneWidget);
  });

  testWidgets('관리자 그룹 선택은 이름만으로 바뀌지 않는다', (tester) async {
    await pumpCreator(
      tester,
      admin: true,
      existing: const ShopProduct(
        id: 'admin-1',
        shopId: 'shop-1',
        name: '관리 상품',
        consumerPrice: 100000,
        professionalPrice: 100000,
        options: [
          ShopProductOption(
            id: 'golf-1',
            name: '골프',
            consumerPrice: 50000,
            group: 'stay',
          ),
        ],
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('option-group-golf-1')));
    expect(find.text('숙박'), findsWidgets);
    expect(find.byKey(const Key('creator-wizard-step-4')), findsNothing);
  });
}
