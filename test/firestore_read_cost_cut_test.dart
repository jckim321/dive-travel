import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('후기 수정·삭제 후 샵 평균이 스토어 캐시에 반영된다', () async {
    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProduct(
      shopId: 'shop-a',
      product: const ShopProduct(
        id: 'prod-1',
        shopId: 'shop-a',
        name: 'Blue Trip',
        consumerPrice: 200,
        professionalPrice: 160,
      ),
    );
    repo.seedBooking(
      TourBooking(
        id: 'b-1',
        uid: 'test-user',
        shopId: 'shop-a',
        shopName: 'Shop A',
        productName: 'Blue Trip',
        productId: 'prod-1',
        price: 200,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        tourDate: DateTime.now().subtract(const Duration(days: 1)),
        status: BookingStatus.confirmed,
      ),
    );

    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await Future<void>.delayed(Duration.zero);
    await store.refreshShopStats();

    await store.submitOperationReview(
      shopId: 'shop-a',
      safety: 5,
      guide: 5,
      boat: 5,
      bookingId: 'b-1',
      productId: 'prod-1',
    );
    var stats = store.shopStats.firstWhere((s) => s.shopId == 'shop-a');
    expect(stats.avgSafety, closeTo(5, 0.01));
    expect(stats.reviewCount, 1);

    final reviewId = (await store.listMyReviews()).single.id;
    await store.updateOperationReview(
      shopId: 'shop-a',
      reviewId: reviewId,
      safety: 2,
      guide: 2,
      boat: 2,
    );
    stats = store.shopStats.firstWhere((s) => s.shopId == 'shop-a');
    expect(stats.avgSafety, closeTo(2, 0.01));

    await store.deleteOperationReview(
      shopId: 'shop-a',
      reviewId: reviewId,
    );
    stats = store.shopStats.firstWhere((s) => s.shopId == 'shop-a');
    expect(stats.reviewCount, 0);
  });

  test('posts·logs는 페이지 get으로 읽고 로그인 감시 없이 동작한다', () async {
    final repo = MemoryDiverRepository.forTest();
    await repo.addCommunityPost(
      uid: 'test-user',
      authorName: 'Tester',
      title: 'Hello',
      subtitle: 'World',
      type: CommunityPostType.buddy,
      language: 'ko',
    );
    await repo.addLog(
      uid: 'test-user',
      siteName: 'Kerama',
      divedAt: DateTime(2024, 1, 1),
      memo: 'fun',
    );

    final posts = await repo.fetchCommunityPosts(limit: 20);
    expect(posts.posts, isNotEmpty);
    expect(posts.hasMore, isFalse);

    final logs = await repo.fetchDiveLogs('test-user', limit: 50);
    expect(logs.logs, isNotEmpty);

    final profile = await repo.watchDiver('test-user').first;
    expect(profile.logs, isEmpty);
  });
}
