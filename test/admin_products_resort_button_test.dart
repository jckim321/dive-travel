import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_products_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('상품관리에는 리조트 글 수정 버튼이 없다', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.saveShopProfile(
      shopId: 'first-reef',
      name: '첫 리프',
      location: '세부',
      productName: '펀',
      consumerPrice: 1,
      professionalPrice: 1,
    );
    await repo.saveShopProfile(
      shopId: 'second-reef',
      name: '둘째 리프',
      location: '보홀',
      productName: '펀',
      consumerPrice: 1,
      professionalPrice: 1,
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await store.refreshShopStats();

    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));
    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminProductsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(store.shopStats, isNotEmpty);
    expect(find.byKey(const Key('admin-product-register')), findsOneWidget);
    expect(find.text(l10n.exploreEditResort), findsNothing);
    expect(find.byType(ResortDeskScreen), findsNothing);
  });
}
