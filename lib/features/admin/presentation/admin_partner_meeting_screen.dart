import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/seat_brief.dart';
import 'package:dive_travel_app/core/models/seat_life.dart';
import 'package:dive_travel_app/core/models/seat_score.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_meeting_archive_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_partner_meeting_preview.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Conditions for one partner's meeting report. Does not save or send.
class AdminPartnerMeetingScreen extends StatefulWidget {
  const AdminPartnerMeetingScreen({super.key, this.now, this.onPrint});

  final DateTime? now;
  final Future<void> Function(Uint8List bytes)? onPrint;

  @override
  State<AdminPartnerMeetingScreen> createState() =>
      _AdminPartnerMeetingScreenState();
}

class _ScopeChoice {
  const _ScopeChoice({
    required this.id,
    required this.label,
    required this.regionId,
    required this.productIds,
  });

  final String id;
  final String label;
  final String regionId;
  final List<String> productIds;
}

class _AdminPartnerMeetingScreenState extends State<AdminPartnerMeetingScreen> {
  SeatBriefPreset _preset = SeatBriefPreset.sevenDays;
  DateTime? _customStart;
  DateTime? _customEnd;
  String? _shopId;
  String _scopeId = 'all';
  var _compare = false;
  var _conclusion = true;
  var _funnel = true;
  var _scorecard = true;
  var _demand = true;
  var _proposals = true;
  var _loading = true;
  var _building = false;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadShops());
  }

  Future<void> _loadShops() async {
    final store = DiverStoreScope.of(context);
    try {
      await store.ensureShopStatsLoaded();
    } catch (error, stackTrace) {
      debugPrint('partner meeting shops failed $error');
      debugPrint('$stackTrace');
    }
    if (!mounted) {
      return;
    }
    final shops = store.shopStats;
    setState(() {
      _loading = false;
      if (_shopId == null && shops.isNotEmpty) {
        _shopId = shops.first.shopId;
      }
    });
  }

  SeatBriefWindow get _window => seatBriefWindow(
    preset: _preset,
    now: _now,
    customStart: _customStart,
    customEnd: _customEnd,
  );

  ShopLiveStats? get _shop {
    final id = _shopId;
    if (id == null) {
      return null;
    }
    final store = DiverStoreScope.of(context);
    for (final stats in store.shopStats) {
      if (partnerShopHull(stats.shopId) == partnerShopHull(id)) {
        return stats;
      }
    }
    return null;
  }

  List<_ScopeChoice> _scopes(AppLocalizations l10n, ShopLiveStats shop) {
    final grouped = <String, List<ShopProduct>>{};
    for (final product in shop.products) {
      final region = _regionId(shop, product);
      grouped.putIfAbsent(region, () => []).add(product);
    }
    final choices = <_ScopeChoice>[
      _ScopeChoice(
        id: 'all',
        label: l10n.partnerMeetingScopeAll(shop.products.length),
        regionId: grouped.length == 1 ? grouped.keys.first : '',
        productIds: const [],
      ),
    ];
    final regions = grouped.keys.where((id) => id.isNotEmpty).toList()..sort();
    for (final region in regions) {
      final products = grouped[region]!;
      final name = seatCatalogRegionName(region);
      choices.add(
        _ScopeChoice(
          id: 'region:$region',
          label: l10n.partnerMeetingScopeRegion(
            name.isEmpty ? region : name,
            products.length,
          ),
          regionId: region,
          productIds: [for (final product in products) product.id],
        ),
      );
    }
    final products = [...shop.products]
      ..sort((a, b) => a.name.compareTo(b.name));
    for (final product in products) {
      choices.add(
        _ScopeChoice(
          id: 'product:${product.id}',
          label: product.name.isEmpty ? product.id : product.name,
          regionId: _regionId(shop, product),
          productIds: [product.id],
        ),
      );
    }
    return choices;
  }

  _ScopeChoice _selectedScope(List<_ScopeChoice> choices) {
    for (final choice in choices) {
      if (choice.id == _scopeId) {
        return choice;
      }
    }
    return choices.first;
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
  }

  Future<void> _preview() async {
    final shop = _shop;
    if (shop == null || _building) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final choices = _scopes(l10n, shop);
    final scope = _selectedScope(choices);
    final window = _window;
    setState(() => _building = true);
    try {
      final events = await store.seatEventsBetween(
        from: window.start,
        to: window.end,
      );
      final demands = await store.seatDemandsBetween(
        from: window.start,
        to: window.end,
      );
      final earlier = seatBriefPreviousWindow(window);
      final List<SeatLifeEvent> previous = _compare
          ? await store.seatEventsBetween(from: earlier.start, to: earlier.end)
          : const <SeatLifeEvent>[];
      final recipe = MeetingReportRecipe(
        shopId: shop.shopId,
        productIds: scope.productIds,
        regionId: scope.regionId,
        periodStart: window.start,
        periodEnd: window.end.subtract(const Duration(days: 1)),
        compare: _compare,
        sections: MeetingReportSections(
          conclusion: _conclusion,
          funnel: _funnel,
          scorecard: _scorecard,
          demand: _demand,
          proposals: _proposals,
        ),
      );
      final report = buildPartnerMeetingReport(
        id: 'preview',
        recipe: recipe,
        events: events,
        demands: demands,
        seats: meetingReportSeats(shop),
        createdAt: _now,
        previousEvents: previous,
      );
      if (!mounted) {
        return;
      }
      final name = (shop.name ?? '').trim().isEmpty
          ? shop.shopId
          : shop.name!.trim();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AdminPartnerMeetingPreview(
            report: report,
            shopName: name,
            periodLabel: seatBriefRangeLabel(window),
            onPrint: widget.onPrint,
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('partner meeting preview failed $error');
      debugPrint('$stackTrace');
    } finally {
      if (mounted) {
        setState(() => _building = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shop = _shop;
    final scopes = shop == null ? const <_ScopeChoice>[] : _scopes(l10n, shop);
    final shops = DiverStoreScope.of(context).shopStats;
    return Theme(
      data: AdminConsoleTheme.dark,
      child: Scaffold(
        backgroundColor: AdminConsoleTheme.bg,
        appBar: AppBar(title: Text(l10n.partnerMeetingTitle)),
        body: ListView(
          key: const Key('partner-meeting-form'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Text(
              l10n.partnerMeetingHint,
              style: const TextStyle(color: AdminConsoleTheme.muted),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Chip(
                    key: const Key('partner-meeting-preset-today'),
                    label: l10n.seatBriefToday,
                    selected: _preset == SeatBriefPreset.today,
                    onTap: () =>
                        setState(() => _preset = SeatBriefPreset.today),
                  ),
                  _Chip(
                    key: const Key('partner-meeting-preset-7'),
                    label: l10n.seatBriefSeven,
                    selected: _preset == SeatBriefPreset.sevenDays,
                    onTap: () =>
                        setState(() => _preset = SeatBriefPreset.sevenDays),
                  ),
                  _Chip(
                    key: const Key('partner-meeting-preset-30'),
                    label: l10n.seatBriefThirty,
                    selected: _preset == SeatBriefPreset.thirtyDays,
                    onTap: () =>
                        setState(() => _preset = SeatBriefPreset.thirtyDays),
                  ),
                  _Chip(
                    key: const Key('partner-meeting-preset-year'),
                    label: l10n.seatBriefYear,
                    selected: _preset == SeatBriefPreset.thisYear,
                    onTap: () =>
                        setState(() => _preset = SeatBriefPreset.thisYear),
                  ),
                  _Chip(
                    key: const Key('partner-meeting-preset-custom'),
                    label: l10n.seatBriefCustom,
                    selected: _preset == SeatBriefPreset.custom,
                    onTap: _pickCustom,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              seatBriefRangeLabel(_window),
              key: const Key('partner-meeting-range'),
              style: const TextStyle(color: AdminConsoleTheme.muted),
            ),
            const SizedBox(height: 16),
            Text(l10n.partnerMeetingPartner),
            const SizedBox(height: 6),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2)
            else if (shops.isEmpty)
              Text(
                l10n.partnerMeetingNoShop,
                key: const Key('partner-meeting-no-shop'),
              )
            else
              DropdownButton<String>(
                key: const Key('partner-meeting-shop'),
                isExpanded: true,
                value: _shopId,
                items: [
                  for (final stats in shops)
                    DropdownMenuItem(
                      value: stats.shopId,
                      child: Text(_shopLabel(stats)),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _shopId = value;
                    _scopeId = 'all';
                  });
                },
              ),
            const SizedBox(height: 12),
            Text(l10n.partnerMeetingScope),
            const SizedBox(height: 6),
            if (scopes.isNotEmpty)
              DropdownButton<String>(
                key: const Key('partner-meeting-scope'),
                isExpanded: true,
                value: scopes.any((choice) => choice.id == _scopeId)
                    ? _scopeId
                    : 'all',
                items: [
                  for (final choice in scopes)
                    DropdownMenuItem(
                      value: choice.id,
                      child: Text(choice.label),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _scopeId = value);
                },
              ),
            SwitchListTile(
              key: const Key('partner-meeting-compare'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.seatBriefCompare),
              value: _compare,
              onChanged: (value) => setState(() => _compare = value),
            ),
            const SizedBox(height: 8),
            _Check(
              id: 'conclusion',
              title: l10n.partnerMeetingConclusion,
              hint: l10n.partnerMeetingConclusionHint,
              value: _conclusion,
              onChanged: (value) => setState(() => _conclusion = value),
            ),
            _Check(
              id: 'funnel',
              title:
                  '${l10n.partnerMeetingFunnel} (${l10n.partnerMeetingFunnelHint})',
              hint: '',
              value: _funnel,
              onChanged: (value) => setState(() => _funnel = value),
            ),
            _Check(
              id: 'scorecard',
              title: l10n.seatBriefScoreTitle,
              hint: l10n.partnerMeetingScoreHint,
              value: _scorecard,
              onChanged: (value) => setState(() => _scorecard = value),
            ),
            _Check(
              id: 'demand',
              title: l10n.seatBriefMissedTitle,
              hint: l10n.partnerMeetingDemandHint,
              value: _demand,
              onChanged: (value) => setState(() => _demand = value),
            ),
            _Check(
              id: 'proposals',
              title: l10n.partnerMeetingProposals,
              hint: l10n.partnerMeetingProposalsHint,
              value: _proposals,
              onChanged: (value) => setState(() => _proposals = value),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.partnerMeetingLock,
              style: const TextStyle(
                color: AdminConsoleTheme.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('partner-meeting-archive'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AdminMeetingArchiveScreen(now: _now),
                  ),
                );
              },
              child: Text(l10n.partnerMeetingArchive),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('partner-meeting-preview'),
              onPressed: shop == null || _building ? null : _preview,
              child: Text(l10n.partnerMeetingPreview),
            ),
          ],
        ),
      ),
    );
  }
}

String _shopLabel(ShopLiveStats stats) {
  final name = (stats.name ?? '').trim();
  return name.isEmpty ? stats.shopId : name;
}

String _regionId(ShopLiveStats shop, ShopProduct product) {
  return seatCatalogRegionId(
        SameBoatPlace(
          continent: product.continent,
          location: shop.location ?? '',
          country: shop.country ?? '',
          sites: [if ((shop.continent ?? '').isNotEmpty) shop.continent!],
        ),
      ) ??
      '';
}

List<MeetingReportSeat> meetingReportSeats(ShopLiveStats shop) {
  final seats = <MeetingReportSeat>[];
  for (final product in shop.products) {
    final region = _regionId(shop, product);
    final options = [
      for (final option in product.options)
        if (option.capacity > 0) option,
    ];
    if (options.isEmpty) {
      seats.add(
        MeetingReportSeat(
          shopId: shop.shopId,
          productId: product.id,
          productName: product.name,
          regionId: region,
          booked: product.bookedSeats,
          capacity: product.capacity,
        ),
      );
      continue;
    }
    for (final option in options) {
      seats.add(
        MeetingReportSeat(
          shopId: shop.shopId,
          productId: product.id,
          productName: product.name,
          regionId: region,
          booked: option.bookedSeats,
          capacity: option.capacity,
        ),
      );
    }
  }
  return seats;
}

class _Chip extends StatelessWidget {
  const _Chip({
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
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({
    required this.id,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final String id;
  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: Key('partner-meeting-section-$id'),
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: (next) => onChanged(next ?? false),
      title: Text(title),
      subtitle: hint.isEmpty ? null : Text(hint),
    );
  }
}
