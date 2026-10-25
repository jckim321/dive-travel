import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/partner_contract.dart';
import 'package:dive_travel_app/core/models/partner_promotion.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_dashboard_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

void main() {
  PartnerContract contract({
    required String id,
    required PartnerContractStatus status,
    required DateTime uploadedAt,
  }) {
    return PartnerContract(
      id: id,
      shopId: 'shop-a',
      kind: PartnerContractKind.master,
      title: id,
      version: '1',
      status: status,
      fileUrl: 'memory://$id.pdf',
      fileSha256: 'abc',
      uploadedAt: uploadedAt,
      uploadedByUid: 'admin-1',
    );
  }

  test('파트너 서류함 조회는 상태 조건만 쓰고 정렬은 화면에서 한다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    repo.seedPartnerContract(
      contract(
        id: 'draft',
        status: PartnerContractStatus.drafting,
        uploadedAt: DateTime.utc(2026, 4, 1),
      ),
    );
    repo.seedPartnerContract(
      contract(
        id: 'wait-old',
        status: PartnerContractStatus.awaitingSignature,
        uploadedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    repo.seedPartnerContract(
      contract(
        id: 'done-new',
        status: PartnerContractStatus.executed,
        uploadedAt: DateTime.utc(2026, 3, 1),
      ),
    );
    repo.seedPartnerContract(
      contract(
        id: 'voided',
        status: PartnerContractStatus.voided,
        uploadedAt: DateTime.utc(2026, 5, 1),
      ),
    );

    final partner = await repo.listPartnerContracts('shop-a', forPartner: true);
    final query = repo.lastPartnerContractListQuery;
    expect(query, isNotNull);
    expect(query!.forPartner, isTrue);
    expect(query.statusIn, ['awaiting_signature', 'executed']);
    expect(query.orderByUploadedAt, isFalse);
    expect(partner.map((doc) => doc.id), ['wait-old', 'done-new']);

    final sorted = sortPartnerContractsByUploadedAt(partner);
    expect(sorted.map((doc) => doc.id), ['done-new', 'wait-old']);

    final admin = await repo.listPartnerContracts('shop-a');
    expect(repo.lastPartnerContractListQuery!.forPartner, isFalse);
    expect(repo.lastPartnerContractListQuery!.statusIn, isEmpty);
    expect(repo.lastPartnerContractListQuery!.orderByUploadedAt, isTrue);
    expect(admin.map((doc) => doc.id), [
      'voided',
      'draft',
      'done-new',
      'wait-old',
    ]);
  });

  test('제안을 저장한 뒤에는 다시 읽지 않는다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    expect(repo.promotionReadCount, 0);
    final created = await repo.createPartnerPromotion(
      shopId: 'shop-a',
      partnerUid: 'partner-1',
      kind: 'price_off',
      startsOn: DateTime(2026, 10, 1),
      endsOn: DateTime(2026, 10, 31),
      note: '주중 할인',
    );
    expect(repo.promotionReadCount, 0);
    expect(created.note, '주중 할인');
    expect(created.kind, 'price_off');
    expect(created.status, PartnerPromotionStatus.incoming);
    expect(created.createdByUid, 'partner-1');

    final listed = await repo.listPartnerPromotions('shop-a');
    expect(repo.promotionReadCount, 1);
    expect(listed.single.id, created.id);
  });

  test('파트너 홈 의향서는 partnerUid로만 읽는다', () async {
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: 'shop-a',
    );
    await repo.submitDiveStarApplication(
      shopId: 'shop-a',
      shopName: 'Alpha',
      partnerUid: 'test-user',
      companyName: 'Alpha',
      contactName: 'Kim',
      contactEmail: 'kim@example.com',
      contactPhone: '010',
      country: 'KR',
      notes: '',
      signaturePngBase64: 'iVBORw0KGgo=',
    );
    await repo.submitDiveStarApplication(
      shopId: 'shop-a',
      shopName: 'Alpha',
      partnerUid: 'other-partner',
      companyName: 'Other',
      contactName: 'Lee',
      contactEmail: 'lee@example.com',
      contactPhone: '010',
      country: 'KR',
      notes: '',
      signaturePngBase64: 'iVBORw0KGgo=',
    );

    final mine = await repo.listDiveStarApplications(partnerUid: 'test-user');
    expect(repo.lastDiveStarApplicationListQuery?.partnerUid, 'test-user');
    expect(repo.lastDiveStarApplicationListQuery?.shopId, isNull);
    expect(mine, hasLength(1));
    expect(mine.single.partnerUid, 'test-user');

    final shop = await repo.listDiveStarApplications(shopId: 'shop-a');
    expect(repo.lastDiveStarApplicationListQuery?.shopId, 'shop-a');
    expect(repo.lastDiveStarApplicationListQuery?.partnerUid, isNull);
    expect(shop, hasLength(2));
  });

  testWidgets('파트너 홈은 의향서를 partnerUid로 읽는다', (tester) async {
    final repo = MemoryDiverRepository.forTest(
      isBusiness: true,
      ownedShopId: 'bohol-hideout',
    );
    final store = DiverStore(repo);
    addTearDown(store.dispose);
    await repo.submitDiveStarApplication(
      shopId: 'bohol-hideout',
      shopName: '보홀',
      partnerUid: 'test-user',
      companyName: 'Mine',
      contactName: 'Kim',
      contactEmail: 'kim@example.com',
      contactPhone: '010',
      country: 'KR',
      notes: '',
      signaturePngBase64: 'iVBORw0KGgo=',
    );
    await repo.submitDiveStarApplication(
      shopId: 'bohol-hideout',
      shopName: '보홀',
      partnerUid: 'other-partner',
      companyName: 'Other',
      contactName: 'Lee',
      contactEmail: 'lee@example.com',
      contactPhone: '010',
      country: 'KR',
      notes: '',
      signaturePngBase64: 'iVBORw0KGgo=',
    );

    await tester.pumpWidget(
      DiverStoreScope(
        store: store,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PartnerDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repo.lastDiveStarApplicationListQuery?.partnerUid, 'test-user');
    expect(repo.lastDiveStarApplicationListQuery?.shopId, isNull);
    expect(repo.lastPartnerContractListQuery?.forPartner, isTrue);
  });
}
