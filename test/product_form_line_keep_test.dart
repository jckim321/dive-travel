import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Finder byPrefix(String prefix) {
    return find.byWidgetPredicate((widget) {
      final key = widget.key;
      return widget is TextField &&
          key is ValueKey<String> &&
          key.value.startsWith(prefix);
    });
  }

  testWidgets('옵션·개별 상품 입력은 다른 칸과 줄 추가 뒤에도 남는다', (tester) async {
    tester.view.physicalSize = const Size(900, 4200);
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

    final optionName = byPrefix('addon-name-');
    final optionPrice = byPrefix('addon-price-');
    final optionNameState = tester.state(optionName);
    final optionPriceState = tester.state(optionPrice);
    final optionNameController =
        tester.widget<TextField>(optionName).controller!;
    final optionPriceController =
        tester.widget<TextField>(optionPrice).controller!;

    await tester.enterText(optionName, '나이트다이브');
    await tester.enterText(optionPrice, '30000');
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('partner-product-name')),
      '다른칸',
    );
    await tester.pump();

    expect(optionNameController.text, '나이트다이브');
    expect(optionPriceController.text, '30000');
    expect(tester.widget<TextField>(optionName).controller, same(optionNameController));
    expect(
      tester.widget<TextField>(optionPrice).controller,
      same(optionPriceController),
    );
    expect(tester.state(optionName), same(optionNameState));
    expect(tester.state(optionPrice), same(optionPriceState));

    final addOption = find.byKey(const Key('partner-form-add-option'));
    await tester.ensureVisible(addOption);
    await tester.tap(addOption);
    await tester.pump();

    expect(optionNameController.text, '나이트다이브');
    expect(optionPriceController.text, '30000');
    expect(tester.state(optionName.first), same(optionNameState));
    expect(tester.state(optionPrice.first), same(optionPriceState));
    expect(byPrefix('addon-name-'), findsNWidgets(2));

    final addIndividual = find.byKey(const Key('partner-form-add-individual'));
    await tester.ensureVisible(addIndividual);
    await tester.tap(addIndividual);
    await tester.pump();

    final individualName = byPrefix('individual-name-');
    final individualPrice = byPrefix('partner-form-individual-price-');
    final individualNameState = tester.state(individualName);
    final individualPriceState = tester.state(individualPrice);
    await tester.enterText(individualName, '펀다이브');
    await tester.enterText(individualPrice, '180000');
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('partner-product-name')),
      '다른칸다시',
    );
    await tester.pump();

    expect(tester.widget<TextField>(individualName).controller!.text, '펀다이브');
    expect(tester.widget<TextField>(individualPrice).controller!.text, '180000');
    expect(tester.state(individualName), same(individualNameState));
    expect(tester.state(individualPrice), same(individualPriceState));
    expect(optionNameController.text, '나이트다이브');

    await tester.ensureVisible(addIndividual);
    await tester.tap(addIndividual);
    await tester.pump();

    expect(tester.state(individualName.first), same(individualNameState));
    expect(tester.state(individualPrice.first), same(individualPriceState));
    expect(tester.widget<TextField>(individualName.first).controller!.text, '펀다이브');
    expect(
      tester.widget<TextField>(individualPrice.first).controller!.text,
      '180000',
    );
    expect(byPrefix('individual-name-'), findsNWidgets(2));
  });
}
