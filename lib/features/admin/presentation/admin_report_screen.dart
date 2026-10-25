import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_report_math.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_sales_math.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_report_pdf.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  AdminReportPeriod _period = AdminReportPeriod.month;
  AdminReportCompare _compare = AdminReportCompare.yearAgo;
  DateTime? _customStart;
  DateTime? _customEnd;
  final _buckets = <AdminSalesBucket>{
    AdminSalesBucket.tour,
    AdminSalesBucket.course,
    AdminSalesBucket.experience,
    AdminSalesBucket.sameBoat,
  };
  final _shops = <String>{};
  final _products = <String>{};
  var _showSummary = true;
  var _showTrend = true;
  var _showPartners = true;
  var _showProducts = true;
  var _showOptions = true;
  var _showCancels = true;
  var _showBasis = true;
  List<({String id, String name})> _shopChoices = const [];
  List<({String key, String name})> _productChoices = const [];
  AdminReportDocument? _document;
  var _busy = false;
  var _printing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChoices());
  }

  Future<void> _loadChoices() async {
    final store = DiverStoreScope.of(context);
    await store.ensureShopStatsLoaded();
    if (!mounted) {
      return;
    }
    setState(() {
      _shopChoices = [
        for (final stats in store.shopStats)
          (
            id: stats.shopId,
            name: (stats.name ?? '').trim().isEmpty ? stats.shopId : stats.name!.trim(),
          ),
      ];
      _productChoices = [
        for (final stats in store.shopStats)
          for (final product in stats.products)
            (key: '${stats.shopId}|${product.id}', name: product.name),
      ];
    });
  }

  Future<void> _make() async {
    final store = DiverStoreScope.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final window = adminReportWindow(
        period: _period,
        now: now,
        customStart: _customStart,
        customEnd: _customEnd,
      );
      final compare = adminReportCompareWindow(
        window: window,
        compare: _compare,
      );
      final spans = <AdminSalesWindow>[
        window,
        if (compare.start.isBefore(compare.end)) compare,
      ];
      final bookings = <TourBooking>[];
      final seen = <String>{};
      for (final span in spans) {
        final rows = await store.loadAdminAnalyticsBookings(
          start: span.start,
          end: span.end,
        );
        for (final booking in rows) {
          if (seen.add('${booking.shopId}|${booking.id}')) {
            bookings.add(booking);
          }
        }
      }
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
      final label =
          '${DateFormat('yyyy-MM-dd').format(window.start)} ~ ${DateFormat('yyyy-MM-dd').format(window.end.subtract(const Duration(days: 1)))}';
      setState(() {
        _document = buildAdminReportDocument(
          bookings: bookings,
          window: window,
          compareWindow: compare,
          catalog: catalog,
          buckets: _buckets,
          shopIds: _shops,
          productKeys: _products,
          periodLabel: label,
          showSummary: _showSummary,
          showTrend: _showTrend,
          showPartners: _showPartners,
          showProducts: _showProducts,
          showOptions: _showOptions,
          showCancels: _showCancels,
          showBasis: _showBasis,
          basisText: l10n.adminReportBasisBody,
          fontLicense: l10n.adminReportFontLicense,
        );
        _busy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = '$error';
      });
    }
  }

  Future<void> _print() async {
    final document = _document;
    if (document == null || _printing) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _printing = true);
    try {
      final bytes = await buildAdminReportPdf(document, l10n);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _printing = false);
      }
    }
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _period = AdminReportPeriod.custom;
      _customStart = picked.start;
      _customEnd = picked.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final settings = _settings(l10n);
        final preview = _preview(l10n);
        if (!wide) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [settings, const SizedBox(height: 16), preview],
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: SingleChildScrollView(child: settings),
              ),
              const SizedBox(width: 16),
              Expanded(child: SingleChildScrollView(child: preview)),
            ],
          ),
        );
      },
    );
  }

  Widget _settings(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.adminReportSettings, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(l10n.adminReportPeriod, style: const TextStyle(color: AdminConsoleTheme.muted)),
        Wrap(
          spacing: 6,
          children: [
            for (final period in AdminReportPeriod.values)
              ChoiceChip(
                key: Key('admin-report-period-${period.name}'),
                label: Text(_periodLabel(l10n, period)),
                selected: _period == period,
                onSelected: (_) {
                  if (period == AdminReportPeriod.custom) {
                    _pickCustom();
                    return;
                  }
                  setState(() => _period = period);
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.adminReportCompare, style: const TextStyle(color: AdminConsoleTheme.muted)),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: Text(l10n.adminSalesComparePrev),
              selected: _compare == AdminReportCompare.previous,
              onSelected: (_) => setState(() => _compare = AdminReportCompare.previous),
            ),
            ChoiceChip(
              label: Text(l10n.adminSalesCompareYear),
              selected: _compare == AdminReportCompare.yearAgo,
              onSelected: (_) => setState(() => _compare = AdminReportCompare.yearAgo),
            ),
            ChoiceChip(
              label: Text(l10n.adminReportCompareNone),
              selected: _compare == AdminReportCompare.none,
              onSelected: (_) => setState(() => _compare = AdminReportCompare.none),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.adminReportCategories),
        for (final bucket in [
          AdminSalesBucket.tour,
          AdminSalesBucket.course,
          AdminSalesBucket.experience,
          AdminSalesBucket.sameBoat,
        ])
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _buckets.contains(bucket),
            title: Text(_bucketLabel(l10n, bucket)),
            onChanged: (value) {
              setState(() {
                if (value ?? false) {
                  _buckets.add(bucket);
                } else {
                  _buckets.remove(bucket);
                }
              });
            },
          ),
        Text(l10n.adminReportPartners),
        SizedBox(
          height: 120,
          child: ListView(
            children: [
              for (final shop in _shopChoices)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _shops.contains(shop.id),
                  title: Text(shop.name),
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _shops.add(shop.id);
                      } else {
                        _shops.remove(shop.id);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
        Text(
          _shops.isEmpty ? '${l10n.adminReportPartners} · ${l10n.adminReportAll}' : l10n.adminReportPartners,
          style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 11),
        ),
        Text(l10n.adminReportProducts),
        SizedBox(
          height: 120,
          child: ListView(
            children: [
              for (final product in _productChoices.take(40))
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _products.contains(product.key),
                  title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _products.add(product.key);
                      } else {
                        _products.remove(product.key);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
        Text(l10n.adminReportInclude, style: const TextStyle(fontWeight: FontWeight.w700)),
        _flag(l10n.adminReportSummary, _showSummary, (v) => _showSummary = v),
        _flag(l10n.adminReportTrend, _showTrend, (v) => _showTrend = v),
        _flag(l10n.adminReportPartnerTable, _showPartners, (v) => _showPartners = v),
        _flag(l10n.adminReportProductRank, _showProducts, (v) => _showProducts = v),
        _flag(l10n.adminReportOptions, _showOptions, (v) => _showOptions = v),
        _flag(l10n.adminReportCancels, _showCancels, (v) => _showCancels = v),
        _flag(l10n.adminReportBasis, _showBasis, (v) => _showBasis = v),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: AdminConsoleTheme.danger)),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('admin-report-make'),
          onPressed: _busy ? null : _make,
          child: Text(_busy ? l10n.adminReportPrinting : l10n.adminReportMake),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('admin-report-print'),
          onPressed: _document == null || _printing ? null : _print,
          child: Text(_printing ? l10n.adminReportPrinting : l10n.adminReportPrint),
        ),
      ],
    );
  }

  Widget _flag(String label, bool value, void Function(bool) set) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(label),
      onChanged: (next) => setState(() => set(next ?? false)),
    );
  }

  Widget _preview(AppLocalizations l10n) {
    final document = _document;
    if (document == null) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Text(
            l10n.adminReportEmpty,
            key: const Key('admin-report-empty'),
            style: const TextStyle(color: AdminConsoleTheme.muted),
          ),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _ReportPage(document: document, l10n: l10n),
      ),
    );
  }
}

class _ReportPage extends StatelessWidget {
  const _ReportPage({required this.document, required this.l10n});

  final AdminReportDocument document;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final totals = document.snapshot.totals;
    return Container(
      key: const Key('admin-report-page'),
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xFF172033), fontSize: 13, height: 1.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.adminReportHeading}  ${document.periodLabel}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 12),
            if (document.showSummary) ...[
              Text(l10n.adminReportSummary, style: const TextStyle(fontSize: 16)),
              Text('${l10n.adminSalesGross} ${_won(totals.gross)}'),
              Text('${l10n.adminSalesRefund} ${_won(totals.refund)}'),
              Text(
                '${l10n.adminSalesNet} ${_won(totals.net)}',
                key: const Key('admin-report-net'),
              ),
              const SizedBox(height: 10),
            ],
            if (document.showTrend) ...[
              Text(l10n.adminReportTrend, style: const TextStyle(fontSize: 16)),
              Text(
                '${l10n.adminSalesNet} ${_won(document.dailyNet.fold<int>(0, (a, b) => a + b))}',
              ),
              const SizedBox(height: 10),
            ],
            if (document.showPartners) ...[
              Text(l10n.adminReportPartnerTable, style: const TextStyle(fontSize: 16)),
              for (final row in document.snapshot.partners)
                Text('${row.shopName}  ${row.received}  ${_won(row.net)}'),
              const SizedBox(height: 10),
            ],
            if (document.showProducts) ...[
              Text(l10n.adminReportProductRank, style: const TextStyle(fontSize: 16)),
              for (final row in document.snapshot.topProducts)
                Text('${row.label}  ${_won(row.net)}  ${row.count}'),
              const SizedBox(height: 10),
            ],
            if (document.showOptions) ...[
              Text(l10n.adminStatsOptions, style: const TextStyle(fontSize: 16)),
              if (!document.optionsApply || document.options.isEmpty)
                Text(l10n.adminStatsGathering)
              else ...[
                for (final option in document.options)
                  Text('${option.name}  ${option.count}'),
                if (document.topOption != null)
                  Text('${l10n.adminStatsMost}: ${document.topOption}'),
              ],
              Text(l10n.adminStatsOptionsHint),
              const SizedBox(height: 10),
            ],
            if (document.showCancels) ...[
              Text(l10n.adminReportCancels, style: const TextStyle(fontSize: 16)),
              Text('${totals.cancelCount} · ${_won(totals.refund)}'),
              const SizedBox(height: 10),
            ],
            if (document.showBasis) Text(document.basisText),
            const SizedBox(height: 8),
            Text(
              document.fontLicense,
              key: const Key('admin-report-font-license'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF5C6B7A)),
            ),
          ],
        ),
      ),
    );
  }
}

String _won(int value) {
  final sign = value < 0 ? '-' : '';
  return '$sign₩${NumberFormat.decimalPattern('ko').format(value.abs())}';
}

String _periodLabel(AppLocalizations l10n, AdminReportPeriod period) {
  return switch (period) {
    AdminReportPeriod.month => l10n.adminReportPeriodMonth,
    AdminReportPeriod.quarter => l10n.adminReportPeriodQuarter,
    AdminReportPeriod.year => l10n.adminReportPeriodYear,
    AdminReportPeriod.custom => l10n.adminReportPeriodCustom,
  };
}

String _bucketLabel(AppLocalizations l10n, AdminSalesBucket bucket) {
  return switch (bucket) {
    AdminSalesBucket.tour => l10n.adminSalesCatTour,
    AdminSalesBucket.course => l10n.adminSalesCatCourse,
    AdminSalesBucket.experience => l10n.adminSalesCatFun,
    AdminSalesBucket.sameBoat => l10n.adminSalesCatFlag,
    AdminSalesBucket.unknown => l10n.adminSalesCatUnknown,
  };
}
