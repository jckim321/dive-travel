import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
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
        final owned =
            store.stats.ownedShopId ?? AppConstants.defaultPartnerShopId;
        final canEdit =
            store.stats.isAdmin ||
            (store.stats.isBusiness && owned == hull.hullId);
        final products =
            store.liveStatsFor(hull.hullId)?.products ?? const <ShopProduct>[];
        final rooms = SameBoatBoard.offers(products).length;
        final hero = _heroProduct(products);
        final ratingValue = hero != null && hero.guestReviewCount > 0
            ? hero.guestRating
            : hull.rating;
        final ratingCount = hero != null && hero.guestReviewCount > 0
            ? hero.guestReviewCount
            : hull.reviewCount;

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
          body: SingleChildScrollView(
            key: Key('resort-detail-$hullId'),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResortPhotoGallery(
                  shop: hull,
                  productId: _heroProduct(products)?.id,
                  photoUrls: _heroPhotoUrls(products),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StarBadge(
                      stars: hull.stars,
                      certified: hull.isDiveStarCertified,
                    ),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        ratingCount > 0
                            ? l10n.reviewCountLabel(
                                ratingValue.toStringAsFixed(1),
                                ratingCount,
                              )
                            : l10n.reviewNoReviewsYet,
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
                Text(
                  l10n.exploreResortIntro,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(hull.intro, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                _MapCard(address: hull.address, location: hull.location),
                const SizedBox(height: 16),
                Text(
                  l10n.exploreResortTraits,
                  style: theme.textTheme.titleSmall,
                ),
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
                Text(
                  l10n.exploreChooseRoom,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.exploreChooseRoomHint,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                ..._productBoxes(
                  context: context,
                  store: store,
                  hull: hull,
                  catalogListings: listings,
                  products: products,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

List<Widget> _productBoxes({
  required BuildContext context,
  required DiverStore store,
  required DiveShop hull,
  required List<DiveShop> catalogListings,
  required List<ShopProduct> products,
}) {
  final bookingListings = _bookingListings(
    store: store,
    hull: hull,
    catalogListings: catalogListings,
    products: products,
  );
  if (bookingListings.isEmpty) {
    return const [];
  }
  final lightest = bookingListings
      .map((item) => item.consumerPrice)
      .reduce((a, b) => a < b ? a : b);
  final out = <Widget>[];
  for (final shop in bookingListings) {
    final product = _listingProduct(shop, products);
    out.add(
      _ProductBox(
        shop: shop,
        product: product,
        quote: store.quoteFor(shop),
        recommended:
            hull.isDiveStarCertified && shop.id == bookingListings.first.id,
        lightest: shop.consumerPrice == lightest,
        openRooms: SameBoatBoard.offers(products)
            .where((offer) => offer.product.id == product.id)
            .length,
        onBook: (presetOptionId) {
          showTourCheckoutSheet(
            context: context,
            shop: shop,
            quote: store.quoteFor(shop),
            product: product,
            presetOptionId: presetOptionId,
          );
        },
      ),
    );
    out.add(const SizedBox(height: 12));
  }
  return out;
}

/// Prefer live public products (id-stable). Fall back to catalog SKUs.
List<DiveShop> _bookingListings({
  required DiverStore store,
  required DiveShop hull,
  required List<DiveShop> catalogListings,
  required List<ShopProduct> products,
}) {
  final public = [
    for (final product in products)
      if (product.isListedPublicly) product,
  ];
  if (public.isNotEmpty) {
    return [
      for (final product in public)
        store.listingCardForProduct(hull, product),
    ];
  }
  return catalogListings;
}

ShopProduct _listingProduct(DiveShop shop, List<ShopProduct> products) {
  final productId = shop.listingProductId;
  if (productId != null && productId.isNotEmpty) {
    for (final item in products) {
      if (item.id == productId) {
        return item;
      }
    }
  }
  for (final item in products) {
    if (item.name == shop.productName) {
      return item;
    }
  }
  for (final item in products) {
    if (item.isListedPublicly) {
      return item;
    }
  }
  return ShopProduct(
    id: productId ?? shop.id,
    shopId: shop.hullId,
    name: shop.productName,
    consumerPrice: shop.consumerPrice,
    professionalPrice: shop.professionalPrice,
    blurb: shop.blurb,
    durationLabel: shop.durationLabel,
  );
}

ShopProduct? _heroProduct(List<ShopProduct> products) {
  for (final product in products) {
    if (product.isListedPublicly) {
      return product;
    }
  }
  return null;
}

List<String> _heroPhotoUrls(List<ShopProduct> products) {
  final product = _heroProduct(products);
  if (product == null) {
    return const [];
  }
  final urls = [
    for (final url in product.photoUrls)
      if (url.trim().isNotEmpty) url.trim(),
  ];
  if (urls.isNotEmpty) {
    return urls;
  }
  final cover = product.coverUrl.trim();
  if (cover.isNotEmpty) {
    return [cover];
  }
  return const [];
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

class _ResortPhotoGallery extends StatefulWidget {
  const _ResortPhotoGallery({
    required this.shop,
    this.productId,
    this.photoUrls = const [],
  });

  final DiveShop shop;
  final String? productId;
  final List<String> photoUrls;

  @override
  State<_ResortPhotoGallery> createState() => _ResortPhotoGalleryState();
}

class _ResortPhotoGalleryState extends State<_ResortPhotoGallery> {
  var _index = 0;

  List<ImageProvider> _slides() {
    final store = DiverStoreScope.of(context);
    final productId = widget.productId;
    if (widget.photoUrls.isNotEmpty && productId != null) {
      final frames = store.productFramesFor(
        '${widget.shop.hullId}--$productId',
      );
      final slides = <ImageProvider>[];
      for (var i = 0; i < widget.photoUrls.length; i++) {
        final url = widget.photoUrls[i];
        if (i < frames.length && frames[i] != null && frames[i]!.isNotEmpty) {
          slides.add(MemoryImage(frames[i]!));
          continue;
        }
        if (url.isNotEmpty && !url.startsWith('memory://')) {
          slides.add(NetworkImage(url));
        }
      }
      if (slides.isNotEmpty) {
        return slides;
      }
    }
    final local = store.galleryBytesFor(widget.shop.hullId);
    if (local.isNotEmpty) {
      return [for (final bytes in local) MemoryImage(bytes)];
    }
    final urls = [
      for (final url in widget.shop.displayGallery)
        if (url.isNotEmpty && !url.startsWith('memory://')) url,
    ];
    if (urls.isNotEmpty) {
      return [for (final url in urls) NetworkImage(url)];
    }
    final cover =
        store.coverBytesFor(widget.shop.id) ??
        store.coverBytesFor(widget.shop.hullId);
    if (cover != null && cover.isNotEmpty) {
      return [MemoryImage(cover)];
    }
    return const [];
  }

  void _openAlbum(List<ImageProvider> slides) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PhotoAlbumPage(providers: slides),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides();
    if (slides.isEmpty) {
      return CCardProductFrame(
        radius: 20,
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: ListingCoverPhoto(shop: widget.shop),
        ),
      );
    }
    final index = _index.clamp(0, slides.length - 1);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              key: const Key('resort-photo-pager'),
              itemCount: slides.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () => _openAlbum(slides),
                  child: Image(
                    image: slides[i],
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    isAntiAlias: true,
                  ),
                );
              },
            ),
            if (slides.length > 1)
              Positioned(
                right: 12,
                bottom: 12,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        '${index + 1} / ${slides.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
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

class _PhotoAlbumPage extends StatelessWidget {
  const _PhotoAlbumPage({required this.providers});

  final List<ImageProvider> providers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.exploreGalleryTitle),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: providers.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              showDialog<void>(
                context: context,
                barrierColor: Colors.black87,
                builder: (_) =>
                    _GalleryLightbox(providers: providers, initialIndex: index),
              );
            },
            child: Image(
              image: providers[index],
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          );
        },
      ),
    );
  }
}

class _GalleryLightbox extends StatefulWidget {
  const _GalleryLightbox({required this.providers, required this.initialIndex});

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
            certified ? l10n.exploreDiveStar(stars) : l10n.exploreStarPending,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
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
    required this.product,
    required this.quote,
    required this.recommended,
    required this.lightest,
    required this.openRooms,
    required this.onBook,
  });

  final DiveShop shop;
  final ShopProduct product;
  final TourPriceQuote quote;
  final bool recommended;
  final bool lightest;
  final int openRooms;
  final ValueChanged<String> onBook;

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
                    onPressed: () => onBook(''),
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
                  onPressed: onPressed,
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
