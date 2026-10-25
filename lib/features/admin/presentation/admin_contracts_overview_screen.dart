import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/partner_contract.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Per-shop contract rollup (no collectionGroup).
class AdminContractsOverviewScreen extends StatefulWidget {
  const AdminContractsOverviewScreen({
    super.key,
    this.embedded = false,
    this.onOpenVault,
  });

  final bool embedded;
  final ValueChanged<String>? onOpenVault;

  @override
  State<AdminContractsOverviewScreen> createState() =>
      _AdminContractsOverviewScreenState();
}

class _AdminContractsOverviewScreenState
    extends State<AdminContractsOverviewScreen> {
  var _loading = true;
  final _statusByShop = <String, PartnerContractShopStatus>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final store = DiverStoreScope.of(context);
    setState(() => _loading = true);
    final next = <String, PartnerContractShopStatus>{};
    for (final shop in store.shops) {
      final hull = shop.hullId;
      try {
        final docs = await store.listPartnerContracts(hull);
        next[hull] = PartnerContract.rollupStatus(docs);
      } catch (_) {
        next[hull] = PartnerContractShopStatus.none;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _statusByShop
        ..clear()
        ..addAll(next);
      _loading = false;
    });
  }

  String _label(AppLocalizations l10n, PartnerContractShopStatus status) {
    return switch (status) {
      PartnerContractShopStatus.none => l10n.adminContractStatusNone,
      PartnerContractShopStatus.awaitingSignature =>
        l10n.adminContractStatusAwaiting,
      PartnerContractShopStatus.executed => l10n.adminContractStatusExecuted,
      PartnerContractShopStatus.expiringSoon =>
        l10n.adminContractStatusExpiring,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final shops = store.shops;

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              key: const Key('admin-contracts-overview'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: shops.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final shop = shops[index];
                final hull = shop.hullId;
                final live = store.liveStatsFor(hull);
                final name = live?.name ??
                    DiveShopCatalog.byId(hull)?.name ??
                    shop.name;
                final status =
                    _statusByShop[hull] ?? PartnerContractShopStatus.none;
                return Material(
                  color: AdminConsoleTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  child: ListTile(
                    key: Key('admin-contract-shop-$hull'),
                    title: Text(
                      name,
                      style: const TextStyle(
                        color: AdminConsoleTheme.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      _label(l10n, status),
                      style: TextStyle(
                        color: status ==
                                PartnerContractShopStatus.awaitingSignature
                            ? AdminConsoleTheme.amber
                            : AdminConsoleTheme.muted,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AdminConsoleTheme.muted,
                    ),
                    onTap: () => widget.onOpenVault?.call(hull),
                  ),
                );
              },
            ),
          );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      backgroundColor: AdminConsoleTheme.bg,
      appBar: AppBar(title: Text(l10n.adminContractsSubOverview)),
      body: body,
    );
  }
}
