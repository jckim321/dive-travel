import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// One option (individual SKU) row for leftover seats.
class SameBoatOptionSeatSlot {
  const SameBoatOptionSeatSlot({required this.id, required this.name});

  final String id;
  final String name;
}

/// Shared state for workbench + [SameBoatSeatsScreen].
class SameBoatSeatOpenController {
  SameBoatSeatOpenController({
    required ShopProduct? existing,
    required List<SameBoatOptionSeatSlot> optionSlots,
    required this.isAdmin,
    DateTime? packageDeparture,
    this.now,
  }) {
    final p = existing;
    _packageWasOpen = p != null &&
        SameBoatSeatOpenLogic.wasAlreadyOpen(
          openEmptySeats: p.openEmptySeats,
          status: p.sameBoatStatus,
        );
    openPackage = _packageWasOpen;
    packageCapacity = TextEditingController(
      text: (p != null && p.capacity > 0) ? '${p.capacity}' : '',
    );
    packageBooked = TextEditingController(
      text: (p != null && p.bookedSeats > 0) ? '${p.bookedSeats}' : '',
    );
    _existingPackageBooked = p?.bookedSeats ?? 0;
    _existingPackageHolds = List<SeatHold>.from(p?.flagHolds ?? const []);
    _packageStatus = p?.sameBoatStatus ?? SameBoatStatus.closed;
    this.packageDeparture = packageDeparture ?? p?.departureStart;
    packageFlagClose = p?.flagClosesAt;
    _syncOptionSlots(optionSlots, existing: p);
  }

  bool isAdmin;

  /// Clock for the schedule lock. Tests pass a fixed time.
  final DateTime? now;

  DateTime get _now => now ?? DateTime.now();

  late bool openPackage;
  late final TextEditingController packageCapacity;
  late final TextEditingController packageBooked;
  DateTime? packageDeparture;
  DateTime? packageFlagClose;

  late bool _packageWasOpen;
  late int _existingPackageBooked;
  late List<SeatHold> _existingPackageHolds;
  late SameBoatStatus _packageStatus;

  final Map<String, SameBoatOptionSeatDraft> options = {};

  bool get packageWasAlreadyOpen => _packageWasOpen;

  int get existingPackageBooked => _existingPackageBooked;

  List<SeatHold> get existingPackageHolds => _existingPackageHolds;

  SameBoatStatus get packageStatus => _packageStatus;

  /// Locked when this product already has a booking or a live flag.
  /// Counts come from the product document, not analytics.
  bool get packageScheduleLocked => SameBoatSeatOpenLogic.scheduleLocked(
        booked: _existingPackageBooked,
        holds: _existingPackageHolds,
        now: _now,
      );

  bool optionScheduleLocked(String id) {
    final draft = options[id];
    if (draft == null) {
      return false;
    }
    return SameBoatSeatOpenLogic.scheduleLocked(
      booked: draft.existingBooked,
      holds: draft.existingHolds,
      now: _now,
    );
  }

  void syncPackageDeparture(DateTime? value) {
    packageDeparture = value;
  }

  void syncOptionSlots(
    List<SameBoatOptionSeatSlot> slots, {
    ShopProduct? existing,
  }) {
    _syncOptionSlots(slots, existing: existing);
  }

  void _syncOptionSlots(
    List<SameBoatOptionSeatSlot> slots, {
    ShopProduct? existing,
  }) {
    final keep = <String>{};
    for (final slot in slots) {
      keep.add(slot.id);
      if (options.containsKey(slot.id)) {
        options[slot.id]!.name = slot.name;
        continue;
      }
      ShopProductOption? prior;
      for (final o in existing?.options ?? const <ShopProductOption>[]) {
        if (o.id == slot.id) {
          prior = o;
          break;
        }
      }
      options[slot.id] = SameBoatOptionSeatDraft.from(
        slot: slot,
        prior: prior,
      );
    }
    final drop = [
      for (final id in options.keys)
        if (!keep.contains(id)) id,
    ];
    for (final id in drop) {
      options.remove(id)?.dispose();
    }
  }

  void dispose() {
    packageCapacity.dispose();
    packageBooked.dispose();
    for (final d in options.values) {
      d.dispose();
    }
  }

  /// Validates open rows; returns localized snack text or null if ok.
  String? validate(AppLocalizations l10n, {required DateTime now}) {
    if (openPackage) {
      final cap = int.tryParse(packageCapacity.text.trim()) ?? 0;
      if (cap <= 0 || packageDeparture == null) {
        return l10n.workbenchOpenSeatsNeedFields;
      }
      if (packageFlagClose == null) {
        return l10n.workbenchFlagDeadlineRequired;
      }
      final booked = SameBoatSeatOpenLogic.resolveBookedSeats(
        nowOpen: true,
        wasAlreadyOpen: _packageWasOpen,
        formBooked: int.tryParse(packageBooked.text.trim()) ?? 0,
        existingBooked: _existingPackageBooked,
      );
      final holds = SameBoatSeatOpenLogic.liveHoldSeats(
        _existingPackageHolds,
        now,
      );
      final bad = SameBoatSeatOpenLogic.capacityViolation(
        capacity: cap,
        booked: booked,
        liveHolds: holds,
      );
      if (bad != null) {
        return l10n.sameBoatCapacityBelowOccupied(bad.booked, bad.liveHolds);
      }
    }
    for (final draft in options.values) {
      if (!draft.open) {
        continue;
      }
      final cap = int.tryParse(draft.capacity.text.trim()) ?? 0;
      if (cap <= 0 || draft.departure == null) {
        return l10n.workbenchOpenSeatsNeedFields;
      }
      if (draft.flagClose == null) {
        return l10n.workbenchFlagDeadlineRequired;
      }
      final booked = SameBoatSeatOpenLogic.resolveBookedSeats(
        nowOpen: true,
        wasAlreadyOpen: draft.wasAlreadyOpen,
        formBooked: int.tryParse(draft.booked.text.trim()) ?? 0,
        existingBooked: draft.existingBooked,
      );
      final holds = SameBoatSeatOpenLogic.liveHoldSeats(
        draft.existingHolds,
        now,
      );
      final bad = SameBoatSeatOpenLogic.capacityViolation(
        capacity: cap,
        booked: booked,
        liveHolds: holds,
      );
      if (bad != null) {
        return l10n.sameBoatCapacityBelowOccupied(bad.booked, bad.liveHolds);
      }
    }
    return null;
  }

  /// Apply seat fields onto a product built from the rest of the form.
  /// Never overwrites [flag_holds]; [booked_seats] only on first open.
  ShopProduct applyToProduct(ShopProduct base) {
    final nextOptions = <ShopProductOption>[
      for (final option in base.options)
        if (options.containsKey(option.id))
          options[option.id]!.apply(
            option,
            isAdmin: isAdmin,
            now: _now,
          )
        else
          option,
    ];
    final packageCap = int.tryParse(packageCapacity.text.trim()) ?? 0;
    final booked = SameBoatSeatOpenLogic.resolveBookedSeats(
      nowOpen: openPackage,
      wasAlreadyOpen: _packageWasOpen,
      formBooked: int.tryParse(packageBooked.text.trim()) ?? 0,
      existingBooked: _existingPackageBooked,
    );
    final status = openPackage
        ? SameBoatSeatOpenLogic.statusWhenOpen(
            isAdmin: isAdmin,
            previous: _packageStatus,
          )
        : SameBoatSeatOpenLogic.statusWhenClosed(
            isAdmin: isAdmin,
            previous: _packageStatus,
          );
    return base.copyWith(
      openEmptySeats: openPackage,
      capacity: openPackage ? packageCap : base.capacity,
      bookedSeats: booked,
      flagHolds: _existingPackageHolds,
      departureStart: openPackage ? packageDeparture : base.departureStart,
      flagClosesAt: openPackage ? packageFlagClose : base.flagClosesAt,
      sameBoatStatus: status,
      sameBoatOpenedAt: SameBoatSeatOpenLogic.openedAtWhenSaving(
        next: status,
        existing: base.sameBoatOpenedAt,
        now: _now,
      ),
      options: nextOptions,
    );
  }
}

class SameBoatOptionSeatDraft {
  SameBoatOptionSeatDraft({
    required this.id,
    required this.name,
    required this.open,
    required this.capacity,
    required this.booked,
    required this.departure,
    required this.flagClose,
    required this.wasAlreadyOpen,
    required this.existingBooked,
    required this.existingHolds,
    required this.existingStatus,
  });

  factory SameBoatOptionSeatDraft.from({
    required SameBoatOptionSeatSlot slot,
    ShopProductOption? prior,
  }) {
    final wasOpen = prior != null &&
        SameBoatSeatOpenLogic.wasAlreadyOpen(
          openEmptySeats: prior.openEmptySeats,
          status: prior.sameBoatStatus,
        );
    return SameBoatOptionSeatDraft(
      id: slot.id,
      name: slot.name,
      open: wasOpen,
      capacity: TextEditingController(
        text: (prior != null && prior.capacity > 0) ? '${prior.capacity}' : '',
      ),
      booked: TextEditingController(
        text: (prior != null && prior.bookedSeats > 0)
            ? '${prior.bookedSeats}'
            : '',
      ),
      departure: prior?.departureStart,
      flagClose: prior?.flagClosesAt,
      wasAlreadyOpen: wasOpen,
      existingBooked: prior?.bookedSeats ?? 0,
      existingHolds: List<SeatHold>.from(prior?.flagHolds ?? const []),
      existingStatus: prior?.sameBoatStatus ?? SameBoatStatus.closed,
    );
  }

  final String id;
  String name;
  bool open;
  final TextEditingController capacity;
  final TextEditingController booked;
  DateTime? departure;
  DateTime? flagClose;
  final bool wasAlreadyOpen;
  final int existingBooked;
  final List<SeatHold> existingHolds;
  final SameBoatStatus existingStatus;

  void dispose() {
    capacity.dispose();
    booked.dispose();
  }

  ShopProductOption apply(
    ShopProductOption base, {
    required bool isAdmin,
    DateTime? now,
  }) {
    final cap = int.tryParse(capacity.text.trim()) ?? 0;
    final nextBooked = SameBoatSeatOpenLogic.resolveBookedSeats(
      nowOpen: open,
      wasAlreadyOpen: wasAlreadyOpen,
      formBooked: int.tryParse(booked.text.trim()) ?? 0,
      existingBooked: existingBooked,
    );
    final status = open
        ? SameBoatSeatOpenLogic.statusWhenOpen(
            isAdmin: isAdmin,
            previous: existingStatus,
          )
        : SameBoatSeatOpenLogic.statusWhenClosed(
            isAdmin: isAdmin,
            previous: existingStatus,
          );
    return base.copyWith(
      openEmptySeats: open,
      capacity: open ? cap : base.capacity,
      bookedSeats: nextBooked,
      flagHolds: existingHolds,
      departureStart: open ? departure : base.departureStart,
      flagClosesAt: open ? flagClose : base.flagClosesAt,
      sameBoatStatus: status,
      sameBoatOpenedAt: SameBoatSeatOpenLogic.openedAtWhenSaving(
        next: status,
        existing: base.sameBoatOpenedAt,
        now: now ?? DateTime.now(),
      ),
    );
  }
}

/// Toggle + capacity / already-booked / flag close / preview.
class SameBoatSeatOpenFields extends StatelessWidget {
  const SameBoatSeatOpenFields({
    super.key,
    required this.controller,
    required this.onChanged,
    this.showPackageDeparturePicker = true,
  });

  final SameBoatSeatOpenController controller;
  final VoidCallback onChanged;

  /// When false, package departure comes from the parent form (workbench stay).
  final bool showPackageDeparturePicker;

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
    required bool locked,
  }) async {
    if (locked) {
      return;
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dayFmt = DateFormat('yyyy.MM.dd');
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('same-boat-open-package'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.workbenchOpenSeats),
          subtitle: Text(l10n.workbenchOpenSeatsHint),
          value: c.openPackage,
          onChanged: (v) {
            c.openPackage = v;
            onChanged();
          },
        ),
        if (c.openPackage) ...[
          _SeatOpenInputs(
            capacity: c.packageCapacity,
            booked: c.packageBooked,
            bookedReadOnly: c.packageWasAlreadyOpen,
            displayBooked: c.existingPackageBooked,
            departure: c.packageDeparture,
            flagClose: c.packageFlagClose,
            scheduleLocked: c.packageScheduleLocked,
            showDeparturePicker: showPackageDeparturePicker,
            dayFmt: dayFmt,
            onPickDeparture: () => _pickDate(
              context,
              current: c.packageDeparture,
              locked: c.packageScheduleLocked,
              onPicked: (d) {
                c.packageDeparture = d;
                onChanged();
              },
            ),
            onPickFlag: () => _pickDate(
              context,
              current: c.packageFlagClose,
              locked: c.packageScheduleLocked,
              onPicked: (d) {
                c.packageFlagClose = d;
                onChanged();
              },
            ),
            onChanged: onChanged,
          ),
        ],
        if (c.options.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.sameBoatIndividualSeats,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final draft in c.options.values) ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(draft.name),
                      value: draft.open,
                      onChanged: (v) {
                        draft.open = v;
                        onChanged();
                      },
                    ),
                    if (draft.open)
                      _SeatOpenInputs(
                        capacity: draft.capacity,
                        booked: draft.booked,
                        bookedReadOnly: draft.wasAlreadyOpen,
                        displayBooked: draft.existingBooked,
                        departure: draft.departure,
                        flagClose: draft.flagClose,
                        scheduleLocked: c.optionScheduleLocked(draft.id),
                        showDeparturePicker: true,
                        dayFmt: dayFmt,
                        onPickDeparture: () => _pickDate(
                          context,
                          current: draft.departure,
                          locked: c.optionScheduleLocked(draft.id),
                          onPicked: (d) {
                            draft.departure = d;
                            onChanged();
                          },
                        ),
                        onPickFlag: () => _pickDate(
                          context,
                          current: draft.flagClose,
                          locked: c.optionScheduleLocked(draft.id),
                          onPicked: (d) {
                            draft.flagClose = d;
                            onChanged();
                          },
                        ),
                        onChanged: onChanged,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _SeatOpenInputs extends StatelessWidget {
  const _SeatOpenInputs({
    required this.capacity,
    required this.booked,
    required this.bookedReadOnly,
    required this.displayBooked,
    required this.departure,
    required this.flagClose,
    required this.scheduleLocked,
    required this.showDeparturePicker,
    required this.dayFmt,
    required this.onPickDeparture,
    required this.onPickFlag,
    required this.onChanged,
  });

  final TextEditingController capacity;
  final TextEditingController booked;
  final bool bookedReadOnly;
  final int displayBooked;
  final DateTime? departure;
  final DateTime? flagClose;
  final bool scheduleLocked;
  final bool showDeparturePicker;
  final DateFormat dayFmt;
  final VoidCallback onPickDeparture;
  final VoidCallback onPickFlag;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cap = int.tryParse(capacity.text.trim()) ?? 0;
    final paid = bookedReadOnly
        ? displayBooked
        : (int.tryParse(booked.text.trim()) ?? 0);
    final open = SameBoatSeatOpenLogic.openPreviewSeats(
      capacity: cap,
      booked: paid,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('same-boat-capacity'),
          controller: capacity,
          enabled: !scheduleLocked,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: l10n.workbenchSeatCount),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 8),
        if (bookedReadOnly)
          ListTile(
            key: const Key('same-boat-booked-readonly'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.sameBoatAlreadyBooked),
            subtitle: Text('$displayBooked'),
          )
        else
          TextField(
            key: const Key('same-boat-booked'),
            controller: booked,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.sameBoatAlreadyBooked),
            onChanged: (_) => onChanged(),
          ),
        if (showDeparturePicker)
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: !scheduleLocked,
            title: Text(l10n.workbenchDepartureDate),
            subtitle: Text(departure == null ? '—' : dayFmt.format(departure!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: scheduleLocked ? null : onPickDeparture,
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.workbenchDepartureDate),
            subtitle: Text(
              departure == null
                  ? l10n.bookingEntryPickDate
                  : dayFmt.format(departure!),
            ),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: !scheduleLocked,
          title: Text(l10n.workbenchFlagDeadline),
          subtitle: Text(
            flagClose == null
                ? l10n.workbenchFlagDeadlineRequired
                : dayFmt.format(flagClose!),
          ),
          trailing: const Icon(Icons.flag_outlined),
          onTap: scheduleLocked ? null : onPickFlag,
        ),
        if (scheduleLocked)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.sameBoatAskAdminToChange,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (cap > 0)
          Text(
            key: const Key('same-boat-seat-preview'),
            l10n.sameBoatSeatOpenPreview(cap, paid, open),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        Text(
          l10n.sameBoatHoldPriorityHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
