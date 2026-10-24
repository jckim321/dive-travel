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
  Future<AppLocalizations> loadKo() {
    return AppLocalizations.delegate.load(const Locale('ko'));
  }

  ShopProduct pendingProduct() {
    return ShopProduct(
      id: 'view-mode-product',
      shopId: AppConstants.defaultPartnerShopId,
      name: '스크롤 테스트 상품',
      consumerPrice: 180000,
      professionalPrice: 126000,
      blurb: '보기 모드 스크롤 확인용',
      detail: '상세\n' * 40,
      publishStatus: ProductPublishStatus.pending,
      active: false,
      openEmptySeats: true,
      capacity: 10,
      bookedSeats: 1,
      departureStart: DateTime(2026, 10, 31),
      flagClosesAt: DateTime(2026, 10, 28),
      sameBoatStatus: SameBoatStatus.pending,
    );
  }

  void ignoreKnownListTileNoise() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('ListTile background color')) {
        return;
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  Future<void> pumpWorkbench(
    WidgetTester tester, {
    bool startEditing = false,
  }) async {
    ignoreKnownListTileNoise();
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
          home: TravelProductRegistrationScreen(
            existing: pendingProduct(),
            startEditing: startEditing,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> goToStep(WidgetTester tester, int step) async {
    await tester.tap(find.byKey(Key('brief-step-$step')));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('보기 모드에서는 스크롤되고 입력은 막힌다', (tester) async {
    await pumpWorkbench(tester);
    final l10n = await loadKo();

    expect(find.byKey(const Key('ops-product-view-hint')), findsOneWidget);
    expect(find.text(l10n.briefViewModeHint), findsOneWidget);
    expect(find.byKey(const Key('brief-edit')), findsOneWidget);

    await reveal(tester, find.byKey(const Key('admin-product-name')));
    await tester.tap(find.byKey(const Key('admin-product-name')));
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.context?.widget,
      isNot(isA<EditableText>()),
      reason: 'view mode must not focus the name field',
    );

    await goToStep(tester, 2);
    await reveal(tester, find.text(l10n.briefSectionSameBoat));
    expect(find.text(l10n.briefSectionSameBoat), findsWidgets);

    await reveal(tester, find.byKey(const Key('same-boat-open-package')));
    final openBefore = tester
        .widget<SwitchListTile>(find.byKey(const Key('same-boat-open-package')))
        .value;
    await tester.tap(find.byKey(const Key('same-boat-open-package')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('same-boat-open-package')),
          )
          .value,
      openBefore,
      reason: 'view mode IgnorePointer must block switch taps',
    );
  });

  testWidgets('startEditing true면 바로 편집 모드', (tester) async {
    await pumpWorkbench(tester, startEditing: true);
    expect(find.byKey(const Key('ops-product-view-hint')), findsNothing);
    expect(find.byKey(const Key('brief-step-next')), findsOneWidget);
    await goToStep(tester, 1);
    expect(find.byKey(const Key('workbench-diver-price')), findsOneWidget);
    await goToStep(tester, 2);
    expect(find.byKey(const Key('admin-product-submit')), findsOneWidget);
  });

  testWidgets('수정 모드에서는 입력이 된다', (tester) async {
    await pumpWorkbench(tester);

    await tester.tap(find.byKey(const Key('brief-edit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ops-product-view-hint')), findsNothing);
    expect(find.byKey(const Key('brief-step-next')), findsOneWidget);

    await reveal(tester, find.byKey(const Key('admin-product-name')));
    await tester.enterText(
      find.byKey(const Key('admin-product-name')),
      '수정된 상품명',
    );
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('admin-product-name')))
          .controller
          ?.text,
      '수정된 상품명',
    );

    await goToStep(tester, 2);
    await reveal(tester, find.byKey(const Key('same-boat-open-package')));
    final openBefore = tester
        .widget<SwitchListTile>(find.byKey(const Key('same-boat-open-package')))
        .value;
    await tester.tap(find.byKey(const Key('same-boat-open-package')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('same-boat-open-package')),
          )
          .value,
      !openBefore,
    );
  });
}
