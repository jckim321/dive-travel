import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class SameBoatRegionChoice {
  const SameBoatRegionChoice({
    required this.id,
    required this.name,
    required this.count,
  });

  final String id;
  final String name;
  final int count;
}

class SameBoatSearchBar extends StatelessWidget {
  const SameBoatSearchBar({
    super.key,
    required this.search,
    required this.expanded,
    required this.resultCount,
    required this.regions,
    required this.countFor,
    required this.onChanged,
    required this.onExpand,
  });

  final SameBoatSearch search;
  final bool expanded;
  final int resultCount;
  final List<SameBoatRegionChoice> regions;
  final int Function(SameBoatSearch draft) countFor;
  final ValueChanged<SameBoatSearch> onChanged;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!expanded) {
      return Material(
        color: AppTheme.canvas,
        child: InkWell(
          key: const Key('same-boat-search-summary'),
          onTap: onExpand,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.tune, size: 18, color: AppTheme.navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _summary(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                ),
                Text(
                  l10n.sameBoatSearchOpenCount(resultCount),
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      key: const Key('same-boat-search-bar'),
      color: AppTheme.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Chip(
                    key: const Key('same-boat-chip-when'),
                    label: _whenLabel(l10n),
                    selected: search.when != SameBoatWhen.any,
                    onTap: () => _openWhen(context, l10n),
                  ),
                  _Chip(
                    key: const Key('same-boat-chip-where'),
                    label: _whereLabel(l10n),
                    selected: search.regionIds.isNotEmpty,
                    onTap: () => _openWhere(context, l10n),
                  ),
                  _Chip(
                    key: const Key('same-boat-chip-party'),
                    label: _partyLabel(l10n),
                    selected: search.party != null,
                    onTap: () => _openParty(context, l10n),
                  ),
                  _Chip(
                    key: const Key('same-boat-chip-budget'),
                    label: _budgetLabel(l10n),
                    selected: search.budgetMax != null,
                    onTap: () => _openBudget(context, l10n),
                  ),
                  _Chip(
                    key: const Key('same-boat-chip-more'),
                    label: _moreLabel(l10n),
                    selected: search.lastCall || search.departingSoon,
                    onTap: () => _openMore(context, l10n),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  l10n.sameBoatSearchOpenCount(resultCount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.sameBoatSearchSortNewest,
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _summary(AppLocalizations l10n) {
    if (!search.hasActiveFilter) {
      return l10n.sameBoatSearchAllSeats;
    }
    final parts = <String>[
      if (search.when != SameBoatWhen.any) _whenLabel(l10n),
      if (search.regionIds.isNotEmpty) _whereLabel(l10n),
      if (search.party != null) _partyLabel(l10n),
      if (search.budgetMax != null) _budgetLabel(l10n),
      if (search.lastCall) l10n.sameBoatSearchLastCall,
      if (search.departingSoon) l10n.sameBoatSearchDeparting,
    ];
    return parts.join(' · ');
  }

  String _whenLabel(AppLocalizations l10n) {
    return switch (search.when) {
      SameBoatWhen.any => l10n.sameBoatSearchWhen,
      SameBoatWhen.thisMonth => l10n.sameBoatSearchThisMonth,
      SameBoatWhen.nextMonth => l10n.sameBoatSearchNextMonth,
      SameBoatWhen.withinThreeMonths => l10n.sameBoatSearchThreeMonths,
    };
  }

  String _whereLabel(AppLocalizations l10n) {
    if (search.regionIds.isEmpty) {
      return l10n.sameBoatSearchWhere;
    }
    final names = <String>[];
    for (final id in search.regionIds) {
      for (final region in regions) {
        if (region.id == id) {
          names.add(region.name);
          break;
        }
      }
    }
    if (names.isEmpty) {
      return l10n.sameBoatSearchWhere;
    }
    return names.join(', ');
  }

  String _partyLabel(AppLocalizations l10n) {
    final party = search.party;
    if (party == null) {
      return l10n.sameBoatSearchParty;
    }
    if (party >= SameBoatSearch.partyFivePlus) {
      return l10n.sameBoatSearchPartyFivePlus;
    }
    return l10n.sameBoatSearchPartyCount(party);
  }

  String _budgetLabel(AppLocalizations l10n) {
    return switch (search.budgetMax) {
      SameBoatSearch.budget50 => l10n.sameBoatSearchBudget50,
      SameBoatSearch.budget100 => l10n.sameBoatSearchBudget100,
      SameBoatSearch.budget200 => l10n.sameBoatSearchBudget200,
      _ => search.budgetMax == null
          ? l10n.sameBoatSearchBudget
          : l10n.sameBoatSearchBudget,
    };
  }

  String _moreLabel(AppLocalizations l10n) {
    if (search.lastCall && search.departingSoon) {
      return '${l10n.sameBoatSearchLastCall}, ${l10n.sameBoatSearchDeparting}';
    }
    if (search.lastCall) {
      return l10n.sameBoatSearchLastCall;
    }
    if (search.departingSoon) {
      return l10n.sameBoatSearchDeparting;
    }
    return l10n.sameBoatSearchMore;
  }

  Future<void> _openWhen(BuildContext context, AppLocalizations l10n) async {
    final picked = await _showSheet<SameBoatWhen>(
      context,
      title: l10n.sameBoatSearchWhen,
      draft: search.when,
      reset: SameBoatWhen.any,
      choices: [
        (SameBoatWhen.any, l10n.communityFilterAll),
        (SameBoatWhen.thisMonth, l10n.sameBoatSearchThisMonth),
        (SameBoatWhen.nextMonth, l10n.sameBoatSearchNextMonth),
        (SameBoatWhen.withinThreeMonths, l10n.sameBoatSearchThreeMonths),
      ],
      countFor: (when) => countFor(search.copyWith(when: when)),
    );
    if (picked != null) {
      onChanged(search.copyWith(when: picked));
    }
  }

  Future<void> _openParty(BuildContext context, AppLocalizations l10n) async {
    final picked = await _showSheet<int>(
      context,
      title: l10n.sameBoatSearchParty,
      draft: search.party ?? 0,
      reset: 0,
      choices: [
        (0, l10n.communityFilterAll),
        (1, l10n.sameBoatSearchPartyCount(1)),
        (2, l10n.sameBoatSearchPartyCount(2)),
        (3, l10n.sameBoatSearchPartyCount(3)),
        (4, l10n.sameBoatSearchPartyCount(4)),
        (SameBoatSearch.partyFivePlus, l10n.sameBoatSearchPartyFivePlus),
      ],
      countFor: (party) => countFor(
        party == 0
            ? search.copyWith(clearParty: true)
            : search.copyWith(party: party),
      ),
    );
    if (picked == null) {
      return;
    }
    onChanged(
      picked == 0
          ? search.copyWith(clearParty: true)
          : search.copyWith(party: picked),
    );
  }

  Future<void> _openBudget(BuildContext context, AppLocalizations l10n) async {
    final picked = await _showSheet<int>(
      context,
      title: l10n.sameBoatSearchBudget,
      draft: search.budgetMax ?? 0,
      reset: 0,
      choices: [
        (0, l10n.sameBoatSearchBudgetAny),
        (SameBoatSearch.budget50, l10n.sameBoatSearchBudget50),
        (SameBoatSearch.budget100, l10n.sameBoatSearchBudget100),
        (SameBoatSearch.budget200, l10n.sameBoatSearchBudget200),
      ],
      countFor: (budget) => countFor(
        budget == 0
            ? search.copyWith(clearBudget: true)
            : search.copyWith(budgetMax: budget),
      ),
    );
    if (picked == null) {
      return;
    }
    onChanged(
      picked == 0
          ? search.copyWith(clearBudget: true)
          : search.copyWith(budgetMax: picked),
    );
  }

  Future<void> _openWhere(BuildContext context, AppLocalizations l10n) async {
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return _WhereSheet(
          selected: search.regionIds,
          regions: regions,
          countFor: (ids) => countFor(search.copyWith(regionIds: ids)),
        );
      },
    );
    if (picked != null) {
      onChanged(search.copyWith(regionIds: picked));
    }
  }

  Future<void> _openMore(BuildContext context, AppLocalizations l10n) async {
    final picked = await showModalBottomSheet<({bool lastCall, bool departing})>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return _MoreSheet(
          lastCall: search.lastCall,
          departingSoon: search.departingSoon,
          countFor: (lastCall, departing) => countFor(
            search.copyWith(lastCall: lastCall, departingSoon: departing),
          ),
        );
      },
    );
    if (picked != null) {
      onChanged(
        search.copyWith(
          lastCall: picked.lastCall,
          departingSoon: picked.departing,
        ),
      );
    }
  }
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
      child: Material(
        color: selected ? AppTheme.navy : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppTheme.navy : const Color(0xFFE8EBEE),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> _showSheet<T>(
  BuildContext context, {
  required String title,
  required T draft,
  required T reset,
  required List<(T, String)> choices,
  required int Function(T value) countFor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      return _SingleSheet<T>(
        title: title,
        draft: draft,
        reset: reset,
        choices: choices,
        countFor: countFor,
      );
    },
  );
}

class _SingleSheet<T> extends StatefulWidget {
  const _SingleSheet({
    required this.title,
    required this.draft,
    required this.reset,
    required this.choices,
    required this.countFor,
  });

  final String title;
  final T draft;
  final T reset;
  final List<(T, String)> choices;
  final int Function(T value) countFor;

  @override
  State<_SingleSheet<T>> createState() => _SingleSheetState<T>();
}

class _SingleSheetState<T> extends State<_SingleSheet<T>> {
  late T _value = widget.draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in widget.choices)
                _Chip(
                  label: choice.$2,
                  selected: _value == choice.$1,
                  onTap: () => setState(() => _value = choice.$1),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _value = widget.reset),
                child: Text(l10n.sameBoatSearchReset),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_value),
                  child: Text(l10n.sameBoatSearchApply(widget.countFor(_value))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhereSheet extends StatefulWidget {
  const _WhereSheet({
    required this.selected,
    required this.regions,
    required this.countFor,
  });

  final Set<String> selected;
  final List<SameBoatRegionChoice> regions;
  final int Function(Set<String> ids) countFor;

  @override
  State<_WhereSheet> createState() => _WhereSheetState();
}

class _WhereSheetState extends State<_WhereSheet> {
  late Set<String> _ids = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.sameBoatSearchWhere,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    label: l10n.communityFilterAll,
                    selected: _ids.isEmpty,
                    onTap: () => setState(_ids.clear),
                  ),
                  for (final region in widget.regions)
                    _Chip(
                      label: region.count > 0
                          ? '${region.name} ${region.count}'
                          : region.name,
                      selected: _ids.contains(region.id),
                      onTap: () => setState(() {
                        if (_ids.contains(region.id)) {
                          _ids.remove(region.id);
                        } else {
                          _ids.add(region.id);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(_ids.clear),
                child: Text(l10n.sameBoatSearchReset),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_ids),
                  child: Text(l10n.sameBoatSearchApply(widget.countFor(_ids))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreSheet extends StatefulWidget {
  const _MoreSheet({
    required this.lastCall,
    required this.departingSoon,
    required this.countFor,
  });

  final bool lastCall;
  final bool departingSoon;
  final int Function(bool lastCall, bool departing) countFor;

  @override
  State<_MoreSheet> createState() => _MoreSheetState();
}

class _MoreSheetState extends State<_MoreSheet> {
  late var _lastCall = widget.lastCall;
  late var _departing = widget.departingSoon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.sameBoatSearchMore,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: l10n.sameBoatSearchLastCall,
                selected: _lastCall,
                onTap: () => setState(() => _lastCall = !_lastCall),
              ),
              _Chip(
                label: l10n.sameBoatSearchDeparting,
                selected: _departing,
                onTap: () => setState(() => _departing = !_departing),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _lastCall = false;
                  _departing = false;
                }),
                child: Text(l10n.sameBoatSearchReset),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    (lastCall: _lastCall, departing: _departing),
                  ),
                  child: Text(
                    l10n.sameBoatSearchApply(widget.countFor(_lastCall, _departing)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
