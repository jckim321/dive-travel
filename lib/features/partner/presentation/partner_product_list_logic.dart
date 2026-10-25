import 'package:dive_travel_app/core/models/price_revision.dart'
    show optionHasSeatCommitment;
import 'package:dive_travel_app/core/models/shop_product.dart';

/// Partner product list publish badge (H1a: no approval queue for partners).
enum PartnerPublishBadgeKind {
  /// Draft / legacy pending / legacy rejected — editing, not public.
  drafting,

  /// `isListedPublicly` (approved + active)
  listed,

  /// approved but inactive ("닫힘")
  closed,
}

/// Same-boat status line under the publish badge.
enum PartnerSameBoatLineKind {
  notOpened,
  pendingReview,
  liveOpen,
  rejected,
}

/// Counts for partner filter chips (전체 / 작성 중 / 게시중 / 닫힘).
class PartnerProductFilterCounts {
  const PartnerProductFilterCounts({
    required this.all,
    required this.drafting,
    required this.listed,
    required this.closed,
  });

  final int all;
  final int drafting;
  final int listed;
  final int closed;
}

enum PartnerProductStatusFilter { all, drafting, listed, closed }

/// Publish badge for a partner product card.
PartnerPublishBadgeKind partnerPublishBadgeKind(ShopProduct product) {
  if (product.isListedPublicly) {
    return PartnerPublishBadgeKind.listed;
  }
  if (product.publishStatus == ProductPublishStatus.approved && !product.active) {
    return PartnerPublishBadgeKind.closed;
  }
  // draft, pending, rejected → 작성 중 (legacy approval states)
  return PartnerPublishBadgeKind.drafting;
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

/// Legacy rejected cards no longer need special resubmit actions (H1a).
bool partnerShowRejectedActions(ShopProduct product) => false;

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
  var drafting = 0;
  var listed = 0;
  var closed = 0;
  var all = 0;
  for (final product in products) {
    all += 1;
    switch (partnerPublishBadgeKind(product)) {
      case PartnerPublishBadgeKind.drafting:
        drafting += 1;
      case PartnerPublishBadgeKind.listed:
        listed += 1;
      case PartnerPublishBadgeKind.closed:
        closed += 1;
    }
  }
  return PartnerProductFilterCounts(
    all: all,
    drafting: drafting,
    listed: listed,
    closed: closed,
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
    PartnerProductStatusFilter.drafting =>
      partnerPublishBadgeKind(product) == PartnerPublishBadgeKind.drafting,
    PartnerProductStatusFilter.listed => product.isListedPublicly,
    PartnerProductStatusFilter.closed =>
      partnerPublishBadgeKind(product) == PartnerPublishBadgeKind.closed,
  };
}

/// Menu card: open same-boat seats across listed products (remaining).
int partnerOpenSameBoatSeatTotal(Iterable<ShopProduct> products) {
  var total = 0;
  for (final product in products) {
    if (!product.isListedPublicly) {
      continue;
    }
    total += partnerSameBoatLiveSummary(product).seats;
  }
  return total;
}

/// Listed base products only (빈자리 열기 picker).
List<ShopProduct> partnerListedBaseProducts(Iterable<ShopProduct> products) {
  return [
    for (final product in products)
      if (product.isListedPublicly) product,
  ];
}

/// Common add-ons (not nested under an individual SKU).
List<ShopProductOption> partnerCommonAddons(ShopProduct product) {
  return [
    for (final option in product.options)
      if (option.kind == ProductOptionKind.addon &&
          option.parentOptionId.trim().isEmpty)
        option,
  ];
}

List<ShopProductOption> partnerIndividualOptions(ShopProduct product) {
  return [
    for (final option in product.options)
      if (option.kind == ProductOptionKind.individual) option,
  ];
}

/// True when close should warn about open seats or live holds.
bool partnerNeedsCloseSeatWarning(
  ShopProduct product, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  if (product.hasLiveSameBoatOffer) {
    return true;
  }
  for (final hold in product.flagHolds) {
    if (hold.expiresAt.isAfter(clock)) {
      return true;
    }
  }
  for (final option in product.options) {
    for (final hold in option.flagHolds) {
      if (hold.expiresAt.isAfter(clock)) {
        return true;
      }
    }
  }
  return false;
}

/// Seat count shown in the close-confirm dialog.
int partnerCloseWarningSeatCount(
  ShopProduct product, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  var seats = partnerSameBoatLiveSummary(product).seats;
  for (final hold in product.flagHolds) {
    if (hold.expiresAt.isAfter(clock)) {
      seats += hold.seats;
    }
  }
  for (final option in product.options) {
    for (final hold in option.flagHolds) {
      if (hold.expiresAt.isAfter(clock)) {
        seats += hold.seats;
      }
    }
  }
  return seats < 0 ? 0 : seats;
}

/// Whether discarding an option should close (bookable=false) instead of delete.
bool partnerOptionDiscardBecomesClose(
  ShopProductOption option, {
  DateTime? now,
}) {
  return optionHasSeatCommitment(option, now: now);
}
