import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
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

  group('applyResubmit', () {
    test('내용 동일하면 차단', () {
      final previous = _product().copyWith(
        publishStatus: ProductPublishStatus.rejected,
        reviewNote: '사진 부족',
        rejectedContentHash: productContentFingerprint(_product()),
      );
      expect(
        () => ProductPublishGuard.applyResubmit(
          previous: previous,
          next: _product(),
          resubmitNote: '사진을 바꿨습니다',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            ProductPublishGuard.unchangedSinceRejectMessage,
          ),
        ),
      );
    });

    test('내용 변경 + 메모면 pending·회차+1·사유 유지', () {
      final base = _product();
      final previous = base.copyWith(
        publishStatus: ProductPublishStatus.rejected,
        reviewNote: '사진 부족',
        rejectedContentHash: productContentFingerprint(base),
        resubmitCount: 1,
      );
      final next = ProductPublishGuard.applyResubmit(
        previous: previous,
        next: _product(consumerPrice: 120000),
        resubmitNote: '가격을 올렸습니다',
      );
      expect(next.publishStatus, ProductPublishStatus.pending);
      expect(next.resubmitCount, 2);
      expect(next.resubmitNote, '가격을 올렸습니다');
      expect(next.reviewNote, '사진 부족');
      expect(next.rejectedContentHash, previous.rejectedContentHash);
    });

    test('해시 없는 옛 반려는 무변경 검사를 건너뛴다', () {
      final previous = _product().copyWith(
        publishStatus: ProductPublishStatus.rejected,
        reviewNote: 'old',
        rejectedContentHash: '',
      );
      final next = ProductPublishGuard.applyResubmit(
        previous: previous,
        next: _product(),
        resubmitNote: '메모를 남깁니다',
      );
      expect(next.publishStatus, ProductPublishStatus.pending);
      expect(next.resubmitCount, 1);
    });

    test('재요청 메모 길이 검증', () {
      final previous = _product().copyWith(
        publishStatus: ProductPublishStatus.rejected,
        rejectedContentHash: '',
      );
      expect(
        () => ProductPublishGuard.applyResubmit(
          previous: previous,
          next: _product(),
          resubmitNote: '짧음',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            ProductPublishGuard.resubmitNoteTooShortMessage,
          ),
        ),
      );
      expect(
        () => ProductPublishGuard.applyResubmit(
          previous: previous,
          next: _product(),
          resubmitNote: 'x' * 201,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            ProductPublishGuard.resubmitNoteTooLongMessage,
          ),
        ),
      );
    });

    test('업로드 전 bytes 사진만 추가해도 재요청 가능', () {
      final emptyPhotos = _product().copyWith(
        coverUrl: '',
        photoUrls: const [],
      );
      final previous = emptyPhotos.copyWith(
        publishStatus: ProductPublishStatus.rejected,
        reviewNote: '사진 없음',
        rejectedContentHash: productContentFingerprint(emptyPhotos),
      );
      final next = ProductPublishGuard.applyResubmit(
        previous: previous,
        next: emptyPhotos,
        resubmitNote: '사진을 첨부했습니다',
        pendingGallery: [
          ShopGallerySlot(bytes: Uint8List.fromList([9, 8, 7, 6])),
        ],
      );
      expect(next.publishStatus, ProductPublishStatus.pending);
      expect(next.resubmitCount, 1);
    });
  });
}
