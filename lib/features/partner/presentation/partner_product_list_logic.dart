import 'package:dive_travel_app/core/models/shop_product.dart';

/// Partner product list publish badge (시안 색 칩).
enum PartnerPublishBadgeKind {
  /// `publish_status == pending`
  pending,

  /// `publish_status == rejected`
  rejected,

  /// `isListedPublicly` (approved + active)
  listed,

  /// draft, or approved but inactive ("닫힘")
  closed,
}

/// Same-boat status line under the publish badge.
enum PartnerSameBoatLineKind {
  notOpened,
  pendingReview,
  liveOpen,
  rejected,
}

/// Counts for partner filter chips (전체 / 승인 대기 / 게시중 / 반려).
class PartnerProductFilterCounts {
  const PartnerProductFilterCounts({
    required this.all,
    required this.pending,
    required this.listed,
    required this.rejected,
  });

  final int all;
  final int pending;
  final int listed;
  final int rejected;
}

enum PartnerProductStatusFilter { all, pending, listed, rejected }

/// Publish badge for a partner product card.
PartnerPublishBadgeKind partnerPublishBadgeKind(ShopProduct product) {
  switch (product.publishStatus) {
    case ProductPublishStatus.pending:
      return PartnerPublishBadgeKind.pending;
    case ProductPublishStatus.rejected:
      return PartnerPublishBadgeKind.rejected;
    case ProductPublishStatus.approved:
      return product.active
          ? PartnerPublishBadgeKind.listed
          : PartnerPublishBadgeKind.closed;
    case ProductPublishStatus.draft:
      return PartnerPublishBadgeKind.closed;
  }
}

/// Same-boat line kind (independent of publish badge).
/// Precedence: pending → live → rejected → not opened.
PartnerSameBoatLineKind partnerSameBoatLineKind(ShopProduct product) {
  if (product.hasPendingSameBoat) {
    return PartnerSameBoatLineKind.pendingReview;
  }
  if (product.hasLiveSameBoatOffer) {
    return PartnerSameBoatLineKind.liveOpen;
  }
  if (product.hasRejectedSameBoat) {
    return PartnerSameBoatLineKind.rejected;
  }
  return PartnerSameBoatLineKind.notOpened;
}

/// Empty-seat open/manage is allowed only when the product is publicly listed.
bool partnerSeatsActionEnabled(ShopProduct product) => product.isListedPublicly;

/// Label switch: manage vs open (destination is still SameBoatSeatsScreen).
bool partnerSeatsIsManage(ShopProduct product) => product.hasAnySameBoatOpen;

/// Show 「가격 미입력」 when consumer price was never set (≤ 0).
bool partnerPriceMissing(ShopProduct product) => product.consumerPrice <= 0;

/// Rejected cards show resubmit + delete.
bool partnerShowRejectedActions(ShopProduct product) =>
    partnerPublishBadgeKind(product) == PartnerPublishBadgeKind.rejected;

/// Live same-boat seat count + departure for the card line (base, else options).
({int seats, DateTime? departure}) partnerSameBoatLiveSummary(
  ShopProduct product,
) {
  if (product.listsOnSameBoat) {
    return (seats: product.remainingSeats, departure: product.departureStart);
  }
  var seats = 0;
  DateTime? departure;
  for (final option in product.options) {
    if (!option.listsOnSameBoat) {
      continue;
    }
    final left = option.capacity - option.bookedSeats;
    seats += left < 0 ? 0 : left;
    departure ??= option.departureStart;
  }
  return (seats: seats, departure: departure);
}

PartnerProductFilterCounts partnerProductFilterCounts(
  Iterable<ShopProduct> products,
) {
  var pending = 0;
  var listed = 0;
  var rejected = 0;
  var all = 0;
  for (final product in products) {
    all += 1;
    switch (product.publishStatus) {
      case ProductPublishStatus.pending:
        pending += 1;
      case ProductPublishStatus.rejected:
        rejected += 1;
      case ProductPublishStatus.approved:
        if (product.isListedPublicly) {
          listed += 1;
        }
      case ProductPublishStatus.draft:
        break;
    }
  }
  return PartnerProductFilterCounts(
    all: all,
    pending: pending,
    listed: listed,
    rejected: rejected,
  );
}

List<ShopProduct> filterPartnerProducts({
  required Iterable<ShopProduct> products,
  required PartnerProductStatusFilter filter,
}) {
  return [
    for (final product in products)
      if (_matchesPartnerFilter(product, filter)) product,
  ];
}

bool _matchesPartnerFilter(
  ShopProduct product,
  PartnerProductStatusFilter filter,
) {
  return switch (filter) {
    PartnerProductStatusFilter.all => true,
    PartnerProductStatusFilter.pending =>
      product.publishStatus == ProductPublishStatus.pending,
    PartnerProductStatusFilter.listed => product.isListedPublicly,
    PartnerProductStatusFilter.rejected =>
      product.publishStatus == ProductPublishStatus.rejected,
  };
}
