import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_sales_math.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Admin sales. Numbers come from [buildAdminSalesSnapshot].
class AdminSalesScreen extends StatefulWidget {
  const AdminSalesScreen({
    super.key,
    required this.ownedShopId,
    required this.onOpenContract,
    required this.onOpenDocuments,
    required this.onOpenPartners,
  });

  final String? ownedShopId;
  final void Function(String shopId) onOpenContract;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenPartners;

  @override
  State<AdminSalesScreen> createState() => _AdminSalesScreenState();
}

class _AdminSalesScreenState extends State<AdminSalesScreen> {
  AdminSalesPreset _preset = AdminSalesPreset.thisMonth;
  AdminSalesCompare _compare = AdminSalesCompare.previous;
  DateTime? _customStart;
  DateTime? _customEnd;
  AdminSalesSnapshot? _snapshot;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = DiverStoreScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final window = adminSalesWindow(
        preset: _preset,
        now: now,
        customStart: _customStart,
        customEnd: _customEnd,
      );
      final compare = adminSalesCompareWindow(
        window: window,
        compare: _compare,
      );
      final start = window.start.isBefore(compare.start)
          ? window.start
          : compare.start;
      final end = window.end.isAfter(compare.end) ? window.end : compare.end;
      final bookings = await store.loadAdminAnalyticsBookings(
        start: start,
        end: end,
      );
      if (!mounted) {
        return;
      }
      final catalog = <AdminCatalogItem>[
        for (final stats in store.shopStats)
          for (final product in stats.products)
            AdminCatalogItem(
              shopId: stats.shopId,
              productId: product.id,
              name: product.name,
              category: product.category,
            ),
      ];
      setState(() {
        _snapshot = buildAdminSalesSnapshot(
          bookings: bookings,
          window: window,
          compareWindow: compare,
          catalog: catalog,
          ownedShopId: widget.ownedShopId,
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _preset = AdminSalesPreset.custom;
      _customStart = picked.start;
      _customEnd = picked.end;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot = _snapshot;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final header = _Header(
          l10n: l10n,
          preset: _preset,
          compare: _compare,
          loading: _loading,
          error: _error,
          snapshot: snapshot,
          wide: wide,
          onPreset: (preset) {
            if (preset == AdminSalesPreset.custom) {
              _pickCustom();
              return;
            }
            setState(() => _preset = preset);
            _load();
          },
          onCompare: (compare) {
            setState(() => _compare = compare);
            _load();
          },
        );
        final table = _PartnerTable(
          l10n: l10n,
          snapshot: snapshot,
          onOpen: (shopId) => _openShop(context, l10n, shopId),
        );
        final side = _SideColumn(l10n: l10n, snapshot: snapshot);
        if (!wide) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              header,
              const SizedBox(height: 12),
              table,
              const SizedBox(height: 12),
              side,
              const SizedBox(height: 8),
              Text(
                l10n.adminSalesBasis,
                key: const Key('admin-sales-basis'),
                style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
              ),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: table),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: ListView(children: [side])),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.adminSalesBasis,
                key: const Key('admin-sales-basis'),
                style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openShop(
    BuildContext context,
    AppLocalizations l10n,
    String shopId,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AdminConsoleTheme.surface,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('admin-sales-open-contract'),
                title: Text(l10n.adminSalesOpenContract),
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenContract(shopId);
                },
              ),
              ListTile(
                key: const Key('admin-sales-open-docs'),
                title: Text(l10n.adminSalesOpenDocs),
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenDocuments();
                },
              ),
              ListTile(
                key: const Key('admin-sales-open-partners'),
                title: Text(l10n.adminSalesOpenPartners),
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenPartners();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.l10n,
    required this.preset,
    required this.compare,
    required this.loading,
    required this.error,
    required this.snapshot,
    required this.wide,
    required this.onPreset,
    required this.onCompare,
  });

  final AppLocalizations l10n;
  final AdminSalesPreset preset;
  final AdminSalesCompare compare;
  final bool loading;
  final String? error;
  final AdminSalesSnapshot? snapshot;
  final bool wide;
  final ValueChanged<AdminSalesPreset> onPreset;
  final ValueChanged<AdminSalesCompare> onCompare;

  @override
  Widget build(BuildContext context) {
    final totals = snapshot?.totals ?? AdminSalesTotals.empty;
    final prior = snapshot?.compareTotals ?? AdminSalesTotals.empty;
    final cards = [
      _Kpi(
        cardKey: const Key('admin-sales-kpi-gross'),
        label: l10n.adminSalesGross,
        value: _won(totals.gross),
        detail: _delta(totals.gross, prior.gross, l10n),
        detailColor: _up(totals.gross, prior.gross),
        hint: '${totals.received}${l10n.adminOverviewCountUnit} · ${l10n.adminSalesBasis}',
      ),
      _Kpi(
        cardKey: const Key('admin-sales-kpi-refund'),
        label: l10n.adminSalesRefund,
        value: _won(totals.refund),
        detail: totals.cancelRate == null
            ? l10n.adminOverviewNoCompare
            : '${l10n.adminSalesColCancel} ${_pct(totals.cancelRate)}',
        detailColor: AdminConsoleTheme.muted,
      ),
      _Kpi(
        cardKey: const Key('admin-sales-kpi-net'),
        label: l10n.adminSalesNet,
        value: _won(totals.net),
        detail: _delta(totals.net, prior.net, l10n),
        detailColor: _up(totals.net, prior.net),
      ),
      _Kpi(
        cardKey: const Key('admin-sales-kpi-average'),
        label: l10n.adminSalesAverage,
        value: totals.average == null ? '—' : _won(totals.average!),
        detail: _delta(totals.average ?? 0, prior.average ?? 0, l10n),
        detailColor: _up(totals.average ?? 0, prior.average ?? 0),
      ),
      _Kpi(
        cardKey: const Key('admin-sales-kpi-partners'),
        label: l10n.adminSalesActivePartners,
        value: '${totals.activePartners}',
        detail: l10n.adminSalesActiveHint,
        detailColor: AdminConsoleTheme.muted,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final item in AdminSalesPreset.values)
              ChoiceChip(
                key: Key('admin-sales-preset-${item.name}'),
                label: Text(_presetLabel(l10n, item)),
                selected: preset == item,
                onSelected: (_) => onPreset(item),
              ),
            const SizedBox(width: 12),
            Text(
              l10n.adminSalesColDelta,
              style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
            ),
            ChoiceChip(
              key: const Key('admin-sales-compare-previous'),
              label: Text(l10n.adminSalesComparePrev),
              selected: compare == AdminSalesCompare.previous,
              onSelected: (_) => onCompare(AdminSalesCompare.previous),
            ),
            ChoiceChip(
              key: const Key('admin-sales-compare-year'),
              label: Text(l10n.adminSalesCompareYear),
              selected: compare == AdminSalesCompare.yearAgo,
              onSelected: (_) => onCompare(AdminSalesCompare.yearAgo),
            ),
          ],
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(error!, style: const TextStyle(color: AdminConsoleTheme.danger)),
          ),
        if (snapshot?.window.clamped == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.adminSalesClamped,
              key: const Key('admin-sales-clamped'),
              style: const TextStyle(color: AdminConsoleTheme.amber, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        if (wide)
          Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: cards[i]),
              ],
            ],
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.7,
            children: cards,
          ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.cardKey,
    required this.label,
    required this.value,
    required this.detail,
    required this.detailColor,
    this.hint,
  });

  final Key cardKey;
  final String label;
  final String value;
  final String detail;
  final Color detailColor;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: detailColor, fontSize: 12),
          ),
          if (hint != null)
            Text(
              hint!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _PartnerTable extends StatelessWidget {
  const _PartnerTable({
    required this.l10n,
    required this.snapshot,
    required this.onOpen,
  });

  final AppLocalizations l10n;
  final AdminSalesSnapshot? snapshot;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = snapshot?.partners ?? const <AdminPartnerPerformance>[];
    final totals = snapshot?.totals ?? AdminSalesTotals.empty;
    return Container(
      key: const Key('admin-sales-partners'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.adminSalesPartners, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            l10n.adminSalesRowHint,
            style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(l10n.adminSalesEmpty, style: const TextStyle(color: AdminConsoleTheme.muted))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 720),
                child: Column(
                  children: [
                    _line(
                      l10n,
                      rank: l10n.adminSalesColRank,
                      name: l10n.adminSalesColPartner,
                      received: l10n.adminSalesColBookings,
                      gross: l10n.adminSalesColGross,
                      refund: l10n.adminSalesColRefund,
                      net: l10n.adminSalesColNet,
                      delta: l10n.adminSalesColDelta,
                      cancel: l10n.adminSalesColCancel,
                      share: l10n.adminSalesColShare,
                      muted: true,
                    ),
                    for (var i = 0; i < rows.length; i++)
                      InkWell(
                        key: Key('admin-sales-row-${rows[i].shopId}'),
                        onTap: () => onOpen(rows[i].shopId),
                        child: _line(
                          l10n,
                          rank: '${i + 1}',
                          name: rows[i].shopName,
                          mine: rows[i].mine,
                          received: '${rows[i].received}',
                          gross: _won(rows[i].gross),
                          refund: _won(rows[i].refund),
                          net: _won(rows[i].net),
                          delta: _delta(rows[i].net, rows[i].compareNet, l10n),
                          deltaColor: _up(rows[i].net, rows[i].compareNet),
                          cancel: _pct(rows[i].cancelRate),
                          share: _pct(rows[i].share),
                        ),
                      ),
                    _line(
                      l10n,
                      rank: '',
                      name: l10n.adminSalesTotalRow,
                      received: '${totals.received}',
                      gross: _won(totals.gross),
                      refund: _won(totals.refund),
                      net: _won(totals.net),
                      delta: _delta(totals.net, snapshot?.compareTotals.net ?? 0, l10n),
                      cancel: _pct(totals.cancelRate),
                      share: totals.net == 0 ? '—' : '100%',
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SideColumn extends StatelessWidget {
  const _SideColumn({required this.l10n, required this.snapshot});

  final AppLocalizations l10n;
  final AdminSalesSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final categories = snapshot?.categories ?? const <AdminCategoryShare>[];
    final top = snapshot?.topProducts ?? const <AdminProductRank>[];
    return Column(
      children: [
        _card(
          title: l10n.adminSalesCategory,
          child: categories.isEmpty
              ? Text(l10n.adminSalesEmpty, style: const TextStyle(color: AdminConsoleTheme.muted))
              : Column(
                  children: [
                    for (final item in categories)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                _bucket(l10n, item.bucket),
                                style: TextStyle(
                                  color: item.bucket == AdminSalesBucket.unknown
                                      ? AdminConsoleTheme.muted
                                      : AdminConsoleTheme.text,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: item.share == null
                                    ? 0
                                    : item.share!.clamp(0, 1).toDouble(),
                                minHeight: 8,
                                color: AdminConsoleTheme.aqua,
                                backgroundColor: AdminConsoleTheme.surfaceHigh,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 48,
                              child: Text(
                                _pct(item.share),
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _card(
          title: l10n.adminSalesTop,
          child: top.isEmpty
              ? Text(l10n.adminSalesEmpty, style: const TextStyle(color: AdminConsoleTheme.muted))
              : Column(
                  children: [
                    for (var i = 0; i < top.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text('${i + 1}. ${top[i].label}'),
                        subtitle: Text(
                          top[i].shopName,
                          style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
                        ),
                        trailing: Text(
                          '${_won(top[i].net)}\n${top[i].count}${l10n.adminOverviewCountUnit}',
                          textAlign: TextAlign.end,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

Widget _line(
  AppLocalizations l10n, {
  required String rank,
  required String name,
  required String received,
  required String gross,
  required String refund,
  required String net,
  required String delta,
  required String cancel,
  required String share,
  bool mine = false,
  bool muted = false,
  bool bold = false,
  Color? deltaColor,
}) {
  final style = TextStyle(
    fontSize: 12,
    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    color: muted ? AdminConsoleTheme.muted : AdminConsoleTheme.text,
  );
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(width: 28, child: Text(rank, style: style)),
        SizedBox(
          width: 160,
          child: Row(
            children: [
              Flexible(child: Text(name, style: style, overflow: TextOverflow.ellipsis)),
              if (mine) ...[
                const SizedBox(width: 4),
                Text(
                  l10n.adminSalesMine,
                  style: const TextStyle(color: AdminConsoleTheme.aqua, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 56, child: Text(received, style: style)),
        SizedBox(width: 80, child: Text(gross, style: style)),
        SizedBox(width: 72, child: Text(refund, style: style)),
        SizedBox(width: 80, child: Text(net, style: style)),
        SizedBox(
          width: 64,
          child: Text(delta, style: style.copyWith(color: deltaColor ?? style.color)),
        ),
        SizedBox(width: 56, child: Text(cancel, style: style)),
        SizedBox(width: 48, child: Text(share, style: style)),
      ],
    ),
  );
}

String _presetLabel(AppLocalizations l10n, AdminSalesPreset preset) {
  return switch (preset) {
    AdminSalesPreset.today => l10n.adminSalesPresetToday,
    AdminSalesPreset.thisWeek => l10n.adminSalesPresetWeek,
    AdminSalesPreset.thisMonth => l10n.adminSalesPresetMonth,
    AdminSalesPreset.threeMonths => l10n.adminSalesPresetQuarter,
    AdminSalesPreset.custom => l10n.adminSalesPresetCustom,
  };
}

String _bucket(AppLocalizations l10n, AdminSalesBucket bucket) {
  return switch (bucket) {
    AdminSalesBucket.tour => l10n.adminSalesCatTour,
    AdminSalesBucket.course => l10n.adminSalesCatCourse,
    AdminSalesBucket.experience => l10n.adminSalesCatFun,
    AdminSalesBucket.sameBoat => l10n.adminSalesCatFlag,
    AdminSalesBucket.unknown => l10n.adminSalesCatUnknown,
  };
}

String _won(int value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  if (abs >= 1000000) {
    return '$sign₩${_trim(abs / 1000000)}M';
  }
  if (abs >= 1000) {
    return '$sign₩${_trim(abs / 1000)}K';
  }
  return '$sign₩${NumberFormat.decimalPattern('ko').format(abs)}';
}

String _trim(double value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

String _pct(double? rate) {
  if (rate == null) {
    return '—';
  }
  return '${(rate * 100).toStringAsFixed(rate.abs() >= 0.1 || rate == 0 ? 1 : 1)}%';
}

String _delta(int now, int then, AppLocalizations l10n) {
  if (then == 0 && now == 0) {
    return l10n.adminOverviewNoCompare;
  }
  if (then == 0) {
    return l10n.adminSalesNew;
  }
  final pct = (((now - then) / then) * 100).round();
  final sign = pct > 0 ? '+' : '';
  return '$sign$pct%';
}

Color _up(int now, int then) {
  if (now == then || then == 0 && now == 0) {
    return AdminConsoleTheme.muted;
  }
  if (then == 0) {
    return AdminConsoleTheme.aqua;
  }
  return now >= then ? AdminConsoleTheme.aqua : AdminConsoleTheme.danger;
}
