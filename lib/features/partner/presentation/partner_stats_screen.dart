import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_chart_shells.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_stats_logic.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Partner stats (목업 보드 25). Real numbers only for product bookings.
class PartnerStatsScreen extends StatefulWidget {
  const PartnerStatsScreen({super.key, required this.shopId});

  final String shopId;

  @override
  State<PartnerStatsScreen> createState() => _PartnerStatsScreenState();
}

class _PartnerStatsScreenState extends State<PartnerStatsScreen> {
  PartnerStatsPeriod _period = PartnerStatsPeriod.thisMonth;
  final _scroll = ScrollController();

  final _keyVisit = GlobalKey();
  final _keyAudience = GlobalKey();
  final _keyDwell = GlobalKey();
  final _keyStrike = GlobalKey();
  final _keyResult = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) {
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return PartnerTheme.wrap(
      Scaffold(
        appBar: AppBar(
          leading: const PartnerBackButton(),
          title: Text(l10n.partnerQuickStats),
        ),
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final rows = computeProductBookingRows(
              bookings: store.shopBookings,
              period: _period,
            );

            return ListView(
              key: const Key('partner-stats'),
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _PeriodChips(
                  period: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
                const SizedBox(height: 10),
                _AnchorChips(
                  onVisit: () => _scrollTo(_keyVisit),
                  onAudience: () => _scrollTo(_keyAudience),
                  onDwell: () => _scrollTo(_keyDwell),
                  onStrike: () => _scrollTo(_keyStrike),
                  onResult: () => _scrollTo(_keyResult),
                ),
                const SizedBox(height: 18),
                _CategoryHeader(l10n.partnerStatsCatInApp),
                const SizedBox(height: 10),
                _SectionCard(
                  key: _keyVisit,
                  title: l10n.partnerStatsSecVisit,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _KpiShell(label: l10n.partnerStatsKpiAppVisits),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _KpiShell(
                              label: l10n.partnerStatsKpiProductViews,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const PartnerLineChartShell(),
                      const SizedBox(height: 8),
                      Text(
                        l10n.partnerStatsCollecting,
                        style: const TextStyle(
                          color: PartnerTheme.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _SectionCard(
                  key: _keyAudience,
                  title: l10n.partnerStatsSecAudience,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PartnerSegmentBarShell(),
                      const SizedBox(height: 12),
                      const PartnerHorizontalBarsShell(),
                      const SizedBox(height: 8),
                      Text(
                        l10n.partnerStatsCollecting,
                        style: const TextStyle(
                          color: PartnerTheme.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _SectionCard(
                  key: _keyDwell,
                  title: l10n.partnerStatsSecDwell,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PartnerHorizontalBarsShell(withAvgLine: true),
                      const SizedBox(height: 8),
                      Text(
                        l10n.partnerStatsCollecting,
                        style: const TextStyle(
                          color: PartnerTheme.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _CategoryHeader(l10n.partnerStatsCatResults),
                const SizedBox(height: 10),
                _SectionCard(
                  key: _keyStrike,
                  title: l10n.partnerStatsSecStrike,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PartnerGaugeShell(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _CompareBox(label: l10n.partnerStatsCmpAppAvg)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _CompareBox(label: l10n.partnerStatsCmpPeers),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.partnerStatsCollecting,
                        style: const TextStyle(
                          color: PartnerTheme.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _SectionCard(
                  key: _keyResult,
                  title: l10n.partnerStatsSecJourney,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(flex: 5, child: PartnerRadarShell()),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final label in [
                                  l10n.partnerStatsFunnelDetail,
                                  l10n.partnerStatsFunnelInterest,
                                  l10n.partnerStatsFunnelAttempt,
                                  l10n.partnerStatsFunnelPaid,
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        color: PartnerTheme.textDim,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.partnerStatsCollecting,
                        style: const TextStyle(
                          color: PartnerTheme.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _SectionCard(
                  title: l10n.partnerStatsSecProducts,
                  child: rows.isEmpty
                      ? Text(
                          key: const Key('partner-stats-products-empty'),
                          l10n.partnerStatsProductsEmpty,
                          style: const TextStyle(
                            color: PartnerTheme.textDim,
                            fontSize: 13,
                          ),
                        )
                      : _ProductTable(rows: rows),
                ),
                _SectionCard(
                  title: l10n.partnerStatsSecPromo,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PartnerGroupedBarsShell(),
                      const SizedBox(height: 8),
                      Text(
                        l10n.partnerStatsCollecting,
                        style: const TextStyle(
                          color: PartnerTheme.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.partnerStatsPrivacyNote,
                  style: const TextStyle(
                    color: PartnerTheme.textDim,
                    fontSize: 11,
                    height: 1.35,
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

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.period, required this.onChanged});

  final PartnerStatsPeriod period;
  final ValueChanged<PartnerStatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: [
        _chip(
          keyName: 'partner-stats-period-week',
          label: l10n.partnerStatsPeriodWeek,
          selected: period == PartnerStatsPeriod.thisWeek,
          onTap: () => onChanged(PartnerStatsPeriod.thisWeek),
        ),
        _chip(
          keyName: 'partner-stats-period-month',
          label: l10n.partnerStatsPeriodMonth,
          selected: period == PartnerStatsPeriod.thisMonth,
          onTap: () => onChanged(PartnerStatsPeriod.thisMonth),
        ),
        _chip(
          keyName: 'partner-stats-period-3m',
          label: l10n.partnerStatsPeriodThreeMonths,
          selected: period == PartnerStatsPeriod.threeMonths,
          onTap: () => onChanged(PartnerStatsPeriod.threeMonths),
        ),
      ],
    );
  }

  Widget _chip({
    required String keyName,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
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
        fontSize: 13,
      ),
      backgroundColor: PartnerTheme.card,
      side: BorderSide(
        color: selected ? PartnerTheme.accent : PartnerTheme.border,
      ),
    );
  }
}

class _AnchorChips extends StatelessWidget {
  const _AnchorChips({
    required this.onVisit,
    required this.onAudience,
    required this.onDwell,
    required this.onStrike,
    required this.onResult,
  });

  final VoidCallback onVisit;
  final VoidCallback onAudience;
  final VoidCallback onDwell;
  final VoidCallback onStrike;
  final VoidCallback onResult;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget chip(String keyName, String label, VoidCallback onTap) {
      return ActionChip(
        key: Key(keyName),
        label: Text(label),
        onPressed: onTap,
        backgroundColor: PartnerTheme.borderStrong,
        labelStyle: const TextStyle(
          color: PartnerTheme.text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: PartnerTheme.border),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        chip('partner-stats-anchor-visit', l10n.partnerStatsAnchorVisit, onVisit),
        chip(
          'partner-stats-anchor-audience',
          l10n.partnerStatsAnchorAudience,
          onAudience,
        ),
        chip('partner-stats-anchor-dwell', l10n.partnerStatsAnchorDwell, onDwell),
        chip(
          'partner-stats-anchor-strike',
          l10n.partnerStatsAnchorStrike,
          onStrike,
        ),
        chip(
          'partner-stats-anchor-result',
          l10n.partnerStatsAnchorResult,
          onResult,
        ),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: PartnerTheme.accent,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: PartnerTheme.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _KpiShell extends StatelessWidget {
  const _KpiShell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: PartnerTheme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PartnerTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PartnerTheme.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).partnerStatsCollecting,
            style: const TextStyle(
              color: PartnerTheme.textDim,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareBox extends StatelessWidget {
  const _CompareBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PartnerTheme.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PartnerTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PartnerTheme.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).partnerStatsCollecting,
            style: const TextStyle(
              color: PartnerTheme.textDim,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTable extends StatelessWidget {
  const _ProductTable({required this.rows});

  final List<PartnerProductBookingRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _headerRow(l10n),
        const Divider(height: 16, color: PartnerTheme.border),
        for (final row in rows) _dataRow(row),
      ],
    );
  }

  Widget _headerRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(flex: 4, child: _th(l10n.partnerStatsColProduct)),
        Expanded(flex: 2, child: _th(l10n.partnerStatsColBookings, alignEnd: true)),
        Expanded(flex: 2, child: _th(l10n.partnerStatsColGuests, alignEnd: true)),
        Expanded(flex: 3, child: _th(l10n.partnerStatsColChange, alignEnd: true)),
      ],
    );
  }

  Widget _dataRow(PartnerProductBookingRow row) {
    final change = row.changeRatio;
    String changeText;
    Color changeColor = PartnerTheme.textDim;
    if (change == null) {
      changeText = '—';
    } else {
      final pct = (change * 100).round();
      if (pct > 0) {
        changeText = '↑$pct%';
        changeColor = PartnerTheme.accent;
      } else if (pct < 0) {
        changeText = '↓${pct.abs()}%';
        changeColor = const Color(0xFFFF6B6B);
      } else {
        changeText = '0%';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              row.productLabel,
              style: const TextStyle(
                color: PartnerTheme.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.bookingCount}',
              textAlign: TextAlign.end,
              style: const TextStyle(color: PartnerTheme.text, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${row.guestCount}',
              textAlign: TextAlign.end,
              style: const TextStyle(color: PartnerTheme.text, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              changeText,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: changeColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _th(String label, {bool alignEnd = false}) {
    return Text(
      label,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: const TextStyle(
        color: PartnerTheme.textDim,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
