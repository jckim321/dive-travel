import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_promotion.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminProposalInboxScreen extends StatefulWidget {
  const AdminProposalInboxScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminProposalInboxScreen> createState() =>
      _AdminProposalInboxScreenState();
}

class _AdminProposalInboxScreenState extends State<AdminProposalInboxScreen> {
  var _loading = true;
  String? _error;
  List<PartnerPromotion> _rows = const [];
  String? _busyId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final store = DiverStoreScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await store.loadPartnerPromotionInbox();
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _handle(PartnerPromotion row) async {
    if (_busyId != null || row.status != PartnerPromotionStatus.incoming) {
      return;
    }
    final store = DiverStoreScope.of(context);
    setState(() => _busyId = row.id);
    try {
      await store.markPartnerPromotionHandled(
        shopId: row.shopId,
        proposalId: row.id,
      );
      await _reload();
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _busyId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final day = DateFormat('yyyy-MM-dd HH:mm');
    final period = DateFormat('yyyy-MM-dd');

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              key: const Key('admin-proposal-inbox'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: AdminConsoleTheme.danger),
                  ),
                if (_rows.isEmpty)
                  Text(
                    l10n.adminPromoEmpty,
                    key: const Key('admin-promo-empty'),
                    style: const TextStyle(color: AdminConsoleTheme.muted),
                  ),
                for (final row in _rows)
                  Card(
                    key: Key('admin-promo-card-${row.id}'),
                    color: AdminConsoleTheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _shopName(store, row.shopId),
                            style: const TextStyle(
                              color: AdminConsoleTheme.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${partnerPromotionKindById(row.kind)?.labelFor(language) ?? row.kind} · ${row.status == PartnerPromotionStatus.incoming ? l10n.adminPromoNew : l10n.adminPromoHandled}',
                            style: const TextStyle(color: AdminConsoleTheme.ice),
                          ),
                          Text(
                            '${period.format(row.startsOn.toLocal())} ~ ${period.format(row.endsOn.toLocal())}',
                            style: const TextStyle(color: AdminConsoleTheme.muted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            row.note,
                            style: const TextStyle(color: AdminConsoleTheme.text),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.format(row.createdAt.toLocal()),
                            style: const TextStyle(
                              color: AdminConsoleTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                          if (row.status == PartnerPromotionStatus.incoming) ...[
                            const SizedBox(height: 8),
                            OutlinedButton(
                              key: Key('admin-promo-handle-${row.id}'),
                              onPressed: _busyId == null ? () => _handle(row) : null,
                              child: Text(l10n.adminPromoMark),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );

    if (widget.embedded) {
      return body;
    }
    return Theme(
      data: AdminConsoleTheme.dark,
      child: Scaffold(
        backgroundColor: AdminConsoleTheme.bg,
        appBar: AppBar(title: Text(l10n.adminContractsSubInbox)),
        body: body,
      ),
    );
  }

  String _shopName(DiverStore store, String shopId) {
    return store.liveStatsFor(shopId)?.name ??
        DiveShopCatalog.byId(shopId)?.name ??
        shopId;
  }
}
