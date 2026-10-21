import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';

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
      await repo.submitOperationReview(
        uid: 'test-user',
        shopId: shopId,
        safety: 5,
        guide: 5,
        boat: 5,
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
    await repo.submitOperationReview(
      uid: 'test-user',
      shopId: 'shop-b',
      safety: 4,
      guide: 4,
      boat: 4,
      comment: 'anonymous note',
    );
    final page = await repo.fetchShopReviewsPage(shopId: 'shop-b');
    expect(page.reviews.single.authorDisplayName, isEmpty);
    expect(page.reviews.single.stars, 4);
  });
}
