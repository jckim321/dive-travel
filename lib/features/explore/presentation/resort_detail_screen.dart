import 'dart:typed_data';

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
  const ResortDetailScreen({
    super.key,
    required this.hullId,
    this.asSheet = false,
  });

  final String hullId;
  final bool asSheet;

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
            appBar: AppBar(
              automaticallyImplyLeading: !asSheet,
              actions: [
                if (asSheet)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
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
            automaticallyImplyLeading: !asSheet,
            leading: asSheet
                ? IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  )
                : null,
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
              _ResortPhotoGallery(shop: hull),
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

/// Agoda-style attachment gallery window over the current screen.
void openResortDetail(BuildContext context, String hullId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height;
      return SizedBox(
        height: height * 0.94,
        child: ResortDetailScreen(hullId: hullId, asSheet: true),
      );
    },
  );
}

class _ResortPhotoGallery extends StatelessWidget {
  const _ResortPhotoGallery({required this.shop});

  final DiveShop shop;

  void _openViewer(BuildContext context, int index) {
    final store = DiverStoreScope.of(context);
    final providers = <ImageProvider>[];
    final local = store.galleryBytesFor(shop.hullId);
    if (local.isNotEmpty) {
      for (final bytes in local) {
        providers.add(MemoryImage(bytes));
      }
    } else {
      for (final url in shop.displayGallery) {
        if (url.isEmpty || url.startsWith('memory://')) {
          continue;
        }
        providers.add(NetworkImage(url));
      }
      if (providers.isEmpty) {
        final cover =
            store.coverBytesFor(shop.id) ?? store.coverBytesFor(shop.hullId);
        if (cover != null && cover.isNotEmpty) {
          providers.add(MemoryImage(cover));
        }
      }
    }
    if (providers.isEmpty) {
      return;
    }
    final start = index.clamp(0, providers.length - 1);
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _GalleryLightbox(
        providers: providers,
        initialIndex: start,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final urls = [
      for (final url in shop.displayGallery)
        if (url.isNotEmpty && !url.startsWith('memory://')) url,
    ];
    final local = store.galleryBytesFor(shop.hullId);
    final coverBytes =
        store.coverBytesFor(shop.id) ?? store.coverBytesFor(shop.hullId);

    Widget sharpMemory(Uint8List bytes) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        isAntiAlias: true,
      );
    }

    Widget sharpNetwork(String url) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        isAntiAlias: true,
        cacheWidth: (1100 * dpr).round().clamp(800, 2200),
        errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF0B1F33)),
      );
    }

    if (urls.isEmpty && local.isEmpty && coverBytes == null) {
      return GestureDetector(
        onTap: () => _openViewer(context, 0),
        child: CCardProductFrame(
          radius: 20,
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
                        Color(0x22000000),
                        Color(0x00000000),
                        Color(0x99052A4A),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Text(
                    shop.name,
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
      );
    }

    Widget coverImage() {
      if (local.isNotEmpty) {
        return sharpMemory(local.first);
      }
      if (coverBytes != null && coverBytes.isNotEmpty && urls.isEmpty) {
        return sharpMemory(coverBytes);
      }
      if (urls.isNotEmpty) {
        return sharpNetwork(urls.first);
      }
      return ListingCoverPhoto(shop: shop);
    }

    Widget thumb(int index) {
      if (index < local.length) {
        return sharpMemory(local[index]);
      }
      if (index < urls.length) {
        return sharpNetwork(urls[index]);
      }
      return const ColoredBox(color: Color(0xFF16324A));
    }

    final photoCount = local.isNotEmpty ? local.length : urls.length;
    final sideCount = photoCount > 1 ? (photoCount - 1).clamp(0, 4) : 0;
    final more = photoCount > 5 ? photoCount - 5 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 2.05,
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: GestureDetector(
                  onTap: () => _openViewer(context, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        coverImage(),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x22000000),
                                Color(0x00000000),
                                Color(0x99052A4A),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: Text(
                            shop.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                        if (photoCount > 1)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_library_outlined,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.exploreGalleryViewAll,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
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
                ),
              ),
              if (sideCount > 0) ...[
                const SizedBox(width: 6),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _openViewer(context, 1),
                                child: _DetailThumb(child: thumb(1)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: sideCount >= 2
                                  ? GestureDetector(
                                      onTap: () => _openViewer(context, 2),
                                      child: _DetailThumb(child: thumb(2)),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: sideCount >= 3
                                  ? GestureDetector(
                                      onTap: () => _openViewer(context, 3),
                                      child: _DetailThumb(child: thumb(3)),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: sideCount >= 4
                                  ? GestureDetector(
                                      onTap: () => _openViewer(context, 4),
                                      child: _DetailThumb(
                                        overlay: more > 0 ? '+$more' : null,
                                        child: thumb(4),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (photoCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            l10n.exploreGalleryCount(photoCount),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ],
    );
  }
}

class _GalleryLightbox extends StatefulWidget {
  const _GalleryLightbox({
    required this.providers,
    required this.initialIndex,
  });

  final List<ImageProvider> providers;
  final int initialIndex;

  @override
  State<_GalleryLightbox> createState() => _GalleryLightboxState();
}

class _GalleryLightboxState extends State<_GalleryLightbox> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.providers.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image(
                      image: widget.providers[index],
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      isAntiAlias: true,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Text(
                '${_index + 1} / ${widget.providers.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailThumb extends StatelessWidget {
  const _DetailThumb({required this.child, this.overlay});

  final Widget child;
  final String? overlay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (overlay != null)
            ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Text(
                  overlay!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
                child: ListingCoverPhoto(shop: shop),
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
