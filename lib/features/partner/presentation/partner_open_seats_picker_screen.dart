import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_back_button.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_list_logic.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Pick a listed base product, then open [SameBoatSeatsScreen] (package only).
class PartnerOpenSeatsPickerScreen extends StatelessWidget {
  const PartnerOpenSeatsPickerScreen({super.key, required this.shopId});

  final String shopId;

  static final _priceFormat = NumberFormat('#,###', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return PartnerTheme.wrap(
      Scaffold(
        appBar: AppBar(
          leading: const PartnerBackButton(),
          title: Text(l10n.partnerOpenSeatsTitle),
        ),
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final listed = partnerListedBaseProducts(
              store.productsForShop(shopId),
            );
            if (listed.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    key: const Key('partner-open-seats-empty'),
                    l10n.partnerOpenSeatsEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: PartnerTheme.textDim),
                  ),
                ),
              );
            }
            return ListView(
              key: const Key('partner-open-seats-picker'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  l10n.partnerOpenSeatsPickHint,
                  style: const TextStyle(color: PartnerTheme.textDim),
                ),
                const SizedBox(height: 12),
                for (final product in listed) ...[
                  _ProductTile(
                    product: product,
                    priceLabel: l10n.partnerProductPriceLine(
                      _priceFormat.format(product.consumerPrice),
                    ),
                    onTap: () => _openSeats(context, product),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openSeats(BuildContext context, ShopProduct product) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PartnerTheme.wrap(
          SameBoatSeatsScreen(
            product: product,
            basePackageOnly: true,
            partnerLiveCopy: true,
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.priceLabel,
    required this.onTap,
  });

  final ShopProduct product;
  final String priceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('partner-open-seats-pick-${product.id}'),
      child: ListTile(
        title: Text(product.name),
        subtitle: Text(priceLabel),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
