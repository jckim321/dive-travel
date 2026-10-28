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
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryDiverRepository.forTest();
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
            creatorMode: true,
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

  Future<void> pickDirect(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.byKey(const Key('creator-product-shop')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(l10n.productFormCreatorShop).last);
    await tester.pump();
  }

  Future<void> composeHangul(WidgetTester tester, Finder field) async {
    await tester.showKeyboard(field);
    final stateBefore = tester.state(field);
    final controller = tester.widget<TextField>(field).controller!;
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'ㄱ',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      ),
    );
    await tester.pump();
    expect(tester.state(field), same(stateBefore));
    expect(tester.widget<TextField>(field).controller, same(controller));
    expect(controller.text, 'ㄱ');

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.state(field), same(stateBefore));
    expect(tester.widget<TextField>(field).controller, same(controller));
    expect(controller.text, 'ㄱ');
  }

  testWidgets('샵·리조트 이름이 없으면 2초 뒤에도 조용히 넘어간다', (tester) async {
    final repo = await pumpCreator(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.enterText(find.byKey(const Key('creator-wizard-blurb')), '한 줄');
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.briefKept), findsNothing);
    expect(find.byKey(const Key('creator-wizard-step-1')), findsOneWidget);
    final stats = await repo.fetchShopStats();
    expect(stats.where((shop) => shop.products.isNotEmpty), isEmpty);
  });

  testWidgets('다음은 임시저장하고 성공 알림 없이 다음 단계에 남는다', (tester) async {
    final repo = await pumpCreator(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await pickDirect(tester, l10n);
    await tester.enterText(
      find.byKey(const Key('product-curated-resort')),
      '블루홀',
    );
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.briefKept), findsNothing);
    expect(find.byKey(const Key('creator-wizard-step-2')), findsOneWidget);
    final stats = await repo.fetchShopStats();
    final curated = stats.where((shop) => shop.shopId.startsWith('curated-'));
    expect(curated, isNotEmpty);
    expect(curated.single.products.single.name, '블루홀');
    expect(
      curated.single.products.single.publishStatus,
      ProductPublishStatus.pending,
    );
  });

  testWidgets('카드 이름 ㄱ 조합 중에도 칸과 컨트롤러가 남는다', (tester) async {
    await pumpCreator(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await pickDirect(tester, l10n);
    await tester.enterText(
      find.byKey(const Key('product-curated-resort')),
      '블루홀',
    );
    for (var step = 0; step < 3; step++) {
      await tester.tap(find.byKey(const Key('creator-wizard-next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.byKey(const Key('creator-offer-add')));
    await tester.pump();
    final name = find
        .descendant(
          of: find.byKey(const Key('creator-wizard-step-4')),
          matching: find.byType(TextField),
        )
        .first;
    await composeHangul(tester, name);
    expect(find.text(l10n.briefKept), findsNothing);
    expect(find.byKey(const Key('creator-wizard-step-4')), findsOneWidget);
  });

  testWidgets('대기 상품은 사진이 없으면 임시저장을 조용히 건너뛴다', (tester) async {
    final repo = await pumpCreator(
      tester,
      existing: const ShopProduct(
        id: 'pending-1',
        shopId: 'curated-pending',
        name: '블루홀',
        consumerPrice: 100000,
        professionalPrice: 100000,
        publishStatus: ProductPublishStatus.pending,
      ),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.enterText(
      find.byKey(const Key('product-curated-resort')),
      '블루홀',
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(l10n.briefKept), findsNothing);
    expect(find.text(l10n.briefTempSaveNeedPhoto), findsNothing);
    final stats = await repo.fetchShopStats();
    expect(stats.where((shop) => shop.products.isNotEmpty), isEmpty);
  });
}
