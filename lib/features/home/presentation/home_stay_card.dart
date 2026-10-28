import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
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
    this.travelTab = false,
  });

  final DiveShop shop;
  final VoidCallback onDetails;
  final double coverAspectRatio;

  /// Travel-products tab. Home shelves keep the photo-then-caption layout.
  final bool travelTab;

  @override
  Widget build(BuildContext context) {
    if (travelTab) {
      return _TravelStayCard(shop: shop, onDetails: onDetails);
    }
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
                    child: _StayHeart(shopId: shop.id, saved: saved),
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

class _TravelStayCard extends StatelessWidget {
  const _TravelStayCard({required this.shop, required this.onDetails});

  final DiveShop shop;
  final VoidCallback onDetails;

  static const _band = Color(0xFFD7EEF8);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final saved = store.isFavoriteShop(shop.id);
    final region = shop.location.trim().isNotEmpty
        ? shop.location.trim()
        : shop.country.trim();
    final hasReviews = shop.reviewCount > 0;

    final band = ColoredBox(
      key: const Key('explore-card-band'),
      color: _band,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shop.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.navy,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                height: 1.2,
              ),
            ),
            if (region.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                region,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
            const SizedBox(height: 2),
            Text(
              hasReviews
                  ? '★ ${l10n.exploreRating(shop.rating.toStringAsFixed(1), shop.reviewCount)}'
                  : l10n.reviewNoReviewsYet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasReviews ? AppTheme.gold : AppTheme.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: onDetails,
      behavior: HitTestBehavior.opaque,
      child: CCardProductFrame(
        color: _band,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final photo = AspectRatio(
              aspectRatio:
                  ListingCover.aspectRatio / ListingCover.travelPhotoScale,
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
                          Color(0x22052A4A),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _TravelBadge(shop: shop),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: _StayHeart(shopId: shop.id, saved: saved),
                  ),
                ],
              ),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                photo,
                if (constraints.hasBoundedHeight)
                  Expanded(child: band)
                else
                  band,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TravelBadge extends StatelessWidget {
  const _TravelBadge({required this.shop});

  final DiveShop shop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (shop.isDiveStarExpired) {
      return Opacity(
        opacity: 0.45,
        child: _pill(
          l10n.exploreCardDiveStarRenew,
          foreground: AppTheme.navy,
          background: AppTheme.gold,
        ),
      );
    }
    if (shop.isDiveStarCertified) {
      final marks = '★' * shop.stars.clamp(1, 3);
      return _pill(
        l10n.exploreCardDiveStar(marks),
        foreground: AppTheme.navy,
        background: AppTheme.gold,
      );
    }
    return _pill(
      l10n.exploreCardPartner,
      foreground: const Color(0xFF8A939C),
      background: const Color(0xE6F3F4F6),
    );
  }

  Widget _pill(String label, {required Color foreground, required Color background}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _StayHeart extends StatelessWidget {
  const _StayHeart({required this.shopId, required this.saved});

  final String shopId;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final store = DiverStoreScope.of(context);
    return IconButton(
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xCCFFFFFF),
        foregroundColor: saved ? const Color(0xFFE11D48) : AppTheme.navy,
        minimumSize: const Size(32, 32),
      ),
      onPressed: () async {
        if (!await ensureSignedIn(context)) return;
        if (!context.mounted) return;
        await store.toggleFavoriteShop(shopId);
      },
      icon: Icon(
        saved ? Icons.favorite : Icons.favorite_border,
        size: 16,
      ),
    );
  }
}

enum HomeShelfStyle { standard, diveStar, ranked, sameBoat, curated, captain }

const homeCoral = Color(0xFFE06A5C);
const homeTicketOrange = Color(0xFFE36A1E);

/// Thousands separator, for example 100000 → ₩100,000.
String homeWon(int amount) {
  final negative = amount < 0;
  final raw = amount.abs().toString();
  final digits = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) {
      digits.write(',');
    }
    digits.write(raw[i]);
  }
  return '${negative ? '-' : ''}₩$digits';
}

String homeDayLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

String homeNameInitial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  return String.fromCharCode(trimmed.runes.first);
}

String homeGradeLabel(AppLocalizations l10n, MemberGrade grade) {
  return switch (grade) {
    MemberGrade.silver => l10n.profileGradeSilver,
    MemberGrade.gold => l10n.profileGradeGold,
    MemberGrade.diamond => l10n.profileGradeDiamond,
    MemberGrade.platinum => l10n.profileGradePlatinum,
  };
}

ShopProduct? homeListingProduct(DiveShop shop, List<ShopProduct> products) {
  final id = shop.listingProductId;
  if (id == null) {
    return null;
  }
  for (final product in products) {
    if (product.id == id) {
      return product;
    }
  }
  return null;
}

class HomeBoatFacts {
  const HomeBoatFacts({this.departure, this.capacity = 0, this.booked = 0});

  final DateTime? departure;
  final int capacity;
  final int booked;

  int? get seatsLeft {
    if (capacity <= 0) {
      return null;
    }
    final left = capacity - booked;
    return left < 0 ? 0 : left;
  }

  /// Filled dots are booked seats, open dots are the rest of capacity.
  String get dots {
    if (capacity <= 0) {
      return '';
    }
    final filled = booked.clamp(0, capacity);
    return '${'●' * filled}${'○' * (capacity - filled)}';
  }
}

/// Product seats win. An option is used only when the product has neither
/// capacity nor a departure. Catalog departure is the last fallback.
HomeBoatFacts homeBoatFacts(DiveShop shop, ShopProduct? product) {
  if (product != null &&
      (product.capacity > 0 || product.departureStart != null)) {
    if (product.capacity > 0) {
      return HomeBoatFacts(
        departure: product.departureStart,
        capacity: product.capacity,
        booked: product.bookedSeats,
      );
    }
    for (final option in product.options) {
      if (option.capacity > 0) {
        return HomeBoatFacts(
          departure: option.departureStart ?? product.departureStart,
          capacity: option.capacity,
          booked: option.bookedSeats,
        );
      }
    }
    return HomeBoatFacts(departure: product.departureStart);
  }
  if (product != null) {
    for (final option in product.options) {
      if (option.capacity > 0 || option.departureStart != null) {
        return HomeBoatFacts(
          departure: option.departureStart,
          capacity: option.capacity,
          booked: option.bookedSeats,
        );
      }
    }
  }
  final seed = shop.departure;
  if (seed == null) {
    return const HomeBoatFacts();
  }
  return HomeBoatFacts(
    departure: seed.start,
    capacity: seed.capacity,
    booked: seed.bookedSeats,
  );
}

class HomeCaptainIdentity {
  const HomeCaptainIdentity({required this.name, required this.grade});

  final String name;
  final MemberGrade grade;
}

/// Name and grade only when a member record or the signed-in submitter has them.
HomeCaptainIdentity? homeCaptainIdentity({
  required String submittedByUid,
  required String viewerUid,
  required String viewerName,
  required MemberGrade viewerGrade,
  required List<MemberAccount> members,
}) {
  if (submittedByUid.isEmpty) {
    return null;
  }
  for (final member in members) {
    if (member.uid == submittedByUid && member.displayName.trim().isNotEmpty) {
      return HomeCaptainIdentity(
        name: member.displayName.trim(),
        grade: member.grade,
      );
    }
  }
  final name = viewerName.trim();
  if (submittedByUid == viewerUid && name.isNotEmpty) {
    return HomeCaptainIdentity(name: name, grade: viewerGrade);
  }
  return null;
}

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

class HomeSameBoatCard extends StatelessWidget {
  const HomeSameBoatCard({
    super.key,
    required this.shop,
    required this.onDetails,
  });

  static const width = 230.0;
  static const height = 176.0;

  final DiveShop shop;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final product = homeListingProduct(
      shop,
      store.liveStatsFor(shop.hullId)?.products ?? const [],
    );
    final facts = homeBoatFacts(shop, product);
    final title = shop.productName.trim().isNotEmpty
        ? shop.productName.trim()
        : shop.name;
    final days = facts.departure == null
        ? null
        : TravelStyleAnalyzer.daysUntil(facts.departure!);
    final seats = facts.seatsLeft;
    final countdown = days != null && days >= 0 && seats != null
        ? l10n.homeSameBoatCountdown(days, seats)
        : seats == null
        ? null
        : l10n.homeSameBoatSeatsLeft(seats);

    return GestureDetector(
      onTap: onDetails,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        key: Key('home-same-boat-card-${shop.hullId}'),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E8EE)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ColoredBox(
                color: homeCoral,
                child: SizedBox(height: 5, width: double.infinity),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (facts.departure != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        homeDayLabel(facts.departure!),
                        key: Key('home-same-boat-date-${shop.hullId}'),
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (facts.dots.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        facts.dots,
                        key: Key('home-same-boat-dots-${shop.hullId}'),
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                    if (countdown != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        countdown,
                        key: Key('home-same-boat-countdown-${shop.hullId}'),
                        style: const TextStyle(
                          color: homeCoral,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      homeWon(shop.consumerPrice),
                      key: Key('home-same-boat-price-${shop.hullId}'),
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
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

/// Location, then the product blurb, on one line.
String homeCuratedLine(DiveShop shop) {
  final place = shop.location.trim();
  final blurb = shop.blurb.trim();
  if (place.isNotEmpty && blurb.isNotEmpty) {
    return '$place · $blurb';
  }
  return place.isNotEmpty ? place : blurb;
}

class HomeCuratedCard extends StatelessWidget {
  const HomeCuratedCard({
    super.key,
    required this.shop,
    required this.onDetails,
  });

  static const width = 260.0;
  static const photoAspect = 1.6;
  static const bandHeight = 86.0;
  static const height = width / photoAspect + bandHeight;

  final DiveShop shop;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = shop.productName.trim().isNotEmpty
        ? shop.productName.trim()
        : shop.name;
    final line = homeCuratedLine(shop);
    return GestureDetector(
      onTap: onDetails,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        key: Key('home-curated-card-${shop.hullId}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: photoAspect,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListingCoverPhoto(shop: shop),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          l10n.homeApdiSpecial,
                          key: Key('home-curated-kicker-${shop.hullId}'),
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppTheme.navy,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      if (line.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          line,
                          key: Key('home-curated-line-${shop.hullId}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD5DDE6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        homeWon(shop.consumerPrice),
                        key: Key('home-curated-price-${shop.hullId}'),
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeCaptainCard extends StatelessWidget {
  const HomeCaptainCard({
    super.key,
    required this.shop,
    required this.onDetails,
  });

  static const width = 260.0;
  static const photoAspect = 1.6;
  static const bandHeight = 86.0;
  static const height = width / photoAspect + bandHeight;

  final DiveShop shop;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final product = homeListingProduct(
      shop,
      store.liveStatsFor(shop.hullId)?.products ?? const [],
    );
    final identity = homeCaptainIdentity(
      submittedByUid: product?.submittedByUid ?? '',
      viewerUid: store.uid ?? '',
      viewerName: store.stats.displayName,
      viewerGrade: store.stats.memberGrade,
      members: store.members,
    );
    final title = shop.productName.trim().isNotEmpty
        ? shop.productName.trim()
        : shop.name;
    final initial = identity == null ? '' : homeNameInitial(identity.name);

    return GestureDetector(
      onTap: onDetails,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        key: Key('home-captain-card-${shop.hullId}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: photoAspect,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListingCoverPhoto(shop: shop),
                  if (identity != null && initial.isNotEmpty)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DecoratedBox(
                            decoration: const BoxDecoration(
                              color: AppTheme.navy,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Center(
                                child: Text(
                                  initial,
                                  key: Key(
                                    'home-captain-initial-${shop.hullId}',
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.gold,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                homeGradeLabel(l10n, identity.grade),
                                key: Key('home-captain-grade-${shop.hullId}'),
                                style: const TextStyle(
                                  color: AppTheme.navy,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppTheme.navy,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.homeCrewRecruiting,
                        key: Key('home-captain-status-${shop.hullId}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD5DDE6),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        homeWon(shop.consumerPrice),
                        key: Key('home-captain-price-${shop.hullId}'),
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
    final cardWidth = switch (style) {
      HomeShelfStyle.diveStar => HomeDiveStarCard.width,
      HomeShelfStyle.sameBoat => HomeSameBoatCard.width,
      HomeShelfStyle.captain => HomeCaptainCard.width,
      HomeShelfStyle.curated => HomeCuratedCard.width,
      _ => (screenW * 0.55).clamp(168.0, 220.0),
    };
    final cardHeight = switch (style) {
      HomeShelfStyle.diveStar => HomeDiveStarCard.height,
      HomeShelfStyle.ranked => HomeHotSpotCard.heightFor(cardWidth),
      HomeShelfStyle.sameBoat => HomeSameBoatCard.height,
      HomeShelfStyle.captain => HomeCaptainCard.height,
      HomeShelfStyle.curated => HomeCuratedCard.height,
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
                      HomeShelfStyle.sameBoat => HomeSameBoatCard(
                        shop: shop,
                        onDetails: () => onOpen(shop),
                      ),
                      HomeShelfStyle.captain => HomeCaptainCard(
                        shop: shop,
                        onDetails: () => onOpen(shop),
                      ),
                      HomeShelfStyle.curated => HomeCuratedCard(
                        shop: shop,
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
