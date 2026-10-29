import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'support/sample_dive_shops.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpForm(
    WidgetTester tester, {
    ShopProduct? existing,
    MemoryDiverRepository? repo,
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = DiverStore(
      repo ?? MemoryDiverRepository.forTest(isAdmin: true),
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
          home: TravelProductRegistrationScreen(
            existing: existing,
            startEditing: existing != null,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  DropdownButtonFormField<String> shopDropdown(WidgetTester tester) {
    return tester.widget<DropdownButtonFormField<String>>(
      find.descendant(
        of: find.byKey(const Key('admin-product-shop')),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
  }

  testWidgets('신규 등록은 샵이 비어 있고 고르지 않으면 저장되지 않는다', (tester) async {
    await pumpForm(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final dropdown = shopDropdown(tester);
    expect(dropdown.initialValue, isNull);
    expect(find.text(l10n.productFormPickShop), findsOneWidget);
    expect(find.text(sampleDiveShops.first.name), findsNothing);
    expect(dropdown.decoration.fillColor, PartnerTheme.bg);
    final hint = tester.widget<Text>(find.text(l10n.productFormPickShop));
    expect(hint.style?.color, PartnerTheme.textDim);

    await tester.ensureVisible(find.byKey(const Key('admin-product-submit')));
    await tester.tap(find.byKey(const Key('admin-product-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.widgetWithText(SnackBar, l10n.productFormPickShop), findsOneWidget);
    expect(find.byKey(const Key('admin-product-shop')), findsOneWidget);
  });

  testWidgets('기존 상품 수정은 저장된 샵을 그대로 보여 준다', (tester) async {
    const shopId = AppConstants.defaultPartnerShopId;
    const shopName = '보홀 테스트 리조트';
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: shopId,
      name: shopName,
      location: '필리핀 보홀',
      country: '필리핀',
      productName: '펀다이빙',
      consumerPrice: 100000,
      professionalPrice: 80000,
    );
    await pumpForm(
      tester,
      repo: repo,
      existing: ShopProduct(
        id: 'keep-shop',
        shopId: shopId,
        name: '기존 상품',
        consumerPrice: 100000,
        professionalPrice: 80000,
        publishStatus: ProductPublishStatus.approved,
      ),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    expect(shopDropdown(tester).initialValue, shopId);
    expect(find.text(shopName), findsOneWidget);
    expect(find.text(l10n.productFormPickShop), findsNothing);
  });

  testWidgets('직접선택 항목은 기획스페셜로 보인다', (tester) async {
    await pumpForm(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('admin-product-shop')),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.productFormDirectSelect), findsOneWidget);
    expect(
      DefaultTextStyle.of(
        tester.element(find.text(l10n.productFormDirectSelect).last),
      ).style.color,
      PartnerTheme.text,
    );
    expect(l10n.productFormDirectSelect, '기획스페셜 (앱에 없는 리조트)');
    expect(find.text('직접선택'), findsNothing);
    await tester.tap(find.text(l10n.productFormDirectSelect).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    void expectDarkField(Key key) {
      final field = tester.widget<TextField>(find.byKey(key));
      expect(field.style?.color, PartnerTheme.text);
      expect(field.decoration?.fillColor, PartnerTheme.bg);
    }

    expectDarkField(const Key('product-curated-resort'));
    expectDarkField(const Key('product-curated-country'));
    expectDarkField(const Key('product-curated-region'));
  });
}
