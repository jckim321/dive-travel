import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/memory_diver_repository.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';

void main() {
  test('pipeline advances guide_sent → result_notified', () {
    var status = DiveStarPipelineStatus.guideSent;
    final seen = <DiveStarPipelineStatus>[status];
    while (status.next != null) {
      status = status.next!;
      seen.add(status);
    }
    expect(seen, [
      DiveStarPipelineStatus.guideSent,
      DiveStarPipelineStatus.loiReceived,
      DiveStarPipelineStatus.docsSubmitted,
      DiveStarPipelineStatus.underReview,
      DiveStarPipelineStatus.resultNotified,
    ]);
    expect(DiveStarPipelineStatus.resultNotified.next, isNull);
  });

  test('submit LOI stores signature and sets loi_received', () async {
    final repo = MemoryDiverRepository();
    final app = await repo.submitDiveStarApplication(
      shopId: 'shop-a',
      shopName: 'Alpha Dive',
      partnerUid: 'partner-1',
      companyName: 'Alpha Dive Co',
      contactName: 'Kim',
      contactEmail: 'kim@example.com',
      contactPhone: '010',
      country: 'KR',
      notes: 'ready',
      signaturePngBase64: 'iVBORw0KGgo=',
    );
    expect(app.pipelineStatus, DiveStarPipelineStatus.loiReceived);
    expect(app.signaturePngBase64, isNotEmpty);
    expect(app.reminderDueAt, isNotNull);

    final listed = await repo.listDiveStarApplications(partnerUid: 'partner-1');
    expect(listed, hasLength(1));
    expect(listed.first.id, app.id);

    final advanced = await repo.updateDiveStarApplicationPipeline(
      applicationId: app.id,
      status: DiveStarPipelineStatus.docsSubmitted,
    );
    expect(advanced.pipelineStatus, DiveStarPipelineStatus.docsSubmitted);

    final mail = await repo.queuePartnerEmail(
      toEmail: 'kim@example.com',
      subject: 'follow-up',
      body: 'please send docs',
      applicationId: app.id,
      shopId: 'shop-a',
    );
    expect(mail.isPending, isTrue);
    await repo.markPartnerEmailOutboxSent(mail.id);
    final outbox = await repo.listPartnerEmailOutbox();
    expect(outbox.first.status, 'sent');
  });
}
