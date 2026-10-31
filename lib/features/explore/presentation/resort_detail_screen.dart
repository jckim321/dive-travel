import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/shop_product_reader.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/ccard_product_frame.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/features/explore/presentation/diver_reviews_section.dart';
import 'package:dive_travel_app/features/explore/presentation/product_offer_box.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/tour_checkout_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

const _kTransportLabels = <String, String>{
  'pickup': '리조트 픽업',
  'taxi': '택시',
  'bus': '버스',
  'rental_car': '렌터카',
  'boat': '보트',
};

class ResortDetailScreen extends StatefulWidget {
  const ResortDetailScreen({
    super.key,
    required this.hullId,
    this.asSheet = false,
  });

  final String hullId;
  final bool asSheet;

  @override
  State<ResortDetailScreen> createState() => _ResortDetailScreenState();
}

class _ResortDetailScreenState extends State<ResortDetailScreen> {
  DiverStore? _store;
  var _listening = false;
  int _contentSig = 0;
  var _visitStarted = false;
  var _visitReady = false;
  DateTime? _visitAt;

  DiverStore _storeRead(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DiverStoreScope>();
    assert(scope != null, 'DiverStoreScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
  }

  static int _detailSignature(
    DiveShop hull,
    ShopLiveStats? live,
    List<ShopProduct> products,
  ) {
    return Object.hashAll([
      hull.name,
      hull.country,
      hull.intro,
      hull.address,
      hull.location,
      live?.name,
      live?.country,
      live?.location,
      hull.coverUrl,
      hull.galleryUrls.join('|'),
      hull.amenities.join('|'),
      hull.sites.join('|'),
      live?.mapUrl,
      live?.featureBlurb,
      live?.featureTags.join('|'),
      live?.checkIn,
      live?.checkOut,
      live?.businessHours,
      live?.operatingStatus,
      live?.intro,
      for (final route in live?.accessRoutes ?? const <AccessRoute>[])
        '${route.from}|${route.duration}|${route.cost}|${route.tips}',
      for (final spot in live?.nearbySpots ?? const <NearbySpot>[])
        '${spot.name}|${spot.distance}|${spot.blurb}',
      for (final p in products)
        Object.hash(
          p.id,
          p.name,
          p.consumerPrice,
          p.professionalPrice,
          p.blurb,
          p.schedule,
          p.meetingPoint,
          p.coverUrl,
          p.active,
          p.publishStatus,
          [
            for (final option in p.options)
              '${option.id}|${option.name}|${option.consumerPrice}|${option.professionalPrice}',
          ].join(';'),
        ),
    ]);
  }

  void _onStoreTick() {
    if (!mounted || _store == null) {
      return;
    }
    final store = _store!;
    final listings = store.listingsOnHull(widget.hullId);
    if (listings.isEmpty) {
      setState(() => _contentSig = -1);
      return;
    }
    final hull = listings.first;
    final live = store.liveStatsFor(hull.hullId);
    final products = _resortShelfProducts(live);
    final sig = _detailSignature(hull, live, products);
    if (sig != _contentSig) {
      setState(() => _contentSig = sig);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = _storeRead(context);
    _store = store;
    if (!_listening) {
      _listening = true;
      store.addListener(_onStoreTick);
      _beginVisit(store);
      final listings = store.listingsOnHull(widget.hullId);
      if (listings.isNotEmpty) {
        final hull = listings.first;
        final live = store.liveStatsFor(hull.hullId);
        _contentSig = _detailSignature(
          hull,
          live,
          _resortShelfProducts(live),
        );
      }
    }
  }

  void _beginVisit(DiverStore store) {
    if (_visitStarted) {
      return;
    }
    _visitStarted = true;
    final shopId = widget.hullId.split('--').first;
    if (shopId.isEmpty) {
      return;
    }
    unawaited(() async {
      final ok = await store.recordShopDay(
        shopId: shopId,
        now: DateTime.now(),
        visit: true,
      );
      _visitReady = ok;
      _visitAt = DateTime.now();
    }());
  }

  @override
  void dispose() {
    final store = _store;
    final at = _visitAt;
    if (_visitReady && store != null && at != null) {
      final shopId = widget.hullId.split('--').first;
      final seconds = DateTime.now().difference(at).inSeconds;
      unawaited(
        store.recordShopDwell(
          shopId: shopId,
          now: DateTime.now(),
          seconds: seconds,
        ),
      );
    }
    if (_listening) {
      _store?.removeListener(_onStoreTick);
      _listening = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = _store ?? _storeRead(context);
    final listings = store.listingsOnHull(widget.hullId);
    if (listings.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.asSheet,
          actions: [
            if (widget.asSheet)
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
    final live = store.liveStatsFor(hull.hullId);
    final theme = Theme.of(context);
    final owned = store.stats.ownedShopId ?? AppConstants.defaultPartnerShopId;
    final canEdit =
        store.stats.isAdmin ||
        (store.stats.isBusiness && owned == hull.hullId);
    final products = _resortShelfProducts(live);
    final rooms = SameBoatBoard.offers(products).length;
    final hero = _heroProduct(products);
    final ratingValue = hero != null && hero.guestReviewCount > 0
        ? hero.guestRating
        : hull.rating;
    final ratingCount = hero != null && hero.guestReviewCount > 0
        ? hero.guestReviewCount
        : hull.reviewCount;
    final mapUrl = live?.mapUrl ?? '';
    final accessRoutes = live?.accessRoutes ?? const <AccessRoute>[];
    final featureBlurb = live?.featureBlurb ?? '';
    final featureTags = live?.featureTags ?? const <String>[];
    final nearbySpots = live?.nearbySpots ?? const <NearbySpot>[];
    final checkIn = live?.checkIn ?? '';
    final checkOut = live?.checkOut ?? '';
    final businessHours = live?.businessHours ?? '';
    final amenityChips = <String>[
      ...hull.amenities,
      ...hull.sites,
    ];
    final showFeatures =
        featureBlurb.trim().isNotEmpty || featureTags.isNotEmpty;
    final showOps = checkIn.isNotEmpty ||
        checkOut.isNotEmpty ||
        businessHours.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(hull.name),
        automaticallyImplyLeading: !widget.asSheet,
        leading: widget.asSheet
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
        key: Key('resort-detail-${widget.hullId}'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RepaintBoundary(
              child: _ResortPhotoGallery(
                shop: hull,
                productId: hero?.id,
                photoUrls: _heroPhotoUrls(products),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('resort-book'),
                onPressed: () => _openRegularProducts(
                  context,
                  store: store,
                  hull: hull,
                  products: products,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.ocean,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text(
                  '이 리조트 예약하러 가기',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hull.showsDiveStarBadge)
                  _StarBadge(
                    stars: hull.stars,
                    certified: hull.isDiveStarCertified,
                    expired: hull.isDiveStarExpired,
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
            if (hull.intro.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.exploreResortIntro,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(hull.intro, style: theme.textTheme.bodyLarge),
            ],
            _MapCard(
              address: hull.address,
              location: hull.location,
              mapUrl: mapUrl,
            ),
            if (accessRoutes.isNotEmpty) ...[
              const SizedBox(height: 20),
              _ResortInfoSection(
                title: l10n.exploreAccessRoutes,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < accessRoutes.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _AccessRouteTile(route: accessRoutes[i]),
                    ],
                  ],
                ),
              ),
            ],
            if (showFeatures) ...[
              const SizedBox(height: 20),
              _ResortInfoSection(
                title: l10n.exploreResortFeatures,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (featureBlurb.trim().isNotEmpty)
                      Text(
                        featureBlurb,
                        style: theme.textTheme.bodyLarge,
                      ),
                    if (featureTags.isNotEmpty) ...[
                      if (featureBlurb.trim().isNotEmpty)
                        const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in featureTags)
                            Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(tag),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (amenityChips.isNotEmpty) ...[
              const SizedBox(height: 20),
              _ResortInfoSection(
                title: l10n.exploreResortTraits,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in amenityChips)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.check_rounded, size: 16),
                        label: Text(item),
                      ),
                  ],
                ),
              ),
            ],
            if (nearbySpots.isNotEmpty) ...[
              const SizedBox(height: 20),
              _ResortInfoSection(
                title: l10n.exploreNearbySpots,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < nearbySpots.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _NearbySpotTile(spot: nearbySpots[i]),
                    ],
                  ],
                ),
              ),
            ],
            if (showOps) ...[
              const SizedBox(height: 20),
              _ResortInfoSection(
                title: l10n.exploreOpsHours,
                child: Column(
                  children: [
                    if (checkIn.isNotEmpty)
                      _OpsRow(
                        label: l10n.exploreCheckInLabel,
                        value: checkIn,
                      ),
                    if (checkOut.isNotEmpty)
                      _OpsRow(
                        label: l10n.exploreCheckOutLabel,
                        value: checkOut,
                      ),
                    if (businessHours.isNotEmpty)
                      _OpsRow(
                        label: l10n.exploreBusinessHoursLabel,
                        value: businessHours,
                      ),
                  ],
                ),
              ),
            ],
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
            RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _productBoxes(
                  context: context,
                  store: store,
                  hull: hull,
                  catalogListings: listings,
                  products: products,
                ),
              ),
            ),
            const SizedBox(height: 28),
            RepaintBoundary(
              child: DiverReviewsSection(
                shopId: hull.hullId,
                rating: ratingValue,
                reviewCount: ratingCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResortInfoSection extends StatelessWidget {
  const _ResortInfoSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AccessRouteTile extends StatelessWidget {
  const _AccessRouteTile({required this.route});

  final AccessRoute route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transport = [
      for (final code in route.transport)
        if (_kTransportLabels[code] != null) _kTransportLabels[code]!,
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6EBEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (route.from.isNotEmpty)
              Text(
                route.from,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (transport.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                transport.join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
            ],
            if (route.duration.isNotEmpty || route.cost.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (route.duration.isNotEmpty) route.duration,
                  if (route.cost.isNotEmpty) route.cost,
                ].join(' · '),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (route.tips.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(route.tips, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _NearbySpotTile extends StatelessWidget {
  const _NearbySpotTile({required this.spot});

  final NearbySpot spot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.place_outlined, size: 18, color: AppTheme.ocean),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (spot.name.isNotEmpty) spot.name,
                  if (spot.distance.isNotEmpty) spot.distance,
                ].join(' · '),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (spot.blurb.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  spot.blurb,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OpsRow extends StatelessWidget {
  const _OpsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
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
      ProductOfferBox(
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
          unawaited(
            store.recordShopDay(
              shopId: hull.hullId,
              now: DateTime.now(),
              productView: true,
            ),
          );
          showTourCheckoutSheet(
            context: context,
            shop: shop,
            quote: store.quoteFor(shop),
            product: _paymentProduct(store, hull.hullId, product),
            presetOptionId: presetOptionId,
          );
        },
      ),
    );
    out.add(const SizedBox(height: 12));
  }
  return out;
}

List<ShopProduct> _resortShelfProducts(ShopLiveStats? live) => [
      for (final product in live?.readerProducts ?? const <ShopProduct>[])
        if (isCustomerShelfProduct(product)) product,
    ];

void _openRegularProducts(
  BuildContext context, {
  required DiverStore store,
  required DiveShop hull,
  required List<ShopProduct> products,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => _RegularProductPicker(
        store: store,
        hull: hull,
        products: [
          for (final product in products)
            if (isCustomerShelfProduct(product)) product,
        ],
      ),
    ),
  );
}

class _RegularProductPicker extends StatelessWidget {
  const _RegularProductPicker({
    required this.store,
    required this.hull,
    required this.products,
  });

  final DiverStore store;
  final DiveShop hull;
  final List<ShopProduct> products;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('resort-book-products'),
      appBar: AppBar(title: Text(hull.name)),
      body: products.isEmpty
          ? const Center(child: Text('예약할 일반 상품이 없습니다.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = products[index];
                final price = NumberFormat('#,###', 'en_US')
                    .format(product.consumerPrice);
                return Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE4E8EE)),
                  ),
                  child: ListTile(
                    key: Key('resort-book-product-${product.id}'),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      product.durationLabel.trim().isEmpty
                          ? '₩$price'
                          : '${product.durationLabel} · ₩$price',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final card = store.listingCardForProduct(hull, product);
                      showTourCheckoutSheet(
                        context: context,
                        shop: card,
                        quote: store.quoteFor(card),
                        product: _paymentProduct(store, hull.hullId, product),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

/// Checkout keeps the shop-array product. The detail list may be a document.
ShopProduct _paymentProduct(
  DiverStore store,
  String shopId,
  ShopProduct shown,
) {
  for (final item in store.liveStatsFor(shopId)?.products ?? const <ShopProduct>[]) {
    if (item.id == shown.id) {
      return item;
    }
  }
  return shown;
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
  List<ImageProvider>? _cachedSlides;
  String _slidesKey = '';

  List<ImageProvider> _slides() {
    final store = _galleryStore(context);
    final productId = widget.productId;
    final key = [
      widget.shop.hullId,
      productId ?? '',
      widget.photoUrls.join('|'),
      widget.shop.displayGallery.join('|'),
    ].join('::');
    if (_cachedSlides != null && _slidesKey == key) {
      return _cachedSlides!;
    }
    final slides = <ImageProvider>[];
    if (widget.photoUrls.isNotEmpty && productId != null) {
      final frames = store.productFramesFor(
        '${widget.shop.hullId}--$productId',
      );
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
    }
    if (slides.isEmpty) {
      final local = store.galleryBytesFor(widget.shop.hullId);
      if (local.isNotEmpty) {
        slides.addAll([for (final bytes in local) MemoryImage(bytes)]);
      }
    }
    if (slides.isEmpty) {
      for (final url in widget.shop.displayGallery) {
        if (url.isNotEmpty && !url.startsWith('memory://')) {
          slides.add(NetworkImage(url));
        }
      }
    }
    if (slides.isEmpty) {
      final cover = store.coverBytesFor(widget.shop.id) ??
          store.coverBytesFor(widget.shop.hullId);
      if (cover != null && cover.isNotEmpty) {
        slides.add(MemoryImage(cover));
      }
    }
    _slidesKey = key;
    _cachedSlides = slides;
    return slides;
  }

  DiverStore _galleryStore(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DiverStoreScope>();
    assert(scope != null, 'DiverStoreScope가 위젯 트리에 없습니다.');
    return scope!.notifier!;
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
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (MediaQuery.sizeOf(context).width * dpr).round().clamp(
          600,
          1600,
        );
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
                    image: ResizeImage(slides[i], width: cacheW),
                    fit: BoxFit.cover,
                    // medium decode: lighter scroll paint on iOS Safari.
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
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
  const _StarBadge({
    required this.stars,
    required this.certified,
    this.expired = false,
  });

  final int stars;
  final bool certified;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = expired
        ? l10n.exploreDiveStarRenewalNeeded
        : l10n.exploreDiveStarCertified;
    final filled = expired ? 0 : stars.clamp(0, 3);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: certified || expired
            ? AppTheme.goldSoft
            : const Color(0xFFE8EEF2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filled > 0) ...[
            for (var i = 0; i < filled; i++)
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: AppTheme.gold,
              ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
    if (!expired) {
      return badge;
    }
    return Opacity(opacity: 0.45, child: badge);
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.address,
    required this.location,
    required this.mapUrl,
  });

  final String address;
  final String location;
  final String mapUrl;

  Uri? get _launchUri {
    final trimmed = mapUrl.trim();
    if (trimmed.isNotEmpty && isShopMapUrlValid(trimmed)) {
      return Uri.tryParse(trimmed);
    }
    final query =
        address.trim().isNotEmpty ? address.trim() : location.trim();
    if (query.isEmpty) {
      return null;
    }
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(query)}',
    );
  }

  Future<void> _openMap(BuildContext context) async {
    final uri = _launchUri;
    if (uri == null) {
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).exploreOpenMap)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = address.trim().isNotEmpty ? address.trim() : location.trim();
    final launchUri = _launchUri;
    if (label.isEmpty && launchUri == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.oceanDeep,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          height: launchUri == null ? 120 : 168,
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
                    if (label.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, color: AppTheme.gold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (launchUri != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          key: const Key('resort-open-map'),
                          onPressed: () => _openMap(context),
                          style: FilledButton.styleFrom(
                            foregroundColor: AppTheme.oceanDeep,
                            backgroundColor: const Color(0xFFF4EBD3),
                          ),
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: Text(l10n.exploreOpenMap),
                        ),
                      ),
                    ],
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
