import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Customer product card. [bookingsEnabled] is false on the creator review step.
class ProductOfferBox extends StatelessWidget {
  const ProductOfferBox({
    super.key,
    required this.shop,
    required this.product,
    required this.quote,
    required this.recommended,
    required this.lightest,
    required this.openRooms,
    required this.onBook,
    this.bookingsEnabled = true,
    this.coverBytes,
  });

  final DiveShop shop;
  final ShopProduct product;
  final TourPriceQuote quote;
  final bool recommended;
  final bool lightest;
  final int openRooms;
  final ValueChanged<String> onBook;
  final bool bookingsEnabled;
  final Uint8List? coverBytes;

  IconData get _kindIcon {
    final text = '${shop.productName}${shop.durationLabel}'.toLowerCase();
    if (text.contains('나이트') || text.contains('night')) {
      return Icons.nights_stay_outlined;
    }
    if (text.contains('라이브') || text.contains('liveaboard')) {
      return Icons.directions_boat_outlined;
    }
    if (text.contains('오픈워터') ||
        text.contains('코스') ||
        text.contains('course')) {
      return Icons.school_outlined;
    }
    return Icons.scuba_diving;
  }

  static final _price = NumberFormat('#,###', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lastCall = shop.departure?.lastCall == true;

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: lastCall ? AppTheme.gold : const Color(0xFFE4E8EC),
          width: lastCall ? 1.6 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: ListingCover.aspectRatio,
                child: ListingCoverPhoto(shop: shop, bytes: coverBytes),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(_kindIcon, size: 18, color: AppTheme.ocean),
                const SizedBox(width: 8),
                if (shop.durationLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.goldSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      shop.durationLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (recommended) ...[
                  const SizedBox(width: 6),
                  Text(
                    l10n.exploreRecommended,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: AppTheme.ocean,
                    ),
                  ),
                ],
                if (lightest && !recommended) ...[
                  const SizedBox(width: 6),
                  Text(
                    l10n.exploreLightest,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
                const Spacer(),
                if (lastCall)
                  Text(
                    l10n.communityKindLast,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(shop.productName, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              product.guestReviewCount > 0
                  ? l10n.reviewCountLabel(
                      product.guestRating.toStringAsFixed(1),
                      product.guestReviewCount,
                    )
                  : l10n.reviewNoReviewsYet,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
            if (shop.blurb.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(shop.blurb, style: theme.textTheme.bodySmall),
            ],
            if (shop.departure != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.exploreDepartureLine(
                  shop.departure!.windowLabel,
                  shop.departure!.emptySeats,
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.ocean,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            if (openRooms > 0) ...[
              const SizedBox(height: 6),
              Text(
                l10n.exploreProductRooms(openRooms),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            if (!_hasOptionRows)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quote.isProfessional
                              ? l10n.exploreProPrice
                              : l10n.exploreConsumerPrice,
                          style: theme.textTheme.labelSmall,
                        ),
                        Text(
                          l10n.explorePriceWon(_price.format(quote.amount)),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    key: Key('shop-book-${shop.id}'),
                    onPressed: bookingsEnabled ? () => onBook('') : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                    ),
                    child: Text(l10n.exploreBook),
                  ),
                ],
              )
            else ...[
              _offerRow(
                context,
                title: product.name,
                note: _packageNote,
                price: quote.amount,
                button: l10n.optionBookPackage,
                buttonKey: Key('shop-book-${shop.id}'),
                onPressed: () => onBook(''),
              ),
              for (final option in _addons) ...[
                const SizedBox(height: 8),
                _offerRow(
                  context,
                  title: option.name,
                  note: option.description,
                  price: _optionPrice(option),
                  button: l10n.optionBookAddon,
                  buttonKey: Key('shop-book-addon-${option.id}'),
                  onPressed: () => onBook(option.id),
                ),
              ],
              for (final option in _individuals) ...[
                const SizedBox(height: 8),
                _offerRow(
                  context,
                  title: option.name,
                  note: option.description,
                  price: _optionPrice(option),
                  button: l10n.optionBookIndividual,
                  buttonKey: Key('shop-book-individual-${option.id}'),
                  onPressed: () => onBook(option.id),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<ShopProductOption> get _addons => [
    for (final option in product.options)
      if (option.bookable && option.kind == ProductOptionKind.addon) option,
  ];

  List<ShopProductOption> get _individuals => [
    for (final option in product.options)
      if (option.bookable && option.kind == ProductOptionKind.individual)
        option,
  ];

  bool get _hasOptionRows => _addons.isNotEmpty || _individuals.isNotEmpty;

  String get _packageNote {
    final cancel = product.cancellationNote.trim();
    if (cancel.isNotEmpty) {
      return cancel;
    }
    for (final line in product.includes.split('\n')) {
      if (line.trim().isNotEmpty) {
        return line.trim();
      }
    }
    return '';
  }

  int _optionPrice(ShopProductOption option) {
    return quote.isProfessional
        ? option.professionalPrice
        : option.consumerPrice;
  }

  Widget _offerRow(
    BuildContext context, {
    required String title,
    required String note,
    required int price,
    required String button,
    required Key buttonKey,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (note.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.explorePriceWon(_price.format(price)),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton(
                  key: buttonKey,
                  onPressed: bookingsEnabled ? onPressed : null,
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.navy),
                  child: Text(button),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Light customer card with booking turned off, for the creator review step.
class ProductOfferPreview extends StatelessWidget {
  const ProductOfferPreview({
    super.key,
    required this.shop,
    required this.product,
    required this.quote,
    this.coverBytes,
  });

  final DiveShop shop;
  final ShopProduct product;
  final TourPriceQuote quote;
  final Uint8List? coverBytes;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: ProductOfferBox(
        shop: shop,
        product: product,
        quote: quote,
        recommended: false,
        lightest: false,
        openRooms: 0,
        onBook: (_) {},
        bookingsEnabled: false,
        coverBytes: coverBytes,
      ),
    );
  }
}
