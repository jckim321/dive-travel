import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_trip_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Horizontal rail of trips this diver submitted + CTA to craft a new one.
class MyCraftedTripsSection extends StatelessWidget {
  const MyCraftedTripsSection({
    super.key,
    required this.products,
    required this.memberGrade,
    required this.viewerUid,
  });

  final List<ShopProduct> products;
  final MemberGrade memberGrade;
  final String viewerUid;

  Future<void> _openCraft(BuildContext context, {ShopProduct? existing}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PlannerTripScreen(existing: existing),
      ),
    );
  }

  /// Home uses [ShopLiveStats.readerProducts]. The card list is still the
  /// shop array. Same id prefers that merge; otherwise the array row.
  ShopProduct _statusProduct(BuildContext context, ShopProduct arrayProduct) {
    final scope = context.dependOnInheritedWidgetOfExactType<DiverStoreScope>();
    final readers = scope?.notifier?.liveStatsFor(arrayProduct.shopId)?.readerProducts;
    if (readers == null) {
      return arrayProduct;
    }
    for (final product in readers) {
      if (product.id == arrayProduct.id) {
        return product;
      }
    }
    return arrayProduct;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      key: const Key('my-crafted-trips'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.profileCraftedTripsHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 14),
        SizedBox(
          height: 132,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _NewTripCard(onTap: () => _openCraft(context)),
              for (final product in products) ...[
                const SizedBox(width: 10),
                _CraftedTripCard(
                  product: product,
                  statusProduct: _statusProduct(context, product),
                  onTap: () => _openCraft(context, existing: product),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NewTripCard extends StatelessWidget {
  const _NewTripCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: const Key('craft-new-trip'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 128,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.navy.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: AppTheme.navy, size: 28),
              const SizedBox(height: 10),
              Text(
                l10n.profileCraftNewTrip,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CraftedTripCard extends StatelessWidget {
  const _CraftedTripCard({
    required this.product,
    required this.statusProduct,
    required this.onTap,
  });

  final ShopProduct product;
  final ShopProduct statusProduct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final adminHidden = statusProduct.sameBoatStatus == SameBoatStatus.hidden;
    final status = adminHidden
        ? '관리자가 잠시 숨김'
        : switch (statusProduct.publishStatus) {
            ProductPublishStatus.pending => l10n.profileCraftStatusPending,
            ProductPublishStatus.approved => l10n.profileCraftStatusLive,
            ProductPublishStatus.rejected => l10n.profileCraftStatusRejected,
            ProductPublishStatus.draft => '임시 저장',
          };
    final accent = switch (statusProduct.publishStatus) {
      ProductPublishStatus.approved => AppTheme.ocean,
      ProductPublishStatus.rejected => const Color(0xFFB45309),
      _ => AppTheme.gold,
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.navy.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (!adminHidden &&
                  statusProduct.publishStatus == ProductPublishStatus.approved)
                Text(
                  statusProduct.listsOnSameBoat ? '같은배 모집 중' : '같은배 닫힘',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.ocean,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                Text(
                  '${product.consumerPrice}원',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
