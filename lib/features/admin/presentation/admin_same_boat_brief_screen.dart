import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/seat_brief.dart';
import 'package:dive_travel_app/core/models/seat_demand.dart';
import 'package:dive_travel_app/core/models/seat_score.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Period funnel for same-boat opens, views, flags, and payments.
class AdminSameBoatBriefScreen extends StatefulWidget {
  const AdminSameBoatBriefScreen({super.key, this.now});

  /// Test clock. Production uses [DateTime.now].
  final DateTime? now;

  @override
  State<AdminSameBoatBriefScreen> createState() =>
      _AdminSameBoatBriefScreenState();
}

enum _ScoreTab { region, product }

class _AdminSameBoatBriefScreenState extends State<AdminSameBoatBriefScreen> {
  SeatBriefPreset _preset = SeatBriefPreset.sevenDays;
  DateTime? _customStart;
  DateTime? _customEnd;
  var _compare = false;
  var _loading = true;
  SeatBriefFunnel _current = SeatBriefFunnel.empty;
  SeatBriefFunnel? _previous;
  SeatDemandDigest _demand = SeatDemandDigest.empty;
  SeatDemandDigest? _demandPrevious;
  SeatScoreboard _score = SeatScoreboard.empty;
  var _scoreTab = _ScoreTab.region;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  SeatBriefWindow get _window => seatBriefWindow(
    preset: _preset,
    now: _now,
    customStart: _customStart,
    customEnd: _customEnd,
  );

  Future<void> _load() async {
    final store = DiverStoreScope.of(context);
    final window = _window;
    setState(() => _loading = true);
    try {
      await store.ensureShopStatsLoaded();
      final currentEvents = await store.seatEventsBetween(
        from: window.start,
        to: window.end,
      );
      final currentDemands = await store.seatDemandsBetween(
        from: window.start,
        to: window.end,
      );
      SeatBriefFunnel? previous;
      SeatDemandDigest? demandPrevious;
      if (_compare) {
        final earlier = seatBriefPreviousWindow(window);
        previous = seatBriefFunnel(
          await store.seatEventsBetween(
            from: earlier.start,
            to: earlier.end,
          ),
        );
        demandPrevious = seatDemandDigest(
          await store.seatDemandsBetween(
            from: earlier.start,
            to: earlier.end,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _current = seatBriefFunnel(currentEvents);
        _demand = seatDemandDigest(currentDemands);
        _score = seatScoreboard(
          events: currentEvents,
          seats: _briefSeats(store),
        );
        _previous = previous;
        _demandPrevious = demandPrevious;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('seat brief failed $error');
      debugPrint('$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(_now.year - 3),
      lastDate: DateTime(_now.year, 12, 31),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _preset = SeatBriefPreset.custom;
      _customStart = picked.start;
      _customEnd = picked.end;
    });
    await _load();
  }

  void _select(SeatBriefPreset preset) {
    setState(() => _preset = preset);
    _load();
  }

  List<SeatScoreRow> get _scoreRows =>
      _scoreTab == _ScoreTab.region ? _score.regions : _score.products;

  String _conclusion(AppLocalizations l10n) {
    final row = seatScoreHeadline(_score.regions);
    if (row == null || row.badge == SeatScoreBadge.ordinary) {
      return l10n.seatBriefConclusionWait;
    }
    final who = l10n.localeName == 'ko' ? seatScoreTopic(row.title) : row.title;
    return switch (row.badge) {
      SeatScoreBadge.viewsOnly => l10n.seatBriefConclusionPrice(
        who,
        row.views,
        row.flags,
        row.pays,
      ),
      SeatScoreBadge.selling => l10n.seatBriefConclusionSelling(
        who,
        row.views,
        row.flags,
        row.pays,
      ),
      SeatScoreBadge.quiet => l10n.seatBriefConclusionQuiet(
        who,
        row.views,
        row.flags,
        row.pays,
      ),
      SeatScoreBadge.ordinary => l10n.seatBriefConclusionWait,
    };
  }

  List<SeatScoreSeat> _briefSeats(DiverStore store) {
    final seats = <SeatScoreSeat>[];
    for (final product in store.allShopProducts) {
      final hull = product.shopId.split('--').first;
      final stats = store.liveStatsFor(hull) ?? store.liveStatsFor(product.shopId);
      final shopContinent = stats?.continent ?? '';
      final place = SameBoatPlace(
        continent: product.continent,
        location: stats?.location ?? '',
        country: stats?.country ?? '',
        sites: [if (shopContinent.isNotEmpty) shopContinent],
      );
      final options = [
        for (final option in product.options)
          if (option.capacity > 0) option,
      ];
      if (options.isEmpty) {
        seats.add(
          SeatScoreSeat(
            productId: product.id,
            optionId: '',
            productName: product.name,
            place: place,
            booked: product.bookedSeats,
            capacity: product.capacity,
          ),
        );
        continue;
      }
      for (final option in options) {
        seats.add(
          SeatScoreSeat(
            productId: product.id,
            optionId: option.id,
            productName: product.name,
            place: place,
            booked: option.bookedSeats,
            capacity: option.capacity,
          ),
        );
      }
    }
    return seats;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final window = _window;
    final earlier = seatBriefPreviousWindow(window);
    final beforeRecording = seatBriefBeforeRecording(
      _compare ? earlier : window,
    );
    final maxCount = [
      _current.opens,
      _current.views,
      _current.flags,
      _current.pays,
    ].reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AdminConsoleTheme.bg,
      body: ListView(
      key: const Key('admin-same-boat-brief'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          _conclusion(l10n),
          key: const Key('seat-brief-conclusion'),
          style: const TextStyle(fontWeight: FontWeight.w800, height: 1.35),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Preset(
                key: const Key('seat-brief-preset-today'),
                label: l10n.seatBriefToday,
                selected: _preset == SeatBriefPreset.today,
                onTap: () => _select(SeatBriefPreset.today),
              ),
              _Preset(
                key: const Key('seat-brief-preset-7'),
                label: l10n.seatBriefSeven,
                selected: _preset == SeatBriefPreset.sevenDays,
                onTap: () => _select(SeatBriefPreset.sevenDays),
              ),
              _Preset(
                key: const Key('seat-brief-preset-30'),
                label: l10n.seatBriefThirty,
                selected: _preset == SeatBriefPreset.thirtyDays,
                onTap: () => _select(SeatBriefPreset.thirtyDays),
              ),
              _Preset(
                key: const Key('seat-brief-preset-year'),
                label: l10n.seatBriefYear,
                selected: _preset == SeatBriefPreset.thisYear,
                onTap: () => _select(SeatBriefPreset.thisYear),
              ),
              _Preset(
                key: const Key('seat-brief-preset-custom'),
                label: l10n.seatBriefCustom,
                selected: _preset == SeatBriefPreset.custom,
                onTap: _pickCustom,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AdminConsoleTheme.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                seatBriefRangeLabel(window),
                key: const Key('seat-brief-range'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              l10n.seatBriefCompare,
              style: const TextStyle(
                color: AdminConsoleTheme.muted,
                fontSize: 12,
              ),
            ),
            Switch(
              key: const Key('seat-brief-compare'),
              value: _compare,
              activeThumbColor: AdminConsoleTheme.aqua,
              onChanged: (value) {
                setState(() => _compare = value);
                _load();
              },
            ),
          ],
        ),
        if (beforeRecording) ...[
          const SizedBox(height: 8),
          Text(
            l10n.seatBriefBeforeRecording,
            key: const Key('seat-brief-before-recording'),
            style: const TextStyle(color: AdminConsoleTheme.amber),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          l10n.seatBriefFunnelTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        const SizedBox(height: 8),
        _FunnelRow(
          countKey: const Key('seat-brief-opens'),
          deltaKey: const Key('seat-brief-opens-delta'),
          label: l10n.seatBriefOpens,
          count: _current.opens,
          previous: _previous?.opens,
          maxCount: maxCount,
          caption: null,
        ),
        _FunnelRow(
          countKey: const Key('seat-brief-views'),
          deltaKey: const Key('seat-brief-views-delta'),
          label: l10n.seatBriefViews,
          count: _current.views,
          previous: _previous?.views,
          maxCount: maxCount,
          caption: l10n.seatBriefViewsPerOpen(
            _current.viewsPerOpen.toStringAsFixed(1),
          ),
        ),
        _FunnelRow(
          countKey: const Key('seat-brief-flags'),
          deltaKey: const Key('seat-brief-flags-delta'),
          label: l10n.seatBriefFlags,
          count: _current.flags,
          previous: _previous?.flags,
          maxCount: maxCount,
          caption: l10n.seatBriefFlagRate(_current.flagPercent),
        ),
        _FunnelRow(
          countKey: const Key('seat-brief-pays'),
          deltaKey: const Key('seat-brief-pays-delta'),
          label: l10n.seatBriefPays,
          count: _current.pays,
          previous: _previous?.pays,
          maxCount: maxCount,
          caption: l10n.seatBriefPayRate(_current.payPercent),
        ),
        const SizedBox(height: 28),
        Text(
          l10n.seatBriefScoreTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.seatBriefScoreHint,
          style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Preset(
              key: const Key('seat-score-tab-region'),
              label: l10n.seatBriefScoreRegion,
              selected: _scoreTab == _ScoreTab.region,
              onTap: () => setState(() => _scoreTab = _ScoreTab.region),
            ),
            _Preset(
              key: const Key('seat-score-tab-product'),
              label: l10n.seatBriefScoreProduct,
              selected: _scoreTab == _ScoreTab.product,
              onTap: () => setState(() => _scoreTab = _ScoreTab.product),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_scoreRows.isEmpty)
          Text(
            l10n.seatBriefMissedEmpty,
            key: const Key('seat-score-empty'),
            style: const TextStyle(color: AdminConsoleTheme.muted),
          )
        else
          for (final row in _scoreRows)
            _ScoreCard(
              row: row,
              counts: l10n.seatBriefScoreCounts(row.views, row.flags, row.pays),
              fill: l10n.seatBriefScoreFill(row.fillPercent),
              badge: _badgeLabel(l10n, row.badge),
              badgeColor: _badgeColor(row.badge),
              showRegion: _scoreTab == _ScoreTab.product,
            ),
        const SizedBox(height: 28),
        Text(
          l10n.seatBriefMissedTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.seatBriefMissedHint,
          style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (_demand.isEmpty)
          Text(
            l10n.seatBriefMissedEmpty,
            key: const Key('seat-demand-empty'),
            style: const TextStyle(color: AdminConsoleTheme.muted),
          )
        else ...[
          Text(
            l10n.seatBriefMissedTop,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _demand.top.length; i++)
            _DemandRank(
              index: i + 1,
              label: _demandLine(l10n, _demand.top[i]),
              count: l10n.seatBriefMissedCount(_demand.top[i].count),
              delta: _demandPrevious == null
                  ? null
                  : seatBriefDeltaLabel(
                      _demand.top[i].count,
                      _demandPrevious!.countFor(_demand.top[i].search),
                    ),
            ),
          const SizedBox(height: 18),
          Text(
            l10n.seatBriefMissedWall,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.seatBriefMissedWallHint,
            style: const TextStyle(
              color: AdminConsoleTheme.muted,
              fontSize: 12,
            ),
          ),
          if (_demand.walls.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.seatBriefMissedEmpty,
                key: const Key('seat-demand-wall-empty'),
                style: const TextStyle(color: AdminConsoleTheme.muted),
              ),
            )
          else
            for (final wall in _demand.walls)
              _FunnelRow(
                countKey: Key('seat-demand-wall-${wall.unlock.name}'),
                deltaKey: Key('seat-demand-wall-${wall.unlock.name}-delta'),
                label: _unlockLabel(l10n, wall.unlock),
                count: wall.count,
                previous: _demandPrevious == null
                    ? null
                    : _demandPrevious!.wallCount(wall.unlock),
                maxCount: _demand.walls
                    .map((item) => item.count)
                    .reduce((a, b) => a > b ? a : b),
                caption: null,
              ),
        ],
      ],
      ),
    );
  }
}

class _Preset extends StatelessWidget {
  const _Preset({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AdminConsoleTheme.aqua : AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected
                    ? AdminConsoleTheme.bg
                    : AdminConsoleTheme.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FunnelRow extends StatelessWidget {
  const _FunnelRow({
    required this.countKey,
    required this.deltaKey,
    required this.label,
    required this.count,
    required this.previous,
    required this.maxCount,
    required this.caption,
  });

  final Key countKey;
  final Key deltaKey;
  final String label;
  final int count;
  final int? previous;
  final int maxCount;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : count / maxCount;
    final delta = previous == null
        ? null
        : seatBriefDeltaLabel(count, previous!);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AdminConsoleTheme.muted),
                ),
              ),
              Text(
                '$count',
                key: countKey,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 8),
                Text(
                  delta,
                  key: deltaKey,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: delta.startsWith('+')
                        ? AdminConsoleTheme.aqua
                        : delta.startsWith('-')
                        ? AdminConsoleTheme.danger
                        : AdminConsoleTheme.muted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AdminConsoleTheme.surfaceHigh,
              color: AdminConsoleTheme.aqua,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: const TextStyle(
                color: AdminConsoleTheme.muted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DemandRank extends StatelessWidget {
  const _DemandRank({
    required this.index,
    required this.label,
    required this.count,
    required this.delta,
  });

  final int index;
  final String label;
  final String count;
  final String? delta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(
            '$index',
            style: const TextStyle(
              color: AdminConsoleTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              key: Key('seat-demand-rank-${index - 1}'),
            ),
          ),
          Text(
            count,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (delta != null) ...[
            const SizedBox(width: 8),
            Text(
              delta!,
              key: Key('seat-demand-rank-${index - 1}-delta'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: delta!.startsWith('+')
                    ? AdminConsoleTheme.aqua
                    : delta!.startsWith('-')
                    ? AdminConsoleTheme.danger
                    : AdminConsoleTheme.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _demandLine(AppLocalizations l10n, SeatDemandGroup group) {
  final parts = <String>[];
  final names = <String>[];
  for (final id in group.search.regionIds) {
    for (final region in RegionCatalog.known) {
      if (region.id == id) {
        names.add(region.name);
        break;
      }
    }
  }
  if (names.isNotEmpty) {
    parts.add(names.join(', '));
  }
  final when = _demandWhen(l10n, group);
  if (when != null) {
    parts.add(when);
  }
  final party = group.search.party;
  if (party != null) {
    parts.add(
      party >= SameBoatSearch.partyFivePlus
          ? l10n.sameBoatSearchPartyFivePlus
          : l10n.sameBoatSearchPartyCount(party),
    );
  }
  final budget = group.search.budgetMax;
  if (budget == SameBoatSearch.budget50) {
    parts.add(l10n.sameBoatSearchBudget50);
  } else if (budget == SameBoatSearch.budget100) {
    parts.add(l10n.sameBoatSearchBudget100);
  } else if (budget == SameBoatSearch.budget200) {
    parts.add(l10n.sameBoatSearchBudget200);
  }
  final more = <String>[
    if (group.search.lastCall) l10n.sameBoatSearchLastCall,
    if (group.search.departingSoon) l10n.sameBoatSearchDeparting,
  ];
  if (more.isNotEmpty) {
    parts.add(more.join(', '));
  }
  return parts.join(' · ');
}

String? _demandWhen(AppLocalizations l10n, SeatDemandGroup group) {
  final local = group.latestAt.toLocal();
  switch (group.search.when) {
    case SameBoatWhen.any:
      return null;
    case SameBoatWhen.thisMonth:
      return l10n.sameBoatAlertMonth(local.month);
    case SameBoatWhen.nextMonth:
      return l10n.sameBoatAlertMonth(DateTime(local.year, local.month + 1).month);
    case SameBoatWhen.withinThreeMonths:
      return l10n.sameBoatSearchThreeMonths;
  }
}

String _unlockLabel(AppLocalizations l10n, SeatUnlock unlock) {
  switch (unlock) {
    case SeatUnlock.budget:
      return l10n.sameBoatUnlockBudget;
    case SeatUnlock.party:
      return l10n.sameBoatUnlockParty;
    case SeatUnlock.when:
      return l10n.sameBoatUnlockWhen;
    case SeatUnlock.where:
      return l10n.sameBoatUnlockWhere;
    case SeatUnlock.more:
      return l10n.sameBoatUnlockMore;
  }
}

String _badgeLabel(AppLocalizations l10n, SeatScoreBadge badge) {
  return switch (badge) {
    SeatScoreBadge.selling => l10n.seatBriefBadgeSelling,
    SeatScoreBadge.viewsOnly => l10n.seatBriefBadgeViews,
    SeatScoreBadge.quiet => l10n.seatBriefBadgeQuiet,
    SeatScoreBadge.ordinary => l10n.seatBriefBadgeOrdinary,
  };
}

Color _badgeColor(SeatScoreBadge badge) {
  return switch (badge) {
    SeatScoreBadge.selling => const Color(0xFF3DDC97),
    SeatScoreBadge.viewsOnly => AdminConsoleTheme.amber,
    SeatScoreBadge.quiet => AdminConsoleTheme.ice,
    SeatScoreBadge.ordinary => AdminConsoleTheme.muted,
  };
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.row,
    required this.counts,
    required this.fill,
    required this.badge,
    required this.badgeColor,
    required this.showRegion,
  });

  final SeatScoreRow row;
  final String counts;
  final String fill;
  final String badge;
  final Color badgeColor;
  final bool showRegion;

  @override
  Widget build(BuildContext context) {
    final prefix = showRegion ? 'product' : 'region';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AdminConsoleTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.title,
                  key: Key('seat-score-$prefix-${row.id}'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                badge,
                key: Key('seat-score-badge-${row.id}'),
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (showRegion && row.regionName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              row.regionName,
              key: Key('seat-score-product-${row.id}-region'),
              style: const TextStyle(
                color: AdminConsoleTheme.muted,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  counts,
                  key: Key('seat-score-counts-${row.id}'),
                  style: const TextStyle(color: AdminConsoleTheme.muted),
                ),
              ),
              Text(
                fill,
                key: Key('seat-score-fill-${row.id}'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: row.fillPercent / 100,
              minHeight: 8,
              backgroundColor: AdminConsoleTheme.surfaceHigh,
              color: AdminConsoleTheme.aqua,
            ),
          ),
        ],
      ),
    );
  }
}
