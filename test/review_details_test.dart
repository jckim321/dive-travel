import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/operation_review_policy.dart';
import 'package:dive_travel_app/core/models/guest_review.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/review_detail_options.dart';

void main() {
  test('GuestReview.fromMap ignores missing detail fields', () {
    final review = GuestReview.fromMap('r1', {
      'shop_id': 'shop-a',
      'overall': 4,
      'comment': 'old review',
      'author_display_name': 'Kim',
      'created_at': DateTime(2024, 1, 1).toIso8601String(),
    });
    expect(review.details.isEmpty, isTrue);
    expect(review.comment, 'old review');
  });

  test('GuestReview.fromMap reads optional details', () {
    final review = GuestReview.fromMap('r2', {
      'shop_id': 'shop-a',
      'overall': 5,
      'diver_level': 'open_water',
      'dive_count_band': 'dives_50_200',
      'visibility': 'vis_good',
      'current': 'current_mild',
      'water_temp_c': 27,
      'created_at': DateTime(2024, 1, 1).toIso8601String(),
    });
    expect(review.details.diverLevel, 'open_water');
    expect(review.details.waterTempC, 27);
    expect(review.details.visibility, 'vis_good');
  });

  test('normalizeDetails rejects bad keys and water temp', () {
    expect(
      () => OperationReviewPolicy.normalizeDetails(
        const ReviewDetails(diverLevel: 'nope'),
      ),
      throwsA(
        isA<ReviewValidationException>().having(
          (e) => e.code,
          'code',
          ReviewValidationCode.invalidDetails,
        ),
      ),
    );
    expect(
      () => OperationReviewPolicy.normalizeDetails(
        const ReviewDetails(waterTempC: 99),
      ),
      throwsA(
        isA<ReviewValidationException>().having(
          (e) => e.code,
          'code',
          ReviewValidationCode.invalidWaterTemp,
        ),
      ),
    );
  });

  test('memory submit stores details when provided', () async {
    final repo = MemoryDiverRepository.forTest();
    repo.seedBooking(
      TourBooking(
        id: 'b-detail',
        uid: 'test-user',
        shopId: 'shop-a',
        shopName: 'Shop',
        productName: 'Trip',
        price: 100,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        tourDate: DateTime.now().subtract(const Duration(days: 1)),
        status: BookingStatus.confirmed,
      ),
    );
    await repo.submitOperationReview(
      uid: 'test-user',
      shopId: 'shop-a',
      safety: 5,
      guide: 5,
      boat: 5,
      bookingId: 'b-detail',
      details: const ReviewDetails(
        diverLevel: 'advanced',
        visibility: 'vis_excellent',
        waterTempC: 28,
      ),
    );
    final page = await repo.fetchShopReviewsPage(shopId: 'shop-a');
    expect(page.reviews.single.details.diverLevel, 'advanced');
    expect(page.reviews.single.details.waterTempC, 28);
  });
}
