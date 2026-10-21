import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Creator UI: open leftover seats on a product (base package and/or individual SKUs).
/// Submits as [SameBoatStatus.pending] for admin approval before the board goes live.
class SameBoatSeatsScreen extends StatefulWidget {
  const SameBoatSeatsScreen({
    super.key,
    required this.product,
    this.adminBypassApproval = false,
  });

  final ShopProduct product;

  /// Admin curated/specials can publish straight to the board.
  final bool adminBypassApproval;

  @override
  State<SameBoatSeatsScreen> createState() => _SameBoatSeatsScreenState();
}

class _SameBoatSeatsScreenState extends State<SameBoatSeatsScreen> {
  late bool _openPackage;
  late final TextEditingController _capacity;
  late DateTime? _departure;
  late DateTime? _flagClose;
  late final Map<String, _OptionDraft> _options;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _openPackage = p.openEmptySeats || p.sameBoatStatus != SameBoatStatus.closed;
    _capacity = TextEditingController(
      text: p.capacity > 0 ? '${p.capacity}' : '',
    );
    _departure = p.departureStart;
    _flagClose = p.flagClosesAt;
    _options = {
      for (final o in p.options)
        if (o.kind == ProductOptionKind.individual ||
            o.kind == ProductOptionKind.basePackage ||
            o.openEmptySeats ||
            o.sameBoatStatus != SameBoatStatus.closed)
          o.id: _OptionDraft.from(o),
    };
    // Always offer individual SKUs even if never opened.
    for (final o in p.options) {
      if (o.kind == ProductOptionKind.individual && !_options.containsKey(o.id)) {
        _options[o.id] = _OptionDraft.from(o);
      }
    }
  }

  @override
  void dispose() {
    _capacity.dispose();
    for (final d in _options.values) {
      d.dispose();
    }
    super.dispose();
  }

  String _optionName(String id) {
    for (final option in widget.product.options) {
      if (option.id == id) {
        return option.name;
      }
    }
    return id;
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) {
      onPicked(DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final status = widget.adminBypassApproval
        ? SameBoatStatus.approved
        : SameBoatStatus.pending;

    final packageCap = int.tryParse(_capacity.text.trim()) ?? 0;
    if (_openPackage) {
      if (packageCap <= 0 || _departure == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workbenchOpenSeatsNeedFields)),
        );
        return;
      }
    }
    for (final draft in _options.values) {
      if (!draft.open) continue;
      final cap = int.tryParse(draft.capacity.text.trim()) ?? 0;
      if (cap <= 0 || draft.departure == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workbenchOpenSeatsNeedFields)),
        );
        return;
      }
    }

    setState(() => _saving = true);
    final nextOptions = [
      for (final option in widget.product.options)
        if (_options.containsKey(option.id))
          _options[option.id]!.apply(option, status)
        else
          option,
    ];
    final next = widget.product.copyWith(
      openEmptySeats: _openPackage,
      capacity: _openPackage ? packageCap : widget.product.capacity,
      departureStart: _openPackage ? _departure : widget.product.departureStart,
      flagClosesAt: _openPackage ? _flagClose : widget.product.flagClosesAt,
      sameBoatStatus: _openPackage ? status : SameBoatStatus.closed,
      options: nextOptions,
    );
    try {
      await store.saveShopProduct(
        shopId: next.shopId,
        product: next,
        intent: ProductSaveIntent.preserveListing,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.adminBypassApproval
                ? l10n.sameBoatSeatsPublished
                : l10n.sameBoatSeatsSubmitted,
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dayFmt = DateFormat('yyyy.MM.dd');
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sameBoatSeatsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(l10n.sameBoatSeatsHint, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            widget.product.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            key: const Key('same-boat-open-package'),
            title: Text(l10n.workbenchOpenSeats),
            subtitle: Text(l10n.workbenchOpenSeatsHint),
            value: _openPackage,
            onChanged: (v) => setState(() => _openPackage = v),
          ),
          if (_openPackage) ...[
            TextField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l10n.workbenchSeatCount),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.workbenchDepartureDate),
              subtitle: Text(
                _departure == null ? '—' : dayFmt.format(_departure!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(
                current: _departure,
                onPicked: (d) => setState(() => _departure = d),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.workbenchFlagDeadline),
              subtitle: Text(
                _flagClose == null ? '—' : dayFmt.format(_flagClose!),
              ),
              trailing: const Icon(Icons.flag_outlined),
              onTap: () => _pickDate(
                current: _flagClose,
                onPicked: (d) => setState(() => _flagClose = d),
              ),
            ),
            Text(
              l10n.sameBoatHoldPriorityHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_options.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.sameBoatIndividualSeats,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final entry in _options.entries) ...[
              _OptionSeatCard(
                name: _optionName(entry.key),
                draft: entry.value,
                dayFmt: dayFmt,
                onPickDeparture: () => _pickDate(
                  current: entry.value.departure,
                  onPicked: (d) => setState(() => entry.value.departure = d),
                ),
                onPickFlag: () => _pickDate(
                  current: entry.value.flagClose,
                  onPicked: (d) => setState(() => entry.value.flagClose = d),
                ),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('same-boat-seats-submit'),
            onPressed: _saving ? null : _submit,
            child: Text(
              widget.adminBypassApproval
                  ? l10n.sameBoatSeatsPublish
                  : l10n.sameBoatSeatsSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionDraft {
  _OptionDraft({
    required this.open,
    required this.capacity,
    required this.departure,
    required this.flagClose,
  });

  factory _OptionDraft.from(ShopProductOption o) {
    return _OptionDraft(
      open: o.openEmptySeats || o.sameBoatStatus != SameBoatStatus.closed,
      capacity: TextEditingController(
        text: o.capacity > 0 ? '${o.capacity}' : '',
      ),
      departure: o.departureStart,
      flagClose: o.flagClosesAt,
    );
  }

  bool open;
  final TextEditingController capacity;
  DateTime? departure;
  DateTime? flagClose;

  void dispose() => capacity.dispose();

  ShopProductOption apply(ShopProductOption base, SameBoatStatus status) {
    final cap = int.tryParse(capacity.text.trim()) ?? 0;
    return base.copyWith(
      openEmptySeats: open,
      capacity: open ? cap : base.capacity,
      departureStart: open ? departure : base.departureStart,
      flagClosesAt: open ? flagClose : base.flagClosesAt,
      sameBoatStatus: open ? status : SameBoatStatus.closed,
    );
  }
}

class _OptionSeatCard extends StatelessWidget {
  const _OptionSeatCard({
    required this.name,
    required this.draft,
    required this.dayFmt,
    required this.onPickDeparture,
    required this.onPickFlag,
    required this.onChanged,
  });

  final String name;
  final _OptionDraft draft;
  final DateFormat dayFmt;
  final VoidCallback onPickDeparture;
  final VoidCallback onPickFlag;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(name),
              value: draft.open,
              onChanged: (v) {
                draft.open = v;
                onChanged();
              },
            ),
            if (draft.open) ...[
              TextField(
                controller: draft.capacity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l10n.workbenchSeatCount),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.workbenchDepartureDate),
                subtitle: Text(
                  draft.departure == null
                      ? '—'
                      : dayFmt.format(draft.departure!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: onPickDeparture,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.workbenchFlagDeadline),
                subtitle: Text(
                  draft.flagClose == null
                      ? '—'
                      : dayFmt.format(draft.flagClose!),
                ),
                trailing: const Icon(Icons.flag_outlined),
                onTap: onPickFlag,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
