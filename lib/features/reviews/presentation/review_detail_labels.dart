import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Maps Firestore detail keys to localized labels.
String? reviewDetailLabel(AppLocalizations l10n, String? key) {
  if (key == null || key.isEmpty) {
    return null;
  }
  switch (key) {
    case 'open_water':
      return l10n.reviewDetailOpenWater;
    case 'advanced':
      return l10n.reviewDetailAdvanced;
    case 'rescue_plus':
      return l10n.reviewDetailRescuePlus;
    case 'instructor':
      return l10n.reviewDetailInstructor;
    case 'freediver':
      return l10n.reviewDetailFreediver;
    case 'dives_under_50':
      return l10n.reviewDetailDivesUnder50;
    case 'dives_50_200':
      return l10n.reviewDetailDives50to200;
    case 'dives_200_plus':
      return l10n.reviewDetailDives200Plus;
    case 'vis_poor':
      return l10n.reviewDetailVisPoor;
    case 'vis_ok':
      return l10n.reviewDetailVisOk;
    case 'vis_good':
      return l10n.reviewDetailVisGood;
    case 'vis_excellent':
      return l10n.reviewDetailVisExcellent;
    case 'current_mild':
      return l10n.reviewDetailCurrentMild;
    case 'current_ok':
      return l10n.reviewDetailCurrentOk;
    case 'current_strong':
      return l10n.reviewDetailCurrentStrong;
    case 'crowd_relaxed':
      return l10n.reviewDetailCrowdRelaxed;
    case 'crowd_ok':
      return l10n.reviewDetailCrowdOk;
    case 'crowd_busy':
      return l10n.reviewDetailCrowdBusy;
    case 'audience_beginner':
      return l10n.reviewDetailAudienceBeginner;
    case 'audience_experienced':
      return l10n.reviewDetailAudienceExperienced;
    case 'audience_couple':
      return l10n.reviewDetailAudienceCouple;
    case 'audience_family':
      return l10n.reviewDetailAudienceFamily;
    case 'audience_photo':
      return l10n.reviewDetailAudiencePhoto;
    case 'audience_freediver':
      return l10n.reviewDetailAudienceFreediver;
    case 'audience_tech':
      return l10n.reviewDetailAudienceTech;
    case 'revisit_yes':
      return l10n.reviewDetailRevisitYes;
    case 'revisit_no':
      return l10n.reviewDetailRevisitNo;
    case 'revisit_unsure':
      return l10n.reviewDetailRevisitUnsure;
    default:
      return null;
  }
}
