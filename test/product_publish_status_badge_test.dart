import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/missing_price_badge.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/product_publish_status_badge.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpBadge(
    WidgetTester tester, {
    required ShopProduct product,
    required Widget badge,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: AppConstants.defaultLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: badge),
      ),
    );
    await tester.pump();
  }

  testWidgets('게시중 뱃지 라벨과 key', (tester) async {
    final product = ShopProduct(
      id: 'live-1',
      shopId: 'shop',
      name: 'Live',
      consumerPrice: 100000,
      professionalPrice: 100000,
      active: true,
      publishStatus: ProductPublishStatus.approved,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await pumpBadge(
      tester,
      product: product,
      badge: ProductPublishStatusBadge(product: product),
    );
    expect(find.byKey(const Key('partner-product-status-live-1')), findsOneWidget);
    expect(find.text(l10n.partnerProductBadgeListed), findsOneWidget);
  });

  testWidgets('가격 미입력 뱃지는 0원일 때만', (tester) async {
    final missing = ShopProduct(
      id: 'zero-1',
      shopId: 'shop',
      name: 'Zero',
      consumerPrice: 0,
      professionalPrice: 0,
    );
    final ok = missing.copyWith(consumerPrice: 50000, professionalPrice: 50000);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await pumpBadge(
      tester,
      product: missing,
      badge: MissingPriceBadge(product: missing),
    );
    expect(
      find.byKey(const Key('partner-product-missing-price-zero-1')),
      findsOneWidget,
    );
    expect(find.text(l10n.partnerProductBadgeMissingPrice), findsOneWidget);

    await pumpBadge(
      tester,
      product: ok,
      badge: MissingPriceBadge(product: ok),
    );
    expect(
      find.byKey(const Key('partner-product-missing-price-zero-1')),
      findsNothing,
    );
  });
}
