import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/ccard_product_frame.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_sign_in_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class HomeStayCard extends StatelessWidget {
  const HomeStayCard({
    super.key,
    required this.shop,
    required this.onDetails,
    this.coverAspectRatio = ListingCover.aspectRatio,
  });

  final DiveShop shop;
  final VoidCallback onDetails;
  final double coverAspectRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final saved = store.isFavoriteShop(shop.id);
    final showBadge = shop.showsDiveStarBadge;
    final expired = shop.isDiveStarExpired;
    final certified = shop.isDiveStarCertified;
    final badgeLabel = expired
        ? l10n.exploreDiveStarRenewalNeeded
        : l10n.exploreDiveStarCertified;

    return GestureDetector(
      onTap: onDetails,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CCardProductFrame(
            child: AspectRatio(
              aspectRatio: coverAspectRatio,
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
                  if (showBadge)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: ListingCertBadge(
                        label: badgeLabel,
                        certified: certified,
                        faded: expired,
                        grade: expired ? 0 : shop.stars,
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
                      onPressed: () async {
                        if (!await ensureSignedIn(context)) return;
                        if (!context.mounted) return;
                        await store.toggleFavoriteShop(shop.id);
                      },
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
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFF4A5560),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            shop.reviewCount > 0
                ? l10n.reviewCountLabel(
                    shop.rating.toStringAsFixed(1),
                    shop.reviewCount,
                  )
                : l10n.reviewNoReviewsYet,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

enum HomeShelfStyle { standard, diveStar, ranked }

/// Gold star marks for a Dive Star grade. Empty when the shop has no grade.
String homeDiveStarMarks(int stars) {
  if (stars >= 3) {
    return '★★★';
  }
  if (stars == 2) {
    return '★★';
  }
  if (stars == 1) {
    return '★';
  }
  return '';
}

class HomeDiveStarCard extends StatelessWidget {
  const HomeDiveStarCard({
    super.key,
    required this.shop,
    required this.onDetails,
  });

  static const width = 250.0;
  static const photoAspect = 4 / 3;
  static const height = width / photoAspect + 72;

  final DiveShop shop;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final marks = homeDiveStarMarks(shop.stars);
    return GestureDetector(
      onTap: onDetails,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        key: Key('home-dive-star-card-${shop.hullId}'),
        decoration: BoxDecoration(
          color: AppTheme.navy,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: photoAspect,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppTheme.navy),
                    ListingCoverPhoto(shop: shop),
                    if (marks.isNotEmpty)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xE60B1F33),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.gold),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              marks,
                              key: Key('home-dive-star-marks-${shop.hullId}'),
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD5DDE6),
                        fontSize: 12,
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
    );
  }
}

class HomeHotSpotCard extends StatelessWidget {
  const HomeHotSpotCard({
    super.key,
    required this.shop,
    required this.rank,
    required this.onDetails,
  });

  static const photoAspect = 4 / 3;

  static double heightFor(double width) => width / photoAspect + 58;

  final DiveShop shop;
  final int rank;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onDetails,
      behavior: HitTestBehavior.opaque,
      child: Column(
        key: Key('home-hot-card-${shop.hullId}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: photoAspect,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListingCoverPhoto(shop: shop),
                  Positioned(
                    left: 8,
                    top: 2,
                    child: Text(
                      '$rank',
                      key: Key('home-hot-rank-$rank'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        shadows: [
                          Shadow(
                            color: Color(0xCC000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
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
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            shop.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.muted),
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
    this.subtitle,
    this.belowSubtitle,
    this.headerAction,
    this.style = HomeShelfStyle.standard,
    this.showWhenEmpty = false,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final Widget? belowSubtitle;
  final Widget? headerAction;
  final HomeShelfStyle style;
  final List<DiveShop> shops;
  final bool showWhenEmpty;
  final VoidCallback? onSeeAll;
  final void Function(DiveShop shop) onOpen;

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty && !showWhenEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // Compact rail: next card peeks; 4:3 keeps image shorter than the old 1:1 tiles.
    const coverAspect = 4 / 3;
    final screenW = MediaQuery.sizeOf(context).width;
    final cardWidth = style == HomeShelfStyle.diveStar
        ? HomeDiveStarCard.width
        : (screenW * 0.55).clamp(168.0, 220.0);
    final cardHeight = switch (style) {
      HomeShelfStyle.diveStar => HomeDiveStarCard.height,
      HomeShelfStyle.ranked => HomeHotSpotCard.heightFor(cardWidth),
      HomeShelfStyle.standard => cardWidth / coverAspect + 50,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                  if (belowSubtitle != null) ...[
                    const SizedBox(height: 4),
                    belowSubtitle!,
                  ],
                ],
              ),
            ),
            if (onSeeAll != null)
              IconButton(
                tooltip: l10n.homeSeeAll,
                onPressed: onSeeAll,
                icon: const Icon(Icons.chevron_right, color: AppTheme.navy),
              ),
          ],
        ),
        if (headerAction != null) ...[
          const SizedBox(height: 10),
          headerAction!,
        ],
        if (shops.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shops.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final shop = shops[index];
                return SizedBox(
                  width: cardWidth,
                  child: switch (style) {
                    HomeShelfStyle.diveStar => HomeDiveStarCard(
                      shop: shop,
                      onDetails: () => onOpen(shop),
                    ),
                    HomeShelfStyle.ranked => HomeHotSpotCard(
                      shop: shop,
                      rank: index + 1,
                      onDetails: () => onOpen(shop),
                    ),
                    HomeShelfStyle.standard => HomeStayCard(
                      shop: shop,
                      coverAspectRatio: coverAspect,
                      onDetails: () => onOpen(shop),
                    ),
                  },
                );
              },
            ),
          ),
        ],
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
