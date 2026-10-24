import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/dive_star_application.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_dive_star_milestone.dart';

DiveStarApplication _app({
  required DiveStarPipelineStatus status,
  String shopId = 'shop-a',
}) {
  return DiveStarApplication(
    id: 'a1',
    shopId: shopId,
    shopName: 'Shop',
    partnerUid: 'u1',
    companyName: 'Co',
    contactName: 'Name',
    contactEmail: 'a@b.c',
    contactPhone: '1',
    country: 'KR',
    notes: '',
    signaturePngBase64: 'x',
    pipelineStatus: status,
    submittedAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('PartnerDiveStarMilestone.resolve', () {
    test('grade 3 → threeStar', () {
      expect(
        PartnerDiveStarMilestone.resolve(diveStarGrade: 3),
        PartnerDiveStarMilestoneStep.threeStar,
      );
    });

    test('grade 2 → twoStar', () {
      expect(
        PartnerDiveStarMilestone.resolve(diveStarGrade: 2),
        PartnerDiveStarMilestoneStep.twoStar,
      );
    });

    test('grade 1 → oneStar', () {
      expect(
        PartnerDiveStarMilestone.resolve(diveStarGrade: 1),
        PartnerDiveStarMilestoneStep.oneStar,
      );
    });

    test('grade 0 + underReview → preReview', () {
      expect(
        PartnerDiveStarMilestone.resolve(
          diveStarGrade: 0,
          latestApplication: _app(status: DiveStarPipelineStatus.underReview),
        ),
        PartnerDiveStarMilestoneStep.preReview,
      );
    });

    test('grade 0 + guideSent → generalPartner', () {
      expect(
        PartnerDiveStarMilestone.resolve(
          diveStarGrade: 0,
          latestApplication: _app(status: DiveStarPipelineStatus.guideSent),
        ),
        PartnerDiveStarMilestoneStep.generalPartner,
      );
    });

    test('grade 0 + no application → generalPartner', () {
      expect(
        PartnerDiveStarMilestone.resolve(diveStarGrade: 0),
        PartnerDiveStarMilestoneStep.generalPartner,
      );
    });

    test('grade wins over application', () {
      expect(
        PartnerDiveStarMilestone.resolve(
          diveStarGrade: 2,
          latestApplication: _app(status: DiveStarPipelineStatus.underReview),
        ),
        PartnerDiveStarMilestoneStep.twoStar,
      );
    });
  });
}
