import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Temporary partner confirm until H3b auto-confirm after payment.
///
/// **H3b removal:** delete this file and its call sites only.
class PartnerTempConfirmButton extends StatelessWidget {
  const PartnerTempConfirmButton({
    super.key,
    required this.shopId,
    required this.booking,
  });

  final String shopId;
  final TourBooking booking;

  /// Show only for active `requested` bookings (H3 temporary).
  static bool shouldShow(TourBooking booking) =>
      booking.isActive && booking.status == BookingStatus.requested;

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(booking)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    return OutlinedButton(
      key: Key('partner-temp-confirm-${booking.id}'),
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
              ok ? l10n.bookingConfirmDone : l10n.bookingConfirmFailed,
            ),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: PartnerTheme.orange,
        side: const BorderSide(color: PartnerTheme.orange),
      ),
      child: Text(l10n.partnerVoucherTempConfirm),
    );
  }
}
