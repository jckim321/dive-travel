import 'package:flutter/material.dart';

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
  const MyBookingsSection({super.key, required this.bookings});

  static final sectionKey = GlobalKey(debugLabel: 'my-bookings-section');

  final List<TourBooking> bookings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (bookings.isEmpty) {
      return const SizedBox.shrink();
    }

    return KeyedSubtree(
      key: sectionKey,
      child: Column(
        key: const Key('my-bookings-section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: l10n.exploreMyBookings),
          const SizedBox(height: 14),
          for (final booking in bookings) ...[
            AppCard(
              onTap: booking.reviewed
                  ? null
                  : () => openOperationReview(
                        context,
                        shopId: booking.shopId,
                        bookingId: booking.id,
                      ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.shopName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${booking.productName}\n${_bookingStatus(l10n, booking)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (booking.isActive)
                    Column(
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
                    )
                  else
                    Text(
                      booking.isWeatherCancelled
                          ? l10n.bookingWeatherCancelled
                          : l10n.bookingCancelled,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  String _bookingStatus(AppLocalizations l10n, TourBooking booking) {
    switch (booking.status) {
      case BookingStatus.cancelled:
        return l10n.bookingCancelledRefund(booking.refundPercent);
      case BookingStatus.weatherCancelled:
        return l10n.bookingWeatherCancelled;
      case BookingStatus.confirmed:
        final quote = RefundPolicy.forUserCancel(
          tourDate: booking.scheduledFor,
        );
        return '${l10n.bookingConfirmed} · ${l10n.refundPolicyHint(quote.percent)}';
    }
  }
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
