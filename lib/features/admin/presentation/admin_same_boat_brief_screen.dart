import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/seat_brief.dart';
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

class _AdminSameBoatBriefScreenState extends State<AdminSameBoatBriefScreen> {
  SeatBriefPreset _preset = SeatBriefPreset.sevenDays;
  DateTime? _customStart;
  DateTime? _customEnd;
  var _compare = false;
  var _loading = true;
  SeatBriefFunnel _current = SeatBriefFunnel.empty;
  SeatBriefFunnel? _previous;

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
      final current = await store.seatEventsBetween(
        from: window.start,
        to: window.end,
      );
      SeatBriefFunnel? previous;
      if (_compare) {
        final earlier = seatBriefPreviousWindow(window);
        final rows = await store.seatEventsBetween(
          from: earlier.start,
          to: earlier.end,
        );
        previous = seatBriefFunnel(rows);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _current = seatBriefFunnel(current);
        _previous = previous;
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
          caption: l10n.seatBriefViewsPerOpen(_current.viewsPerOpen),
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
