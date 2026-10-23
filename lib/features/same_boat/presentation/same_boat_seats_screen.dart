import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/same_boat_seat_open.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seat_open_fields.dart';
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
  late final SameBoatSeatOpenController _seats;
  var _saving = false;

  bool get _partnerBlocked =>
      !widget.adminBypassApproval &&
      SameBoatSeatOpenLogic.blocksPartnerRequest(widget.product);

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final slots = <SameBoatOptionSeatSlot>[
      for (final o in p.options)
        if (o.kind == ProductOptionKind.individual ||
            o.kind == ProductOptionKind.basePackage ||
            o.openEmptySeats ||
            o.sameBoatStatus != SameBoatStatus.closed)
          SameBoatOptionSeatSlot(id: o.id, name: o.name),
    ];
    final seen = {for (final s in slots) s.id};
    for (final o in p.options) {
      if (o.kind == ProductOptionKind.individual && !seen.contains(o.id)) {
        slots.add(SameBoatOptionSeatSlot(id: o.id, name: o.name));
      }
    }
    _seats = SameBoatSeatOpenController(
      existing: p,
      optionSlots: slots,
      isAdmin: widget.adminBypassApproval,
    );
  }

  @override
  void dispose() {
    _seats.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (_partnerBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product.hasPendingSameBoat
                ? l10n.sameBoatSeatsAlreadyPending
                : l10n.sameBoatSeatsAlreadyLive,
          ),
        ),
      );
      return;
    }
    _seats.isAdmin = widget.adminBypassApproval;
    final error = _seats.validate(l10n, now: DateTime.now());
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _saving = true);
    final next = _seats.applyToProduct(widget.product);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final waiting = _partnerBlocked && widget.product.hasPendingSameBoat;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sameBoatSeatsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            l10n.sameBoatSeatsHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          IgnorePointer(
            ignoring: _partnerBlocked,
            child: Opacity(
              opacity: _partnerBlocked ? 0.55 : 1,
              child: SameBoatSeatOpenFields(
                controller: _seats,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('same-boat-seats-submit'),
            onPressed: (_saving || _partnerBlocked) ? null : _submit,
            child: Text(
              waiting
                  ? l10n.sameBoatSeatsWaiting
                  : widget.adminBypassApproval
                      ? l10n.sameBoatSeatsPublish
                      : l10n.sameBoatSeatsSubmit,
            ),
          ),
        ],
      ),
    );
  }
}
