import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/refund_policy.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/features/community/presentation/open_tide_room.dart';
import 'package:dive_travel_app/features/reviews/presentation/operation_review_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Shared booking list for Profile (and scroll target from Explore banner).
class MyBookingsSection extends StatelessWidget {
  const MyBookingsSection({super.key, this.bookings});

  static final sectionKey = GlobalKey(debugLabel: 'my-bookings-section');

  /// When null, listens to [DiverStore.bookings] so the sheet stays live.
  final List<TourBooking>? bookings;

  @override
  Widget build(BuildContext context) {
    final store = DiverStoreScope.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = bookings ?? store.bookings;
        final flags = store.myLiveFlags();
        return KeyedSubtree(
          key: sectionKey,
          child: _BookingList(bookings: list, flags: flags),
        );
      },
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.bookings, required this.flags});

  final List<TourBooking> bookings;
  final List<SameBoatOffer> flags;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (bookings.isEmpty && flags.isEmpty) {
      return KeyedSubtree(
        key: const Key('my-bookings-section'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            l10n.bookingListEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: const Key('my-bookings-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: l10n.exploreMyBookings),
          const SizedBox(height: 14),
          for (final booking in bookings) ...[
            _ReservationRow(
              productName: booking.productLabel,
              optionName: booking.optionLabel,
              statusLabel: _combinedStatusLabel(l10n, booking),
              statusTone: _combinedTone(booking),
              onStatus: () => openBookingDetail(context, booking),
              onDetail: () => openBookingDetail(context, booking),
            ),
            const SizedBox(height: 12),
          ],
          for (final offer in flags) ...[
            _ReservationRow(
              productName: offer.product.name,
              optionName: offer.optionName,
              statusLabel: l10n.profileBookingFilterHolding,
              statusTone: _ChipTone.gold,
              onStatus: () => _openFlagDetail(context, offer),
              onDetail: () => _openFlagDetail(context, offer),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Public entry so Profile boards can open the same detail sheet.
void openBookingDetail(BuildContext context, TourBooking booking) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _BookingDetailSheet(booking: booking),
  );
}

void _openFlagDetail(BuildContext context, SameBoatOffer offer) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _FlagDetailSheet(offer: offer),
  );
}

class _ReservationRow extends StatelessWidget {
  const _ReservationRow({
    required this.productName,
    required this.optionName,
    required this.statusLabel,
    required this.statusTone,
    required this.onStatus,
    required this.onDetail,
  });

  final String productName;
  final String optionName;
  final String statusLabel;
  final _ChipTone statusTone;
  final VoidCallback onStatus;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (optionName.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    optionName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusButton(
                label: statusLabel,
                tone: statusTone,
                onPressed: onStatus,
              ),
              const SizedBox(height: 6),
              TextButton(
                key: const Key('booking-detail-cta'),
                onPressed: onDetail,
                child: Text(l10n.bookingDetailCta),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.tone,
    required this.onPressed,
  });

  final String label;
  final _ChipTone tone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _ChipTone.muted => (const Color(0xFFF0F2F4), AppTheme.muted),
      _ChipTone.navy => (const Color(0xFFE8EEF2), AppTheme.navy),
      _ChipTone.gold => (AppTheme.goldSoft, const Color(0xFF8A6A12)),
      _ChipTone.danger => (const Color(0xFFFCE8EC), const Color(0xFFB42318)),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingDetailSheet extends StatelessWidget {
  const _BookingDetailSheet({required this.booking});

  final TourBooking booking;

  static final _money = NumberFormat('#,###', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final refund = booking.status == BookingStatus.cancelled
        ? null
        : RefundPolicy.forUserCancel(tourDate: booking.scheduledFor);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canReview = booking.isActive &&
        !booking.reviewed &&
        booking.scheduledFor.isBefore(DateTime.now());

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookingDetailTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              booking.productLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (booking.optionLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                booking.optionLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(booking.shopName, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _StatusChip(
                  label: _bookingStatusLabel(l10n, booking),
                  tone: _bookingTone(booking),
                ),
                _StatusChip(
                  label: _paymentStatusLabel(l10n, booking),
                  tone: _paymentTone(booking),
                ),
                if (booking.fromFlag)
                  _StatusChip(
                    label: l10n.profileBookingFilterHolding,
                    tone: _ChipTone.gold,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _DetailRow(
              label: l10n.weatherTourDate,
              value: DateFormat('yyyy.MM.dd').format(booking.scheduledFor),
            ),
            _DetailRow(
              label: l10n.checkoutGuests,
              value: booking.hasPartyDetail
                  ? l10n.bookingPartySummary(
                      booking.divers,
                      booking.nondivers,
                      booking.children,
                      booking.infants,
                    )
                  : '${booking.partySize}',
            ),
            _DetailRow(
              label: l10n.checkoutStepPay,
              value: l10n.explorePriceWon(_money.format(booking.price)),
            ),
            _DetailRow(
              label: l10n.bookingCreatedAt,
              value: DateFormat('yyyy.MM.dd HH:mm').format(booking.createdAt),
            ),
            if (booking.quoteLines.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                l10n.bookingQuoteBreakdown,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final line in booking.quoteLines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(line.label)),
                      Text(_money.format(line.amount)),
                    ],
                  ),
                ),
            ],
            if (refund != null && booking.isActive) ...[
              const SizedBox(height: 12),
              Text(
                l10n.refundPolicyHint(refund.percent),
                style:
                    theme.textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ],
            if (booking.status == BookingStatus.cancelled)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  l10n.bookingCancelledRefund(booking.refundPercent),
                ),
              ),
            if (booking.isActive) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        openTideRoomForBooking(
                          context: context,
                          booking: booking,
                        );
                      },
                      child: Text(l10n.communityPlantFlag),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await DiverStoreScope.of(context)
                            .cancelBookingAsGuest(booking.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(l10n.bookingCancel),
                    ),
                  ),
                ],
              ),
            ],
            if (canReview) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openOperationReview(
                      context,
                      shopId: booking.shopId,
                      bookingId: booking.id,
                      productId: booking.productId,
                    );
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.navy),
                  child: Text(l10n.reviewWrite),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FlagDetailSheet extends StatelessWidget {
  const _FlagDetailSheet({required this.offer});

  final SameBoatOffer offer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final product = offer.product;
    final option = offer.option;
    final departure = option?.departureStart ?? product.departureStart;
    final flagCloses = option?.flagClosesAt ?? product.flagClosesAt;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookingDetailTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (offer.optionName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                offer.optionName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _StatusChip(
              label: l10n.profileBookingFilterHolding,
              tone: _ChipTone.gold,
            ),
            const SizedBox(height: 16),
            if (departure != null)
              _DetailRow(
                label: l10n.workbenchDepartureDate,
                value: DateFormat('yyyy.MM.dd').format(departure),
              ),
            if (flagCloses != null)
              _DetailRow(
                label: l10n.workbenchFlagDeadline,
                value: DateFormat('yyyy.MM.dd HH:mm').format(flagCloses),
              ),
            _DetailRow(
              label: l10n.workbenchSeatCount,
              value: '${offer.remainingSeats}',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

enum _ChipTone { muted, navy, gold, danger }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _ChipTone.muted => (const Color(0xFFF0F2F4), AppTheme.muted),
      _ChipTone.navy => (const Color(0xFFE8EEF2), AppTheme.navy),
      _ChipTone.gold => (AppTheme.goldSoft, const Color(0xFF8A6A12)),
      _ChipTone.danger => (const Color(0xFFFCE8EC), const Color(0xFFB42318)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

String _combinedStatusLabel(AppLocalizations l10n, TourBooking booking) {
  if (!booking.isActive) {
    return _bookingStatusLabel(l10n, booking);
  }
  if (booking.isPaid) {
    return l10n.bookingPaymentCaptured;
  }
  if (booking.status == BookingStatus.requested) {
    return l10n.bookingRequested;
  }
  return '${l10n.bookingConfirmed} · ${l10n.bookingPaymentUnpaid}';
}

_ChipTone _combinedTone(TourBooking booking) {
  if (!booking.isActive) {
    return _ChipTone.danger;
  }
  if (booking.isPaid) {
    return _ChipTone.navy;
  }
  if (booking.status == BookingStatus.requested) {
    return _ChipTone.gold;
  }
  return _ChipTone.muted;
}

String _bookingStatusLabel(AppLocalizations l10n, TourBooking booking) {
  return switch (booking.status) {
    BookingStatus.requested => l10n.bookingRequested,
    BookingStatus.confirmed => l10n.bookingConfirmed,
    BookingStatus.cancelled => l10n.bookingCancelled,
    BookingStatus.weatherCancelled => l10n.bookingWeatherCancelled,
  };
}

String _paymentStatusLabel(AppLocalizations l10n, TourBooking booking) {
  return switch (booking.paymentStatus) {
    PaymentStatus.unpaid => l10n.bookingPaymentUnpaid,
    PaymentStatus.captured => l10n.bookingPaymentCaptured,
    PaymentStatus.refunded => l10n.bookingPaymentRefunded,
  };
}

_ChipTone _bookingTone(TourBooking booking) {
  return switch (booking.status) {
    BookingStatus.requested => _ChipTone.gold,
    BookingStatus.confirmed => _ChipTone.navy,
    BookingStatus.cancelled || BookingStatus.weatherCancelled =>
      _ChipTone.danger,
  };
}

_ChipTone _paymentTone(TourBooking booking) {
  return switch (booking.paymentStatus) {
    PaymentStatus.unpaid => _ChipTone.muted,
    PaymentStatus.captured => _ChipTone.navy,
    PaymentStatus.refunded => _ChipTone.danger,
  };
}

/// One-line upcoming departure chip on Explore.
class DepartureTripBanner extends StatelessWidget {
  const DepartureTripBanner({
    super.key,
    required this.days,
    required this.shopName,
    required this.onTap,
  });

  final int days;
  final String shopName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Material(
      color: const Color(0xFFE8EEF2),
      borderRadius: BorderRadius.circular(AppTheme.radiusTight),
      child: InkWell(
        key: const Key('explore-departure-banner'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusTight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.flight_takeoff_outlined,
                size: 18,
                color: AppTheme.navy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.exploreDepartureBanner(days, shopName),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppTheme.navy),
            ],
          ),
        ),
      ),
    );
  }
}
