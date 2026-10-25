import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_form_focus.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_product_list_logic.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_theme.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/missing_price_badge.dart';
import 'package:dive_travel_app/features/partner/presentation/widgets/product_publish_status_badge.dart';
import 'package:dive_travel_app/features/same_boat/presentation/same_boat_seats_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Partner master product card (시안 20): base + individuals + add-ons.
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
    final badge = partnerPublishBadgeKind(product);
    final drafting = badge == PartnerPublishBadgeKind.drafting;
    final closed = badge == PartnerPublishBadgeKind.closed;
    final listed = badge == PartnerPublishBadgeKind.listed;
    final seatsEnabled = partnerSeatsActionEnabled(product);
    final seatsManage = partnerSeatsIsManage(product);
    final sameBoatKind = partnerSameBoatLineKind(product);
    final individuals = partnerIndividualOptions(product);
    final addons = partnerCommonAddons(product);

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
                    style: const TextStyle(
                      color: PartnerTheme.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  key: Key('partner-product-basic-${product.id}'),
                  label: Text(
                    l10n.partnerProductBadgeBasic,
                    style: const TextStyle(
                      color: PartnerTheme.badgeBlueFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor: PartnerTheme.badgeBlueBg,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                const SizedBox(width: 6),
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
                    style: const TextStyle(color: PartnerTheme.text),
                  ),
                ),
                MissingPriceBadge(product: product),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              key: Key('partner-product-same-boat-${product.id}'),
              _sameBoatLabel(l10n, product, sameBoatKind),
              style: const TextStyle(
                color: PartnerTheme.textDim,
                fontSize: 12,
              ),
            ),
            if (drafting) ...[
              const SizedBox(height: 6),
              Text(
                key: Key('partner-product-draft-hint-${product.id}'),
                l10n.partnerProductDraftHiddenHint,
                style: const TextStyle(
                  color: PartnerTheme.textDim,
                  fontSize: 12,
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
                  onPressed: () => _openEdit(
                    context,
                    focus: PartnerFormFocus.none,
                  ),
                  child: Text(
                    drafting
                        ? l10n.partnerProductContinueDraft
                        : l10n.briefEdit,
                  ),
                ),
                FilledButton.tonal(
                  key: Key('partner-product-seats-${product.id}'),
                  onPressed: seatsEnabled
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PartnerTheme.wrap(
                                SameBoatSeatsScreen(
                                  product: product,
                                  basePackageOnly: true,
                                  partnerLiveCopy: true,
                                ),
                              ),
                            ),
                          )
                      : null,
                  child: Text(
                    seatsManage
                        ? l10n.partnerProductSeatsManage
                        : l10n.partnerProductMenuSeats,
                  ),
                ),
                if (listed || closed)
                  OutlinedButton(
                    key: Key(
                      closed
                          ? 'partner-product-reopen-${product.id}'
                          : 'partner-product-close-${product.id}',
                    ),
                    onPressed: () => closed
                        ? _reopen(context)
                        : _close(context),
                    child: Text(
                      closed
                          ? l10n.partnerProductReopen
                          : l10n.partnerProductClose,
                    ),
                  ),
                if (drafting || listed)
                  OutlinedButton(
                    key: Key('partner-product-add-lines-${product.id}'),
                    onPressed: () => _openEdit(
                      context,
                      focus: PartnerFormFocus.addAddon,
                    ),
                    child: Text(l10n.partnerProductAddOptionIndividual),
                  ),
              ],
            ),
            if (individuals.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                key: Key('partner-product-individuals-title-${product.id}'),
                l10n.bookingEntryIndividuals,
                style: const TextStyle(
                  color: PartnerTheme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              for (final option in individuals)
                _OptionLine(
                  productId: product.id,
                  option: option,
                  onEdit: () => _openEdit(
                    context,
                    focus: PartnerFormFocus.individuals,
                  ),
                  onDiscard: () => _discardOption(context, option),
                ),
            ],
            if (addons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                key: Key('partner-product-addons-title-${product.id}'),
                l10n.productFormSectionOptions,
                style: const TextStyle(
                  color: PartnerTheme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              for (final option in addons)
                _OptionLine(
                  productId: product.id,
                  option: option,
                  onEdit: () => _openEdit(
                    context,
                    focus: PartnerFormFocus.addons,
                  ),
                  onDiscard: () => _discardOption(context, option),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context, {
    required PartnerFormFocus focus,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TravelProductRegistrationScreen(
          lockedShopId: shopId,
          partnerMode: true,
          existing: product,
          startEditing: true,
          partnerFocus: focus,
        ),
      ),
    );
  }

  Future<void> _close(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (partnerNeedsCloseSeatWarning(product)) {
      final seats = partnerCloseWarningSeatCount(product);
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => PartnerTheme.wrap(
          AlertDialog(
            key: Key('partner-product-close-confirm-${product.id}'),
            title: Text(l10n.partnerProductCloseSeatTitle),
            content: Text(l10n.partnerProductCloseSeatBody(seats)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.adminHqClose),
              ),
              FilledButton(
                key: Key('partner-product-close-confirm-ok-${product.id}'),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.partnerProductClose),
              ),
            ],
          ),
        ),
      );
      if (ok != true || !context.mounted) {
        return;
      }
    }
    try {
      await store.setPartnerProductActive(
        shopId: shopId,
        productId: product.id,
        active: false,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _reopen(BuildContext context) async {
    final store = DiverStoreScope.of(context);
    try {
      await store.setPartnerProductActive(
        shopId: shopId,
        productId: product.id,
        active: true,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _discardOption(
    BuildContext context,
    ShopProductOption option,
  ) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => PartnerTheme.wrap(
        AlertDialog(
          key: Key('partner-option-discard-confirm-${option.id}'),
          title: Text(l10n.partnerProductDiscardConfirmTitle),
          content: Text(l10n.partnerProductDiscardConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.adminHqClose),
            ),
            FilledButton(
              key: Key('partner-option-discard-ok-${option.id}'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.partnerProductDiscard),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    try {
      final result = await store.discardPartnerOption(
        shopId: shopId,
        productId: product.id,
        optionId: option.id,
      );
      if (!context.mounted) {
        return;
      }
      if (result == PartnerOptionDiscardResult.closed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.partnerProductDiscardClosedSnack)),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
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

class _OptionLine extends StatelessWidget {
  const _OptionLine({
    required this.productId,
    required this.option,
    required this.onEdit,
    required this.onDiscard,
  });

  final String productId;
  final ShopProductOption option;
  final VoidCallback onEdit;
  final VoidCallback onDiscard;

  static final _priceFormat = NumberFormat('#,###', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final closed = !option.bookable;
    return Padding(
      key: Key('partner-option-line-${option.id}'),
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.name,
                  style: TextStyle(
                    color: closed
                        ? PartnerTheme.textDim
                        : PartnerTheme.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  closed
                      ? l10n.partnerProductOptionClosedLabel
                      : '${_priceFormat.format(option.consumerPrice)}원',
                  style: const TextStyle(
                    color: PartnerTheme.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: Key('partner-option-edit-${option.id}'),
            onPressed: onEdit,
            child: Text(l10n.briefEdit),
          ),
          TextButton(
            key: Key('partner-option-discard-${option.id}'),
            onPressed: closed ? null : onDiscard,
            child: Text(l10n.partnerProductDiscard),
          ),
        ],
      ),
    );
  }
}
