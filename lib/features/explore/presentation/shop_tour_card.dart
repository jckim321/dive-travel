import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ShopTourCard extends StatelessWidget {
  const ShopTourCard({
    super.key,
    required this.shop,
    required this.quote,
    required this.onBook,
  });

  final DiveShop shop;
  final TourPriceQuote quote;
  final VoidCallback onBook;

  static final _priceFormat = NumberFormat('#,###', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = quote.isProfessional
        ? l10n.exploreProPrice
        : l10n.exploreConsumerPrice;
    final accent = Color(shop.accentColor);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShopHero(shop: shop, accent: accent, l10n: l10n),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.productName, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '${shop.name} · ${shop.location}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (shop.departure != null) ...[
                  const SizedBox(height: 6),
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final site in shop.sites.take(3))
                      Chip(
                        label: Text(site),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  shop.amenities.join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: Column(
                          key: ValueKey('${shop.id}-${quote.isProfessional}'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  label,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: quote.isProfessional
                                        ? AppTheme.gold
                                        : theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (quote.isProfessional) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified_outlined,
                                    size: 16,
                                    color: AppTheme.gold,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.explorePriceWon(_priceFormat.format(quote.amount)),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (quote.hasDiscount)
                              Text(
                                l10n.exploreOriginalPrice(
                                  _priceFormat.format(quote.compareAtAmount!),
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    FilledButton(
                      key: Key('shop-book-${shop.id}'),
                      onPressed: onBook,
                      child: Text(l10n.exploreBook),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopHero extends StatelessWidget {
  const _ShopHero({
    required this.shop,
    required this.accent,
    required this.l10n,
  });

  final DiveShop shop;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.navy,
            accent.withValues(alpha: 0.92),
            AppTheme.navyMid,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -14,
            child: Icon(
              Icons.scuba_diving,
              size: 110,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        shop.stars > 0
                            ? l10n.exploreDiveStar(shop.stars)
                            : l10n.exploreStarPending,
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (shop.reviewCount > 0) ...[
                      const Spacer(),
                      Icon(Icons.star_outline_rounded, color: AppTheme.gold, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        l10n.exploreRating(
                          shop.rating.toStringAsFixed(1),
                          shop.reviewCount,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else
                      const Spacer(),
                  ],
                ),
                const Spacer(),
                Text(
                  shop.country,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
