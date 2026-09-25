import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
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

class TravelProductRegistrationScreen extends StatefulWidget {
  const TravelProductRegistrationScreen({
    super.key,
    this.lockedShopId,
    this.partnerMode = false,
    this.existing,
  });

  final String? lockedShopId;
  final bool partnerMode;
  final ShopProduct? existing;

  @override
  State<TravelProductRegistrationScreen> createState() =>
      _TravelProductRegistrationScreenState();
}

class _TravelProductRegistrationScreenState
    extends State<TravelProductRegistrationScreen> {
  late final TextEditingController _name;
  late final TextEditingController _consumer;
  late final TextEditingController _pro;
  late final TextEditingController _blurb;
  late final TextEditingController _duration;
  final _photoPicker = const DivePhotoPicker();
  PickedPhoto? _photo;
  late String _shopId;
  late ProductListingKind _kind;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _shopId = widget.lockedShopId ??
        existing?.shopId ??
        DiveShopCatalog.shops.first.id;
    _kind = existing?.listingKind ?? ProductListingKind.diveStar;
    _name = TextEditingController(text: existing?.name ?? '');
    _consumer = TextEditingController(
      text: existing == null ? '' : '${existing.consumerPrice}',
    );
    _pro = TextEditingController(
      text: existing == null ? '' : '${existing.professionalPrice}',
    );
    _blurb = TextEditingController(text: existing?.blurb ?? '');
    _duration = TextEditingController(text: existing?.durationLabel ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _consumer.dispose();
    _pro.dispose();
    _blurb.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await DiverStoreScope.of(context).saveShopProduct(
        shopId: _shopId,
        product: ShopProduct(
          id: widget.existing?.id ??
              'p-${DateTime.now().millisecondsSinceEpoch}',
          shopId: _shopId,
          name: name,
          consumerPrice: int.tryParse(_consumer.text) ?? 0,
          professionalPrice: int.tryParse(_pro.text) ?? 0,
          blurb: _blurb.text.trim(),
          durationLabel: _duration.text.trim(),
          coverUrl: widget.existing?.coverUrl ?? '',
          listingKind: _kind,
          publishStatus: ProductPublishStatus.pending,
          submittedAt: DateTime.now(),
          active: false,
        ),
        photoBytes: _photo?.bytes,
        photoFileName: _photo?.fileName,
        photoContentType: _photo?.contentType,
        useAsResortCover: widget.existing == null,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminProductSubmitted)),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.exploreSaveFail}\n$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopLocked = widget.lockedShopId != null;
    final shops = DiveShopCatalog.shops;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminProductsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.adminProductSubmitHint),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.partnerShopName,
              border: const OutlineInputBorder(),
            ),
            child: shopLocked
                ? Text(
                    DiveShopCatalog.byId(_shopId)?.name ?? _shopId,
                    style: Theme.of(context).textTheme.titleMedium,
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: const Key('admin-product-shop'),
                      isExpanded: true,
                      value: _shopId,
                      items: [
                        for (final shop in shops)
                          DropdownMenuItem(
                            value: shop.id,
                            child: Text(shop.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _shopId = value);
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(l10n.productListingKind, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in ProductListingKind.values)
                ChoiceChip(
                  key: Key('product-kind-${kind.name}'),
                  label: Text(_kindLabel(l10n, kind)),
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final photo = await _photoPicker.pick();
              if (photo == null || !mounted) {
                return;
              }
              setState(() => _photo = photo);
            },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              _photo == null
                  ? l10n.exploreAttachPhoto
                  : l10n.exploreGalleryAddMore,
            ),
          ),
          if (_photo != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(_photo!.bytes, fit: BoxFit.cover),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            key: const Key('admin-product-name'),
            controller: _name,
            decoration: InputDecoration(labelText: l10n.partnerDefaultProduct),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _duration,
            decoration: InputDecoration(labelText: l10n.exploreProductDuration),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _blurb,
            maxLines: 3,
            decoration: InputDecoration(labelText: l10n.exploreProductBlurb),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _consumer,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.exploreConsumerPrice),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pro,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.exploreProPrice),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('admin-product-submit'),
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? l10n.exploreSaving : l10n.partnerSave,
            ),
          ),
        ],
      ),
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
              style: const TextStyle(color: AdminConsoleTheme.muted, fontSize: 12),
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
