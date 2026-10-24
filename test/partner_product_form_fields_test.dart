import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/partner_product_form_fields.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  group('category chip preserve', () {
    test('funDive stays until user selects a chip', () {
      expect(
        selectedPartnerCategoryChip(ProductCategory.funDive),
        isNull,
      );
      expect(
        categoryForPartnerSave(
          stored: ProductCategory.funDive,
          userSelectedChip: false,
          chipValue: ProductCategory.resortPackage,
        ),
        ProductCategory.funDive,
      );
      expect(
        categoryForPartnerSave(
          stored: ProductCategory.funDive,
          userSelectedChip: true,
          chipValue: ProductCategory.dayTrip,
        ),
        ProductCategory.dayTrip,
      );
    });

    test('course preserved; resort chip maps when selected', () {
      expect(
        categoryForPartnerSave(
          stored: ProductCategory.course,
          userSelectedChip: false,
          chipValue: ProductCategory.liveaboard,
        ),
        ProductCategory.course,
      );
      expect(
        selectedPartnerCategoryChip(ProductCategory.resortPackage),
        ProductCategory.resortPackage,
      );
    });
  });

  group('duration label preserve', () {
    test('parses N박 M일', () {
      final parts = parseDurationLabelParts('2박 3일');
      expect(parts.parsed, isTrue);
      expect(parts.nights, 2);
      expect(parts.days, 3);
    });

    test('freeform text is not parsed', () {
      final parts = parseDurationLabelParts('주말 패키지 / 협의');
      expect(parts.parsed, isFalse);
    });

    test('save keeps original until fields edited', () {
      expect(
        durationLabelForPartnerSave(
          originalLabel: '주말 패키지 / 협의',
          userEditedFields: false,
          nights: 2,
          days: 3,
        ),
        '주말 패키지 / 협의',
      );
      expect(
        durationLabelForPartnerSave(
          originalLabel: '주말 패키지 / 협의',
          userEditedFields: true,
          nights: 2,
          days: 3,
        ),
        '2박 3일',
      );
    });

    test('empty original + no edit stays empty', () {
      expect(
        durationLabelForPartnerSave(
          originalLabel: '',
          userEditedFields: false,
          nights: null,
          days: null,
        ),
        '',
      );
    });
  });
}
