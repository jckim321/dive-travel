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

  /// Admin → approved. Non-admin keeps an existing approved listing live;
  /// otherwise pending for the monitor queue.
  static SameBoatStatus statusWhenOpen({
    required bool isAdmin,
    required SameBoatStatus previous,
  }) {
    if (isAdmin) {
      return SameBoatStatus.approved;
    }
    if (previous == SameBoatStatus.approved) {
      return SameBoatStatus.approved;
    }
    return SameBoatStatus.pending;
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
