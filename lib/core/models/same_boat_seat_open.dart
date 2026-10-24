import 'package:dive_travel_app/core/models/shop_product.dart';

/// Pure helpers for opening leftover seats from product forms / seats screen.
///
/// Does not touch plant / createBooking / cancel transactions.
abstract final class SameBoatSeatOpenLogic {
  static bool wasAlreadyOpen({
    required bool openEmptySeats,
    required SameBoatStatus status,
  }) {
    return openEmptySeats || status != SameBoatStatus.closed;
  }

  static int liveHoldSeats(List<SeatHold> holds, DateTime now) {
    var total = 0;
    for (final hold in holds) {
      if (hold.expiresAt.isAfter(now)) {
        total += hold.seats;
      }
    }
    return total;
  }

  /// [booked_seats] may only be set when first opening; later saves keep DB.
  static int resolveBookedSeats({
    required bool nowOpen,
    required bool wasAlreadyOpen,
    required int formBooked,
    required int existingBooked,
  }) {
    if (!nowOpen) {
      return existingBooked;
    }
    if (!wasAlreadyOpen) {
      return formBooked < 0 ? 0 : formBooked;
    }
    return existingBooked;
  }

  /// Null when ok; otherwise a machine-readable reason for UI copy.
  static SameBoatCapacityViolation? capacityViolation({
    required int capacity,
    required int booked,
    required int liveHolds,
  }) {
    final occupied = booked + liveHolds;
    if (capacity < occupied) {
      return SameBoatCapacityViolation(
        capacity: capacity,
        booked: booked,
        liveHolds: liveHolds,
      );
    }
    return null;
  }

  static int openPreviewSeats({
    required int capacity,
    required int booked,
    int liveHolds = 0,
  }) {
    final left = capacity - booked - liveHolds;
    return left < 0 ? 0 : left;
  }

  /// Open seats go live immediately (H1a). Legacy `pending` rows stay pending
  /// until an admin approves/rejects them in the monitor.
  static SameBoatStatus statusWhenOpen({
    required bool isAdmin,
    required SameBoatStatus previous,
  }) {
    if (previous == SameBoatStatus.pending) {
      // Do not auto-approve an in-flight legacy request on re-save.
      return isAdmin ? SameBoatStatus.approved : SameBoatStatus.pending;
    }
    return SameBoatStatus.approved;
  }

  /// Product- or option-level seat open fields required for board / approve.
  static bool hasCompleteSeatOpenFields({
    required bool openEmptySeats,
    required int capacity,
    required DateTime? departureStart,
  }) {
    return openEmptySeats && capacity > 0 && departureStart != null;
  }

  /// Partner may not submit again while pending or already live (product/option).
  static bool blocksPartnerRequest(ShopProduct product) {
    return product.hasPendingSameBoat || product.hasLiveSameBoatOffer;
  }

  /// Every pending unit (package and/or options) has complete seat fields.
  static bool canApprovePending(ShopProduct product) {
    if (!product.hasPendingSameBoat) {
      return false;
    }
    if (product.sameBoatStatus.isPendingReview &&
        !hasCompleteSeatOpenFields(
          openEmptySeats: product.openEmptySeats,
          capacity: product.capacity,
          departureStart: product.departureStart,
        )) {
      return false;
    }
    for (final option in product.options) {
      if (option.sameBoatStatus.isPendingReview &&
          !hasCompleteSeatOpenFields(
            openEmptySeats: option.openEmptySeats,
            capacity: option.capacity,
            departureStart: option.departureStart,
          )) {
        return false;
      }
    }
    return true;
  }
}

class SameBoatCapacityViolation {
  const SameBoatCapacityViolation({
    required this.capacity,
    required this.booked,
    required this.liveHolds,
  });

  final int capacity;
  final int booked;
  final int liveHolds;

  int get occupied => booked + liveHolds;
}
