import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(DiverStoreScope.of(context).ensureSalesBookingsLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return adminScreenShell(
      embedded: widget.embedded,
      title: l10n.adminBookingsTitle,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final bookings = [...store.salesBookings]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final money = NumberFormat('#,###', 'en_US');
          return RefreshIndicator(
            onRefresh: store.refreshSalesBookings,
            child: bookings.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.4,
                        child: Center(child: Text(l10n.adminBookingsEmpty)),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: bookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return _AdminBookingTile(booking: booking, money: money);
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _AdminBookingTile extends StatelessWidget {
  const _AdminBookingTile({
    required this.booking,
    required this.money,
  });

  final TourBooking booking;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final status = switch (booking.status) {
      BookingStatus.requested => l10n.bookingRequested,
      BookingStatus.confirmed => l10n.bookingConfirmed,
      BookingStatus.cancelled => l10n.bookingCancelled,
      BookingStatus.weatherCancelled => l10n.bookingWeatherCancelled,
    };
    final payment = switch (booking.paymentStatus) {
      PaymentStatus.unpaid => l10n.bookingPaymentUnpaid,
      PaymentStatus.captured => l10n.bookingPaymentCaptured,
      PaymentStatus.refunded => l10n.bookingPaymentRefunded,
    };

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
              '${booking.shopName} · '
              '${DateFormat('yyyy.MM.dd').format(booking.scheduledFor)}\n'
              '$status · $payment · '
              '${l10n.explorePriceWon(money.format(booking.price))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (booking.awaitsShopConfirm) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  key: Key('admin-confirm-${booking.id}'),
                  onPressed: () async {
                    final ok = await store.confirmShopBooking(
                      shopId: booking.shopId,
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
                  ),
                  child: Text(l10n.bookingConfirmAndCapture),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
