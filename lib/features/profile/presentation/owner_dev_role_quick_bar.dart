import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/dev/dev_roles.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_gate.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_gate.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Owner-only DevRoles controls shared by settings and My Page.
class OwnerDevRoleQuickBar extends StatefulWidget {
  const OwnerDevRoleQuickBar({
    super.key,
    this.showTrialCaption = false,
  });

  /// Small "trial / remove before launch" line (My Page).
  final bool showTrialCaption;

  @override
  State<OwnerDevRoleQuickBar> createState() => _OwnerDevRoleQuickBarState();
}

class _OwnerDevRoleQuickBarState extends State<OwnerDevRoleQuickBar> {
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

  Future<void> _apply(DevRoleKind kind) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (kind == DevRoleKind.partner && _shopId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.devRolesNeedShop)),
      );
      return;
    }
    setState(() {
      _kind = kind;
      _busy = true;
    });
    try {
      await store.applyDevRole(
        kind: kind,
        ownedShopId: kind == DevRoleKind.partner ? _shopId : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.devRolesApplied)),
      );
      if (kind == DevRoleKind.diver) {
        // Switch tab while this context still has MainShell as ancestor, then
        // dismiss any pushed routes (e.g. settings).
        MainShell.goToTab(context, 0);
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (kind == DevRoleKind.partner) {
        await openPartnerMode(context);
      } else {
        await openAdminMode(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _roleButton({
    required Key key,
    required DevRoleKind kind,
    required String label,
  }) {
    final selected = _kind == kind;
    final onPressed = _busy ? null : () => _apply(kind);
    if (selected) {
      return FilledButton(
        key: key,
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: AppTheme.navy),
        child: Text(label),
      );
    }
    return OutlinedButton(
      key: key,
      onPressed: onPressed,
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (!store.canUseDevRoles) {
      return const SizedBox.shrink();
    }
    final shops = DiveShopCatalog.shops;
    final shopValue = shops.any((s) => s.id == _shopId)
        ? _shopId
        : shops.first.id;
    return Column(
      key: const Key('owner-dev-role-quick-bar'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.devRolesTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (widget.showTrialCaption) ...[
          const SizedBox(height: 4),
          Text(
            l10n.devRolesTrialCaption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.muted,
              fontSize: 11,
            ),
          ),
        ],
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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _roleButton(
                        key: const Key('dev-role-diver'),
                        kind: DevRoleKind.diver,
                        label: l10n.devRolesDiver,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _roleButton(
                        key: const Key('dev-role-partner'),
                        kind: DevRoleKind.partner,
                        label: l10n.devRolesPartner,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _roleButton(
                        key: const Key('dev-role-admin'),
                        kind: DevRoleKind.admin,
                        label: l10n.devRolesAdmin,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('dev-role-shop'),
                  value: shopValue,
                  decoration: InputDecoration(
                    labelText: l10n.devRolesShop,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final shop in shops)
                      DropdownMenuItem(
                        value: shop.id,
                        child: Text(
                          '${shop.name} (${shop.id})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (id) {
                          if (id != null) {
                            setState(() {
                              _shopId = id;
                              _kind = DevRoleKind.partner;
                            });
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
