import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/ccard_product_frame.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class HomeStayCard extends StatelessWidget {
  const HomeStayCard({
    super.key,
    required this.shop,
    required this.quote,
    required this.onDetails,
    required this.onBuy,
    this.asResort = true,
    this.productCount = 1,
  });

  final DiveShop shop;
  final TourPriceQuote quote;
  final VoidCallback onDetails;
  final VoidCallback onBuy;
  final bool asResort;
  final int productCount;

  static final _price = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final saved = store.isFavoriteShop(shop.id);
    final certified = shop.isDiveStarCertified;
    final badgeLabel = certified
        ? l10n.exploreDiveStarCertified
        : shop.isNewListing
            ? l10n.exploreListingNew
            : l10n.exploreListingPendingReview;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onDetails,
          child: CCardProductFrame(
            child: AspectRatio(
              aspectRatio: ListingCover.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListingCoverPhoto(shop: shop),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33000000),
                        Color(0x00000000),
                        Color(0xCC052A4A),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: ListingCertBadge(
                    label: badgeLabel,
                    certified: certified,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xCCFFFFFF),
                      foregroundColor:
                          saved ? const Color(0xFFE11D48) : AppTheme.navy,
                      minimumSize: const Size(32, 32),
                    ),
                    onPressed: () => store.toggleFavoriteShop(shop.id),
                    icon: Icon(
                      saved ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            key: Key('shop-details-${shop.id}'),
                            onPressed: onDetails,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.navy,
                              backgroundColor: const Color(0xF2FFFFFF),
                              side: const BorderSide(
                                color: AppTheme.gold,
                                width: 1.1,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              textStyle: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                            child: Text(
                              l10n.exploreViewListing,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: FilledButton(
                            key: Key('shop-buy-${shop.id}'),
                            onPressed: onBuy,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.navy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: Text(l10n.exploreBuyNow),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          shop.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          asResort
              ? l10n.exploreResortCardLine(
                  shop.location,
                  productCount,
                )
              : '${shop.location} · ${shop.productName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        if (!asResort && shop.departure != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.exploreDepartureLine(
              shop.departure!.windowLabel,
              shop.departure!.emptySeats,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.ocean,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 4),
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
                    style: theme.textTheme.labelMedium,
                  ),
                  Text(
                    '${_price.format(quote.amount)}원',
                    style: theme.textTheme.labelLarge,
                  ),
                  if (quote.hasDiscount)
                    Text(
                      l10n.exploreOriginalPrice(
                        _price.format(quote.compareAtAmount!),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
            if (shop.reviewCount > 0) ...[
              const Icon(Icons.star_rounded, size: 14, color: AppTheme.gold),
              const SizedBox(width: 2),
              Text(
                shop.rating.toStringAsFixed(1),
                style: theme.textTheme.labelMedium,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class HomeDiscoverySection extends StatelessWidget {
  const HomeDiscoverySection({
    super.key,
    required this.title,
    required this.shops,
    required this.onOpen,
    this.emptyText,
    this.onSeeAll,
  });

  final String title;
  final List<DiveShop> shops;
  final String? emptyText;
  final VoidCallback? onSeeAll;
  final void Function(DiveShop shop) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            if (onSeeAll != null)
              IconButton(
                tooltip: l10n.homeSeeAll,
                onPressed: onSeeAll,
                icon: const Icon(Icons.chevron_right, color: AppTheme.navy),
              ),
          ],
        ),
        if (shops.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 8),
            child: Text(
              emptyText ?? l10n.homeFavoritesEmpty,
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shops.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              mainAxisExtent: ListingCover.cardExtent(context),
            ),
            itemBuilder: (context, index) {
              final shop = shops[index];
              return HomeStayCard(
                shop: shop,
                quote: store.quoteFor(shop),
                productCount: store.listingsOnHull(shop.hullId).length,
                onDetails: () => onOpen(shop),
                onBuy: () => onOpen(shop),
              );
            },
          ),
      ],
    );
  }
}

class LastMinuteCrewBanner extends StatelessWidget {
  const LastMinuteCrewBanner({
    super.key,
    required this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFB42318),
                Color(0xFFC45A2A),
                Color(0xFF0A4A73),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330B1F33),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 148,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.28,
                    child: Image.asset(
                      'assets/images/test_dive_photo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xCC8A1C14),
                          Color(0x660A4A73),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.gold,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              l10n.homeChipLastMinute,
                              style: const TextStyle(
                                color: AppTheme.navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.homeLastMinuteCrew,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.homeLastMinuteSeat,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
