import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/app.dart';
import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/trial_data_cleanup.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  Future<AppLocalizations> loadKo() {
    return AppLocalizations.delegate.load(const Locale('ko'));
  }

  Future<void> openAdmin(WidgetTester tester) async {
    final l10n = await loadKo();
    await tester.tap(find.text(l10n.navProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-profile-settings')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('profile-settings-scroll')),
      const Offset(0, -560),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-admin-mode')));
    await tester.tap(find.byKey(const Key('open-admin-mode')));
    await tester.pumpAndSettle();
    if (find.byKey(const Key('admin-pin-field')).evaluate().isNotEmpty) {
      await tester.enterText(
        find.byKey(const Key('admin-pin-field')),
        AppConstants.adminPin,
      );
      await tester.tap(find.byKey(const Key('admin-pin-submit')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('review tab lists Jeju Orange and opens the audit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    const shopId = 'jeju-orange';
    await repo.saveShopProfile(
      shopId: shopId,
      name: kJejuOrangeShopName,
      location: '제주',
      productName: '펀다이빙',
      consumerPrice: 120000,
      professionalPrice: 90000,
    );
    await repo.saveShopProduct(
      shopId: shopId,
      product: const ShopProduct(
        id: 'jeju-fundive',
        shopId: shopId,
        name: '펀다이빙',
        consumerPrice: 120000,
        professionalPrice: 90000,
        publishStatus: ProductPublishStatus.approved,
      ),
    );
    final reviewed = DateTime.utc(2026, 1, 1);
    await repo.setDiveStarGrade(
      shopId: shopId,
      grade: 1,
      reviewedAt: reviewed,
      expiresAt: reviewed.add(const Duration(days: 365)),
    );

    await tester.pumpWidget(
      DiveTravelApp(firebaseReady: true, repository: repo),
    );
    await tester.pump();
    await tester.pump();
    final l10n = await loadKo();
    await openAdmin(tester);

    await tester.tap(find.byKey(const Key('admin-menu-dive-star')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-sub-dive-star-apps')), findsOneWidget);
    expect(find.byKey(const Key('admin-sub-dive-star-review')), findsOneWidget);
    expect(find.byKey(const Key('admin-sub-dive-star-forms')), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-sub-dive-star-review')));
    await tester.pumpAndSettle();
    expect(find.text(kJejuOrangeShopName), findsOneWidget);
    expect(find.text(l10n.partnerMilestoneOneStar), findsOneWidget);
    expect(find.text(l10n.adminShopMonitor), findsNothing);

    await tester.enterText(
      find.byKey(const Key('admin-dive-star-review-search')),
      '없는샵',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('admin-dive-star-review-empty')),
      findsOneWidget,
    );
    expect(find.text(kJejuOrangeShopName), findsNothing);

    await tester.enterText(
      find.byKey(const Key('admin-dive-star-review-search')),
      '',
    );
    await tester.pumpAndSettle();
    final row = find.byKey(const Key('admin-dive-star-review-$shopId'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text(l10n.adminDiveStarAssessmentTitle), findsOneWidget);
    expect(find.text(kJejuOrangeShopName), findsWidgets);
  });
}
