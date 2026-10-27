import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Gold or above, own trip, and an approved listing.
bool craftedTripCanOpenSeats({
  required MemberGrade grade,
  required String viewerUid,
  required ShopProduct product,
}) {
  if (viewerUid.isEmpty || product.submittedByUid != viewerUid) {
    return false;
  }
  if (grade.rank < MemberGrade.gold.rank) {
    return false;
  }
  return product.publishStatus == ProductPublishStatus.approved;
}

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
        builder: (_) => TravelProductRegistrationScreen(
          creatorMode: true,
          existing: existing,
          startEditing: true,
        ),
      ),
    );
  }

  Future<void> _askOpenSeats(BuildContext context, ShopProduct product) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('same-boat-ask-create-seats'),
          content: Text(l10n.sameBoatAskCreateSeats),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.sameBoatAskCreateSeatsNo),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.sameBoatAskCreateSeatsYes),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SameBoatSeatsScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      key: const Key('my-crafted-trips'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.profileCraftedTripsTitle),
        const SizedBox(height: 8),
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
                  onTap: () => _openCraft(context, existing: product),
                  onOpenSeats: craftedTripCanOpenSeats(
                    grade: memberGrade,
                    viewerUid: viewerUid,
                    product: product,
                  )
                      ? () => _askOpenSeats(context, product)
                      : null,
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
    required this.onTap,
    this.onOpenSeats,
  });

  final ShopProduct product;
  final VoidCallback onTap;
  final VoidCallback? onOpenSeats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = switch (product.publishStatus) {
      ProductPublishStatus.pending => l10n.profileCraftStatusPending,
      ProductPublishStatus.approved => l10n.profileCraftStatusLive,
      ProductPublishStatus.rejected => l10n.profileCraftStatusRejected,
      ProductPublishStatus.draft => l10n.profileCraftStatusPending,
    };
    final accent = switch (product.publishStatus) {
      ProductPublishStatus.approved => AppTheme.ocean,
      ProductPublishStatus.rejected => const Color(0xFFB45309),
      _ => AppTheme.gold,
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onOpenSeats,
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
              if (onOpenSeats != null)
                TextButton(
                  key: Key('crafted-open-seats-${product.id}'),
                  onPressed: onOpenSeats,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.sameBoatSeatsTitle,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
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
