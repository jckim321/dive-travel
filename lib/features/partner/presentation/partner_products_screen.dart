import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/partner_product_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Partner product list (시안 20): master cards with individuals / add-ons.
class PartnerProductsScreen extends StatelessWidget {
  const PartnerProductsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return PartnerTheme.wrap(
      Scaffold(
        appBar: embedded
            ? null
            : AppBar(
                leading: const PartnerBackButton(),
                title: Text(l10n.partnerProductListTitle),
              ),
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final owned = store.partnerOwnedShopId;
            final products = store.productsForShop(owned);

            return ListView(
              key: const Key('partner-products'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (products.isEmpty)
                  _EmptyProductsCard(
                    onRegister: () => _openRegister(context, owned),
                  )
                else ...[
                  for (final product in products) ...[
                    PartnerProductCard(
                      product: product,
                      shopId: owned,
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    key: const Key('partner-products-footer'),
                    l10n.partnerProductListFooter,
                    style: const TextStyle(
                      color: PartnerTheme.textDim,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
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

class _EmptyProductsCard extends StatelessWidget {
  const _EmptyProductsCard({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const Key('partner-products-empty'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.partnerProductsEmptyH2,
              style: const TextStyle(
                color: PartnerTheme.text,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('partner-products-empty-cta'),
              onPressed: onRegister,
              child: Text(l10n.partnerProductsEmptyCtaH2),
            ),
          ],
        ),
      ),
    );
  }
}
