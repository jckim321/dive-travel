import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/data/refund_policy.dart';

void main() {
  test('commission and creator uid rules follow the document', () {
    expect(
      RefundPolicy.shopProfileWritesCommissionRate(
        partnerProfile: false,
        stored: 0.12,
      ),
      isTrue,
    );
    expect(
      RefundPolicy.shopProfileWritesCommissionRate(
        partnerProfile: true,
        stored: null,
      ),
      isTrue,
    );
    expect(
      RefundPolicy.shopProfileWritesCommissionRate(
        partnerProfile: true,
        stored: 0.12,
      ),
      isFalse,
    );
    expect(
      RefundPolicy.shopProfileWritesCommissionRate(
        partnerProfile: true,
        stored: 0.2,
      ),
      isTrue,
    );
    expect(
      RefundPolicy.shopProfileWritesCreatorUid(
        documentExists: false,
        shopId: 'curated-1',
        creatorUid: 'captain-1',
      ),
      isTrue,
    );
    expect(
      RefundPolicy.shopProfileWritesCreatorUid(
        documentExists: true,
        shopId: 'curated-1',
        creatorUid: 'other',
      ),
      isFalse,
    );
    expect(
      RefundPolicy.shopProfileWritesCreatorUid(
        documentExists: false,
        shopId: 'reef',
        creatorUid: 'captain-1',
      ),
      isFalse,
    );
  });

  test('a new curated shop keeps the first creator uid', () async {
    final repo = MemoryDiverRepository.forTest();
    await repo.saveShopProfile(
      shopId: 'curated-1',
      name: '없는 리조트',
      location: '보홀',
      productName: '펀',
      consumerPrice: 1,
      professionalPrice: 1,
      curated: true,
      creatorUid: 'captain-1',
    );
    expect(repo.debugLastProfileFields, contains('creator_uid'));
    expect((await repo.fetchShopStat('curated-1'))?.creatorUid, 'captain-1');

    await repo.saveShopProfile(
      shopId: 'curated-1',
      name: '다른 이름',
      location: '보홀',
      productName: '펀',
      consumerPrice: 1,
      professionalPrice: 1,
      curated: true,
      creatorUid: 'other',
    );
    expect(repo.debugLastProfileFields, isNot(contains('creator_uid')));
    final saved = await repo.fetchShopStat('curated-1');
    expect(saved?.creatorUid, 'captain-1');
    expect(saved?.name, '다른 이름');
  });

  test('partner profile save skips an unchanged commission rate', () async {
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: 'reef',
    );
    await repo.saveShopProfile(
      shopId: 'reef',
      name: '리프',
      location: '세부',
      productName: '펀',
      consumerPrice: 1,
      professionalPrice: 1,
      partnerProfile: true,
    );
    expect(repo.debugLastProfileFields, contains('commission_rate'));
    expect((await repo.fetchShopStat('reef'))?.commissionRate, 0.12);

    await repo.saveShopProfile(
      shopId: 'reef',
      name: '리프',
      location: '세부',
      productName: '펀',
      consumerPrice: 2,
      professionalPrice: 1,
      partnerProfile: true,
    );
    expect(repo.debugLastProfileFields, isNot(contains('commission_rate')));
    final saved = await repo.fetchShopStat('reef');
    expect(saved?.commissionRate, 0.12);
    expect(saved?.consumerPrice, 2);
    expect(saved?.creatorUid, isEmpty);
  });
}
