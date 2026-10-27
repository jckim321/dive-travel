import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpCreator(WidgetTester tester, {ShopProduct? existing}) async {
    tester.view.physicalSize = const Size(900, 1600);
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
            startEditing: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> pickShop(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.byKey(const Key('creator-product-shop')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(l10n.productFormCreatorShop).last);
    await tester.pump();
  }

  testWidgets('1단계는 소개만 보이고 다음으로 일정·가격·빈 단계로 간다', (tester) async {
    await pumpCreator(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    expect(find.text(l10n.creatorWizardProgress(1)), findsOneWidget);
    expect(find.text(l10n.creatorWizardStepIntro), findsOneWidget);
    expect(find.byKey(const Key('creator-wizard-step-1')), findsOneWidget);
    expect(find.byKey(const Key('creator-wizard-blurb')), findsOneWidget);
    expect(find.byKey(const Key('partner-form-nights')), findsNothing);
    expect(find.byKey(const Key('workbench-diver-price')), findsNothing);
    expect(find.byKey(const Key('partner-form-add-option')), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('creator-wizard-prev')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    expect(find.text(l10n.creatorWizardProgress(2)), findsOneWidget);
    expect(find.byKey(const Key('creator-wizard-step-2')), findsOneWidget);
    expect(find.byKey(const Key('partner-form-nights')), findsOneWidget);
    expect(find.byKey(const Key('partner-form-days')), findsOneWidget);
    expect(find.byKey(const Key('product-detail-editor')), findsOneWidget);
    expect(find.text(l10n.productFormIncludes), findsOneWidget);
    expect(find.text(l10n.productFormExcludes), findsOneWidget);
    expect(find.text(l10n.partnerFormCancelPolicy), findsOneWidget);
    expect(find.byKey(const Key('workbench-diver-price')), findsNothing);

    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    expect(find.text(l10n.creatorWizardProgress(3)), findsOneWidget);
    final price = find.byKey(const Key('workbench-diver-price'));
    expect(price, findsOneWidget);
    expect(tester.widget<TextField>(price).keyboardType, TextInputType.number);
    await tester.enterText(price, '180000');
    await tester.pump();
    expect(tester.widget<TextField>(price).controller?.text, '180,000원');
    expect(find.byKey(const Key('partner-form-guest-rates')), findsOneWidget);

    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    expect(find.byKey(const Key('creator-wizard-step-4')), findsOneWidget);
    expect(find.byKey(const Key('partner-form-add-option')), findsNothing);
    expect(find.byKey(const Key('workbench-diver-price')), findsNothing);

    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    expect(find.text(l10n.creatorWizardProgress(5)), findsOneWidget);
    expect(find.byKey(const Key('creator-wizard-step-5')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('creator-wizard-next')))
          .onPressed,
      isNull,
    );
    expect(find.byKey(const Key('partner-product-save')), findsOneWidget);

    await tester.tap(find.byKey(const Key('creator-wizard-prev')));
    await tester.pump();
    expect(find.byKey(const Key('creator-wizard-step-4')), findsOneWidget);
  });

  testWidgets('뒤로가기는 이전 단계로, 1단계에서 입력이 있으면 나가기 확인', (tester) async {
    await pumpCreator(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await pickShop(tester, l10n);
    await tester.enterText(
      find.byKey(const Key('product-curated-resort')),
      '블루홀',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const Key('brief-leave-dialog')), findsNothing);
    expect(find.byKey(const Key('creator-wizard-step-1')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('product-curated-resort')))
          .controller
          ?.text,
      '블루홀',
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const Key('brief-leave-dialog')), findsOneWidget);
    expect(find.byKey(const Key('creator-wizard-step-1')), findsOneWidget);
  });

  testWidgets('반려 배너는 단계를 옮겨도 남는다', (tester) async {
    await pumpCreator(
      tester,
      existing: const ShopProduct(
        id: 'crafted-rejected',
        shopId: 'curated-9',
        name: '블루홀',
        consumerPrice: 100000,
        professionalPrice: 80000,
        publishStatus: ProductPublishStatus.rejected,
        reviewNote: '일정을 더 적어 주세요',
      ),
    );
    expect(
      find.byKey(const Key('partner-reject-reason-banner')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('creator-wizard-next')));
    await tester.pump();
    expect(find.byKey(const Key('creator-wizard-step-2')), findsOneWidget);
    expect(
      find.byKey(const Key('partner-reject-reason-banner')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('partner-product-save')), findsOneWidget);
  });

  testWidgets('관리자 양식은 한 화면이고 마법사 막대가 없다', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = DiverStore(MemoryDiverRepository.forTest(isAdmin: true));
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
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('creator-wizard-progress')), findsNothing);
    expect(find.byKey(const Key('creator-wizard-next')), findsNothing);
    expect(find.byKey(const Key('admin-product-name')), findsOneWidget);
    expect(find.byKey(const Key('workbench-diver-price')), findsOneWidget);
  });
}
