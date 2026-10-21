import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

Future<void> openBookingVoucher(BuildContext context, TourBooking booking) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => BookingVoucherScreen(booking: booking),
    ),
  );
}

/// Full-screen travel voucher — open anytime and save to the phone for field use.
class BookingVoucherScreen extends StatefulWidget {
  const BookingVoucherScreen({super.key, required this.booking});

  final TourBooking booking;

  @override
  State<BookingVoucherScreen> createState() => _BookingVoucherScreenState();
}

class _BookingVoucherScreenState extends State<BookingVoucherScreen> {
  final _boundaryKey = GlobalKey();
  var _saving = false;
  static final _money = NumberFormat('#,###', 'en_US');
  static final _day = DateFormat('yyyy.MM.dd');

  Future<void> _saveToPhone() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        return;
      }
      final png = bytes.buffer.asUint8List();
      final name =
          'dive-travel-voucher-${widget.booking.id}.png'.replaceAll(' ', '_');
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(png, mimeType: 'image/png', name: name),
          ],
          fileNameOverrides: [name],
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bookingVoucherSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final booking = widget.booking;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(title: Text(l10n.bookingVoucherTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4E8EC)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DIVE TRAVEL',
                          style: theme.textTheme.labelLarge?.copyWith(
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ocean,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.bookingVoucherTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          booking.productLabel,
                          style: theme.textTheme.titleLarge?.copyWith(
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
                        const SizedBox(height: 16),
                        _row(l10n.bookingVoucherId, booking.id),
                        _row(l10n.bookingVoucherShop, booking.shopName),
                        _row(
                          l10n.workbenchDepartureDate,
                          _day.format(booking.scheduledFor),
                        ),
                        if (booking.hasPartyDetail)
                          _row(
                            l10n.checkoutGuests,
                            l10n.bookingPartySummary(
                              booking.divers,
                              booking.nondivers,
                              booking.children,
                              booking.infants,
                            ),
                          )
                        else if (booking.partySize > 0)
                          _row(
                            l10n.checkoutGuests,
                            '${booking.partySize}',
                          ),
                        _row(
                          l10n.checkoutStepPay,
                          l10n.explorePriceWon(_money.format(booking.price)),
                        ),
                        _row(
                          l10n.bookingPaymentCaptured,
                          l10n.bookingPaymentCaptured,
                        ),
                        if (booking.quoteLines.isNotEmpty) ...[
                          const Divider(height: 28),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Material(
            elevation: 8,
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
              child: FilledButton.icon(
                key: const Key('booking-voucher-save'),
                onPressed: _saving ? null : _saveToPhone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.download_rounded),
                label: Text(l10n.bookingVoucherSave),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
