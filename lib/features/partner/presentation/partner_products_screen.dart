import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_list_logic.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/partner_product_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Partner-only product list with full [PartnerProductCard] actions.
class PartnerProductsScreen extends StatefulWidget {
  const PartnerProductsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PartnerProductsScreen> createState() => _PartnerProductsScreenState();
}

class _PartnerProductsScreenState extends State<PartnerProductsScreen> {
  PartnerProductStatusFilter _filter = PartnerProductStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final owned = store.partnerOwnedShopId;
        final products = store.productsForShop(owned);
        final counts = partnerProductFilterCounts(products);
        final visible = filterPartnerProducts(
          products: products,
          filter: _filter,
        );

        final body = ListView(
          key: const Key('partner-products'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.partnerProductsTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                FilledButton.icon(
                  key: const Key('admin-product-register'),
                  onPressed: () => _openRegister(context, owned),
                  icon: const Icon(Icons.add_box_outlined),
                  label: Text(l10n.partnerProductForm),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _filterChip(
                  key: 'partner-product-filter-all',
                  label: l10n.partnerProductFilterAll,
                  count: counts.all,
                  selected: _filter == PartnerProductStatusFilter.all,
                  onSelected: () => setState(
                    () => _filter = PartnerProductStatusFilter.all,
                  ),
                ),
                _filterChip(
                  key: 'partner-product-filter-drafting',
                  label: l10n.partnerProductBadgeDrafting,
                  count: counts.drafting,
                  selected: _filter == PartnerProductStatusFilter.drafting,
                  onSelected: () => setState(
                    () => _filter = PartnerProductStatusFilter.drafting,
                  ),
                ),
                _filterChip(
                  key: 'partner-product-filter-listed',
                  label: l10n.partnerProductBadgeListed,
                  count: counts.listed,
                  selected: _filter == PartnerProductStatusFilter.listed,
                  onSelected: () => setState(
                    () => _filter = PartnerProductStatusFilter.listed,
                  ),
                ),
                _filterChip(
                  key: 'partner-product-filter-closed',
                  label: l10n.partnerProductBadgeClosed,
                  count: counts.closed,
                  selected: _filter == PartnerProductStatusFilter.closed,
                  onSelected: () => setState(
                    () => _filter = PartnerProductStatusFilter.closed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GuideBox(text: l10n.partnerProductsGuide),
            const SizedBox(height: 16),
            if (products.isEmpty)
              _EmptyProductsCard(
                onRegister: () => _openRegister(context, owned),
              )
            else if (visible.isEmpty)
              Card(
                key: const Key('partner-products-filter-empty'),
                child: ListTile(
                  title: Text(l10n.partnerProductsFilterEmpty),
                ),
              )
            else
              for (final product in visible) ...[
                PartnerProductCard(
                  product: product,
                  shopId: owned,
                ),
                const SizedBox(height: 8),
              ],
          ],
        );

        return adminScreenShell(
          embedded: widget.embedded,
          title: l10n.partnerProductsTitle,
          body: body,
        );
      },
    );
  }

  Widget _filterChip({
    required String key,
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      key: Key(key),
      label: Text('$label $count'),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }

  Future<void> _openRegister(BuildContext context, String shopId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TravelProductRegistrationScreen(
          lockedShopId: shopId,
          partnerMode: true,
        ),
      ),
    );
  }
}

class _GuideBox extends StatelessWidget {
  const _GuideBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      key: const Key('partner-products-guide'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProductsCard extends StatelessWidget {
  const _EmptyProductsCard({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      key: const Key('partner-products-empty'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.partnerProductsEmptyReason,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.partnerProductsEmptyNext,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('partner-products-empty-cta'),
              onPressed: onRegister,
              child: Text(l10n.partnerProductsEmptyCta),
            ),
          ],
        ),
      ),
    );
  }
}
