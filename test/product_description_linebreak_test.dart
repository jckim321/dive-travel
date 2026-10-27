import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/explore/presentation/tour_checkout_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _source = '첫째 줄\n둘째 줄';

void main() {
  testWidgets('등록 미리보기에서 엔터 한 번이 줄바꿈이다', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
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
          home: const TravelProductRegistrationScreen(startEditing: true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final composer = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.minLines == 10,
    );
    await tester.ensureVisible(composer);
    await tester.enterText(composer, _source);
    await tester.pump();

    await tester.ensureVisible(find.text('미리보기'));
    await tester.tap(find.text('미리보기'));
    await tester.pump();

    final body = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
    expect(body.softLineBreak, isTrue);
    expect(body.data, _source);
    expect(_plain(tester), '첫째 줄\n둘째 줄');
  });

  testWidgets('고객 상세도 엔터 한 번을 같은 줄바꿈으로 보여 준다', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const shop = DiveShop(
      id: 'hull',
      name: '샵',
      location: '세부',
      country: 'PH',
      continent: 'asia',
      sites: ['샵'],
      productName: '펀다이빙',
      stars: 0,
      rating: 0,
      reviewCount: 0,
      amenities: [],
      consumerPrice: 100000,
      professionalPrice: 80000,
    );
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
          home: TourCheckoutSheet(
            shop: shop,
            quote: const TourPriceQuote(amount: 100000, isProfessional: false),
            product: const ShopProduct(
              id: 'prod-1',
              shopId: 'hull',
              name: '펀다이빙',
              consumerPrice: 100000,
              professionalPrice: 80000,
              schedule: _source,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.scrollUntilVisible(
      find.byType(MarkdownBody),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    final body = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
    expect(body.softLineBreak, isTrue);
    expect(body.data, _source);
    expect(_plain(tester), '첫째 줄\n둘째 줄');
  });
}

String _plain(WidgetTester tester) {
  final texts = tester.widgetList<RichText>(
    find.descendant(
      of: find.byType(MarkdownBody),
      matching: find.byType(RichText),
    ),
  );
  return texts.map((text) => text.text.toPlainText()).join();
}
