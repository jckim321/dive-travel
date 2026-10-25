import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/partner_contract.dart';

void main() {
  const shopId = AppConstants.defaultPartnerShopId;
  final pdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.4 h6-test'));
  final digest = sha256.convert(pdfBytes).toString();

  Future<PartnerContract> draft(MemoryDiverRepository repo) {
    const url = 'mem://contracts/h6.pdf';
    repo.seedPartnerContractFile(url, pdfBytes);
    return repo.createPartnerContractDraft(
      shopId: shopId,
      adminUid: 'admin-1',
      kind: PartnerContractKind.master,
      title: '기본계약',
      version: '1',
      fileUrl: url,
      fileSha256: digest,
    );
  }

  test('send → sign executes; sealed blocks further edits', () async {
    final repo = MemoryDiverRepository.forTest(isBusiness: true);
    final created = await draft(repo);
    expect(created.status, PartnerContractStatus.drafting);

    await repo.sendPartnerContract(
      shopId: shopId,
      contractId: created.id,
      adminUid: 'admin-1',
    );
    var doc = (await repo.getPartnerContract(
      shopId: shopId,
      contractId: created.id,
    ))!;
    expect(doc.status, PartnerContractStatus.awaitingSignature);

    await repo.signPartnerContract(
      shopId: shopId,
      contractId: created.id,
      partnerUid: 'test-user',
      signerName: '파트너',
      signaturePngBase64: 'aaa',
      expectedSha256: digest,
    );
    doc = (await repo.getPartnerContract(
      shopId: shopId,
      contractId: created.id,
    ))!;
    expect(doc.status, PartnerContractStatus.executed);
    expect(doc.signature?.docSha256, digest);

    expect(
      () => repo.voidPartnerContract(
        shopId: shopId,
        contractId: created.id,
        adminUid: 'admin-1',
      ),
      throwsStateError,
    );
  });

  test('sha mismatch blocks sign; revision keeps awaiting', () async {
    final repo = MemoryDiverRepository.forTest(isBusiness: true);
    final created = await draft(repo);
    await repo.sendPartnerContract(
      shopId: shopId,
      contractId: created.id,
      adminUid: 'admin-1',
    );

    expect(
      () => repo.signPartnerContract(
        shopId: shopId,
        contractId: created.id,
        partnerUid: 'test-user',
        signerName: '파트너',
        signaturePngBase64: 'aaa',
        expectedSha256: 'deadbeef',
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'file_sha256_mismatch',
        ),
      ),
    );

    await repo.requestPartnerContractRevision(
      shopId: shopId,
      contractId: created.id,
      partnerUid: 'test-user',
      memo: '날짜 수정 부탁',
    );
    final doc = (await repo.getPartnerContract(
      shopId: shopId,
      contractId: created.id,
    ))!;
    expect(doc.status, PartnerContractStatus.awaitingSignature);
    expect(doc.revisionNote, '날짜 수정 부탁');
  });

  test('events append for upload/send/view/sign; rollup status', () async {
    final repo = MemoryDiverRepository.forTest(isBusiness: true);
    final created = await draft(repo);
    await repo.sendPartnerContract(
      shopId: shopId,
      contractId: created.id,
      adminUid: 'admin-1',
    );
    await repo.markPartnerContractViewed(
      shopId: shopId,
      contractId: created.id,
      partnerUid: 'test-user',
    );
    await repo.signPartnerContract(
      shopId: shopId,
      contractId: created.id,
      partnerUid: 'test-user',
      signerName: '파트너',
      signaturePngBase64: 'aaa',
      expectedSha256: digest,
    );
    final events = await repo.listPartnerContractEvents(
      shopId: shopId,
      contractId: created.id,
    );
    expect(
      events.map((e) => e.type).toList(),
      containsAll([
        PartnerContractEventType.uploaded,
        PartnerContractEventType.sent,
        PartnerContractEventType.viewed,
        PartnerContractEventType.signed,
        PartnerContractEventType.executed,
      ]),
    );
    for (final e in events) {
      expect(e.docSha256, digest);
    }

    final all = await repo.listPartnerContracts(shopId);
    expect(
      PartnerContract.rollupStatus(all),
      PartnerContractShopStatus.executed,
    );
  });
}
