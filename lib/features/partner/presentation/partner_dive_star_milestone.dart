import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/models/dive_star_application.dart';

/// Five steps on the partner home 「리조트 이정표 · 다이브스타 진행」.
enum PartnerDiveStarMilestoneStep {
  generalPartner,
  preReview,
  oneStar,
  twoStar,
  threeStar,
}

/// Maps shop grade + LOI pipeline → milestone step (read-only).
///
/// | Condition | Step |
/// |-----------|------|
/// | `diveStar >= 3` | threeStar |
/// | `diveStar == 2` | twoStar |
/// | `diveStar == 1` | oneStar |
/// | `diveStar == 0` + application with loiReceived / docsSubmitted / underReview / resultNotified | preReview |
/// | no application, guideSent only, unknown/reject/hold raw (not in enum) | generalPartner |
///
/// `DiveStarPipelineStatus` has no reject/hold cases today; unknown → generalPartner.
abstract final class PartnerDiveStarMilestone {
  static PartnerDiveStarMilestoneStep resolve({
    required int diveStarGrade,
    DiveStarApplication? latestApplication,
  }) {
    final grade = DiveStar.clampGrade(diveStarGrade);
    if (grade >= 3) {
      return PartnerDiveStarMilestoneStep.threeStar;
    }
    if (grade == 2) {
      return PartnerDiveStarMilestoneStep.twoStar;
    }
    if (grade == 1) {
      return PartnerDiveStarMilestoneStep.oneStar;
    }
    if (latestApplication != null &&
        _countsAsPreReview(latestApplication.pipelineStatus)) {
      return PartnerDiveStarMilestoneStep.preReview;
    }
    return PartnerDiveStarMilestoneStep.generalPartner;
  }

  static bool _countsAsPreReview(DiveStarPipelineStatus status) {
    return switch (status) {
      DiveStarPipelineStatus.loiReceived ||
      DiveStarPipelineStatus.docsSubmitted ||
      DiveStarPipelineStatus.underReview ||
      DiveStarPipelineStatus.resultNotified =>
        true,
      DiveStarPipelineStatus.guideSent => false,
    };
  }

  /// Prefer newest application for [shopId] (by submittedAt).
  static DiveStarApplication? latestForShop(
    Iterable<DiveStarApplication> apps,
    String shopId,
  ) {
    final id = shopId.trim();
    DiveStarApplication? best;
    for (final app in apps) {
      if (app.shopId.trim() != id) {
        continue;
      }
      if (best == null || app.submittedAt.isAfter(best.submittedAt)) {
        best = app;
      }
    }
    return best;
  }
}
