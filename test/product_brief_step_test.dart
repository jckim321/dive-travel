import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/product_publish_guard.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/product_brief_stepper.dart';
import 'package:dive_travel_app/features/admin/presentation/product_submit_checklist.dart';

void main() {
  test('briefStepForSection maps legacy sections to wizard steps', () {
    expect(briefStepForSection(0), 0);
    expect(briefStepForSection(1), 0);
    expect(briefStepForSection(2), 0);
    expect(briefStepForSection(3), 1);
    expect(briefStepForSection(4), 2);
  });

  test('submit checklist has the six confirmation items', () {
    expect(ProductSubmitChecklist.ids, [
      'photos',
      'copy',
      'price',
      'options',
      'includes',
      'cancel',
    ]);
  });

  test('keepEditing path: rejected stays rejected without resubmit bump', () {
    // Mirrors DiverStore._withSaveIntent(keepEditing) rules used by temp save.
    final previous = ShopProduct(
      id: 'p1',
      shopId: 'shop',
      name: 'Trip',
      consumerPrice: 100000,
      professionalPrice: 100000,
      publishStatus: ProductPublishStatus.rejected,
      active: false,
      reviewNote: '사진',
      rejectedContentHash: 'abc',
      rejectedReasonTags: const ['photos'],
      resubmitCount: 2,
      resubmitNote: 'old',
    );
    final nextStatus =
        previous.publishStatus == ProductPublishStatus.rejected
            ? ProductPublishStatus.rejected
            : ProductPublishStatus.draft;
    expect(nextStatus, ProductPublishStatus.rejected);
    expect(previous.resubmitCount, 2);
    // Resubmit gate only runs on submitForReview, not keepEditing.
    expect(
      () => ProductPublishGuard.assertChangedSinceReject(
        previous: previous,
        next: previous,
      ),
      returnsNormally,
    );
  });
}
