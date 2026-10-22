import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/partner_document.dart';

void main() {
  test('시드 문서 2건과 기본 설정을 만든다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    final docs = await repo.ensurePartnerDocumentsSeeded();
    expect(docs, hasLength(2));
    expect(docs.every((d) => d.isDraft), isTrue);
    expect(docs.every((d) => d.audience == PartnerDocAudience.public), isTrue);

    final config = await repo.ensurePartnerDocConfig();
    expect(config.channelsForCountry('KR'), contains('kakao'));
    final filled = config.templateFor('ko').fill(
      partnerName: '보홀 샵',
      link: 'docs_public/a.pdf',
    );
    expect(filled, contains('보홀 샵'));
    expect(filled, contains('docs_public/a.pdf'));
  });

  test('발송 기록을 남긴다', () async {
    final repo = MemoryDiverRepository.forTest(isAdmin: true);
    await repo.ensurePartnerDocumentsSeeded();
    final record = await repo.recordDocumentShare(
      documentId: 'dive-star-guide-ko',
      documentTitle: '다이브스타 심사 안내서',
      shopId: 'shop-a',
      shopName: '테스트 샵',
      method: PartnerDocShareMethod.share,
      adminUid: 'admin-1',
    );
    expect(record.shopName, '테스트 샵');
    final list = await repo.listDocumentShares();
    expect(list, hasLength(1));
    expect(list.first.method, PartnerDocShareMethod.share);
  });
}
