import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_settlement_logic.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class _ShopSettlement {
  const _ShopSettlement({
    required this.shopId,
    required this.name,
    required this.month,
    required this.fee,
  });

  final String shopId;
  final String name;
  final PartnerSettlementMonth month;
  final PartnerSettlementFee fee;
}

/// Admin settlement history. Same receive-month net as the partner screen,
/// times the shop's stored commission rate.
class AdminSettlementHistoryPane extends StatefulWidget {
  const AdminSettlementHistoryPane({super.key});

  @override
  State<AdminSettlementHistoryPane> createState() =>
      _AdminSettlementHistoryPaneState();
}

class _AdminSettlementHistoryPaneState extends State<AdminSettlementHistoryPane> {
  static final _money = NumberFormat('#,###', 'en_US');

  late int _year;
  late int _month;
  var _loading = true;
  String? _error;
  List<_ShopSettlement> _rows = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _shiftMonth(int delta) {
    var month = _month + delta;
    var year = _year;
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    while (month > 12) {
      month -= 12;
      year += 1;
    }
    setState(() {
      _year = year;
      _month = month;
    });
    _load();
  }

  Future<void> _load() async {
    final store = DiverStoreScope.of(context);
    final year = _year;
    final month = _month;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await store.ensureShopStatsLoaded();
      final start = DateTime(year, month);
      final end = DateTime(year, month + 1);
      final bookings = await store.loadAdminAnalyticsBookings(
        start: start,
        end: end,
      );
      final byShop = <String, List<TourBooking>>{};
      for (final booking in bookings) {
        byShop.putIfAbsent(booking.shopId, () => []).add(booking);
      }
      final shops = [...store.shopStats]
        ..sort((a, b) => (a.name ?? a.shopId).compareTo(b.name ?? b.shopId));
      final rows = <_ShopSettlement>[];
      for (final shop in shops) {
        final terms = await store.getPartnerContractTerms(shop.shopId);
        final summary = computePartnerSettlementMonth(
          bookings: byShop[shop.shopId] ?? const [],
          year: year,
          month: month,
        );
        rows.add(
          _ShopSettlement(
            shopId: shop.shopId,
            name: _shopName(shop),
            month: summary,
            fee: PartnerSettlementFee(
              netSales: summary.netSales,
              ratePercent: terms?.commissionRatePercent,
            ),
          ),
        );
      }
      if (!mounted || year != _year || month != _month) {
        return;
      }
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || year != _year || month != _month) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  String _shopName(ShopLiveStats shop) {
    final name = shop.name?.trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }
    return shop.shopId;
  }

  String _amount(AppLocalizations l10n, int? amount) {
    if (amount == null) {
      return l10n.partnerSettlementRateMissing;
    }
    return '₩${_money.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      key: const Key('admin-settlement-history'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                l10n.partnerSettlementMonthLabel(_year, _month),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Text(
          l10n.partnerSettlementByReceiveDate,
          style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: AdminConsoleTheme.muted))
        else if (_rows.isEmpty)
          Text(
            l10n.partnerSettlementEmpty,
            style: const TextStyle(color: AdminConsoleTheme.muted),
          )
        else
          for (final row in _rows) ...[
            Container(
              key: Key('admin-settlement-${row.shopId}'),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AdminConsoleTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminConsoleTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  _line(
                    l10n.partnerSettlementGross,
                    '₩${_money.format(row.month.grossPaid)}',
                  ),
                  _line(
                    l10n.partnerSettlementRefunds,
                    '₩${_money.format(row.month.refundTotal)}',
                  ),
                  _line(
                    l10n.partnerSettlementNet,
                    '₩${_money.format(row.month.netSales)}',
                  ),
                  _line(l10n.partnerFee, _amount(l10n, row.fee.fee)),
                  _line(l10n.partnerNet, _amount(l10n, row.fee.payout)),
                ],
              ),
            ),
          ],
      ],
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AdminConsoleTheme.muted),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
