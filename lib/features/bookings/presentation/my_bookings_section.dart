import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/refund_policy.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
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
        return KeyedSubtree(
          key: sectionKey,
          child: _BookingList(bookings: list),
        );
      },
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.bookings});

  final List<TourBooking> bookings;

  static final _money = NumberFormat('#,###', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (bookings.isEmpty) {
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
            AppCard(
              onTap: () => _openDetail(context, booking),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.displayTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.shopName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${DateFormat('yyyy.MM.dd').format(booking.scheduledFor)}'
                    ' · ${_partyLine(l10n, booking)}'
                    ' · ${l10n.explorePriceWon(_money.format(booking.price))}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (booking.isActive) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => openTideRoomForBooking(
                            context: context,
                            booking: booking,
                          ),
                          child: Text(l10n.communityPlantFlag),
                        ),
                        TextButton(
                          onPressed: () => DiverStoreScope.of(context)
                              .cancelBookingAsGuest(booking.id),
                          child: Text(l10n.bookingCancel),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, TourBooking booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _BookingDetailSheet(booking: booking),
    );
  }

  String _partyLine(AppLocalizations l10n, TourBooking booking) {
    if (booking.hasPartyDetail) {
      return l10n.bookingPartySummary(
        booking.divers,
        booking.nondivers,
        booking.children,
        booking.infants,
      );
    }
    if (booking.partySize > 0) {
      return '${l10n.checkoutGuests} ${booking.partySize}';
    }
    return l10n.checkoutGuests;
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

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.displayTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(booking.shopName, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
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
            ],
          ),
          const SizedBox(height: 16),
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
          if (booking.quoteLines.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.bookingQuoteBreakdown,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final line in booking.quoteLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(line.label)),
                    Text(_money.format(line.amount)),
                  ],
                ),
              ),
          ],
          if (refund != null && booking.isActive) ...[
            const SizedBox(height: 10),
            Text(
              l10n.refundPolicyHint(refund.percent),
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
          if (booking.status == BookingStatus.cancelled)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(l10n.bookingCancelledRefund(booking.refundPercent)),
            ),
          if (canReview) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                openOperationReview(
                  context,
                  shopId: booking.shopId,
                  bookingId: booking.id,
                );
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.navy),
              child: Text(l10n.reviewWrite),
            ),
          ],
        ],
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
            width: 88,
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
