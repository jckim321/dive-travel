import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_list_logic.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Warns that [ShopProduct.consumerPrice] was never set (≤ 0).
class MissingPriceBadge extends StatelessWidget {
  const MissingPriceBadge({
    super.key,
    required this.product,
  });

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    if (!partnerPriceMissing(product)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Chip(
      key: Key('partner-product-missing-price-${product.id}'),
      label: Text(
        l10n.partnerProductBadgeMissingPrice,
        style: const TextStyle(
          color: Color(0xFF8B1A1A),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
      backgroundColor: const Color(0xFFFFE0E0),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
