import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/operation_review_policy.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

TourBooking _pastBooking({
  String id = 'b1',
  String uid = 'test-user',
  String shopId = 'shop-a',
  String productId = 'prod-1',
  bool reviewed = false,
  BookingStatus status = BookingStatus.confirmed,
  DateTime? tourDate,
}) {
  return TourBooking(
    id: id,
    uid: uid,
    shopId: shopId,
    shopName: 'Shop A',
    productName: 'Trip',
    productId: productId,
    price: 100,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    tourDate: tourDate ?? DateTime.now().subtract(const Duration(days: 2)),
    reviewed: reviewed,
    status: status,
  );
}

void main() {
  group('OperationReviewPolicy', () {
    test('rejects missing booking id', () {
      expect(
        () => OperationReviewPolicy.requireEligibleBooking(
          bookingId: '',
          bookings: [_pastBooking()],
          uid: 'test-user',
          shopId: 'shop-a',
        ),
        throwsA(
          isA<ReviewValidationException>().having(
            (e) => e.code,
            'code',
            ReviewValidationCode.bookingRequired,
          ),
        ),
      );
    });

    test('rejects already reviewed booking', () {
      expect(
        () => OperationReviewPolicy.requireEligibleBooking(
          bookingId: 'b1',
          bookings: [_pastBooking(reviewed: true)],
          uid: 'test-user',
          shopId: 'shop-a',
        ),
        throwsA(
          isA<ReviewValidationException>().having(
            (e) => e.code,
            'code',
            ReviewValidationCode.alreadyReviewed,
          ),
        ),
      );
    });

    test('rejects comment over 2000 chars', () {
      expect(
        () => OperationReviewPolicy.normalizeComment('x' * 2001),
        throwsA(
          isA<ReviewValidationException>().having(
            (e) => e.code,
            'code',
            ReviewValidationCode.commentTooLong,
          ),
        ),
      );
    });

    test('clamps stars into 1-5', () {
      expect(OperationReviewPolicy.clampStars(0), 1);
      expect(OperationReviewPolicy.clampStars(9), 5);
    });
  });

  group('MemoryDiverRepository submit gates', () {
    test('fails without bookingId', () async {
      final repo = MemoryDiverRepository.forTest();
      expect(
        () => repo.submitOperationReview(
          uid: 'test-user',
          shopId: 'shop-a',
          safety: 5,
          guide: 5,
          boat: 5,
        ),
        throwsA(
          isA<ReviewValidationException>().having(
            (e) => e.code,
            'code',
            ReviewValidationCode.bookingRequired,
          ),
        ),
      );
    });

    test('succeeds once for an eligible past booking', () async {
      final repo = MemoryDiverRepository.forTest();
      const shopId = 'shop-a';
      await repo.saveShopProduct(
        shopId: shopId,
        product: const ShopProduct(
          id: 'prod-1',
          shopId: shopId,
          name: 'Blue Trip',
          consumerPrice: 200,
          professionalPrice: 160,
        ),
      );
      repo.seedBooking(_pastBooking());

      await repo.submitOperationReview(
        uid: 'test-user',
        shopId: shopId,
        safety: 4,
        guide: 4,
        boat: 4,
        bookingId: 'b1',
        productId: 'prod-1',
        comment: 'Nice',
      );

      expect(
        () => repo.submitOperationReview(
          uid: 'test-user',
          shopId: shopId,
          safety: 5,
          guide: 5,
          boat: 5,
          bookingId: 'b1',
        ),
        throwsA(
          isA<ReviewValidationException>().having(
            (e) => e.code,
            'code',
            ReviewValidationCode.alreadyReviewed,
          ),
        ),
      );

      final page = await repo.fetchShopReviewsPage(shopId: shopId);
      expect(page.reviews, hasLength(1));
      expect(page.reviews.single.stars, 4);
    });
  });
}
