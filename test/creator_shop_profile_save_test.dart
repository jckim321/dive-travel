import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('creatorMode 기획스페셜 저장은 샵 프로필 수정을 허용한다', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest();
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: AppConstants.defaultLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TravelProductRegistrationScreen(creatorMode: true),
        ),
      ),
    );
    await tester.pump();
    expect(store.uid, 'test-user');

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('admin-product-shop')),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(l10n.productFormDirectSelect).last);
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('admin-product-name')),
      '골드 기획 여행',
    );
    await tester.ensureVisible(find.byKey(const Key('product-curated-resort')));
    await tester.enterText(
      find.byKey(const Key('product-curated-resort')),
      '없는 리조트',
    );
    await tester.ensureVisible(find.byKey(const Key('workbench-diver-price')));
    await tester.enterText(
      find.byKey(const Key('workbench-diver-price')),
      '180000',
    );
    await tester.ensureVisible(find.byKey(const Key('partner-product-save')));
    await tester.tap(find.byKey(const Key('partner-product-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.textContaining('Not allowed to edit this shop profile'),
      findsNothing,
    );
    final stats = await repo.fetchShopStats();
    final curated = stats.where((shop) => shop.shopId.startsWith('curated-'));
    expect(curated, isNotEmpty);
    expect(curated.single.name, '없는 리조트');
    expect(curated.single.curated, isTrue);
  });
}
