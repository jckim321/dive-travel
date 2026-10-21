import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';

void main() {
  test('fetchShopReviewsPage returns empty when there are no reviews', () async {
    final repo = MemoryDiverRepository.forTest();
    final page = await repo.fetchShopReviewsPage(shopId: 'shop-a', limit: 10);
    expect(page.reviews, isEmpty);
    expect(page.hasMore, isFalse);
  });

  test('fetchShopReviewsPage pages newest-first in chunks of 10', () async {
    final repo = MemoryDiverRepository.forTest();
    const shopId = 'shop-a';

    for (var i = 0; i < 15; i++) {
      final bookingId = 'b-$i';
      repo.seedBooking(
        TourBooking(
          id: bookingId,
          uid: 'test-user',
          shopId: shopId,
          shopName: 'Shop A',
          productName: 'Trip',
          price: 100,
          createdAt: DateTime.now().subtract(Duration(days: 20 - i)),
          tourDate: DateTime.now().subtract(Duration(days: 15 - i)),
          status: BookingStatus.confirmed,
        ),
      );
      await repo.submitOperationReview(
        uid: 'test-user',
        shopId: shopId,
        safety: 5,
        guide: 5,
        boat: 5,
        bookingId: bookingId,
        comment: 'review-$i',
        authorDisplayName: 'Tester',
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }

    final first = await repo.fetchShopReviewsPage(shopId: shopId, limit: 10);
    expect(first.reviews, hasLength(10));
    expect(first.hasMore, isTrue);
    expect(first.reviews.first.comment, 'review-14');
    expect(first.reviews.last.comment, 'review-5');
    expect(first.reviews.first.authorDisplayName, 'Tester');

    final second = await repo.fetchShopReviewsPage(
      shopId: shopId,
      limit: 10,
      cursor: first.cursor,
    );
    expect(second.reviews, hasLength(5));
    expect(second.hasMore, isFalse);
    expect(second.reviews.first.comment, 'review-4');
    expect(second.reviews.last.comment, 'review-0');
  });

  test('missing author name stays empty for UI fallback', () async {
    final repo = MemoryDiverRepository.forTest();
    repo.seedBooking(
      TourBooking(
        id: 'b-anon',
        uid: 'test-user',
        shopId: 'shop-b',
        shopName: 'Shop B',
        productName: 'Trip',
        price: 100,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        tourDate: DateTime.now().subtract(const Duration(days: 1)),
        status: BookingStatus.confirmed,
      ),
    );
    await repo.submitOperationReview(
      uid: 'test-user',
      shopId: 'shop-b',
      safety: 4,
      guide: 4,
      boat: 4,
      bookingId: 'b-anon',
      comment: 'anonymous note',
    );
    final page = await repo.fetchShopReviewsPage(shopId: 'shop-b');
    expect(page.reviews.single.authorDisplayName, isEmpty);
    expect(page.reviews.single.stars, 4);
  });
}
