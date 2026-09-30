import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Admin/partner travel-product registration + owner approval queue.
class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({
    super.key,
    this.embedded = false,
    this.partnerMode = false,
  });

  final bool embedded;
  final bool partnerMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final owned = store.stats.ownedShopId ??
            AppConstants.defaultPartnerShopId;
        final pending = partnerMode
            ? [
                for (final product in store.pendingProductApprovals)
                  if (product.shopId == owned) product,
              ]
            : store.pendingProductApprovals;
        final body = ListView(
          key: const Key('admin-products'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              partnerMode
                  ? l10n.partnerProductPendingHint
                  : l10n.adminProductsSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: embedded ? AdminConsoleTheme.muted : null,
                  ),
            ),
            if (partnerMode) ...[
              const SizedBox(height: 8),
              Text(
                l10n.partnerOwnProductsOnly,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('admin-product-register'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TravelProductRegistrationScreen(
                    lockedShopId: partnerMode ? owned : null,
                    partnerMode: partnerMode,
                  ),
                ),
              ),
              icon: const Icon(Icons.add_box_outlined),
              label: Text(l10n.adminProductsTitle),
            ),
            if (!partnerMode) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ResortDeskScreen(
                      shopId: DiveShopCatalog.shops.first.id,
                    ),
                  ),
                ),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.exploreEditResort),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.adminProductPendingQueue,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: embedded ? Colors.white : null,
                  ),
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              Card(
                color: embedded ? AdminConsoleTheme.surfaceHigh : null,
                child: ListTile(
                  title: Text(
                    l10n.adminProductPendingEmpty,
                    style: TextStyle(
                      color: embedded ? AdminConsoleTheme.muted : null,
                    ),
                  ),
                ),
              )
            else
              for (final product in pending) ...[
                _PendingProductTile(
                  product: product,
                  canApprove: !partnerMode && store.stats.isAdmin,
                ),
                const SizedBox(height: 8),
              ],
            if (partnerMode) ...[
              const SizedBox(height: 24),
              Text(
                l10n.partnerProductForm,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final product in store.productsForShop(owned)) ...[
                Card(
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      '${_kindLabel(l10n, product.listingKind)} · '
                      '${_statusLabel(l10n, product.publishStatus)}',
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TravelProductRegistrationScreen(
                          lockedShopId: owned,
                          partnerMode: true,
                          existing: product,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        );

        return adminScreenShell(
          embedded: embedded,
          title: l10n.adminProductsTitle,
          body: body,
        );
      },
    );
  }
}

class _PendingProductTile extends StatelessWidget {
  const _PendingProductTile({
    required this.product,
    required this.canApprove,
  });

  final ShopProduct product;
  final bool canApprove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final shopName =
        DiveShopCatalog.byId(product.shopId)?.name ?? product.shopId;

    return Card(
      color: AdminConsoleTheme.surfaceHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$shopName · ${_kindLabel(l10n, product.listingKind)}',
              style: const TextStyle(color: AdminConsoleTheme.muted),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.exploreConsumerPrice} ${product.consumerPrice} · '
              '${l10n.exploreProPrice} ${product.professionalPrice}',
              style: const TextStyle(
                color: AdminConsoleTheme.muted,
                fontSize: 12,
              ),
            ),
            if (canApprove) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  FilledButton(
                    key: Key('approve-product-${product.id}'),
                    onPressed: () async {
                      await store.approveShopProduct(
                        shopId: product.shopId,
                        productId: product.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.adminProductApproved)),
                        );
                      }
                    },
                    child: Text(l10n.adminApprove),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: Key('reject-product-${product.id}'),
                    onPressed: () async {
                      await store.rejectShopProduct(
                        shopId: product.shopId,
                        productId: product.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.adminProductRejected)),
                        );
                      }
                    },
                    child: Text(l10n.adminReject),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _kindLabel(AppLocalizations l10n, ProductListingKind kind) {
  switch (kind) {
    case ProductListingKind.diveStar:
      return l10n.productListingDiveStar;
    case ProductListingKind.favorites:
      return l10n.productListingFavorites;
    case ProductListingKind.popular:
      return l10n.productListingPopular;
    case ProductListingKind.nextDeparture:
      return l10n.productListingNextDeparture;
    case ProductListingKind.curated:
      return l10n.productListingCurated;
  }
}

String _statusLabel(AppLocalizations l10n, ProductPublishStatus status) {
  switch (status) {
    case ProductPublishStatus.pending:
      return l10n.productStatusPending;
    case ProductPublishStatus.approved:
      return l10n.productStatusApproved;
    case ProductPublishStatus.rejected:
      return l10n.productStatusRejected;
    case ProductPublishStatus.draft:
      return l10n.productStatusDraft;
  }
}
