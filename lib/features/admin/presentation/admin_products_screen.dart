import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum _ProductSourceFilter { all, partner, diy, special }

enum _ProductStatusFilter { all, pending, approved, rejected, draft }

/// Admin/partner travel-product registration + owner approval queue.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({
    super.key,
    this.embedded = false,
    this.partnerMode = false,
    this.filterShopId,
    this.onClearShopFilter,
  });

  final bool embedded;
  final bool partnerMode;
  final String? filterShopId;
  final VoidCallback? onClearShopFilter;

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  _ProductSourceFilter _source = _ProductSourceFilter.all;
  _ProductStatusFilter _status = _ProductStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final owned = widget.partnerMode
            ? store.partnerOwnedShopId
            : (store.stats.ownedShopId ?? AppConstants.defaultPartnerShopId);
        final partnerProducts = widget.partnerMode
            ? store.productsForShop(owned)
            : const <ShopProduct>[];
        final pending = widget.partnerMode
            ? [
                for (final product in store.pendingProductApprovals)
                  if (product.shopId == owned) product,
              ]
            : store.pendingProductApprovals;
        final shopFilter = widget.filterShopId;
        final all = [
          for (final product in store.allShopProducts)
            if (shopFilter == null || product.shopId == shopFilter) product,
        ];
        final filtered = [
          for (final product in all)
            if (_matchesSource(product) && _matchesStatus(product)) product,
        ];

        final body = ListView(
          key: const Key('admin-products'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              widget.partnerMode
                  ? l10n.partnerProductPendingHint
                  : l10n.adminProductsSubtitle,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: widget.embedded ? AdminConsoleTheme.muted : null),
            ),
            if (widget.partnerMode) ...[
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
                    lockedShopId: widget.partnerMode ? owned : null,
                    partnerMode: widget.partnerMode,
                  ),
                ),
              ),
              icon: const Icon(Icons.add_box_outlined),
              label: Text(l10n.adminProductsTitle),
            ),
            if (!widget.partnerMode) ...[
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
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: widget.embedded ? Colors.white : null),
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              Card(
                color: widget.embedded ? AdminConsoleTheme.surfaceHigh : null,
                child: ListTile(
                  title: Text(
                    l10n.adminProductPendingEmpty,
                    style: TextStyle(
                      color: widget.embedded ? AdminConsoleTheme.muted : null,
                    ),
                  ),
                ),
              )
            else
              for (final product in pending) ...[
                _PendingProductTile(
                  product: product,
                  canApprove: !widget.partnerMode && store.stats.isAdmin,
                ),
                const SizedBox(height: 8),
              ],
            if (!widget.partnerMode) ...[
              const SizedBox(height: 24),
              Text(
                l10n.adminAllProducts,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: widget.embedded ? Colors.white : null),
              ),
              if (shopFilter != null) ...[
                const SizedBox(height: 8),
                InputChip(
                  label: Text(
                    l10n.adminProductFilterShop(
                      DiveShopCatalog.byId(shopFilter)?.name ?? shopFilter,
                    ),
                  ),
                  onDeleted: widget.onClearShopFilter,
                  deleteIcon: const Icon(Icons.close, size: 16),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in <(_ProductSourceFilter, String)>[
                    (_ProductSourceFilter.all, l10n.adminProductSourceAll),
                    (
                      _ProductSourceFilter.partner,
                      l10n.adminProductSourcePartner,
                    ),
                    (_ProductSourceFilter.diy, l10n.adminProductSourceDiy),
                    (
                      _ProductSourceFilter.special,
                      l10n.adminProductSourceSpecial,
                    ),
                  ])
                    ChoiceChip(
                      key: Key('admin-product-source-${entry.$1.name}'),
                      label: Text(entry.$2),
                      selected: _source == entry.$1,
                      onSelected: (_) => setState(() => _source = entry.$1),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in <(_ProductStatusFilter, String)>[
                    (_ProductStatusFilter.all, l10n.adminProductSourceAll),
                    (
                      _ProductStatusFilter.pending,
                      l10n.productStatusPending,
                    ),
                    (
                      _ProductStatusFilter.approved,
                      l10n.productStatusApproved,
                    ),
                    (
                      _ProductStatusFilter.rejected,
                      l10n.productStatusRejected,
                    ),
                    (_ProductStatusFilter.draft, l10n.productStatusDraft),
                  ])
                    FilterChip(
                      key: Key('admin-product-status-${entry.$1.name}'),
                      label: Text(entry.$2),
                      selected: _status == entry.$1,
                      onSelected: (_) => setState(() => _status = entry.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (final product in filtered) ...[
                Card(
                  color: widget.embedded ? AdminConsoleTheme.surfaceHigh : null,
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(child: Text(product.name)),
                        if (_hasOpenSeats(product))
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              l10n.adminOpenSeatsBadge,
                              style: const TextStyle(
                                color: AdminConsoleTheme.aqua,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: _productLines(
                      l10n,
                      product,
                      color: widget.embedded ? AdminConsoleTheme.muted : null,
                    ),
                    trailing: IconButton(
                      key: Key('delete-product-${product.id}'),
                      tooltip: l10n.adminProductDelete,
                      onPressed: () => _confirmDeleteProduct(context, product),
                      icon: Icon(
                        Icons.delete_outline,
                        color: widget.embedded ? AdminConsoleTheme.muted : null,
                      ),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            TravelProductRegistrationScreen(existing: product),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
            if (widget.partnerMode) ...[
              const SizedBox(height: 24),
              Text(
                l10n.partnerProductForm,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (partnerProducts.isEmpty)
                Card(
                  key: const Key('partner-products-empty'),
                  child: ListTile(
                    title: Text(l10n.partnerProductListEmpty),
                  ),
                )
              else
                for (final product in partnerProducts) ...[
                  Card(
                    key: Key('partner-product-${product.id}'),
                    child: ListTile(
                      title: Text(product.name),
                      subtitle: _productLines(l10n, product),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PublishStatusChip(product: product),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        TravelProductRegistrationScreen(
                                      lockedShopId: owned,
                                      partnerMode: true,
                                      existing: product,
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (value == 'seats') {
                                if (!product.isListedPublicly) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.sameBoatSeatsNoProducts),
                                    ),
                                  );
                                  return;
                                }
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        SameBoatSeatsScreen(product: product),
                                  ),
                                );
                                return;
                              }
                              if (value == 'delete') {
                                await _confirmDeleteProduct(context, product);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(l10n.exploreEditResort),
                              ),
                              if (product.isListedPublicly)
                                PopupMenuItem(
                                  value: 'seats',
                                  child: Text(l10n.sameBoatSeatsTitle),
                                ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(l10n.adminProductDelete),
                              ),
                            ],
                          ),
                        ],
                      ),
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
          embedded: widget.embedded,
          title: l10n.adminProductsTitle,
          body: body,
        );
      },
    );
  }

  bool _matchesSource(ShopProduct product) {
    final source = classifyAdminProductSource(product);
    return switch (_source) {
      _ProductSourceFilter.all => true,
      _ProductSourceFilter.partner => source == AdminProductSource.partner,
      _ProductSourceFilter.diy => source == AdminProductSource.diverDiy,
      _ProductSourceFilter.special =>
        source == AdminProductSource.curatedSpecial,
    };
  }

  bool _matchesStatus(ShopProduct product) {
    return switch (_status) {
      _ProductStatusFilter.all => true,
      _ProductStatusFilter.pending =>
        product.publishStatus == ProductPublishStatus.pending,
      _ProductStatusFilter.approved =>
        product.publishStatus == ProductPublishStatus.approved,
      _ProductStatusFilter.rejected =>
        product.publishStatus == ProductPublishStatus.rejected,
      _ProductStatusFilter.draft =>
        product.publishStatus == ProductPublishStatus.draft,
    };
  }
}

enum AdminProductSource { partner, diverDiy, curatedSpecial, unknown }

AdminProductSource classifyAdminProductSource(ShopProduct product) {
  if (product.listingKind == ProductListingKind.diverPlanned) {
    return AdminProductSource.diverDiy;
  }
  if (product.listingKind == ProductListingKind.curated ||
      product.shopId.startsWith('curated-')) {
    return AdminProductSource.curatedSpecial;
  }
  return AdminProductSource.partner;
}

String _sourceLabel(AppLocalizations l10n, AdminProductSource source) {
  return switch (source) {
    AdminProductSource.partner => l10n.adminProductSourcePartner,
    AdminProductSource.diverDiy => l10n.adminProductSourceDiy,
    AdminProductSource.curatedSpecial => l10n.adminProductSourceSpecial,
    AdminProductSource.unknown => l10n.adminProductSourceUnknown,
  };
}

bool _hasOpenSeats(ShopProduct product) {
  if (product.openEmptySeats) {
    return true;
  }
  for (final option in product.options) {
    if (option.openEmptySeats) {
      return true;
    }
  }
  return false;
}

class _PendingProductTile extends StatelessWidget {
  const _PendingProductTile({required this.product, required this.canApprove});

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
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                TravelProductRegistrationScreen(existing: product),
          ),
        ),
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
                '$shopName · ${_sourceLabel(l10n, classifyAdminProductSource(product))} · '
                '${_kindLabel(l10n, product.listingKind)}',
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
              if (product.reviewNote.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  product.reviewNote,
                  style: const TextStyle(
                    color: AdminConsoleTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (canApprove) ...[
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
                        final note = await showDialog<String>(
                          context: context,
                          builder: (_) => const _RejectNoteDialog(),
                        );
                        if (note == null || !context.mounted) {
                          return;
                        }
                        await store.rejectShopProduct(
                          shopId: product.shopId,
                          productId: product.id,
                          reviewNote: note,
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
                  const Spacer(),
                  IconButton(
                    key: Key('delete-pending-product-${product.id}'),
                    tooltip: l10n.adminProductDelete,
                    onPressed: () => _confirmDeleteProduct(context, product),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AdminConsoleTheme.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublishStatusChip extends StatelessWidget {
  const _PublishStatusChip({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Chip(
        key: Key('partner-product-status-${product.id}'),
        label: Text(_statusLabel(l10n, product.publishStatus)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

String _kindLabel(AppLocalizations l10n, ProductListingKind kind) {
  switch (kind) {
    case ProductListingKind.exploreOnly:
      return l10n.productListingExploreOnly;
    case ProductListingKind.diveStar:
      return l10n.productListingDiveStar;
    case ProductListingKind.diverPlanned:
      return l10n.productListingFavorites;
    case ProductListingKind.hotSpot:
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

Widget _productLines(
  AppLocalizations l10n,
  ShopProduct product, {
  Color? color,
}) {
  final style = TextStyle(color: color);
  final shopName =
      DiveShopCatalog.byId(product.shopId)?.name ?? product.shopId;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$shopName · ${_sourceLabel(l10n, classifyAdminProductSource(product))}',
        style: style,
      ),
      Text(
        '${_kindLabel(l10n, product.listingKind)} · '
        '${_statusLabel(l10n, product.publishStatus)}',
        style: style.copyWith(fontSize: 12),
      ),
      if (product.reviewNote.isNotEmpty)
        Text(product.reviewNote, style: style.copyWith(fontSize: 12)),
    ],
  );
}

Future<void> _confirmDeleteProduct(
  BuildContext context,
  ShopProduct product,
) async {
  final l10n = AppLocalizations.of(context);
  final store = DiverStoreScope.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.adminProductDelete),
      content: Text(l10n.adminProductDeleteBody(product.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.adminHqClose),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.adminProductDelete),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) {
    return;
  }
  try {
    await store.deleteShopProduct(
      shopId: product.shopId,
      productId: product.id,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.adminProductDeleted)));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _RejectNoteDialog extends StatefulWidget {
  const _RejectNoteDialog();

  @override
  State<_RejectNoteDialog> createState() => _RejectNoteDialogState();
}

class _RejectNoteDialogState extends State<_RejectNoteDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final note = _note.text.trim();
    return AlertDialog(
      title: Text(l10n.adminProductRejectNote),
      content: TextField(
        controller: _note,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(hintText: l10n.adminProductRejectNoteHint),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.adminHqClose),
        ),
        FilledButton(
          onPressed: note.isEmpty ? null : () => Navigator.pop(context, note),
          child: Text(l10n.adminReject),
        ),
      ],
    );
  }
}
