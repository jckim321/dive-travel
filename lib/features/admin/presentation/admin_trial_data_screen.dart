import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/trial_data_cleanup.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// H9: admin-only trial data inspection + selective delete (pre-launch).
class AdminTrialDataScreen extends StatefulWidget {
  const AdminTrialDataScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminTrialDataScreen> createState() => _AdminTrialDataScreenState();
}

class _AdminTrialDataScreenState extends State<AdminTrialDataScreen> {
  TrialDataSnapshot? _snapshot;
  Object? _error;
  var _loading = false;
  var _deleting = false;
  var _backupOk = false;
  var _selection = const TrialDeleteSelection();
  final _confirm = TextEditingController();
  TrialDeleteProgress? _progress;
  TrialDeleteResult? _lastResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refresh());
    });
  }

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await DiverStoreScope.of(context).fetchTrialDataCounts();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _runDelete() async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final snap = _snapshot;
    if (snap == null) {
      return;
    }
    if (snap.jejuOrange.blocksDeletion) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminTrialJejuAmbiguous)),
      );
      return;
    }
    if (!_backupOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminTrialBackupRequired)),
      );
      return;
    }
    if (_confirm.text.trim() != kTrialDeleteConfirmPhrase) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminTrialConfirmMismatch)),
      );
      return;
    }
    if (!_selection.anySelected) {
      return;
    }

    setState(() {
      _deleting = true;
      _progress = null;
      _lastResult = null;
    });
    try {
      // Re-fetch counts immediately before delete.
      await store.fetchTrialDataCounts();
      final result = await store.runTrialDataDeletion(
        selection: _selection,
        confirmPhrase: _confirm.text,
        backupAcknowledged: _backupOk,
        onProgress: (p) {
          if (!mounted) {
            return;
          }
          setState(() => _progress = p);
        },
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lastResult = result;
        _deleting = false;
        _confirm.clear();
      });
      await _refresh();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final snap = _snapshot;
    final deleteLocked = snap?.jejuOrange.blocksDeletion == true || _deleting;

    return adminScreenShell(
      embedded: widget.embedded,
      title: l10n.adminTrialDataTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Material(
            color: AdminConsoleTheme.danger.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.adminTrialPrelaunchBanner,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AdminConsoleTheme.danger,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.adminTrialLimitsBody, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          if (snap != null) _JejuBanner(resolve: snap.jejuOrange, l10n: l10n),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonal(
                key: const Key('admin-trial-refresh'),
                onPressed: _loading || _deleting ? null : _refresh,
                child: Text(l10n.adminTrialRefresh),
              ),
              const SizedBox(width: 12),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text('$_error', style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          Text(l10n.adminTrialCountsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (snap != null)
            for (final row in snap.rows) _CountTile(row: row, l10n: l10n),
          const SizedBox(height: 20),
          Text(l10n.adminTrialDeleteTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.adminTrialDeleteHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          ..._selectionTiles(l10n, deleteLocked),
          CheckboxListTile(
            key: const Key('admin-trial-backup'),
            value: _backupOk,
            onChanged: deleteLocked
                ? null
                : (v) => setState(() => _backupOk = v ?? false),
            title: Text(l10n.adminTrialBackupCheck),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          TextField(
            key: const Key('admin-trial-confirm'),
            controller: _confirm,
            enabled: !deleteLocked,
            decoration: InputDecoration(
              labelText: l10n.adminTrialConfirmLabel,
              hintText: kTrialDeleteConfirmPhrase,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('admin-trial-run-delete'),
            onPressed: deleteLocked || !_selection.anySelected
                ? null
                : _runDelete,
            child: Text(l10n.adminTrialRunDelete),
          ),
          if (_progress != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progress!.fraction),
            Text(_progress!.message, style: theme.textTheme.bodySmall),
          ],
          if (_lastResult != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.adminTrialResult(
                _lastResult!.successCount,
                _lastResult!.failureCount,
              ),
              style: theme.textTheme.titleSmall,
            ),
            for (final note in _lastResult!.notes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('· $note', style: theme.textTheme.bodySmall),
              ),
          ],
        ],
      ),
    );
  }

  List<Widget> _selectionTiles(AppLocalizations l10n, bool locked) {
    Widget tile({
      required Key key,
      required String title,
      required bool value,
      required void Function(bool) onChanged,
    }) {
      return CheckboxListTile(
        key: key,
        value: value,
        onChanged: locked ? null : (v) => onChanged(v ?? false),
        title: Text(title),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      );
    }

    return [
      tile(
        key: const Key('admin-trial-sel-outbox'),
        title: l10n.adminTrialSelOutbox,
        value: _selection.partnerEmailOutbox,
        onChanged: (v) => setState(
          () => _selection = _selection.copyWith(partnerEmailOutbox: v),
        ),
      ),
      tile(
        key: const Key('admin-trial-sel-loi'),
        title: l10n.adminTrialSelLoi,
        value: _selection.diveStarApplications,
        onChanged: (v) => setState(
          () => _selection = _selection.copyWith(diveStarApplications: v),
        ),
      ),
      tile(
        key: const Key('admin-trial-sel-posts'),
        title: l10n.adminTrialSelPosts,
        value: _selection.postsAndComments,
        onChanged: (v) => setState(
          () => _selection = _selection.copyWith(postsAndComments: v),
        ),
      ),
      tile(
        key: const Key('admin-trial-sel-reviews'),
        title: l10n.adminTrialSelReviews,
        value: _selection.reviews,
        onChanged: (v) =>
            setState(() => _selection = _selection.copyWith(reviews: v)),
      ),
      tile(
        key: const Key('admin-trial-sel-user-bookings'),
        title: l10n.adminTrialSelUserBookings,
        value: _selection.userBookings,
        onChanged: (v) => setState(
          () => _selection = _selection.copyWith(userBookings: v),
        ),
      ),
      tile(
        key: const Key('admin-trial-sel-logs'),
        title: l10n.adminTrialSelUserLogs,
        value: _selection.userLogs,
        onChanged: (v) =>
            setState(() => _selection = _selection.copyWith(userLogs: v)),
      ),
      tile(
        key: const Key('admin-trial-sel-assessments'),
        title: l10n.adminTrialSelAssessments,
        value: _selection.unconfirmedAssessments,
        onChanged: (v) => setState(
          () => _selection = _selection.copyWith(unconfirmedAssessments: v),
        ),
      ),
      tile(
        key: const Key('admin-trial-sel-shop-bookings'),
        title: l10n.adminTrialSelShopBookings,
        value: _selection.trialShopBookings,
        onChanged: (v) => setState(
          () => _selection = _selection.copyWith(trialShopBookings: v),
        ),
      ),
      tile(
        key: const Key('admin-trial-sel-products'),
        title: l10n.adminTrialSelProducts,
        value: _selection.clearTrialShopProducts,
        onChanged: (v) => setState(
          () => _selection = _selection.copyWith(clearTrialShopProducts: v),
        ),
      ),
      tile(
        key: const Key('admin-trial-sel-shops'),
        title: l10n.adminTrialSelShops,
        value: _selection.trialShops,
        onChanged: (v) =>
            setState(() => _selection = _selection.copyWith(trialShops: v)),
      ),
      tile(
        key: const Key('admin-trial-sel-users'),
        title: l10n.adminTrialSelUsers,
        value: _selection.trialUsers,
        onChanged: (v) =>
            setState(() => _selection = _selection.copyWith(trialUsers: v)),
      ),
    ];
  }
}

class _JejuBanner extends StatelessWidget {
  const _JejuBanner({required this.resolve, required this.l10n});

  final JejuOrangeResolve resolve;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (resolve.kind) {
      case JejuOrangeResolveKind.exactOne:
        return Material(
          color: AdminConsoleTheme.aqua.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.adminTrialJejuProtected(
                resolve.shopName ?? kJejuOrangeShopName,
                resolve.shopId ?? '',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      case JejuOrangeResolveKind.none:
        return Material(
          color: AdminConsoleTheme.amber.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l10n.adminTrialJejuMissing),
          ),
        );
      case JejuOrangeResolveKind.ambiguous:
        return Material(
          color: AdminConsoleTheme.danger.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.adminTrialJejuAmbiguous,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                for (final c in resolve.candidates)
                  Text('· ${c.name} (${c.id})'),
              ],
            ),
          ),
        );
    }
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.row, required this.l10n});

  final TrialCountRow row;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = switch (row.status) {
      TrialCountStatus.ok => '${row.count ?? 0}',
      TrialCountStatus.unavailable => l10n.adminTrialUnavailable,
      TrialCountStatus.error => l10n.adminTrialCountError,
    };
    final flags = <String>[
      if (row.protected) l10n.adminTrialFlagProtected,
      if (row.deletable) l10n.adminTrialFlagDeletable,
    ].join(' · ');
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(row.label),
      subtitle: Text(
        [
          row.pathHint,
          if (flags.isNotEmpty) flags,
          if (row.detail != null) row.detail!,
        ].join(' · '),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        status,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
