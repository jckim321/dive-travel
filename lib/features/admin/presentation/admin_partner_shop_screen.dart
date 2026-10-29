import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/shop_operating.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dive_star_assessment_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// 소유주, 예약, 후기가 모두 없을 때만 샵 문서를 지운다.
bool partnerResortCanDelete({
  required bool hasOwner,
  required int bookingCount,
  required int reviewCount,
}) {
  return !hasOwner && bookingCount == 0 && reviewCount == 0;
}

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
  final _ownerQuery = TextEditingController();
  final _ownerName = TextEditingController();
  var _status = ShopOperatingStatus.active;
  var _seeded = false;
  var _saving = false;
  var _ownerSaving = false;
  MemberAccount? _ownerMatch;
  String? _ownerError;
  var _events = const <ShopOperatingEvent>[];
  var _bookingCount = 0;
  var _countsReady = false;
  var _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(DiverStoreScope.of(context).ensureAdminInboxLoaded());
    });
  }

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
    unawaited(_loadBookingCount());
  }

  Future<void> _loadBookingCount() async {
    final count = (await DiverStoreScope.of(context).fetchShopBookings(widget.shopId)).length;
    if (!mounted) {
      return;
    }
    setState(() {
      _bookingCount = count;
      _countsReady = true;
    });
  }

  @override
  void dispose() {
    _note.dispose();
    _ownerQuery.dispose();
    _ownerName.dispose();
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

  void _findOwner() {
    final l10n = AppLocalizations.of(context);
    final query = _ownerQuery.text.trim().toLowerCase();
    final store = DiverStoreScope.of(context);
    MemberAccount? match;
    if (query.isNotEmpty) {
      for (final member in store.members) {
        if (member.listHandle.trim().toLowerCase() == query) {
          match = member;
          break;
        }
      }
    }
    String? error;
    if (match == null) {
      error = l10n.adminPartnerOwnerNotFound;
    } else if (match.isAdmin) {
      error = l10n.adminPartnerOwnerRejectedAdmin;
      match = null;
    } else if (match.isBusiness || match.ownedShopId.trim().isNotEmpty) {
      error = l10n.adminPartnerOwnerRejectedShop;
      match = null;
    }
    setState(() {
      _ownerMatch = match;
      _ownerError = error;
    });
  }

  Future<void> _transferOwner(String currentName) async {
    final match = _ownerMatch;
    if (match == null || _ownerSaving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final requested = _ownerName.text.trim();
    final rename = requested.isNotEmpty && requested != currentName.trim();
    final previous = store.members
        .where((member) => member.ownedShopId.trim() == widget.shopId.trim())
        .firstOrNull;
    final fromId = previous == null
        ? operatingOwnerNoneId
        : operatingOwnerHandle(
            uid: previous.uid,
            loginId: previous.loginId,
            email: previous.email,
          );
    final toId = operatingOwnerHandle(
      uid: match.uid,
      loginId: match.loginId,
      email: match.email,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.adminPartnerOwnerConfirmTitle),
          content: Text(
            [
              l10n.adminPartnerOwnerConfirmBody(fromId, toId),
              if (rename) '$currentName → $requested',
            ].join('\n'),
          ),
          actions: [
            TextButton(
              key: const Key('admin-partner-owner-cancel'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.adminHqClose),
            ),
            FilledButton(
              key: const Key('admin-partner-owner-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.adminPartnerOwnerConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _ownerSaving = true);
    try {
      await store.transferShopOwner(
        shopId: widget.shopId,
        toUid: match.uid,
        shopName: rename ? requested : null,
      );
      final events = await store.fetchShopOperatingEvents(widget.shopId);
      if (!mounted) {
        return;
      }
      setState(() {
        _events = events;
        _ownerSaving = false;
        _ownerMatch = null;
        _ownerError = null;
        _ownerQuery.clear();
        _ownerName.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminPartnerOwnerSaved)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final raw = '$error';
      final message = raw.contains('OWNER_IS_ADMIN')
          ? l10n.adminPartnerOwnerRejectedAdmin
          : raw.contains('OWNER_HAS_SHOP') || raw.contains('SAME_OWNER')
              ? l10n.adminPartnerOwnerRejectedShop
              : raw.contains('NO_CURRENT_OWNER')
                  ? l10n.adminPartnerOwnerNoCurrent
                  : raw.contains('OWNER_NOT_FOUND')
                      ? l10n.adminPartnerOwnerNotFound
                      : l10n.adminPartnerOwnerFailed;
      setState(() => _ownerSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _deleteShop() async {
    if (_deleting) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.adminPartnerDeleteTitle),
          content: Text(l10n.adminPartnerDeleteBody),
          actions: [
            TextButton(
              key: const Key('admin-partner-delete-cancel'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.adminHqClose),
            ),
            FilledButton(
              key: const Key('admin-partner-delete-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.adminPartnerDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _deleting = true);
    final store = DiverStoreScope.of(context);
    try {
      await store.deleteEmptyPartnerShop(widget.shopId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminPartnerDeleteFailed)),
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
        final hasOwner = store.members.any(
          (member) => member.ownedShopId.trim() == widget.shopId.trim(),
        );
        final canDelete = _countsReady &&
            partnerResortCanDelete(
              hasOwner: hasOwner,
              bookingCount: _bookingCount,
              reviewCount: stats?.reviewCount ?? 0,
            );
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
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('admin-partner-delete'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8E2F2F),
                  foregroundColor: Colors.white,
                ),
                onPressed: canDelete && !_deleting ? _deleteShop : null,
                child: Text(l10n.adminPartnerDelete),
              ),
              if (_countsReady && !canDelete)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.adminPartnerDeleteBlocked,
                    key: const Key('admin-partner-delete-blocked'),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                l10n.adminPartnerChangeOwner,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('admin-partner-owner-search'),
                controller: _ownerQuery,
                decoration: InputDecoration(
                  labelText: l10n.adminPartnerLoginId,
                  hintText: l10n.adminPartnerOwnerSearchHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_ownerMatch != null || _ownerError != null) {
                    setState(() {
                      _ownerMatch = null;
                      _ownerError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  key: const Key('admin-partner-owner-find'),
                  onPressed: _ownerSaving ? null : _findOwner,
                  child: Text(l10n.adminPartnerOwnerFind),
                ),
              ),
              if (_ownerError != null)
                Text(
                  _ownerError!,
                  key: const Key('admin-partner-owner-error'),
                ),
              if (_ownerMatch != null)
                Text(
                  _ownerMatch!.listHandle,
                  key: const Key('admin-partner-owner-picked'),
                ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('admin-partner-owner-name'),
                controller: _ownerName,
                decoration: InputDecoration(
                  labelText: l10n.adminPartnerOwnerName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('admin-partner-owner-save'),
                onPressed: _ownerMatch == null || _ownerSaving
                    ? null
                    : () => _transferOwner(title),
                child: Text(l10n.adminPartnerChangeOwner),
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
    final statusLine = event.kind == 'status' &&
        event.fromStatus != null &&
        event.toStatus != null;
    final line = statusLine
        ? '${shopOperatingStatusLabel(l10n, event.fromStatus!)} → '
            '${shopOperatingStatusLabel(l10n, event.toStatus!)}'
        : '${event.fromOwnerId} → ${event.toOwnerId}';
    final nameLine = !statusLine &&
            (event.fromName.isNotEmpty || event.toName.isNotEmpty)
        ? '${event.fromName} → ${event.toName}'
        : '';
    return Card(
      key: Key('admin-partner-event-${event.id}'),
      child: ListTile(
        title: Text(line),
        subtitle: Text(
          [
            if (nameLine.isNotEmpty) nameLine,
            if (event.note.trim().isNotEmpty) event.note.trim(),
            '${event.byName} · ${formatShopOperatingStamp(event.at)}',
          ].join('\n'),
        ),
        isThreeLine: nameLine.isNotEmpty || event.note.trim().isNotEmpty,
      ),
    );
  }
}
