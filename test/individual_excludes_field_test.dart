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
  testWidgets('개별 상품 불포함은 포함 아래에 있고 저장 후 다시 불러온다', (tester) async {
    tester.view.physicalSize = const Size(900, 4200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: AppConstants.defaultPartnerShopId,
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);

    Future<void> pumpForm(ShopProduct? existing) async {
      await tester.pumpWidget(
        DiverStoreScope(
          store: store,
          child: MaterialApp(
            theme: AppTheme.light,
            locale: AppConstants.defaultLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TravelProductRegistrationScreen(
              lockedShopId: AppConstants.defaultPartnerShopId,
              partnerMode: true,
              existing: existing,
              startEditing: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    await pumpForm(null);
    final add = find.byKey(const Key('partner-form-add-individual'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pump();

    final includes = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('partner-form-individual-includes-');
    });
    final excludes = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('partner-form-individual-excludes-');
    });
    await tester.ensureVisible(excludes);
    expect(
      tester.widget<TextField>(includes).decoration?.labelText,
      l10n.productFormIncludes,
    );
    expect(
      tester.widget<TextField>(excludes).decoration?.labelText,
      l10n.productFormExcludes,
    );
    expect(tester.getTopLeft(includes).dy, lessThan(tester.getTopLeft(excludes).dy));
    expect(tester.widget<TextField>(includes).minLines, 2);
    expect(tester.widget<TextField>(excludes).minLines, 2);
    expect(tester.widget<TextField>(includes).maxLines, 3);
    expect(tester.widget<TextField>(excludes).maxLines, 3);

    await tester.enterText(
      find.byKey(const Key('partner-product-name')),
      '개별 불포함',
    );
    await tester.enterText(
      find.byKey(const Key('workbench-diver-price')),
      '120000',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.bookingEntryIndividualName),
      '펀다이브',
    );
    final prices = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == l10n.partnerFormBasePrice,
    );
    await tester.enterText(prices.last, '50000');
    await tester.enterText(includes, '보트');
    await tester.enterText(excludes, '장비');
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('partner-product-save')));
    await tester.tap(find.byKey(const Key('partner-product-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final stats = await repo.fetchShopStats();
    final shop = stats.singleWhere(
      (item) => item.shopId == AppConstants.defaultPartnerShopId,
    );
    final product = shop.products.singleWhere((item) => item.name == '개별 불포함');
    final individual = product.options.singleWhere(
      (option) => option.kind == ProductOptionKind.individual,
    );
    expect(individual.description, contains('포함:\n보트'));
    expect(individual.description, contains('불포함:\n장비'));

    await pumpForm(product);
    expect(
      tester
          .widget<TextField>(
            find.byWidgetPredicate((widget) {
              final key = widget.key;
              return key is ValueKey<String> &&
                  key.value.startsWith('partner-form-individual-excludes-');
            }),
          )
          .controller
          ?.text,
      '장비',
    );
    expect(
      tester
          .widget<TextField>(
            find.byWidgetPredicate((widget) {
              final key = widget.key;
              return key is ValueKey<String> &&
                  key.value.startsWith('partner-form-individual-includes-');
            }),
          )
          .controller
          ?.text,
      '보트',
    );
  });
}
