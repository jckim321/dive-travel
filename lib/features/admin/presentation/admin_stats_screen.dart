import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/nationality.dart';
import 'package:dive_travel_app/core/constants/option_group.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_option_groups.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_sales_math.dart';
import 'package:dive_travel_app/features/admin/analytics/admin_stats_math.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_dive_star_milestone.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Admin statistics. Charts use the same receive-date snapshot as sales.
class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  AdminStatsPreset _preset = AdminStatsPreset.thisMonth;
  AdminStatsSnapshot? _snapshot;
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
      final window = adminStatsWindow(preset: _preset, now: now);
      final load = adminStatsLoadWindow(now);
      await store.ensureAdminInboxLoaded();
      final bookings = await store.loadAdminAnalyticsBookings(
        start: load.start,
        end: load.end,
      );
      final applications = await store.listDiveStarApplications();
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
      final optionCatalog = <AdminListedOption>[
        for (final stats in store.shopStats)
          for (final product in stats.products)
            for (final option in product.options)
              AdminListedOption(
                shopId: stats.shopId,
                productId: product.id,
                optionId: option.id,
                name: option.name,
                group: option.group,
              ),
      ];
      setState(() {
        _snapshot = buildAdminStatsSnapshot(
          bookings: bookings,
          window: window,
          now: now,
          catalog: catalog,
          members: store.members,
          shops: [
            for (final stats in store.shopStats)
              AdminShopGrade(shopId: stats.shopId, diveStar: stats.diveStar),
          ],
          applications: applications,
          optionCatalog: optionCatalog,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot = _snapshot;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final gap = 12.0;
        final columnWidth = wide
            ? (constraints.maxWidth - 32 - gap * 2) / 3
            : constraints.maxWidth - 32;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in AdminStatsPreset.values)
                  ChoiceChip(
                    key: Key('admin-stats-preset-${preset.name}'),
                    label: Text(_presetLabel(l10n, preset)),
                    selected: _preset == preset,
                    onSelected: (_) {
                      setState(() => _preset = preset);
                      _load();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.adminStatsBasis,
              key: const Key('admin-stats-basis'),
              style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: AdminConsoleTheme.danger)),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                _box(columnWidth, _flow(l10n, snapshot)),
                _box(columnWidth, _who(l10n, snapshot)),
                _box(columnWidth, _what(l10n, snapshot)),
                _box(columnWidth, _partners(l10n, snapshot)),
                _box(columnWidth, _cancels(l10n, snapshot)),
                _box(columnWidth, _stars(l10n, snapshot)),
                _box(wide ? columnWidth * 2 + gap : columnWidth, _lead(l10n, snapshot)),
                _box(columnWidth, _season(l10n, snapshot)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _box(double width, Widget child) {
    return SizedBox(width: width, child: child);
  }
}

Widget _card({required String title, String? hint, required Widget child}) {
  return Container(
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
        if (hint != null)
          Text(hint, style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 11)),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

Widget _flow(AppLocalizations l10n, AdminStatsSnapshot? snapshot) {
  final daily = snapshot?.dailyNet ?? const <int>[];
  final prior = snapshot?.hasYearAgo == true ? snapshot!.dailyYearAgoNet : null;
  return _card(
    title: '1 ${l10n.adminStatsFlow}',
    hint: l10n.adminStatsFlowHint,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (snapshot != null && !snapshot.hasYearAgo)
          Text(
            l10n.adminOverviewNoCompare,
            key: const Key('admin-stats-no-compare'),
            style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
          ),
        SizedBox(
          height: 120,
          child: CustomPaint(
            painter: _LinePainter(primary: daily, compare: prior),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    ),
  );
}

Widget _who(AppLocalizations l10n, AdminStatsSnapshot? snapshot) {
  final grades = snapshot?.gradeCounts ?? const <ProfileDisplayGrade, int>{};
  final maxGrade = grades.values.fold<int>(0, (max, value) => value > max ? value : max);
  return _card(
    title: '2 ${l10n.adminStatsWho}',
    hint: l10n.adminStatsBuyerNote,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final grade in ProfileDisplayGrade.values)
          _hBar(
            _gradeLabel(l10n, grade),
            grades[grade] ?? 0,
            maxGrade,
            AdminConsoleTheme.aqua,
          ),
        if ((snapshot?.gradeUnknown ?? 0) > 0)
          Text(
            '${l10n.adminStatsGradeUnknown} ${snapshot!.gradeUnknown}',
            style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
          ),
        const SizedBox(height: 8),
        _hBar(l10n.adminSalesNew, snapshot?.newBuyers ?? 0, _buyerMax(snapshot), AdminConsoleTheme.ice),
        _hBar(
          l10n.adminStatsReturn,
          snapshot?.returnBuyers ?? 0,
          _buyerMax(snapshot),
          AdminConsoleTheme.amber,
        ),
        if ((snapshot?.buyerUnknown ?? 0) > 0)
          Text(
            '${l10n.adminStatsGathering} ${snapshot!.buyerUnknown}',
            style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.adminStatsCountry,
          key: const Key('admin-stats-country'),
          style: const TextStyle(color: AdminConsoleTheme.muted),
        ),
        if (snapshot == null || snapshot.countries.isEmpty)
          Text(
            l10n.adminStatsGathering,
            key: const Key('admin-stats-country-empty'),
            style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
          )
        else
          for (final row in snapshot.countries)
            Text(
              '${row.code.isEmpty ? l10n.adminStatsCountryUnknown : nationalityNameKo(row.code)}  ${row.count} · ${row.net}',
              key: Key(
                'admin-stats-country-${row.code.isEmpty ? 'unknown' : row.code}',
              ),
              style: const TextStyle(fontSize: 12),
            ),
      ],
    ),
  );
}

List<Widget> _optionGroupLines(List<AdminOptionGroupLine> lines, int max) {
  final widgets = <Widget>[];
  String? current;
  for (final line in lines) {
    if (line.group != current) {
      current = line.group;
      final key = line.group.isEmpty ? 'unknown' : line.group;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            optionGroupNameKo(line.group),
            key: Key('admin-stats-option-group-$key'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      );
    }
    widgets.add(
      _hBar(line.name, line.count, max, AdminConsoleTheme.amber),
    );
  }
  return widgets;
}

int _buyerMax(AdminStatsSnapshot? snapshot) {
  final a = snapshot?.newBuyers ?? 0;
  final b = snapshot?.returnBuyers ?? 0;
  return a > b ? a : b;
}

Widget _what(AppLocalizations l10n, AdminStatsSnapshot? snapshot) {
  final categories = snapshot?.sales.categories ?? const <AdminCategoryShare>[];
  final partners = snapshot?.sales.partners ?? const <AdminPartnerPerformance>[];
  final options = snapshot?.options ?? const <AdminOptionPick>[];
  final maxOption = options.fold<int>(0, (max, item) => item.count > max ? item.count : max);
  return _card(
    title: '3 ${l10n.adminStatsWhat}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: CustomPaint(
            painter: _DonutPainter(
              values: [for (final item in categories) item.net],
            ),
            child: const SizedBox.expand(),
          ),
        ),
        for (final item in categories)
          Text(
            '${_bucket(l10n, item.bucket)}  ${item.share == null ? '—' : '${(item.share! * 100).toStringAsFixed(0)}%'}',
            style: const TextStyle(fontSize: 12),
          ),
        const SizedBox(height: 8),
        Text(l10n.adminStatsResort, style: const TextStyle(fontWeight: FontWeight.w700)),
        for (final row in partners.take(5))
          _hBar(row.shopName, row.net, partners.first.net, AdminConsoleTheme.aqua),
        const SizedBox(height: 8),
        Text(
          l10n.adminStatsOptions,
          key: const Key('admin-stats-options'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (options.isEmpty)
          Text(
            l10n.adminStatsGathering,
            key: const Key('admin-stats-options-empty'),
            style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
          )
        else ...[
          for (final option in options)
            _hBar(option.name, option.count, maxOption, AdminConsoleTheme.ice),
          if (snapshot?.topOption != null)
            Text(
              '${l10n.adminStatsMost}: ${snapshot!.topOption}',
              key: const Key('admin-stats-top-option'),
            ),
          ..._optionGroupLines(
            snapshot?.optionGroups ?? const [],
            maxOption,
          ),
        ],
        const SizedBox(height: 4),
        if (snapshot?.optionGroupsKnown != true)
          Text(
            l10n.adminStatsOptionsHint,
            key: const Key('admin-stats-options-hint'),
            style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
          ),
      ],
    ),
  );
}

Widget _partners(AppLocalizations l10n, AdminStatsSnapshot? snapshot) {
  final rows = snapshot?.sales.partners ?? const <AdminPartnerPerformance>[];
  return _card(
    title: '4 ${l10n.adminStatsPartner}',
    hint: l10n.adminStatsPartnerHint,
    child: SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _ScatterPainter(rows: rows),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

Widget _cancels(AppLocalizations l10n, AdminStatsSnapshot? snapshot) {
  return _card(
    title: '5 ${l10n.adminStatsCancel}',
    hint: l10n.adminStatsCancelHint,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: CustomPaint(
            painter: _ColumnPainter(
              values: snapshot?.cancelByMonth ?? const [],
              color: AdminConsoleTheme.danger,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 6),
        Text(l10n.adminStatsTopCancel, style: const TextStyle(fontSize: 12)),
        if (snapshot == null || snapshot.topCancelled.isEmpty)
          Text(l10n.adminStatsGathering, style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12))
        else
          for (final item in snapshot.topCancelled)
            Text('${item.label} · ${item.count}', style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

Widget _stars(AppLocalizations l10n, AdminStatsSnapshot? snapshot) {
  final counts = snapshot?.diveStarCounts ?? const <PartnerDiveStarMilestoneStep, int>{};
  final max = counts.values.fold<int>(0, (max, value) => value > max ? value : max);
  return _card(
    title: '6 ${l10n.adminStatsDiveStar}',
    hint: l10n.adminStatsDiveNote,
    child: Column(
      children: [
        for (final step in PartnerDiveStarMilestoneStep.values)
          _hBar(_starLabel(l10n, step), counts[step] ?? 0, max, AdminConsoleTheme.amber),
      ],
    ),
  );
}

Widget _lead(AppLocalizations l10n, AdminStatsSnapshot? snapshot) {
  final counts = snapshot?.leadCounts ?? const <int>[];
  final labels = [
    l10n.adminStatsLead0,
    l10n.adminStatsLead3,
    l10n.adminStatsLead7,
    l10n.adminStatsLead14,
    l10n.adminStatsLead30,
    l10n.adminStatsLead30p,
  ];
  return _card(
    title: '7 ${l10n.adminStatsLead}',
    hint: l10n.adminStatsLeadHint,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: CustomPaint(
            painter: _ColumnPainter(values: counts, color: AdminConsoleTheme.ice),
            child: const SizedBox.expand(),
          ),
        ),
        Text(labels.join('  ·  '), style: const TextStyle(fontSize: 11, color: AdminConsoleTheme.muted)),
        const SizedBox(height: 4),
        Text(
          l10n.adminStatsLeadNote,
          style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

Widget _season(AppLocalizations l10n, AdminStatsSnapshot? snapshot) {
  final counts = snapshot?.seasonCounts ?? const <int>[];
  final labels = snapshot?.monthLabels ?? const <String>[];
  final max = counts.fold<int>(0, (max, value) => value > max ? value : max);
  return _card(
    title: l10n.adminStatsSeason,
    hint: l10n.adminStatsSeasonHint,
    child: Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < counts.length; i++)
          Container(
            width: 28,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AdminConsoleTheme.aqua.withValues(
                alpha: max == 0 ? 0.15 : 0.2 + 0.6 * (counts[i] / max),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              i < labels.length ? labels[i] : '',
              style: const TextStyle(fontSize: 10),
            ),
          ),
      ],
    ),
  );
}

Widget _hBar(String label, int value, int max, Color color) {
  final ratio = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: ratio.toDouble(),
            minHeight: 8,
            color: color,
            backgroundColor: AdminConsoleTheme.surfaceHigh,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 36,
          child: Text('$value', textAlign: TextAlign.end, style: const TextStyle(fontSize: 11)),
        ),
      ],
    ),
  );
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.primary, required this.compare});

  final List<int> primary;
  final List<int>? compare;

  @override
  void paint(Canvas canvas, Size size) {
    if (primary.isEmpty || size.width <= 0) {
      return;
    }
    var max = 1;
    for (final value in [...primary, ...?compare]) {
      if (value > max) {
        max = value;
      }
    }
    _stroke(canvas, size, primary, AdminConsoleTheme.aqua, max);
    final prior = compare;
    if (prior != null && prior.length == primary.length) {
      _stroke(canvas, size, prior, AdminConsoleTheme.muted, max);
    }
  }

  void _stroke(Canvas canvas, Size size, List<int> series, Color color, int max) {
    final path = Path();
    for (var i = 0; i < series.length; i++) {
      final x = series.length == 1 ? size.width / 2 : size.width * i / (series.length - 1);
      final y = size.height - size.height * (series[i] / max);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => true;
}

class _ColumnPainter extends CustomPainter {
  _ColumnPainter({required this.values, required this.color});

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }
    var max = 1;
    for (final value in values) {
      if (value > max) {
        max = value;
      }
    }
    final gap = 3.0;
    final width = (size.width - gap * (values.length - 1)) / values.length;
    final paint = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final h = size.height * (values[i] / max);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * (width + gap), size.height - h, width.clamp(1, 40), h),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ColumnPainter oldDelegate) => true;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values});

  final List<int> values;
  static const _colors = [
    AdminConsoleTheme.aqua,
    AdminConsoleTheme.ice,
    AdminConsoleTheme.amber,
    AdminConsoleTheme.danger,
    AdminConsoleTheme.muted,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (sum, value) => sum + (value > 0 ? value : 0));
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height / 2 - 4;
    if (total <= 0 || radius <= 0) {
      canvas.drawCircle(
        center,
        radius.clamp(0, size.height),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = AdminConsoleTheme.surfaceHigh,
      );
      return;
    }
    var start = -1.5708;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) {
        continue;
      }
      final sweep = values[i] / total * 6.2832;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = _colors[i % _colors.length],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class _ScatterPainter extends CustomPainter {
  _ScatterPainter({required this.rows});

  final List<AdminPartnerPerformance> rows;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty) {
      return;
    }
    var maxNet = 1;
    for (final row in rows) {
      if (row.net > maxNet) {
        maxNet = row.net;
      }
    }
    final paint = Paint()..color = AdminConsoleTheme.aqua;
    for (final row in rows) {
      final x = size.width * (row.cancelRate ?? 0).clamp(0, 1);
      final y = size.height - size.height * (row.net <= 0 ? 0 : row.net / maxNet);
      canvas.drawCircle(Offset(x, y), 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter oldDelegate) => true;
}

String _presetLabel(AppLocalizations l10n, AdminStatsPreset preset) {
  return switch (preset) {
    AdminStatsPreset.thisWeek => l10n.adminStatsPresetWeek,
    AdminStatsPreset.thisMonth => l10n.adminStatsPresetMonth,
    AdminStatsPreset.threeMonths => l10n.adminStatsPresetQuarter,
    AdminStatsPreset.thisYear => l10n.adminStatsPresetYear,
  };
}

String _gradeLabel(AppLocalizations l10n, ProfileDisplayGrade grade) {
  return switch (grade) {
    ProfileDisplayGrade.silver => l10n.memberGradeSilver,
    ProfileDisplayGrade.gold => l10n.memberGradeGold,
    ProfileDisplayGrade.diamond => l10n.memberGradeDiamond,
    ProfileDisplayGrade.platinum => l10n.memberGradePlatinum,
    ProfileDisplayGrade.instructor => l10n.profileGradeInstructor,
  };
}

String _starLabel(AppLocalizations l10n, PartnerDiveStarMilestoneStep step) {
  return switch (step) {
    PartnerDiveStarMilestoneStep.generalPartner => l10n.partnerMilestoneGeneral,
    PartnerDiveStarMilestoneStep.preReview => l10n.partnerMilestonePreReview,
    PartnerDiveStarMilestoneStep.oneStar => l10n.partnerMilestoneOneStar,
    PartnerDiveStarMilestoneStep.twoStar => l10n.partnerMilestoneTwoStar,
    PartnerDiveStarMilestoneStep.threeStar => l10n.partnerMilestoneThreeStar,
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
