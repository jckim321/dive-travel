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
  });

  final DiveShop shop;
  final TourPriceQuote quote;
  final VoidCallback onDetails;

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

    return GestureDetector(
      onTap: onDetails,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CCardProductFrame(
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
                          Color(0x66052A4A),
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
                ],
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
            '${_price.format(quote.amount)}원',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge,
          ),
        ],
      ),
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
                onDetails: () => onOpen(shop),
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
