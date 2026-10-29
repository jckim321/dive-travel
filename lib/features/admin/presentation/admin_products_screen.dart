import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/price_revision.dart';
import 'package:dive_travel_app/core/models/product_content_fingerprint.dart';
import 'package:dive_travel_app/core/models/product_publish_guard.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/admin/presentation/product_reject_dialog.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_menu_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

enum _ProductSourceFilter { all, partner, diy, special }

enum _ProductStatusFilter { all, pending, approved, rejected, draft }

/// Admin/partner travel-product registration + owner approval queue.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({
    super.key,
    this.embedded = false,
    this.partnerMode = false,
    this.partnerShopId,
    this.filterShopId,
    this.onClearShopFilter,
  });

  final bool embedded;
  final bool partnerMode;

  /// Resort the partner menu should manage. Empty uses the signed-in shop.
  final String? partnerShopId;
  final String? filterShopId;
  final VoidCallback? onClearShopFilter;

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  _ProductSourceFilter _source = _ProductSourceFilter.all;
  _ProductStatusFilter _status = _ProductStatusFilter.all;
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.partnerMode) {
      return PartnerProductMenuScreen(
        embedded: widget.embedded,
        shopId: widget.partnerShopId,
      );
    }

    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        // partnerMode early-returns above; admin path only from here.
        final pending = store.pendingProductApprovals;
        final shopFilter = widget.filterShopId;
        final needle = _query.text.trim().toLowerCase();
        final all = [
          for (final product in store.allShopProducts)
            if (shopFilter == null || product.shopId == shopFilter) product,
        ];
        final filtered = [
          for (final product in all)
            if (_matchesSource(product) &&
                _matchesStatus(product) &&
                (needle.isEmpty ||
                    product.name.toLowerCase().contains(needle) ||
                    product.shopId.toLowerCase().contains(needle)))
              product,
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
            TextField(
              key: const Key('admin-products-search'),
              controller: _query,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.adminProductsSearch,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
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
                ])
                  FilterChip(
                    key: Key('admin-product-status-${entry.$1.name}'),
                    label: Text(entry.$2),
                    selected: _status == entry.$1,
                    onSelected: (_) => setState(() => _status = entry.$1),
                  ),
                PopupMenuButton<Object>(
                  key: const Key('admin-product-filter-more'),
                  tooltip: l10n.adminFilterMore,
                  onSelected: (value) {
                    setState(() {
                      if (value is _ProductStatusFilter) {
                        _status = value;
                      } else if (value is _ProductSourceFilter) {
                        _source = value;
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _ProductStatusFilter.draft,
                      child: Text(l10n.productStatusDraft),
                    ),
                    const PopupMenuDivider(),
                    for (final entry in <(_ProductSourceFilter, String)>[
                      (
                        _ProductSourceFilter.all,
                        l10n.adminProductSourceAll,
                      ),
                      (
                        _ProductSourceFilter.partner,
                        l10n.adminProductSourcePartner,
                      ),
                      (
                        _ProductSourceFilter.diy,
                        l10n.adminProductSourceDiy,
                      ),
                      (
                        _ProductSourceFilter.special,
                        l10n.adminProductSourceSpecial,
                      ),
                    ])
                      PopupMenuItem(
                        value: entry.$1,
                        child: Text(
                          '${l10n.adminProductSourceFilter}: ${entry.$2}',
                        ),
                      ),
                  ],
                  child: Chip(
                    label: Text(l10n.adminFilterMore),
                    avatar: const Icon(Icons.expand_more, size: 16),
                  ),
                ),
              ],
            ),
            if (_source != _ProductSourceFilter.all)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: InputChip(
                  key: Key('admin-product-source-${_source.name}'),
                  label: Text(
                    switch (_source) {
                      _ProductSourceFilter.partner =>
                        l10n.adminProductSourcePartner,
                      _ProductSourceFilter.diy => l10n.adminProductSourceDiy,
                      _ProductSourceFilter.special =>
                        l10n.adminProductSourceSpecial,
                      _ProductSourceFilter.all => l10n.adminProductSourceAll,
                    },
                  ),
                  onDeleted: () =>
                      setState(() => _source = _ProductSourceFilter.all),
                ),
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

class _PendingProductTile extends StatefulWidget {
  const _PendingProductTile({required this.product, required this.canApprove});

  final ShopProduct product;
  final bool canApprove;

  @override
  State<_PendingProductTile> createState() => _PendingProductTileState();
}

class _PendingProductTileState extends State<_PendingProductTile> {
  var _busy = false;

  ShopProduct get product => widget.product;

  // H1a: ignore legacy price_revision / pending_options (do not surface).
  bool get _isPriceRevisionQueue => false;

  // TODO(a1-desk-save-timing): remove with owner timing snackbar.
  static String _formatSeconds(Duration d) =>
      (d.inMilliseconds / 1000).toStringAsFixed(1);

  Future<void> _approvePriceRevision() async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final preview = applyPriceRevisionToLive(product);
    if (!ProductPublishGuard.hasDiverPrice(preview)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminProductApproveNeedsPrice)),
      );
      return;
    }
    if (!ProductPublishGuard.hasValidPricesForApprove(preview)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminProductApproveOverCap)),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await store.approvePriceRevision(
        shopId: product.shopId,
        productId: product.id,
        expectedFreshness: product.priceRevision!.freshnessToken,
      );
      if (mounted) {
        setState(() => _busy = false);
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminPriceRevisionApproved)),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
      }
      messenger.showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    } finally {
      if (mounted && _busy) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _rejectPriceRevision() async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final result = await showProductRejectDialog(context);
    if (result == null || !mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await store.rejectPriceRevision(
        shopId: product.shopId,
        productId: product.id,
        expectedFreshness: product.priceRevision!.freshnessToken,
        reviewNote: result.note,
      );
      if (mounted) {
        setState(() => _busy = false);
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminPriceRevisionRejected)),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
      }
      messenger.showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    } finally {
      if (mounted && _busy) {
        setState(() => _busy = false);
      }
    }
  }

  static String _errorMessage(Object error) {
    final raw = '$error';
    return raw
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '');
  }

  Future<void> _approve() async {
    if (_isPriceRevisionQueue) {
      return _approvePriceRevision();
    }
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (!ProductPublishGuard.hasDiverPrice(product)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminProductApproveNeedsPrice)),
      );
      return;
    }
    if (!ProductPublishGuard.hasValidPricesForApprove(product)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminProductApproveOverCap)),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final showProbe = store.stats.isAdmin;
    setState(() => _busy = true);
    try {
      final probe = await store.approveShopProduct(
        shopId: product.shopId,
        productId: product.id,
      );
      // Local patch may remove this tile from the pending list.
      if (mounted) {
        setState(() => _busy = false);
      }
      // TODO(a1-desk-save-timing): remove owner timing snackbar after probe.
      if (showProbe) {
        final write = probe.write;
        final read = await probe.readFuture;
        final total = write + read;
        messenger.showSnackBar(
          SnackBar(
            content: Text('승인 ${_formatSeconds(total)}초'),
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        unawaited(probe.readFuture);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.adminProductApproved)),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
      }
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted && _busy) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reject() async {
    if (_isPriceRevisionQueue) {
      return _rejectPriceRevision();
    }
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final result = await showProductRejectDialog(context);
    if (result == null || !mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final showProbe = store.stats.isAdmin;
    setState(() => _busy = true);
    try {
      final probe = await store.rejectShopProduct(
        shopId: product.shopId,
        productId: product.id,
        reviewNote: result.note,
        reasonTags: result.reasonTags,
      );
      if (mounted) {
        setState(() => _busy = false);
      }
      // TODO(a1-desk-save-timing): remove owner timing snackbar after probe.
      if (showProbe) {
        final write = probe.write;
        final read = await probe.readFuture;
        final total = write + read;
        messenger.showSnackBar(
          SnackBar(
            content: Text('반려 ${_formatSeconds(total)}초'),
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        unawaited(probe.readFuture);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.adminProductRejected)),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
      }
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted && _busy) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopName =
        DiveShopCatalog.byId(product.shopId)?.name ?? product.shopId;
    final canCompare =
        productSectionHashesComparable(product.rejectedSectionHashes);
    final changeFlags = sectionChangeFlags(
      product.rejectedSectionHashes,
      product,
    );

    return Card(
      color: AdminConsoleTheme.surfaceHigh,
      child: InkWell(
        onTap: _busy
            ? null
            : () => Navigator.of(context).push(
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
              if (_isPriceRevisionQueue) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    key: Key('price-revision-chip-${product.id}'),
                    label: Text(l10n.adminPriceRevisionChip),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: const TextStyle(
                      color: AdminConsoleTheme.bg,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: AdminConsoleTheme.aqua,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _priceRevisionSummary(l10n, product),
                  style: const TextStyle(
                    color: AdminConsoleTheme.ice,
                    fontSize: 12,
                  ),
                ),
                if (product.priceRevision!.pendingOptions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.adminPriceRevisionPendingOptions(
                      product.priceRevision!.pendingOptions
                          .map((o) => o.name.trim().isEmpty ? o.id : o.name)
                          .join(', '),
                    ),
                    style: const TextStyle(
                      color: AdminConsoleTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ] else
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
                if (!canCompare)
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
                  if (widget.canApprove) ...[
                    FilledButton(
                      key: Key('approve-product-${product.id}'),
                      onPressed: _busy ? null : _approve,
                      child: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.adminApprove),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      key: Key('reject-product-${product.id}'),
                      onPressed: _busy ? null : _reject,
                      child: Text(l10n.adminReject),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    key: Key('delete-pending-product-${product.id}'),
                    tooltip: l10n.adminProductDelete,
                    onPressed:
                        _busy ? null : () => _confirmDeleteProduct(context, product),
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

String _priceRevisionSummary(AppLocalizations l10n, ShopProduct product) {
  final revision = product.priceRevision!;
  final liveConsumer = product.consumerPrice;
  final livePro = product.professionalPrice;
  final nextConsumer = revision.consumerPrice ?? liveConsumer;
  final nextPro = revision.professionalPrice ?? livePro;
  final parts = <String>[
    '${l10n.exploreConsumerPrice} $liveConsumer → $nextConsumer',
    '${l10n.exploreProPrice} $livePro → $nextPro',
  ];
  for (final update in revision.optionPriceUpdates) {
    ShopProductOption? live;
    for (final option in product.options) {
      if (option.id == update.id) {
        live = option;
        break;
      }
    }
    if (live == null) {
      continue;
    }
    final label = live.name.trim().isEmpty ? live.id : live.name;
    parts.add(
      '$label ${live.consumerPrice}→${update.consumerPrice}',
    );
  }
  return parts.join(' · ');
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

