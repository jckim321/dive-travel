import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

/// Gold or above, own trip, and an approved listing.
bool craftedTripCanOpenSeats({
  required MemberGrade grade,
  required String viewerUid,
  required ShopProduct product,
}) {
  if (viewerUid.isEmpty || product.submittedByUid != viewerUid) {
    return false;
  }
  if (grade.rank < MemberGrade.gold.rank) {
    return false;
  }
  return product.publishStatus == ProductPublishStatus.approved;
}
