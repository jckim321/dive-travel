import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/ccard_product_frame.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/tour_checkout_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ResortDetailScreen extends StatelessWidget {
  const ResortDetailScreen({super.key, required this.hullId});

  final String hullId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final listings = store.listingsOnHull(hullId);
        if (listings.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.exploreNoResults)),
          );
        }
        final hull = listings.first;
        final theme = Theme.of(context);
        final owned = store.stats.ownedShopId ??
            AppConstants.defaultPartnerShopId;
        final canEdit = store.stats.isAdmin ||
            (store.stats.isBusiness && owned == hull.hullId);
        final rooms = store.visiblePosts
            .where((post) => post.shopId?.split('--').first == hull.hullId)
            .length;

        return Scaffold(
          appBar: AppBar(
            title: Text(hull.name),
            actions: [
              if (canEdit)
                IconButton(
                  key: const Key('edit-resort-page'),
                  tooltip: l10n.exploreEditResort,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ResortDeskScreen(shopId: hull.hullId),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: ListView(
            key: Key('resort-detail-$hullId'),
            cacheExtent: 2400,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              CCardProductFrame(
                radius: 20,
                child: AspectRatio(
                  aspectRatio: ListingCover.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ListingCoverPhoto(shop: hull, opacity: 0.55),
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
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Text(
                          hull.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StarBadge(stars: hull.stars, certified: hull.isDiveStarCertified),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      hull.reviewCount > 0
                          ? l10n.exploreRating(
                              hull.rating.toStringAsFixed(2),
                              hull.reviewCount,
                            )
                          : l10n.exploreListingPendingReview,
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.cloud_off_outlined, size: 16),
                    visualDensity: VisualDensity.compact,
                    label: Text(l10n.exploreWeatherRefundTitle),
                  ),
                  if (rooms > 0)
                    Chip(
                      avatar: const Icon(Icons.flag_outlined, size: 16),
                      visualDensity: VisualDensity.compact,
                      label: Text(l10n.exploreOpenRooms(rooms)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.exploreResortIntro, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(hull.intro, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              _MapCard(address: hull.address, location: hull.location),
              const SizedBox(height: 16),
              Text(l10n.exploreResortTraits, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in [...hull.amenities, ...hull.sites])
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.check_rounded, size: 16),
                      label: Text(item),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Text(l10n.exploreChooseRoom, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(l10n.exploreChooseRoomHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: 14),
              for (final shop in listings) ...[
                _ProductBox(
                  shop: shop,
                  quote: store.quoteFor(shop),
                  recommended: hull.isDiveStarCertified && shop.id == listings.first.id,
                  lightest: shop.consumerPrice ==
                      listings
                          .map((item) => item.consumerPrice)
                          .reduce((a, b) => a < b ? a : b),
                  openRooms: store.visiblePosts
                      .where((post) =>
                          post.shopId == shop.id ||
                          (post.shopId?.split('--').first == hull.hullId &&
                              post.subtitle == shop.productName))
                      .length,
                  onBook: () => showTourCheckoutSheet(
                    context: context,
                    shop: shop,
                    quote: store.quoteFor(shop),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

void openResortDetail(BuildContext context, String hullId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ResortDetailScreen(hullId: hullId),
    ),
  );
}

class _StarBadge extends StatelessWidget {
  const _StarBadge({required this.stars, required this.certified});

  final int stars;
  final bool certified;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: certified ? AppTheme.goldSoft : const Color(0xFFE8EEF2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16,
              color: AppTheme.gold,
            ),
          const SizedBox(width: 6),
          Text(
            certified
                ? l10n.exploreDiveStar(stars)
                : l10n.exploreStarPending,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.address, required this.location});

  final String address;
  final String location;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.oceanDeep,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        height: 132,
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -30,
              child: Icon(
                Icons.public,
                size: 160,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.exploreResortMap,
                    style: const TextStyle(
                      color: Color(0xFFF4EBD3),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, color: AppTheme.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address.isEmpty ? location : address,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductBox extends StatelessWidget {
  const _ProductBox({
    required this.shop,
    required this.quote,
    required this.recommended,
    required this.lightest,
    required this.openRooms,
    required this.onBook,
  });

  final DiveShop shop;
  final TourPriceQuote quote;
  final bool recommended;
  final bool lightest;
  final int openRooms;
  final VoidCallback onBook;

  IconData get _kindIcon {
    final text = '${shop.productName}${shop.durationLabel}'.toLowerCase();
    if (text.contains('나이트') || text.contains('night')) {
      return Icons.nights_stay_outlined;
    }
    if (text.contains('라이브') || text.contains('liveaboard')) {
      return Icons.directions_boat_outlined;
    }
    if (text.contains('오픈워터') || text.contains('코스') || text.contains('course')) {
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
                child: ListingCoverPhoto(shop: shop, opacity: 0.7),
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
                  onPressed: onBook,
                  child: Text(l10n.exploreBook),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
