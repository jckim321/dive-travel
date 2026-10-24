import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/product_content_fingerprint.dart';
import 'package:dive_travel_app/core/models/product_publish_guard.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/admin/presentation/product_reject_dialog.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_products_screen.dart';
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
    if (widget.partnerMode) {
      return PartnerProductsScreen(embedded: widget.embedded);
    }

    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        // partnerMode early-returns above; admin path only from here.
        final pending = store.pendingProductApprovals;
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
              l10n.adminProductsSubtitle,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: widget.embedded ? AdminConsoleTheme.muted : null),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('admin-product-register'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TravelProductRegistrationScreen(),
                ),
              ),
              icon: const Icon(Icons.add_box_outlined),
              label: Text(l10n.adminProductsTitle),
            ),
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
                  canApprove: store.stats.isAdmin,
                ),
                const SizedBox(height: 8),
              ],
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
                      builder: (_) => TravelProductRegistrationScreen(
                        existing: product,
                        startEditing: true,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
    final changeFlags = sectionChangeFlags(
      product.rejectedSectionHashes,
      product,
    );

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
              if (product.resubmitCount > 0) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    key: Key('pending-resubmit-count-${product.id}'),
                    label: Text(l10n.partnerResubmitCount(product.resubmitCount)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: const TextStyle(
                      color: AdminConsoleTheme.bg,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: AdminConsoleTheme.amber,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
              if (product.reviewNote.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.adminPendingPreviousReject,
                  style: const TextStyle(
                    color: AdminConsoleTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  key: Key('pending-review-note-${product.id}'),
                  product.reviewNote,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminConsoleTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
              if (product.resubmitNote.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.adminPendingPartnerNote,
                  style: const TextStyle(
                    color: AdminConsoleTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  key: Key('pending-resubmit-note-${product.id}'),
                  product.resubmitNote,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminConsoleTheme.ice,
                    fontSize: 12,
                  ),
                ),
              ],
              if (product.resubmitCount > 0 ||
                  product.rejectedSectionHashes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.adminPendingChangesTitle,
                  style: const TextStyle(
                    color: AdminConsoleTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                if (product.rejectedSectionHashes.isEmpty)
                  Text(
                    key: Key('pending-changes-unknown-${product.id}'),
                    l10n.adminPendingChangeUnknown,
                    style: const TextStyle(
                      color: AdminConsoleTheme.muted,
                      fontSize: 12,
                    ),
                  )
                else
                  Wrap(
                    key: Key('pending-changes-wrap-${product.id}'),
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final section in productContentSectionKeys)
                        _PendingChangeChip(
                          productId: product.id,
                          section: section,
                          flag: changeFlags[section] ??
                              SectionChangeFlag.unknown,
                          label: productRejectTagLabel(l10n, section),
                        ),
                    ],
                  ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (canApprove) ...[
                    FilledButton(
                      key: Key('approve-product-${product.id}'),
                      onPressed: () async {
                        if (!ProductPublishGuard.hasDiverPrice(product)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.adminProductApproveNeedsPrice),
                            ),
                          );
                          return;
                        }
                        if (!ProductPublishGuard.hasValidPricesForApprove(
                          product,
                        )) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.adminProductApproveOverCap),
                            ),
                          );
                          return;
                        }
                        try {
                          await store.approveShopProduct(
                            shopId: product.shopId,
                            productId: product.id,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.adminProductApproved),
                              ),
                            );
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$error')),
                            );
                          }
                        }
                      },
                      child: Text(l10n.adminApprove),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      key: Key('reject-product-${product.id}'),
                      onPressed: () async {
                        final result = await showProductRejectDialog(context);
                        if (result == null || !context.mounted) {
                          return;
                        }
                        await store.rejectShopProduct(
                          shopId: product.shopId,
                          productId: product.id,
                          reviewNote: result.note,
                          reasonTags: result.reasonTags,
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

class _PendingChangeChip extends StatelessWidget {
  const _PendingChangeChip({
    required this.productId,
    required this.section,
    required this.flag,
    required this.label,
  });

  final String productId;
  final String section;
  final SectionChangeFlag flag;
  final String label;

  @override
  Widget build(BuildContext context) {
    final changed = flag == SectionChangeFlag.changed;
    final color = changed ? AdminConsoleTheme.aqua : AdminConsoleTheme.muted;
    return Container(
      key: Key('pending-change-$section-$productId'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: changed
            ? AdminConsoleTheme.aqua.withValues(alpha: 0.16)
            : AdminConsoleTheme.border.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: changed ? FontWeight.w700 : FontWeight.w500,
          height: 1.1,
        ),
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
      if (product.rejectedReasonTags.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final tag in product.rejectedReasonTags)
                Text(
                  productRejectTagLabel(l10n, tag),
                  style: style.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color ?? AdminConsoleTheme.amber,
                  ),
                ),
            ],
          ),
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

