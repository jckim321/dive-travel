import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_settlement_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_voucher_logic.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Partner reservation vouchers (시안 24). Replaces H0 temp bookings list.
class PartnerVouchersScreen extends StatefulWidget {
  const PartnerVouchersScreen({super.key, required this.shopId});

  final String shopId;

  @override
  State<PartnerVouchersScreen> createState() => _PartnerVouchersScreenState();
}

class _PartnerVouchersScreenState extends State<PartnerVouchersScreen> {
  PartnerVoucherTab _tab = PartnerVoucherTab.arrived;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return PartnerTheme.wrap(
      Scaffold(
        appBar: AppBar(
          leading: const PartnerBackButton(),
          title: Text(l10n.partnerVouchersTitle),
        ),
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final bookings = store.shopBookings;
            final counts = partnerVoucherTabCounts(bookings);
            final visible = filterPartnerVouchers(
              bookings: bookings,
              tab: _tab,
            );

            return ListView(
              key: const Key('partner-vouchers'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                DecoratedBox(
                  key: const Key('partner-vouchers-guide'),
                  decoration: BoxDecoration(
                    color: PartnerTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: PartnerTheme.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Text(
                      l10n.partnerVouchersGuide,
                      style: const TextStyle(
                        color: PartnerTheme.text,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TabChip(
                      keyName: 'partner-voucher-tab-arrived',
                      label: l10n.partnerVoucherTabArrived(counts.arrived),
                      selected: _tab == PartnerVoucherTab.arrived,
                      onTap: () => setState(
                        () => _tab = PartnerVoucherTab.arrived,
                      ),
                    ),
                    _TabChip(
                      keyName: 'partner-voucher-tab-past',
                      label: l10n.partnerVoucherTabPast,
                      selected: _tab == PartnerVoucherTab.past,
                      onTap: () => setState(
                        () => _tab = PartnerVoucherTab.past,
                      ),
                    ),
                    _TabChip(
                      keyName: 'partner-voucher-tab-cancelled',
                      label: l10n.partnerVoucherTabCancelled(counts.cancelled),
                      selected: _tab == PartnerVoucherTab.cancelled,
                      onTap: () => setState(
                        () => _tab = PartnerVoucherTab.cancelled,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        key: const Key('partner-vouchers-empty'),
                        l10n.partnerVouchersEmpty,
                        style: const TextStyle(color: PartnerTheme.textDim),
                      ),
                    ),
                  )
                else
                  for (final booking in visible) ...[
                    PartnerVoucherCard(
                      booking: booking,
                      shopId: widget.shopId,
                      tab: _tab,
                    ),
                    const SizedBox(height: 10),
                  ],
                if (_tab == PartnerVoucherTab.cancelled &&
                    counts.cancelled > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.partnerVoucherCancelOpsNote,
                    style: const TextStyle(
                      color: PartnerTheme.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Card(
                  key: const Key('partner-vouchers-settlement'),
                  child: ListTile(
                    title: Text(l10n.partnerVoucherSettlementTitle),
                    subtitle: Text(l10n.partnerVoucherSettlementSub),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PartnerSettlementScreen(
                          shopId: widget.shopId,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.keyName,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      key: Key(keyName),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: PartnerTheme.accent,
      checkmarkColor: PartnerTheme.bg,
      labelStyle: TextStyle(
        color: selected ? PartnerTheme.bg : PartnerTheme.text,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected ? PartnerTheme.accent : PartnerTheme.borderStrong,
      ),
      backgroundColor: PartnerTheme.card,
    );
  }
}

class PartnerVoucherCard extends StatelessWidget {
  const PartnerVoucherCard({
    super.key,
    required this.booking,
    required this.shopId,
    required this.tab,
  });

  final TourBooking booking;
  final String shopId;
  final PartnerVoucherTab tab;

  static final _day = DateFormat('M월 d일');
  static final _stamp = DateFormat('M월 d일 HH:mm');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unread = tab != PartnerVoucherTab.cancelled && !booking.partnerAcked;
    final status = partnerVoucherStatusKind(booking);
    final foc = partnerVoucherFocLabel(booking);
    final option = booking.optionLabel;

    return Card(
      key: Key('partner-voucher-${booking.id}'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: unread ? PartnerTheme.accent : PartnerTheme.border,
          width: unread ? 1.6 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l10n.partnerVoucherTitleLine(
                      booking.id,
                      booking.productLabel,
                    ),
                    style: const TextStyle(
                      color: PartnerTheme.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (unread)
                      _Badge(
                        label: l10n.partnerVoucherJustArrived,
                        fg: PartnerTheme.badgeGreenFg,
                        bg: PartnerTheme.badgeGreenBg,
                      ),
                    const SizedBox(height: 4),
                    _StatusBadge(kind: status, l10n: l10n),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _line(l10n.partnerVoucherTourDate, _day.format(booking.scheduledFor)),
            _line(
              l10n.partnerVoucherParty,
              booking.hasPartyDetail
                  ? l10n.partnerVoucherPartyDetail(
                      booking.divers,
                      booking.nondivers,
                    )
                  : (booking.partySize > 0
                      ? '${booking.partySize}'
                      : l10n.partnerVoucherNone),
            ),
            _line(
              l10n.partnerVoucherOptions,
              option.isEmpty ? l10n.partnerVoucherNone : option,
            ),
            _line(
              l10n.partnerVoucherFoc,
              foc ?? l10n.partnerVoucherNone,
            ),
            _line(
              l10n.partnerVoucherGuestName,
              booking.guestDisplayName.trim().isEmpty
                  ? l10n.partnerVoucherGuestNameMissing
                  : booking.guestDisplayName.trim(),
            ),
            _line(
              l10n.partnerVoucherRequests,
              l10n.partnerVoucherNone,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.partnerVoucherCreatedStamp(
                _stamp.format(booking.createdAt),
              ),
              style: const TextStyle(
                color: PartnerTheme.textDim,
                fontSize: 12,
              ),
            ),
            if (tab == PartnerVoucherTab.cancelled) ...[
              const SizedBox(height: 8),
              Text(
                l10n.partnerVoucherCancelCardBody(
                  booking.productLabel,
                  _day.format(booking.scheduledFor),
                  booking.hasPartyDetail
                      ? booking.divers
                      : booking.partySize,
                ),
                style: const TextStyle(
                  color: PartnerTheme.textDim,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (unread)
                  FilledButton(
                    key: Key('partner-voucher-ack-${booking.id}'),
                    onPressed: () => DiverStoreScope.of(context)
                        .ackPartnerBooking(
                          shopId: shopId,
                          bookingId: booking.id,
                        ),
                    child: Text(l10n.partnerVoucherAck),
                  ),
                OutlinedButton(
                  key: Key(
                    unread
                        ? 'partner-voucher-print-${booking.id}'
                        : 'partner-voucher-view-${booking.id}',
                  ),
                  onPressed: () => _openDetail(context),
                  child: Text(
                    unread
                        ? l10n.partnerVoucherSavePrint
                        : l10n.partnerVoucherView,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: PartnerTheme.text,
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PartnerVoucherDetailScreen(
          booking: booking,
          shopId: shopId,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.kind, required this.l10n});

  final PartnerVoucherStatusKind kind;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (kind) {
      PartnerVoucherStatusKind.awaitingConfirm => (
          l10n.partnerVoucherStatusAwaiting,
          PartnerTheme.badgeOrangeFg,
          PartnerTheme.badgeOrangeBg,
        ),
      PartnerVoucherStatusKind.confirmed => (
          l10n.partnerVoucherStatusConfirmed,
          PartnerTheme.badgeGreenFg,
          PartnerTheme.badgeGreenBg,
        ),
      PartnerVoucherStatusKind.cancelled => (
          l10n.partnerVoucherStatusCancelled,
          const Color(0xFFFFB4B4),
          const Color(0xFF4A1C1C),
        ),
    };
    return _Badge(label: label, fg: fg, bg: bg);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.fg,
    required this.bg,
  });

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Simple partner voucher detail + share/print.
class PartnerVoucherDetailScreen extends StatelessWidget {
  const PartnerVoucherDetailScreen({
    super.key,
    required this.booking,
    required this.shopId,
  });

  final TourBooking booking;
  final String shopId;

  static final _day = DateFormat('yyyy.MM.dd');
  static final _stamp = DateFormat('yyyy.MM.dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final body = _plainText(l10n);

    return PartnerTheme.wrap(
      Scaffold(
        appBar: AppBar(
          leading: const PartnerBackButton(),
          title: Text(l10n.partnerVoucherView),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            SelectableText(
              body,
              style: const TextStyle(
                color: PartnerTheme.text,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: Key('partner-voucher-share-${booking.id}'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: body));
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.partnerVoucherCopied)),
                );
              },
              child: Text(l10n.partnerVoucherSavePrint),
            ),
          ],
        ),
      ),
    );
  }

  String _plainText(AppLocalizations l10n) {
    final foc = partnerVoucherFocLabel(booking);
    final option = booking.optionLabel;
    return [
      l10n.partnerVoucherTitleLine(booking.id, booking.productLabel),
      '${l10n.partnerVoucherTourDate}: ${_day.format(booking.scheduledFor)}',
      '${l10n.partnerVoucherParty}: ${booking.hasPartyDetail ? l10n.partnerVoucherPartyDetail(booking.divers, booking.nondivers) : booking.partySize}',
      '${l10n.partnerVoucherOptions}: ${option.isEmpty ? l10n.partnerVoucherNone : option}',
      '${l10n.partnerVoucherFoc}: ${foc ?? l10n.partnerVoucherNone}',
      '${l10n.partnerVoucherGuestName}: ${booking.guestDisplayName.trim().isEmpty ? l10n.partnerVoucherGuestNameMissing : booking.guestDisplayName.trim()}',
      '${l10n.partnerVoucherRequests}: ${l10n.partnerVoucherNone}',
      l10n.partnerVoucherCreatedStamp(_stamp.format(booking.createdAt)),
    ].join('\n');
  }
}
