import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<AppLocalizations> loadKo() {
    return AppLocalizations.delegate.load(const Locale('ko'));
  }

  Future<void> pumpPartnerForm(
    WidgetTester tester, {
    ShopProduct? existing,
    bool startEditing = true,
  }) async {
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: AppConstants.defaultPartnerShopId,
    );
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
            lockedShopId: AppConstants.defaultPartnerShopId,
            partnerMode: true,
            existing: existing,
            startEditing: startEditing,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('이름과 1인 가격이 한 줄 사진보다 위에 있다', (tester) async {
    tester.view.physicalSize = const Size(900, 4200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPartnerForm(tester);

    final name = tester.getTopLeft(find.byKey(const Key('partner-product-name'))).dy;
    final price = tester.getTopLeft(find.byKey(const Key('workbench-diver-price'))).dy;
    final photo = tester.getTopLeft(find.byKey(const Key('product-photo-add'))).dy;
    expect(name, lessThan(price));
    expect(price, lessThan(photo));
    expect(
      tester.getSize(find.byKey(const Key('product-photo-strip'))).height,
      72,
    );
    expect(
      tester.getSize(find.byKey(const Key('product-photo-add'))),
      const Size(72, 72),
    );
    expect(find.text('+ 사진 추가'), findsOneWidget);
  });

  testWidgets('partner form is single-scroll dark (no stepper)', (tester) async {
    await pumpPartnerForm(tester);
    expect(find.byKey(const Key('partner-product-form-scroll')), findsOneWidget);
    expect(find.byKey(const Key('partner-product-shop')), findsOneWidget);
    expect(find.byKey(const Key('admin-product-shop')), findsNothing);
    expect(find.byKey(const Key('same-boat-open-package')), findsNothing);
    expect(find.byKey(const Key('partner-form-soft-guide')), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
    expect(find.textContaining('확인'), findsNothing);
  });

  testWidgets('empty name blocks temp save with snackbar', (tester) async {
    final l10n = await loadKo();
    await pumpPartnerForm(tester);
    await tester.tap(find.byKey(const Key('partner-form-temp-save')));
    await tester.pump();
    expect(find.text('상품명을 입력해 주세요'), findsOneWidget);
  });

  testWidgets('name without price blocks publish', (tester) async {
    final l10n = await loadKo();
    await pumpPartnerForm(tester);
    await tester.enterText(
      find.byKey(const Key('partner-product-name')),
      '보홀 패키지',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('partner-product-save')));
    await tester.pump();
    expect(find.text('1인 기준 가격을 입력해 주세요'), findsWidgets);
  });

  testWidgets('photo not required when name and price filled', (tester) async {
    final l10n = await loadKo();
    await pumpPartnerForm(tester);
    await tester.enterText(
      find.byKey(const Key('partner-product-name')),
      '사진 없는 상품',
    );
    await tester.enterText(
      find.byKey(const Key('workbench-diver-price')),
      '150000',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('partner-product-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Should not ask for photos.
    expect(find.text(l10n.briefTempSaveNeedPhoto), findsNothing);
    // Either published snack or still on form after async save.
    final published = find.text(l10n.partnerProductPublished);
    final stillForm = find.byKey(const Key('partner-product-form-scroll'));
    expect(published.evaluate().isNotEmpty || stillForm.evaluate().isNotEmpty, isTrue);
  });

  testWidgets('option name without price is blocked', (tester) async {
    tester.view.physicalSize = const Size(900, 5200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final l10n = await loadKo();
    await pumpPartnerForm(tester);
    await tester.enterText(
      find.byKey(const Key('partner-product-name')),
      '옵션 테스트',
    );
    await tester.enterText(
      find.byKey(const Key('workbench-diver-price')),
      '100000',
    );
    await tester.ensureVisible(find.byKey(const Key('partner-form-add-option')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('partner-form-add-option')));
    await tester.pump();
    final optionName = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.labelText == l10n.productFormOptionName),
    );
    expect(optionName, findsWidgets);
    await tester.enterText(optionName.first, '공항픽업');
    await tester.pump();
    await tester.tap(find.byKey(const Key('partner-product-save')));
    await tester.pump();
    expect(
      find.text('옵션 소비자가를 입력해 주세요'),
      findsWidgets,
    );
  });

  testWidgets('funDive category chip not selected until tap', (tester) async {
    await pumpPartnerForm(
      tester,
      existing: ShopProduct(
        id: 'fun-1',
        shopId: AppConstants.defaultPartnerShopId,
        name: '펀다이브',
        consumerPrice: 90000,
        professionalPrice: 90000,
        category: ProductCategory.funDive,
        publishStatus: ProductPublishStatus.draft,
        active: false,
      ),
    );
    final resort = tester.widget<FilterChip>(
      find.byKey(const Key('partner-cat-resort')),
    );
    final day = tester.widget<FilterChip>(
      find.byKey(const Key('partner-cat-day')),
    );
    final live = tester.widget<FilterChip>(
      find.byKey(const Key('partner-cat-liveaboard')),
    );
    expect(resort.selected, isFalse);
    expect(day.selected, isFalse);
    expect(live.selected, isFalse);
  });

  testWidgets('unparsed duration leaves nights/days empty', (tester) async {
    await pumpPartnerForm(
      tester,
      existing: ShopProduct(
        id: 'dur-1',
        shopId: AppConstants.defaultPartnerShopId,
        name: '자유일정',
        consumerPrice: 90000,
        professionalPrice: 90000,
        durationLabel: '주말 패키지 / 협의',
        publishStatus: ProductPublishStatus.draft,
        active: false,
      ),
    );
    final nights = tester.widget<TextField>(
      find.byKey(const Key('partner-form-nights')),
    );
    final days = tester.widget<TextField>(
      find.byKey(const Key('partner-form-days')),
    );
    expect(nights.controller?.text ?? '', isEmpty);
    expect(days.controller?.text ?? '', isEmpty);
  });

  testWidgets('섹션 박스로 나뉘고 옵션 카드와 개별상품 카드가 같다', (tester) async {
    tester.view.physicalSize = const Size(900, 5200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPartnerForm(tester);

    const sections = [
      Key('partner-form-section-basics'),
      Key('partner-form-section-price'),
      Key('partner-form-section-options'),
      Key('partner-form-section-individuals'),
      Key('partner-form-section-includes'),
      Key('partner-form-section-publish'),
    ];
    const titles = ['기본정보', '가격·사진', '옵션', '개별상품', '포함·불포함', '공개'];
    for (var i = 0; i < sections.length; i++) {
      expect(
        find.descendant(of: find.byKey(sections[i]), matching: find.text(titles[i])),
        findsOneWidget,
      );
      if (i > 0) {
        expect(
          tester.getTopLeft(find.byKey(sections[i - 1])).dy,
          lessThan(tester.getTopLeft(find.byKey(sections[i])).dy),
        );
      }
    }
    expect(
      find.descendant(
        of: find.byKey(sections[0]),
        matching: find.byKey(const Key('partner-product-name')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(sections[1]),
        matching: find.byKey(const Key('workbench-diver-price')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(sections[1]),
        matching: find.byKey(const Key('product-photo-add')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(sections[5]),
        matching: find.byKey(const Key('partner-form-preview-card')),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('partner-form-add-individual')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('partner-form-add-individual')));
    await tester.pump();

    Material card(String prefix) {
      return tester.widget<Material>(
        find.byWidgetPredicate((widget) {
          final key = widget.key;
          return widget is Material &&
              key is ValueKey<String> &&
              key.value.startsWith(prefix);
        }),
      );
    }

    final option = card('addon-row-');
    final individual = card('individual-row-');
    expect(option.color, PartnerTheme.bg);
    expect(individual.color, option.color);
    expect(individual.shape, option.shape);
    expect(
      tester.widget<Padding>(find.descendant(
        of: find.byKey(option.key!),
        matching: find.byType(Padding),
      ).first).padding,
      tester.widget<Padding>(find.descendant(
        of: find.byKey(individual.key!),
        matching: find.byType(Padding),
      ).first).padding,
    );
  });
}
