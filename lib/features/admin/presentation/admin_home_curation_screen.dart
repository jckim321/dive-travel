import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Admin picks which public products appear on each home shelf.
class AdminHomeCurationScreen extends StatefulWidget {
  const AdminHomeCurationScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminHomeCurationScreen> createState() =>
      _AdminHomeCurationScreenState();
}

class _AdminHomeCurationScreenState extends State<AdminHomeCurationScreen> {
  ProductListingKind _shelf = ProductListingKind.diveStar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final public = store.publicProductsForCuration;
        final onShelf = [
          for (final product in public)
            if (product.listingKind == _shelf) product,
        ];
        final pool = [
          for (final product in public)
            if (product.listingKind == ProductListingKind.exploreOnly ||
                product.listingKind == ProductListingKind.nextDeparture)
              product,
        ];
        final count = store.countOnHomeShelf(_shelf);
        final limit = ProductListingKind.homeShelfLimit;

        final body = ListView(
          key: const Key('admin-home-curation'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              l10n.adminHomeCurationSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.embedded ? AdminConsoleTheme.muted : null,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in ProductListingKind.homeShelves)
                  if (kind != ProductListingKind.nextDeparture)
                    ChoiceChip(
                      key: Key('home-shelf-${kind.name}'),
                      label: Text(
                        '${_shelfLabel(l10n, kind)} · '
                        '${store.countOnHomeShelf(kind)}/$limit',
                      ),
                      selected: _shelf == kind,
                      selectedColor:
                          AdminConsoleTheme.aqua.withValues(alpha: 0.35),
                      onSelected: (_) => setState(() => _shelf = kind),
                    ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adminHomeCurationCount(count, limit),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: widget.embedded ? Colors.white70 : null,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.adminHomeCurationOnShelf,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: widget.embedded ? Colors.white : null,
                  ),
            ),
            const SizedBox(height: 8),
            if (onShelf.isEmpty)
              _EmptyCard(
                embedded: widget.embedded,
                text: l10n.adminHomeCurationEmptyShelf,
              )
            else
              for (final product in onShelf) ...[
                _CurationTile(
                  product: product,
                  embedded: widget.embedded,
                  order: _OrderField(
                    key: Key('home-shelf-order-${product.id}'),
                    product: product,
                    embedded: widget.embedded,
                    onSave: (order) => store.setProductHomeOrder(
                      shopId: product.shopId,
                      productId: product.id,
                      order: order,
                    ),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () => _removeFromHome(context, store, product),
                    child: Text(l10n.adminHomeCurationRemove),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 20),
            Text(
              l10n.adminHomeCurationPool,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: widget.embedded ? Colors.white : null,
                  ),
            ),
            const SizedBox(height: 8),
            if (pool.isEmpty)
              _EmptyCard(
                embedded: widget.embedded,
                text: l10n.adminHomeCurationEmptyPool,
              )
            else
              for (final product in pool) ...[
                _CurationTile(
                  product: product,
                  embedded: widget.embedded,
                  trailing: FilledButton(
                    onPressed: count >= limit
                        ? null
                        : () => _assign(context, store, product, _shelf),
                    child: Text(l10n.adminHomeCurationSend),
                  ),
                ),
                const SizedBox(height: 8),
              ],
          ],
        );

        return adminScreenShell(
          embedded: widget.embedded,
          title: l10n.adminHomeCurationTitle,
          body: body,
        );
      },
    );
  }

  Future<void> _assign(
    BuildContext context,
    DiverStore store,
    ShopProduct product,
    ProductListingKind kind,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await store.setProductHomeShelf(
        shopId: product.shopId,
        productId: product.id,
        listingKind: kind,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kind.isHomeShelf
                ? l10n.adminHomeCurationMoved
                : l10n.adminHomeCurationCleared,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = error.toString().contains('Home shelf full')
          ? l10n.adminHomeCurationFull
          : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _removeFromHome(
    BuildContext context,
    DiverStore store,
    ShopProduct product,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await store.setProductHomeShelf(
        shopId: product.shopId,
        productId: product.id,
        listingKind: ProductListingKind.exploreOnly,
      );
      await store.setProductHomeOrder(
        shopId: product.shopId,
        productId: product.id,
        order: null,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminHomeCurationCleared)),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = error.toString().contains('Home shelf full')
          ? l10n.adminHomeCurationFull
          : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.embedded, required this.text});

  final bool embedded;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: embedded ? AdminConsoleTheme.surfaceHigh : null,
      child: ListTile(
        title: Text(
          text,
          style: TextStyle(color: embedded ? AdminConsoleTheme.muted : null),
        ),
      ),
    );
  }
}

class _CurationTile extends StatelessWidget {
  const _CurationTile({
    required this.product,
    required this.embedded,
    required this.trailing,
    this.order,
  });

  final ShopProduct product;
  final bool embedded;
  final Widget trailing;
  final Widget? order;

  @override
  Widget build(BuildContext context) {
    final shopName =
        DiveShopCatalog.byId(product.shopId)?.name ?? product.shopId;

    return Card(
      color: embedded ? AdminConsoleTheme.surfaceHigh : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      color: embedded ? Colors.white : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shopName,
                    style: TextStyle(
                      color: embedded ? AdminConsoleTheme.muted : null,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (order != null) ...[
              const SizedBox(width: 8),
              order!,
            ],
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _OrderField extends StatefulWidget {
  const _OrderField({
    super.key,
    required this.product,
    required this.embedded,
    required this.onSave,
  });

  final ShopProduct product;
  final bool embedded;
  final Future<void> Function(int? order) onSave;

  @override
  State<_OrderField> createState() => _OrderFieldState();
}

class _OrderFieldState extends State<_OrderField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _label(widget.product));
    _focus = FocusNode()..addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant _OrderField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus &&
        oldWidget.product.homeShelfOrder != widget.product.homeShelfOrder) {
      _controller.text = _label(widget.product);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _label(ShopProduct product) {
    final order = product.homeShelfOrder;
    return order == null ? '' : '$order';
  }

  void _onFocus() {
    if (!_focus.hasFocus) {
      _commit();
    }
  }

  Future<void> _commit() async {
    final raw = _controller.text.trim();
    final current = widget.product.homeShelfOrder;
    final parsed = raw.isEmpty ? null : int.tryParse(raw);
    if (raw.isNotEmpty && (parsed == null || parsed < 1)) {
      _controller.text = _label(widget.product);
      return;
    }
    if (parsed == current) {
      return;
    }
    try {
      await widget.onSave(parsed);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _controller.text = _label(widget.product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = widget.embedded ? Colors.white : null;
    return SizedBox(
      width: 88,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _commit(),
        style: TextStyle(color: ink, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          labelText: l10n.adminHomeCurationOrder,
          labelStyle: TextStyle(
            color: widget.embedded ? AdminConsoleTheme.muted : null,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

String _shelfLabel(AppLocalizations l10n, ProductListingKind kind) {
  switch (kind) {
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
    case ProductListingKind.exploreOnly:
      return l10n.productListingExploreOnly;
  }
}
