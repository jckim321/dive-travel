import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/dev/dev_roles.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Owner-only role overlay controls (Pages release included).
class DevRoleSwitcher extends StatefulWidget {
  const DevRoleSwitcher({super.key});

  @override
  State<DevRoleSwitcher> createState() => _DevRoleSwitcherState();
}

class _DevRoleSwitcherState extends State<DevRoleSwitcher> {
  var _seeded = false;
  var _kind = DevRoleKind.admin;
  var _shopId = AppConstants.defaultPartnerShopId;
  var _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    _seeded = true;
    final store = DiverStoreScope.of(context);
    final overlay = store.devRoleOverlay;
    if (overlay != null) {
      _kind = overlay.kind;
      _shopId = overlay.ownedShopId ?? AppConstants.defaultPartnerShopId;
    } else if (store.stats.isAdmin) {
      _kind = DevRoleKind.admin;
    } else if (store.stats.isBusiness) {
      _kind = DevRoleKind.partner;
      _shopId = store.stats.ownedShopId ?? AppConstants.defaultPartnerShopId;
    } else {
      _kind = DevRoleKind.diver;
    }
  }

  Future<void> _apply() async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (_kind == DevRoleKind.partner && _shopId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.devRolesNeedShop)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await store.applyDevRole(
        kind: _kind,
        ownedShopId: _kind == DevRoleKind.partner ? _shopId : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.devRolesApplied)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shops = DiveShopCatalog.shops;
    final shopValue = shops.any((s) => s.id == _shopId)
        ? _shopId
        : shops.first.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.devRolesTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.devRolesHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.muted,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<DevRoleKind>(
                  key: const Key('dev-role-kind'),
                  segments: [
                    ButtonSegment(
                      value: DevRoleKind.diver,
                      label: Text(l10n.devRolesDiver),
                    ),
                    ButtonSegment(
                      value: DevRoleKind.partner,
                      label: Text(l10n.devRolesPartner),
                    ),
                    ButtonSegment(
                      value: DevRoleKind.admin,
                      label: Text(l10n.devRolesAdmin),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: _busy
                      ? null
                      : (next) => setState(() => _kind = next.first),
                ),
                if (_kind == DevRoleKind.partner) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: Key('dev-role-shop-$shopValue'),
                    initialValue: shopValue,
                    decoration: InputDecoration(
                      labelText: l10n.devRolesShop,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final shop in shops)
                        DropdownMenuItem(
                          value: shop.id,
                          child: Text('${shop.name} (${shop.id})'),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (id) {
                            if (id != null) setState(() => _shopId = id);
                          },
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('dev-role-apply'),
                  onPressed: _busy ? null : _apply,
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.navy),
                  child: Text(_busy ? l10n.exploreSaving : l10n.devRolesApply),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
