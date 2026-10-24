import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_list_logic.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/missing_price_badge.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/product_publish_status_badge.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Full partner product card (build 3): price, same-boat line, edit/seats/reject actions.
class PartnerProductCard extends StatelessWidget {
  const PartnerProductCard({
    super.key,
    required this.product,
    required this.shopId,
  });

  final ShopProduct product;
  final String shopId;

  static final _priceFormat = NumberFormat('#,###', 'en_US');
  static final _dayFormat = DateFormat('yyyy.MM.dd');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final seatsEnabled = partnerSeatsActionEnabled(product);
    final seatsManage = partnerSeatsIsManage(product);
    final rejected = partnerShowRejectedActions(product);
    final sameBoatKind = partnerSameBoatLineKind(product);

    return Card(
      key: Key('partner-product-${product.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ProductPublishStatusBadge(product: product),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    key: Key('partner-product-price-${product.id}'),
                    l10n.partnerProductPriceLine(
                      _priceFormat.format(product.consumerPrice),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                MissingPriceBadge(product: product),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              key: Key('partner-product-same-boat-${product.id}'),
              _sameBoatLabel(l10n, product, sameBoatKind),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (rejected && product.reviewNote.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                key: Key('partner-product-review-note-${product.id}'),
                product.reviewNote.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8B1A1A),
                ),
              ),
            ],
            if (product.resubmitCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                key: Key('partner-product-resubmit-count-${product.id}'),
                l10n.partnerResubmitCount(product.resubmitCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: Key('partner-product-edit-${product.id}'),
                  onPressed: () => _openEdit(context),
                  child: Text(l10n.briefEdit),
                ),
                FilledButton.tonal(
                  key: Key('partner-product-seats-${product.id}'),
                  onPressed: seatsEnabled
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  SameBoatSeatsScreen(product: product),
                            ),
                          )
                      : null,
                  child: Text(
                    seatsManage
                        ? l10n.partnerProductSeatsManage
                        : l10n.sameBoatSeatsTitle,
                  ),
                ),
                if (rejected) ...[
                  FilledButton(
                    key: Key('partner-product-resubmit-${product.id}'),
                    onPressed: () => _openEdit(context),
                    child: Text(l10n.partnerProductResubmit),
                  ),
                  OutlinedButton(
                    key: Key('partner-product-delete-${product.id}'),
                    onPressed: () => confirmDeletePartnerProduct(
                      context,
                      product,
                    ),
                    child: Text(l10n.adminProductDelete),
                  ),
                ],
              ],
            ),
            if (!seatsEnabled) ...[
              const SizedBox(height: 6),
              Text(
                key: Key('partner-product-seats-hint-${product.id}'),
                l10n.sameBoatSeatsNoProducts,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TravelProductRegistrationScreen(
          lockedShopId: shopId,
          partnerMode: true,
          existing: product,
          startEditing: true,
        ),
      ),
    );
  }

  static String _sameBoatLabel(
    AppLocalizations l10n,
    ShopProduct product,
    PartnerSameBoatLineKind kind,
  ) {
    return switch (kind) {
      PartnerSameBoatLineKind.pendingReview =>
        l10n.partnerProductSameBoatPending,
      PartnerSameBoatLineKind.liveOpen => () {
          final summary = partnerSameBoatLiveSummary(product);
          final date = summary.departure == null
              ? '—'
              : _dayFormat.format(summary.departure!);
          return l10n.partnerProductSameBoatLive(summary.seats, date);
        }(),
      PartnerSameBoatLineKind.rejected =>
        l10n.partnerProductSameBoatRejected,
      PartnerSameBoatLineKind.notOpened =>
        l10n.partnerProductSameBoatNotOpened,
    };
  }
}

/// Confirm + delete (same pattern as admin product list).
Future<void> confirmDeletePartnerProduct(
  BuildContext context,
  ShopProduct product,
) async {
  final l10n = AppLocalizations.of(context);
  final store = DiverStoreScope.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.adminProductDelete),
      content: Text(l10n.adminProductDeleteBody(product.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.adminHqClose),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.adminProductDelete),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) {
    return;
  }
  try {
    await store.deleteShopProduct(
      shopId: product.shopId,
      productId: product.id,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.adminProductDeleted)));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}
