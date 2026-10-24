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

  group('keepEditingStatus', () {
    test('pending stays pending', () {
      expect(
        ProductPublishGuard.keepEditingStatus(ProductPublishStatus.pending),
        ProductPublishStatus.pending,
      );
    });

    test('rejected stays rejected', () {
      expect(
        ProductPublishGuard.keepEditingStatus(ProductPublishStatus.rejected),
        ProductPublishStatus.rejected,
      );
    });

    test('null and draft become draft', () {
      expect(
        ProductPublishGuard.keepEditingStatus(null),
        ProductPublishStatus.draft,
      );
      expect(
        ProductPublishGuard.keepEditingStatus(ProductPublishStatus.draft),
        ProductPublishStatus.draft,
      );
    });

    test('approved stays approved (defensive)', () {
      expect(
        ProductPublishGuard.keepEditingStatus(ProductPublishStatus.approved),
        ProductPublishStatus.approved,
      );
    });
  });
}
