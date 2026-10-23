import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/product_content_fingerprint.dart';
import 'package:dive_travel_app/core/models/product_publish_guard.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

ShopProduct _product({
  int consumerPrice = 100000,
  String reviewNote = '',
  String rejectedContentHash = '',
  int resubmitCount = 0,
  String resubmitNote = '',
}) {
  return ShopProduct(
    id: 'p1',
    shopId: 'shop',
    name: 'Golf 2n3d',
    consumerPrice: consumerPrice,
    professionalPrice: consumerPrice,
    blurb: 'body',
    publishStatus: ProductPublishStatus.pending,
    active: false,
    reviewNote: reviewNote,
    rejectedContentHash: rejectedContentHash,
    resubmitCount: resubmitCount,
    resubmitNote: resubmitNote,
  );
}

void main() {
  group('ensureCanApprove', () {
    test('가격 > 0 이면 통과', () {
      expect(
        () => ProductPublishGuard.ensureCanApprove(_product()),
        returnsNormally,
      );
    });

    test('가격 ≤ 0 이면 StateError', () {
      expect(
        () => ProductPublishGuard.ensureCanApprove(_product(consumerPrice: 0)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            ProductPublishGuard.missingPriceMessage,
          ),
        ),
      );
    });

    test('가격 1억 초과면 StateError', () {
      expect(
        () => ProductPublishGuard.ensureCanApprove(
          _product(consumerPrice: 100000001),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            ProductPublishGuard.overCapPriceMessage,
          ),
        ),
      );
    });

    test('가격 1억이면 통과', () {
      expect(
        () => ProductPublishGuard.ensureCanApprove(
          _product(consumerPrice: 100000000),
        ),
        returnsNormally,
      );
    });
  });

  group('ensureRejectNote', () {
    test('빈 사유면 StateError', () {
      expect(
        () => ProductPublishGuard.ensureRejectNote('  '),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            ProductPublishGuard.emptyRejectNoteMessage,
          ),
        ),
      );
    });

    test('사유 있으면 통과', () {
      expect(
        () => ProductPublishGuard.ensureRejectNote('사진 부족'),
        returnsNormally,
      );
    });
  });

  group('applyStatusChange', () {
    test('승인: 가격 0이면 거부', () {
      expect(
        () => ProductPublishGuard.applyStatusChange(
          product: _product(consumerPrice: 0),
          status: ProductPublishStatus.approved,
        ),
        throwsStateError,
      );
    });

    test('승인: 메모·해시·회차 클리어', () {
      final next = ProductPublishGuard.applyStatusChange(
        product: _product(
          reviewNote: 'old reject',
          rejectedContentHash: 'abc',
          resubmitCount: 2,
          resubmitNote: 'fixed photos',
        ),
        status: ProductPublishStatus.approved,
      );
      expect(next.publishStatus, ProductPublishStatus.approved);
      expect(next.active, isTrue);
      expect(next.reviewNote, '');
      expect(next.rejectedContentHash, '');
      expect(next.resubmitCount, 0);
      expect(next.resubmitNote, '');
    });

    test('반려: 빈 사유면 거부', () {
      expect(
        () => ProductPublishGuard.applyStatusChange(
          product: _product(),
          status: ProductPublishStatus.rejected,
          reviewNote: '',
        ),
        throwsStateError,
      );
    });

    test('반려: 가격 0이어도 가능, 해시·사유 기록, 재요청 메모 클리어', () {
      final product = _product(consumerPrice: 0, resubmitNote: 'old memo');
      final next = ProductPublishGuard.applyStatusChange(
        product: product,
        status: ProductPublishStatus.rejected,
        reviewNote: '  가격 미입력  ',
      );
      expect(next.publishStatus, ProductPublishStatus.rejected);
      expect(next.active, isFalse);
      expect(next.reviewNote, '가격 미입력');
      expect(next.rejectedContentHash, productContentFingerprint(product));
      expect(next.resubmitNote, '');
    });
  });
}
