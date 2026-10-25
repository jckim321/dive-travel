import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_settlement_logic.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Partner settlement by booking receive month ([TourBooking.createdAt]).
class PartnerSettlementScreen extends StatefulWidget {
  const PartnerSettlementScreen({super.key, required this.shopId});

  final String shopId;

  @override
  State<PartnerSettlementScreen> createState() =>
      _PartnerSettlementScreenState();
}

class _PartnerSettlementScreenState extends State<PartnerSettlementScreen> {
  static final _money = NumberFormat('#,###', 'en_US');
  static final _day = DateFormat('M월 d일');

  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _shiftMonth(int delta) {
    var m = _month + delta;
    var y = _year;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    setState(() {
      _year = y;
      _month = m;
    });
  }

  String _statusLabel(AppLocalizations l10n, TourBooking b) {
    if (b.status == BookingStatus.weatherCancelled) {
      return l10n.bookingWeatherCancelled;
    }
    if (b.status == BookingStatus.cancelled) {
      return l10n.partnerVoucherStatusCancelled;
    }
    if (b.status == BookingStatus.confirmed && b.isPaid) {
      return l10n.partnerVoucherStatusConfirmed;
    }
    return l10n.partnerVoucherStatusAwaiting;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return PartnerTheme.wrap(
      Scaffold(
        appBar: AppBar(
          leading: const PartnerBackButton(),
          title: Text(l10n.partnerQuickSettlement),
        ),
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final summary = computePartnerSettlementMonth(
              bookings: store.shopBookings,
              year: _year,
              month: _month,
            );

            return ListView(
              key: const Key('partner-settlement'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  l10n.partnerSettlementSimPayNote,
                  style: const TextStyle(
                    color: PartnerTheme.textDim,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                _MonthHeader(
                  label: l10n.partnerSettlementMonthLabel(_year, _month),
                  onPrev: () => _shiftMonth(-1),
                  onNext: () => _shiftMonth(1),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.partnerSettlementByReceiveDate,
                  style: const TextStyle(
                    color: PartnerTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  key: const Key('partner-settlement-summary'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      children: [
                        _metricRow(
                          l10n.partnerSettlementValidCount,
                          l10n.partnerSettlementCountValue(summary.validCount),
                        ),
                        _metricRow(
                          l10n.partnerSettlementCancelledCount,
                          l10n.partnerSettlementCountValue(
                            summary.cancelledCount,
                          ),
                        ),
                        const Divider(height: 20, color: PartnerTheme.border),
                        _metricRow(
                          l10n.partnerSettlementGross,
                          '₩${_money.format(summary.grossPaid)}',
                        ),
                        _metricRow(
                          l10n.partnerSettlementRefunds,
                          '₩${_money.format(summary.refundTotal)}',
                        ),
                        _metricRow(
                          l10n.partnerSettlementNet,
                          '₩${_money.format(summary.netSales)}',
                          emphasize: true,
                        ),
                        const Divider(height: 20, color: PartnerTheme.border),
                        _metricRow(
                          l10n.partnerFee,
                          l10n.partnerSettlementFeePending,
                        ),
                        _metricRow(
                          l10n.partnerNet,
                          l10n.partnerSettlementFeePending,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.partnerSettlementListTitle,
                  style: const TextStyle(
                    color: PartnerTheme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (summary.rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        key: const Key('partner-settlement-empty'),
                        l10n.partnerSettlementEmpty,
                        style: const TextStyle(color: PartnerTheme.textDim),
                      ),
                    ),
                  )
                else
                  for (final b in summary.rows) ...[
                    Card(
                      key: Key('partner-settlement-row-${b.id}'),
                      child: ListTile(
                        title: Text(
                          b.productLabel,
                          style: const TextStyle(
                            color: PartnerTheme.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${_day.format(b.createdAt)} · ${_statusLabel(l10n, b)}',
                          style: const TextStyle(
                            color: PartnerTheme.textDim,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Text(
                          '₩${_money.format(b.price)}',
                          style: const TextStyle(
                            color: PartnerTheme.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasize ? PartnerTheme.text : PartnerTheme.textDim,
                fontSize: 13,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasize ? PartnerTheme.accent : PartnerTheme.text,
              fontSize: emphasize ? 16 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const Key('partner-settlement-prev-month'),
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, color: PartnerTheme.text),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PartnerTheme.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          key: const Key('partner-settlement-next-month'),
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, color: PartnerTheme.text),
        ),
      ],
    );
  }
}
