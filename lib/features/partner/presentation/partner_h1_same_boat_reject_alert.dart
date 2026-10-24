import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_hub_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

// =============================================================================
// H1 TEMP — remove this entire file + call sites when H1 lands.
// Same-boat reject count badge / home alert for affiliate partners.
// Search: PartnerH1SameBoatRejectAlert
// =============================================================================

/// H0/H1 temporary UI for same-boat **rejected** applications that need partner
/// rework. Pending (admin wait) is not counted as actionable.
abstract final class PartnerH1SameBoatRejectAlert {
  static int rejectedCount(Iterable<ShopProduct> shopProducts) {
    var n = 0;
    for (final product in shopProducts) {
      if (product.hasRejectedSameBoat) {
        n++;
      }
    }
    return n;
  }

  /// Popup menu entry with optional count badge. Returns null when unused.
  static PopupMenuItem<String> menuItem({
    required AppLocalizations l10n,
    required int rejectedCount,
  }) {
    return PopupMenuItem<String>(
      value: 'same_boat',
      child: Row(
        children: [
          Expanded(child: Text(l10n.partnerHomeMenuSameBoat)),
          if (rejectedCount > 0) ...[
            const SizedBox(width: 8),
            _CountBadge(count: rejectedCount),
          ],
        ],
      ),
    );
  }

  static void openHub(BuildContext context, String shopId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SameBoatSeatsHubScreen(shopId: shopId),
      ),
    );
  }

  /// Compact home banner when [rejectedCount] > 0. Null if none.
  static Widget? homeBanner({
    required BuildContext context,
    required AppLocalizations l10n,
    required String shopId,
    required int rejectedCount,
  }) {
    if (rejectedCount <= 0) {
      return null;
    }
    return Material(
      key: const Key('partner-h1-same-boat-reject-banner'),
      color: PartnerTheme.badgeOrangeBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => openHub(context, shopId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: PartnerTheme.badgeOrangeFg, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.partnerHomeSameBoatRejectedBanner(rejectedCount),
                  style: const TextStyle(
                    color: PartnerTheme.badgeOrangeFg,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: PartnerTheme.badgeOrangeFg, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('partner-h1-same-boat-reject-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: PartnerTheme.badgeOrangeBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PartnerTheme.badgeOrangeFg),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: PartnerTheme.badgeOrangeFg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
