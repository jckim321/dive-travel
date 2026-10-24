import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Temporary 「예약 바우처」 host for the former home booking list.
/// Replace in the vouchers build; keep confirm / weather-cancel behavior.
class PartnerBookingsTempScreen extends StatelessWidget {
  const PartnerBookingsTempScreen({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final money = NumberFormat('#,###', 'en_US');

    return PartnerTheme.wrap(
      Scaffold(
        appBar: AppBar(title: Text(l10n.partnerQuickBookings)),
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final bookings = store.shopBookings;
            if (bookings.isEmpty) {
              return Center(
                child: Text(
                  l10n.partnerNoBookings,
                  style: const TextStyle(color: PartnerTheme.textDim),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return PartnerBookingCard(
                  booking: bookings[index],
                  shopId: shopId,
                  money: money,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Booking row with confirm + weather cancel (moved from the old home).
class PartnerBookingCard extends StatelessWidget {
  const PartnerBookingCard({
    super.key,
    required this.booking,
    required this.shopId,
    required this.money,
  });

  final TourBooking booking;
  final String shopId;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.displayTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('yyyy.MM.dd').format(booking.scheduledFor)}\n'
              '${_partyLabel(l10n, booking)}'
              '${_statusLabel(l10n, booking)} · '
              '${l10n.explorePriceWon(money.format(booking.price))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (booking.isActive) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (booking.awaitsShopConfirm)
                    FilledButton(
                      key: Key('partner-confirm-${booking.id}'),
                      onPressed: () async {
                        final ok = await store.confirmShopBooking(
                          shopId: shopId,
                          bookingId: booking.id,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? l10n.bookingConfirmDone
                                  : l10n.bookingConfirmFailed,
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.bookingConfirmAndCapture),
                    ),
                  TextButton(
                    onPressed: () => store.cancelBookingsForWeather(
                      shopId: shopId,
                      tourDate: booking.scheduledFor,
                    ),
                    child: Text(l10n.weatherCancel),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _partyLabel(AppLocalizations l10n, TourBooking booking) {
    if (booking.hasPartyDetail) {
      return '${l10n.bookingPartySummary(
        booking.divers,
        booking.nondivers,
        booking.children,
        booking.infants,
      )}\n';
    }
    if (booking.partySize > 0) {
      return '${l10n.checkoutGuests} ${booking.partySize}\n';
    }
    return '';
  }

  String _statusLabel(AppLocalizations l10n, TourBooking booking) {
    final bookingLabel = switch (booking.status) {
      BookingStatus.requested => l10n.bookingRequested,
      BookingStatus.cancelled => l10n.bookingCancelled,
      BookingStatus.weatherCancelled => l10n.bookingWeatherCancelled,
      BookingStatus.confirmed => l10n.bookingConfirmed,
    };
    final paymentLabel = switch (booking.paymentStatus) {
      PaymentStatus.unpaid => l10n.bookingPaymentUnpaid,
      PaymentStatus.captured => l10n.bookingPaymentCaptured,
      PaymentStatus.refunded => l10n.bookingPaymentRefunded,
    };
    return '$bookingLabel · $paymentLabel';
  }
}
