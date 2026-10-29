import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_operating.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dive_star_assessment_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

String shopOperatingStatusLabel(
  AppLocalizations l10n,
  ShopOperatingStatus status,
) {
  return switch (status) {
    ShopOperatingStatus.active => l10n.shopOperatingActive,
    ShopOperatingStatus.paused => l10n.shopOperatingPaused,
    ShopOperatingStatus.contractEnded => l10n.shopOperatingContractEnded,
    ShopOperatingStatus.closed => l10n.shopOperatingClosed,
  };
}

String formatShopOperatingStamp(DateTime at) {
  final local = at.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Partner-resort detail: status, history, resort edit, and this shop's products.
class AdminPartnerShopScreen extends StatefulWidget {
  const AdminPartnerShopScreen({
    super.key,
    required this.shopId,
    this.onOpenProducts,
  });

  final String shopId;
  final ValueChanged<String>? onOpenProducts;

  @override
  State<AdminPartnerShopScreen> createState() => _AdminPartnerShopScreenState();
}

class _AdminPartnerShopScreenState extends State<AdminPartnerShopScreen> {
  final _note = TextEditingController();
  var _status = ShopOperatingStatus.active;
  var _seeded = false;
  var _saving = false;
  var _events = const <ShopOperatingEvent>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    _seeded = true;
    final stats = DiverStoreScope.of(context).liveStatsFor(widget.shopId);
    _status = stats?.operatingStatus ?? ShopOperatingStatus.active;
    _note.text = stats?.operatingNote ?? '';
    unawaited(_loadEvents());
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final events = await DiverStoreScope.of(context)
        .fetchShopOperatingEvents(widget.shopId);
    if (!mounted) {
      return;
    }
    setState(() => _events = events);
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    try {
      await store.setShopOperatingStatus(
        shopId: widget.shopId,
        status: _status,
        note: _note.text,
      );
      final events = await store.fetchShopOperatingEvents(widget.shopId);
      if (!mounted) {
        return;
      }
      setState(() {
        _events = events;
        _saving = false;
        _note.text = clampOperatingNote(_note.text);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminPartnerOperatingSaved)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminPartnerOperatingFailed)),
      );
    }
  }

  Future<void> _editInternalScore(ShopLiveStats? stats) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final current = stats?.internalScore ?? 0;
    final controller = TextEditingController(text: current > 0 ? '$current' : '');
    final score = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.adminInternalScoreEdit),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.adminInternalScore,
              hintText: l10n.adminInternalScoreHint,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.adminHqClose),
            ),
            FilledButton(
              onPressed: () {
                final raw = int.tryParse(controller.text.trim()) ?? 0;
                Navigator.pop(context, raw.clamp(0, 100));
              },
              child: Text(l10n.briefSave),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (score == null || !mounted) {
      return;
    }
    await store.setInternalScore(shopId: widget.shopId, score: score);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminInternalScoreSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final stats = store.liveStatsFor(widget.shopId);
        final name = (stats?.name ?? '').trim();
        final title = name.isEmpty ? widget.shopId : name;
        final products = stats?.products ?? const [];
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                l10n.adminPartnerStatus,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final status in ShopOperatingStatus.values)
                RadioListTile<ShopOperatingStatus>(
                  key: Key('admin-partner-status-${status.name}'),
                  value: status,
                  groupValue: _status,
                  title: Text(shopOperatingStatusLabel(l10n, status)),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => _status = value);
                        },
                ),
              TextField(
                key: const Key('admin-partner-note'),
                controller: _note,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.adminPartnerOperatingNote,
                  hintText: l10n.adminPartnerOperatingNoteHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('admin-partner-operating-save'),
                onPressed: _saving ? null : _save,
                child: Text(l10n.adminPartnerOperatingSave),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                key: const Key('admin-partner-edit-resort'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ResortDeskScreen(shopId: widget.shopId),
                    ),
                  );
                },
                child: Text(l10n.exploreEditResort),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.adminPartnerProductsHeading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (products.isEmpty)
                Text(l10n.adminPartnerProductsEmpty)
              else
                for (final product in products)
                  ListTile(
                    key: Key('admin-partner-product-${product.id}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.name),
                  ),
              if (widget.onOpenProducts != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const Key('admin-partner-open-products'),
                    onPressed: () {
                      final open = widget.onOpenProducts;
                      Navigator.of(context).pop();
                      open?.call(widget.shopId);
                    },
                    child: Text(l10n.adminViewShopProducts),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                l10n.adminPartnerHistory,
                key: const Key('admin-partner-history'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_events.isEmpty)
                Text(l10n.adminPartnerHistoryEmpty)
              else
                for (final event in _events) ...[
                  _EventTile(event: event),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AdminDiveStarAssessmentScreen(
                        shopId: widget.shopId,
                        shopName: title,
                      ),
                    ),
                  );
                },
                child: Text(l10n.adminDiveStarAssessmentMenu),
              ),
              TextButton(
                onPressed: () => _editInternalScore(stats),
                child: Text(l10n.adminInternalScoreEdit),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final ShopOperatingEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final line = event.kind == 'status' &&
            event.fromStatus != null &&
            event.toStatus != null
        ? '${shopOperatingStatusLabel(l10n, event.fromStatus!)} → '
            '${shopOperatingStatusLabel(l10n, event.toStatus!)}'
        : '${event.fromOwnerId} → ${event.toOwnerId}';
    return Card(
      key: Key('admin-partner-event-${event.id}'),
      child: ListTile(
        title: Text(line),
        subtitle: Text(
          [
            if (event.note.trim().isNotEmpty) event.note.trim(),
            '${event.byName} · ${formatShopOperatingStamp(event.at)}',
          ].join('\n'),
        ),
        isThreeLine: event.note.trim().isNotEmpty,
      ),
    );
  }
}
