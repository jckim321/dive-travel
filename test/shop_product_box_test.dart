import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/features/admin/presentation/shop_product_box.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpBox(WidgetTester tester, {bool showDate = false}) {
    return tester.pumpWidget(
      MaterialApp(
        locale: AppConstants.defaultLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShopProductBox(
            showDate: showDate,
            priceTitle: '가격·사진',
            optionsTitle: '옵션',
            includesTitle: '포함·불포함',
            priceAndPhotos: const Text('가격'),
            options: const Text('옵션줄'),
            includes: const Text('포함'),
            betweenOptionsAndIncludes: const Text('개별'),
          ),
        ),
      ),
    );
  }

  testWidgets('date field stays hidden unless asked', (tester) async {
    await pumpBox(tester);
    expect(find.byKey(const Key('shop-product-box-date')), findsNothing);
    expect(find.byKey(const Key('partner-form-section-price')), findsOneWidget);
    expect(find.byKey(const Key('partner-form-section-options')), findsOneWidget);
    expect(find.byKey(const Key('partner-form-section-includes')), findsOneWidget);
    expect(find.text('개별'), findsOneWidget);

    final price = tester.getTopLeft(find.byKey(const Key('partner-form-section-price'))).dy;
    final options = tester.getTopLeft(find.byKey(const Key('partner-form-section-options'))).dy;
    final includes = tester.getTopLeft(find.byKey(const Key('partner-form-section-includes'))).dy;
    expect(price, lessThan(options));
    expect(options, lessThan(includes));
  });

  testWidgets('date field shows when showDate is on', (tester) async {
    await pumpBox(tester, showDate: true);
    expect(find.byKey(const Key('shop-product-box-date')), findsOneWidget);
    expect(find.text('출발일'), findsWidgets);
    final date = tester.getTopLeft(find.byKey(const Key('shop-product-box-date'))).dy;
    final price = tester.getTopLeft(find.byKey(const Key('partner-form-section-price'))).dy;
    expect(date, lessThan(price));
  });
}
