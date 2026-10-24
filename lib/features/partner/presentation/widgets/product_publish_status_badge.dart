import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_list_logic.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Colored publish-status chip for partner product cards (작성 중 / 게시중 / 닫힘).
class ProductPublishStatusBadge extends StatelessWidget {
  const ProductPublishStatusBadge({
    super.key,
    required this.product,
  });

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kind = partnerPublishBadgeKind(product);
    final (label, fg, bg) = _style(l10n, kind);
    return Chip(
      key: Key('partner-product-status-${product.id}'),
      label: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
      backgroundColor: bg,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  static (String, Color, Color) _style(
    AppLocalizations l10n,
    PartnerPublishBadgeKind kind,
  ) {
    return switch (kind) {
      PartnerPublishBadgeKind.drafting => (
          l10n.partnerProductBadgeDrafting,
          const Color(0xFF4A5560),
          const Color(0xFFE2E6EA),
        ),
      PartnerPublishBadgeKind.listed => (
          l10n.partnerProductBadgeListed,
          const Color(0xFF0D5C3D),
          const Color(0xFFC8E6D0),
        ),
      PartnerPublishBadgeKind.closed => (
          l10n.partnerProductBadgeClosed,
          const Color(0xFF4A5560),
          const Color(0xFFE2E6EA),
        ),
    };
  }
}
