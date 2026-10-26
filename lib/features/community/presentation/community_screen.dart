import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/booking_quote.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/models/same_boat_board.dart';
import 'package:dive_travel_app/core/models/same_boat_search.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:intl/intl.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/features/auth/presentation/auth_sign_in_sheet.dart';
import 'package:dive_travel_app/features/community/presentation/same_boat_search_bar.dart';
import 'package:dive_travel_app/features/explore/presentation/tour_checkout_sheet.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class _DesignPreview {
  const _DesignPreview({required this.offer, required this.shopName});

  final SameBoatOffer offer;
  final String shopName;
}

List<_DesignPreview> _designPreviews(DateTime now) {
  final soon = now.add(const Duration(days: 4));
  final later = now.add(const Duration(days: 18));
  final earlyDeparture = now.add(const Duration(days: 3));
  final lateFlag = now.add(const Duration(days: 12));
  return [
    _DesignPreview(
      shopName: '블루홀 다이브',
      offer: SameBoatOffer(
        product: ShopProduct(
          id: 'preview-blue-hole',
          shopId: 'preview-blue-hole',
          name: '블루홀 라이브어보드',
          consumerPrice: 890000,
          professionalPrice: 790000,
          blurb: '팀이 잡힌 3박 4일 일정에 캐빈 한 자리가 남았습니다.',
          options: [
            ShopProductOption(
              id: 'deluxe',
              name: '디럭스 캐빈',
              description: '2인실, 전용 욕실.',
              kind: ProductOptionKind.individual,
              openEmptySeats: true,
              capacity: 8,
              bookedSeats: 3,
              flagHolds: [
                SeatHold(
                  seats: 2,
                  expiresAt: now.add(const Duration(hours: 20)),
                ),
              ],
              departureStart: later,
              flagClosesAt: soon,
            ),
          ],
        ),
        option: ShopProductOption(
          id: 'deluxe',
          name: '디럭스 캐빈',
          description: '2인실, 전용 욕실.',
          kind: ProductOptionKind.individual,
          openEmptySeats: true,
          capacity: 8,
          bookedSeats: 3,
          flagHolds: [
            SeatHold(
              seats: 2,
              expiresAt: now.add(const Duration(hours: 20)),
            ),
          ],
          departureStart: later,
          flagClosesAt: soon,
        ),
      ),
    ),
    _DesignPreview(
      shopName: '케라마 보트',
      offer: SameBoatOffer(
        product: ShopProduct(
          id: 'preview-kerama',
          shopId: 'preview-kerama',
          name: '케라마 당일 보트',
          consumerPrice: 180000,
          professionalPrice: 150000,
          openEmptySeats: true,
          capacity: 6,
          bookedSeats: 4,
          departureStart: later,
          flagClosesAt: soon,
        ),
      ),
    ),
    _DesignPreview(
      shopName: '팔라우 어젠다',
      offer: SameBoatOffer(
        product: ShopProduct(
          id: 'preview-palau',
          shopId: 'preview-palau',
          name: '저먼 채널 데이 트립',
          consumerPrice: 240000,
          professionalPrice: 210000,
          detail: '오전 출항, 오후 귀항.',
          openEmptySeats: true,
          capacity: 5,
          bookedSeats: 1,
          departureStart: earlyDeparture,
          flagClosesAt: lateFlag,
        ),
      ),
    ),
  ];
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  var _search = const SameBoatSearch();
  var _searchOpen = true;

  bool _onBoardScroll(ScrollNotification notice) {
    if (notice.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notice.metrics.pixels <= 8) {
      if (!_searchOpen) {
        setState(() => _searchOpen = true);
      }
      return false;
    }
    if (notice is UserScrollNotification &&
        notice.direction == ScrollDirection.reverse &&
        notice.metrics.pixels > 48 &&
        _searchOpen) {
      setState(() => _searchOpen = false);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final store = DiverStoreScope.of(context);
      unawaited(store.ensureShopStatsLoaded());
      unawaited(store.ensureCommunityPostsLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = DateTime.now();
        final all = store.sameBoatOffers(SameBoatFilter.all, now: now);
        final offers = _search.apply(
          all,
          now: now,
          priceOf: _perPersonPrice,
          placeOf: (offer) => _placeFor(store, offer),
        );
        final results = store.sameBoatResults(now: now);
        final lastCallCount = store
            .sameBoatOffers(SameBoatFilter.lastCall, now: now)
            .length;
        final openSeats = all.fold<int>(
          0,
          (sum, offer) => sum + offer.remainingSeatsAt(now),
        );
        final regions = _regionChoices(all, store);

        return Scaffold(
          backgroundColor: AppTheme.canvas,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  store.refreshShopStats(),
                  store.refreshCommunityPosts(),
                ]);
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: _onBoardScroll,
                child: CustomScrollView(
                  key: const Key('tide-board'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TideHeader(
                              openSeats: openSeats,
                              departureCount: all.length,
                              lastCallCount: lastCallCount,
                            ),
                            if (lastCallCount > 0) ...[
                              const SizedBox(height: 14),
                              _UrgentStrip(
                                count: lastCallCount,
                                onTap: () => setState(() {
                                  _search = _search.copyWith(lastCall: true);
                                  _searchOpen = true;
                                }),
                              ),
                            ],
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: SameBoatSearchSliver(
                        height: _searchOpen ? 112 : 48,
                        child: SameBoatSearchBar(
                          search: _search,
                          expanded: _searchOpen,
                          resultCount: offers.length,
                          regions: regions,
                          countFor: (draft) => draft
                              .apply(
                                all,
                                now: now,
                                priceOf: _perPersonPrice,
                                placeOf: (offer) => _placeFor(store, offer),
                              )
                              .length,
                          onChanged: (next) => setState(() => _search = next),
                          onExpand: () => setState(() => _searchOpen = true),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            l10n.communityBoardList,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.communityBoardListHint,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          if (openSeats < 1) ...[
                            Text(
                              l10n.communityDesignPreview,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            for (final entry in _designPreviews(now)) ...[
                              _SeatCard(
                                offer: entry.offer,
                                shopName: entry.shopName,
                                onOpen: () =>
                                    _showDesignPreviewFlagHint(context),
                                onTake: () =>
                                    _showDesignPreviewFlagHint(context),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ] else if (offers.isEmpty)
                            AppCard(
                              child: Text(
                                l10n.communityEmpty,
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                          else
                            for (var i = 0; i < offers.length; i++) ...[
                              _SeatCard(
                                offer: offers[i],
                                shop: _shopForProduct(store, offers[i].product),
                                shopName: store.shopLabelFor(
                                  offers[i].product.shopId,
                                ),
                                onOpen: () => _openOfferDetail(
                                  context,
                                  offers[i],
                                  shop: _shopForProduct(
                                    store,
                                    offers[i].product,
                                  ),
                                  shopName: store.shopLabelFor(
                                    offers[i].product.shopId,
                                  ),
                                ),
                                onTake: () =>
                                    _takeSeat(context, store, offers[i]),
                              ),
                              const SizedBox(height: 12),
                            ],
                          if (results.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.communitySameBoatResults,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            for (final offer in results) ...[
                              _ResultCard(
                                offer: offer,
                                shopName: store.shopLabelFor(
                                  offer.product.shopId,
                                ),
                                now: now,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                          const SizedBox(height: 8),
                          Text(
                            l10n.communityHostMileage,
                            style: theme.textTheme.bodySmall,
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDesignPreviewFlagHint(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.communityDesignPreviewFlag)),
    );
  }

  Future<void> _takeSeat(
    BuildContext context,
    DiverStore store,
    SameBoatOffer offer,
  ) async {
    final l10n = AppLocalizations.of(context);
    final product = offer.product;
    final now = DateTime.now();
    final open = offer.remainingSeatsAt(now);
    if (open <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communitySeatsShort)),
      );
      return;
    }
    final until = ShopProduct.personalFlagUntil(now, offer.flagClosesAt);
    final deadline = DateFormat('yyyy.MM.dd HH:mm').format(until);
    final shortened = offer.flagClosesAt != null &&
        offer.flagClosesAt!.isBefore(now.add(const Duration(hours: 24)));
    final shop = _shopForProduct(store, product);
    final professional = shop != null && store.quoteFor(shop).isProfessional;
    final partySize = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return _FlagPlantSheet(
          offer: offer,
          shop: shop,
          shopName: store.shopLabelFor(product.shopId),
          open: open,
          deadline: deadline,
          shortened: shortened,
          totalFor: (seats) => BookingQuote.compute(
            product: product,
            professional: professional,
            divers: seats,
            nondivers: 0,
            children: 0,
            infants: 0,
            bookPackage: offer.optionId.isEmpty,
            selectedOptionIds:
                offer.optionId.isEmpty ? const {} : {offer.optionId},
          ).total,
        );
      },
    );
    if (partySize == null || partySize <= 0 || !context.mounted) {
      return;
    }
    await _plantThenPay(context, store, offer, partySize);
  }

  Future<void> _openOfferDetail(
    BuildContext context,
    SameBoatOffer offer, {
    DiveShop? shop,
    String shopName = '',
  }) async {
    final store = DiverStoreScope.of(context);
    final now = DateTime.now();
    final open = offer.remainingSeatsAt(now);
    final product = offer.product;
    final resolvedShop = shop ?? _shopForProduct(store, product);
    final professional =
        resolvedShop != null && store.quoteFor(resolvedShop).isProfessional;
    final seats = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => _SameBoatDetailPage(
          offer: offer,
          shop: resolvedShop,
          shopName: shopName,
          open: open,
          totalFor: (count) => BookingQuote.compute(
            product: product,
            professional: professional,
            divers: count,
            nondivers: 0,
            children: 0,
            infants: 0,
            bookPackage: offer.optionId.isEmpty,
            selectedOptionIds:
                offer.optionId.isEmpty ? const {} : {offer.optionId},
          ).total,
        ),
      ),
    );
    if (seats == null || seats <= 0 || !context.mounted) {
      return;
    }
    await _plantThenPay(context, store, offer, seats);
  }

  Future<void> _plantThenPay(
    BuildContext context,
    DiverStore store,
    SameBoatOffer offer,
    int partySize,
  ) async {
    final l10n = AppLocalizations.of(context);
    final product = offer.product;
    if (!await ensureSignedIn(context)) {
      return;
    }
    if (!context.mounted || store.uid == null || store.uid!.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final until = ShopProduct.personalFlagUntil(now, offer.flagClosesAt);
    final shop = _shopForProduct(store, product);
    final professional = shop != null && store.quoteFor(shop).isProfessional;
    final lockedPrice = BookingQuote.compute(
      product: product,
      professional: professional,
      divers: partySize,
      nondivers: 0,
      children: 0,
      infants: 0,
      bookPackage: offer.optionId.isEmpty,
      selectedOptionIds: offer.optionId.isEmpty ? const {} : {offer.optionId},
    ).total;
    final planted = await store.plantSeatFlag(
      shopId: product.shopId,
      productId: product.id,
      partySize: partySize,
      optionId: offer.optionId,
      lockedPrice: lockedPrice,
    );
    if (!context.mounted) {
      return;
    }
    if (planted == SeatFlagPlant.taken) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityFlagTaken)),
      );
      return;
    }
    if (planted == SeatFlagPlant.tooLate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityFlagTooLate)),
      );
      return;
    }
    if (planted == SeatFlagPlant.limitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityFlagLimitReached)),
      );
      return;
    }
    if (planted == SeatFlagPlant.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communitySeatsShort)),
      );
      return;
    }
    if (planted == SeatFlagPlant.alreadyHeld) {
      final continuePay = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            content: Text(l10n.communityFlagContinuePayAsk),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.communityPlantFlagLater),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.communityFlagContinuePay),
              ),
            ],
          );
        },
      );
      if (continuePay != true || !context.mounted) {
        return;
      }
      await _openFlagCheckout(
        context,
        store,
        offer,
        useExistingHold: true,
      );
      return;
    }
    if (planted != SeatFlagPlant.planted || !context.mounted) {
      return;
    }
    await _openFlagCheckout(
      context,
      store,
      offer,
      lockedPartySize: partySize,
      flagPayBy: until,
    );
  }

  Future<void> _openFlagCheckout(
    BuildContext context,
    DiverStore store,
    SameBoatOffer offer, {
    bool useExistingHold = false,
    int? lockedPartySize,
    DateTime? flagPayBy,
  }) async {
    final product = _freshProduct(store, offer.product) ?? offer.product;
    final shop = _shopForProduct(store, product);
    if (shop == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).communitySeatsShort)),
        );
      }
      return;
    }
    var party = lockedPartySize ?? 1;
    var payBy = flagPayBy;
    if (useExistingHold) {
      final uid = store.uid ?? '';
      final now = DateTime.now();
      final optionId = offer.optionId;
      final hold = product.liveFlagFor(uid, now, optionId: optionId) ??
          product.liveFlagFor(uid, now);
      if (hold != null) {
        party = hold.seats;
        payBy = hold.expiresAt;
      }
    }
    await showTourCheckoutSheet(
      context: context,
      shop: shop,
      quote: store.quoteFor(shop),
      product: product,
      lockedOptionId: offer.optionId,
      fromFlag: true,
      lockedPartySize: party,
      flagPayBy: payBy,
    );
  }
}

SameBoatPlace _placeFor(DiverStore store, SameBoatOffer offer) {
  final shop = _shopForProduct(store, offer.product);
  return SameBoatPlace(
    continent: offer.product.continent,
    location: shop?.location ?? '',
    country: shop?.country ?? '',
    sites: [
      ...shop?.sites ?? const [],
      if (shop != null && shop.continent.isNotEmpty) shop.continent,
    ],
  );
}

List<SameBoatRegionChoice> _regionChoices(
  List<SameBoatOffer> offers,
  DiverStore store,
) {
  final choices = <SameBoatRegionChoice>[];
  for (final region in RegionCatalog.known) {
    var count = 0;
    for (final offer in offers) {
      if (placeHitsRegion(region, _placeFor(store, offer))) {
        count++;
      }
    }
    choices.add(
      SameBoatRegionChoice(
        id: region.id,
        name: region.name,
        count: count,
      ),
    );
  }
  choices.sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) {
      return byCount;
    }
    return a.name.compareTo(b.name);
  });
  return choices;
}

ShopProduct? _freshProduct(DiverStore store, ShopProduct product) {
  final hullId = product.shopId.split('--').first;
  final stats = store.liveStatsFor(hullId);
  if (stats == null) {
    return null;
  }
  for (final item in stats.products) {
    if (item.id == product.id) {
      return item;
    }
  }
  return null;
}

DiveShop? _shopForProduct(DiverStore store, ShopProduct product) {
  final hullId = product.shopId.split('--').first;
  final listings = store.listingsOnHull(hullId);
  DiveShop? hull;
  for (final shop in listings) {
    if (shop.listingProductId == product.id) {
      return store.listingCardForProduct(shop, product);
    }
    hull ??= shop;
  }
  if (hull == null) {
    for (final shop in store.shops) {
      if (shop.hullId == hullId) {
        hull = shop;
        break;
      }
    }
  }
  if (hull == null) {
    final stats = store.liveStatsFor(hullId);
    if (stats != null) {
      hull = DiveShop(
        id: hullId,
        name: (stats.name?.trim().isNotEmpty == true)
            ? stats.name!.trim()
            : store.shopLabelFor(hullId),
        location: stats.location?.trim() ?? '',
        country: stats.country?.trim() ?? '',
        continent: (stats.continent?.trim().isNotEmpty == true)
            ? stats.continent!.trim()
            : ContinentId.asia,
        sites: const [],
        productName: product.name,
        stars: stats.diveStar,
        rating: stats.avgOverall,
        reviewCount: stats.reviewCount,
        amenities: stats.amenities,
        consumerPrice: product.consumerPrice,
        professionalPrice: product.professionalPrice,
        coverUrl: product.coverUrl.isNotEmpty
            ? product.coverUrl
            : (stats.coverUrl ?? ''),
        galleryUrls: product.photoUrls.isNotEmpty
            ? product.photoUrls
            : stats.galleryUrls,
        intro: stats.intro ?? '',
        address: stats.address ?? '',
        blurb: product.blurb,
      );
    }
  }
  if (hull == null) {
    return null;
  }
  return store.listingCardForProduct(hull, product);
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.offer,
    required this.shopName,
    required this.now,
  });

  final SameBoatOffer offer;
  final String shopName;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final product = offer.product;
    final dayFmt = DateFormat('yyyy.MM.dd');
    final departure = offer.departureStart;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _resultReason(l10n, offer, now),
            key: Key('same-boat-result-${product.id}-${offer.optionId}'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
          if (offer.optionName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              offer.optionName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
            ),
          ],
          if (shopName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              shopName,
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            [
              if (departure != null) dayFmt.format(departure),
              '${offer.bookedSeats}/${offer.capacity}',
            ].join(' · '),
            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

String _resultReason(AppLocalizations l10n, SameBoatOffer offer, DateTime now) {
  final departure = offer.departureStart;
  if (departure != null) {
    final start = DateTime(departure.year, departure.month, departure.day);
    final today = DateTime(now.year, now.month, now.day);
    if (start.isBefore(today)) {
      return l10n.communitySameBoatResultDeparted;
    }
  }
  if (offer.capacity > 0 && offer.bookedSeats >= offer.capacity) {
    return l10n.communitySameBoatResultSoldOut;
  }
  return l10n.communitySameBoatResultClosed;
}

class _SeatCard extends StatelessWidget {
  const _SeatCard({
    required this.offer,
    required this.shopName,
    required this.onOpen,
    required this.onTake,
    this.shop,
  });

  final SameBoatOffer offer;
  final DiveShop? shop;
  final String shopName;
  final VoidCallback onOpen;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final product = offer.product;
    final now = DateTime.now();
    final paid = offer.bookedSeats;
    final held = offer.flaggedSeatsAt(now);
    final intro = _offerIntro(offer);
    final price = _perPersonPrice(offer);
    final capacity = offer.capacity;
    final paidSeats = capacity <= 0 ? 0 : paid.clamp(0, capacity).toInt();
    final heldSeats = capacity <= 0
        ? 0
        : held.clamp(0, capacity - paidSeats).toInt();
    final openSeats = capacity <= 0 ? 0 : capacity - paidSeats - heldSeats;
    final rating = product.guestRating;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EBEE)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: Key('same-boat-${product.id}-${offer.optionId}'),
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OfferPhoto(
                      product: product,
                      departure: offer.departureStart,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.navy,
                            ),
                          ),
                          if (offer.optionName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              offer.optionName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.navy,
                              ),
                            ),
                          ],
                          if (shopName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              shopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (shop != null && shop!.showsDiveStarBadge)
                                Text(
                                  shop!.isDiveStarCertified
                                      ? l10n.exploreDiveStarCertified
                                      : l10n.exploreDiveStarRenewalNeeded,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE07A1F),
                                  ),
                                ),
                              Text(
                                rating > 0
                                    ? '★ ${rating.toStringAsFixed(1)}'
                                    : l10n.reviewNoReviewsYet,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.navy,
                                ),
                              ),
                            ],
                          ),
                          if (intro.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              intro,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            _wonTilde(price),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (capacity > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (var i = 0; i < capacity; i++)
                      _SeatDot(
                        filled: i < paidSeats + heldSeats,
                        color: i < paidSeats
                            ? AppTheme.navy
                            : const Color(0xFFE07A1F),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                '${l10n.communitySeatPaid(paidSeats)} · ${l10n.communitySeatHeld(heldSeats)} · ${l10n.communitySeatOpen(openSeats)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: FilledButton(
                key: Key('same-boat-flag-${product.id}-${offer.optionId}'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE07A1F),
                  foregroundColor: Colors.white,
                ),
                onPressed: onTake,
                child: Text(l10n.communityFlagButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _seatMoney = NumberFormat('#,###', 'en_US');

String _wonTilde(int amount) => '₩${_seatMoney.format(amount)}~';

String _won(int amount) => '₩${_seatMoney.format(amount)}';

String? _firstPhoto(ShopProduct product) {
  for (final url in product.photoUrls) {
    final trimmed = url.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  final cover = product.coverUrl.trim();
  if (cover.isNotEmpty) {
    return cover;
  }
  return null;
}

String _offerIntro(SameBoatOffer offer) {
  if (offer.optionDescription.trim().isNotEmpty) {
    return offer.optionDescription.trim();
  }
  if (offer.product.blurb.trim().isNotEmpty) {
    return offer.product.blurb.trim();
  }
  return offer.product.detail.trim();
}

int _perPersonPrice(SameBoatOffer offer) {
  final option = offer.option;
  if (option != null && option.consumerPrice > 0) {
    return option.consumerPrice;
  }
  return offer.product.consumerPrice;
}

class _SeatDot extends StatelessWidget {
  const _SeatDot({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : Colors.transparent,
        border: Border.all(
          color: filled ? color : const Color(0xFFB7C0C8),
          width: 1.6,
        ),
      ),
    );
  }
}

class _OfferPhoto extends StatelessWidget {
  const _OfferPhoto({required this.product, required this.departure});

  final ShopProduct product;
  final DateTime? departure;

  @override
  Widget build(BuildContext context) {
    final url = _firstPhoto(product);
    final badge = departure == null ? '' : DateFormat('M.d').format(departure!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 108,
        height: 132,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _OfferImage(url: url),
            if (badge.isNotEmpty)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xF0052A4A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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

class _OfferImage extends StatelessWidget {
  const _OfferImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final photo = url;
    if (photo != null &&
        photo.isNotEmpty &&
        !photo.startsWith('memory://')) {
      return Image.network(
        photo,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _OfferFallback(),
      );
    }
    return const _OfferFallback();
  }
}

class _OfferFallback extends StatelessWidget {
  const _OfferFallback();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/test_dive_photo.png',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFE7EEF3)),
    );
  }
}

class _FlagDeadlineNote extends StatelessWidget {
  const _FlagDeadlineNote({
    required this.deadline,
    required this.shortened,
  });

  final String deadline;
  final bool shortened;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.communityFlagPayBy(deadline),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        if (shortened) ...[
          const SizedBox(height: 6),
          Text(l10n.communityFlagPayByShortened),
        ],
        const SizedBox(height: 12),
        Text(l10n.communityFlagHoldAsk(deadline)),
      ],
    );
  }
}

class _FlagPlantSheet extends StatefulWidget {
  const _FlagPlantSheet({
    required this.offer,
    required this.shopName,
    required this.open,
    required this.deadline,
    required this.shortened,
    required this.totalFor,
    this.shop,
  });

  final SameBoatOffer offer;
  final DiveShop? shop;
  final String shopName;
  final int open;
  final String deadline;
  final bool shortened;
  final int Function(int seats) totalFor;

  @override
  State<_FlagPlantSheet> createState() => _FlagPlantSheetState();
}

class _FlagPlantSheetState extends State<_FlagPlantSheet> {
  late final ValueNotifier<int> _party;

  @override
  void initState() {
    super.initState();
    _party = ValueNotifier(1);
    _party.addListener(_onParty);
  }

  void _onParty() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _party.removeListener(_onParty);
    _party.dispose();
    super.dispose();
  }

  int get _seats => _party.value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final total = widget.totalFor(_seats);
    return SingleChildScrollView(
      child: Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: Column(
        key: const Key('same-boat-flag-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _OfferPhoto(
                product: widget.offer.product,
                departure: widget.offer.departureStart,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.offer.product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.offer.optionName.isNotEmpty)
                      Text(widget.offer.optionName),
                    if (widget.shopName.isNotEmpty)
                      Text(
                        widget.shopName,
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _wonTilde(_perPersonPrice(widget.offer)),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.communityFlagPartyAsk(widget.open)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _seats <= 1 ? null : () => _party.value = _seats - 1,
                icon: const Icon(Icons.remove),
              ),
              Text(
                '$_seats',
                key: const Key('same-boat-party-count'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: _seats >= widget.open
                    ? null
                    : () => _party.value = _seats + 1,
                icon: const Icon(Icons.add),
              ),
              const Spacer(),
              Text(
                l10n.communityFlagPartyTotal(_won(total)),
                key: const Key('same-boat-party-total'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FlagDeadlineNote(
            deadline: widget.deadline,
            shortened: widget.shortened,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('same-boat-plant-pay'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE07A1F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, _seats),
            child: Text(l10n.communityFlagPlantAndPay),
          ),
          TextButton(
            key: const Key('same-boat-see-product'),
            onPressed: () async {
              final chosen = await Navigator.of(context).push<int>(
                MaterialPageRoute<int>(
                  builder: (_) => _SameBoatDetailPage(
                    offer: widget.offer,
                    shop: widget.shop,
                    shopName: widget.shopName,
                    open: widget.open,
                    totalFor: widget.totalFor,
                    party: _party,
                  ),
                ),
              );
              if (chosen != null && mounted) {
                Navigator.pop(context, chosen);
              }
            },
            child: Text(l10n.communitySeeProduct),
          ),
        ],
      ),
    ),
    );
  }
}

class _SameBoatDetailPage extends StatefulWidget {
  const _SameBoatDetailPage({
    required this.offer,
    required this.shopName,
    required this.open,
    required this.totalFor,
    this.shop,
    this.party,
  });

  final SameBoatOffer offer;
  final DiveShop? shop;
  final String shopName;
  final int open;
  final int Function(int seats) totalFor;

  /// Shared with the flag sheet when the detail is opened from it.
  final ValueNotifier<int>? party;

  @override
  State<_SameBoatDetailPage> createState() => _SameBoatDetailPageState();
}

class _SameBoatDetailPageState extends State<_SameBoatDetailPage> {
  late final ValueNotifier<int> _party;
  late final bool _ownsParty;
  DiverStore? _seatStore;
  var _seatWatchArmed = false;

  @override
  void initState() {
    super.initState();
    _ownsParty = widget.party == null;
    _party = widget.party ?? ValueNotifier(1);
    _party.addListener(_onParty);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = DiverStoreScope.of(context);
    _seatStore = store;
    if (_seatWatchArmed) {
      return;
    }
    _seatWatchArmed = true;
    final offer = widget.offer;
    final optionPrice = offer.option?.consumerPrice ?? 0;
    store.watchSeatView(
      shopId: offer.product.shopId,
      productId: offer.product.id,
      optionId: offer.optionId,
      region: widget.shop?.country ?? '',
      resort: widget.shop?.name.isNotEmpty == true
          ? widget.shop!.name
          : widget.shopName,
      departure: offer.departureStart,
      price: optionPrice > 0 ? optionPrice : offer.product.consumerPrice,
    );
  }

  void _onParty() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _seatStore?.flushSeatViews(leaving: true);
    _party.removeListener(_onParty);
    if (_ownsParty) _party.dispose();
    super.dispose();
  }

  void _setSeats(int next) {
    final cap = widget.open < 1 ? 1 : widget.open;
    _party.value = next.clamp(1, cap);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offer = widget.offer;
    final shop = widget.shop;
    final shopName = widget.shopName;
    final now = DateTime.now();
    final until = ShopProduct.personalFlagUntil(now, offer.flagClosesAt);
    final deadline = DateFormat('yyyy.MM.dd HH:mm').format(until);
    final shortened = offer.flagClosesAt != null &&
        offer.flagClosesAt!.isBefore(now.add(const Duration(hours: 24)));
    final intro = _offerIntro(offer);
    final seats = _party.value;
    final total = widget.totalFor(seats);
    return Scaffold(
      key: const Key('same-boat-detail'),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(offer.product.name),
        actions: [
          IconButton(
            key: const Key('same-boat-detail-close'),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _OfferImage(url: _firstPhoto(offer.product)),
            ),
          ),
          const SizedBox(height: 14),
          if (offer.optionName.isNotEmpty)
            Text(
              offer.optionName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          if (shopName.isNotEmpty)
            Text(shopName, style: const TextStyle(color: AppTheme.muted)),
          if (shop != null && shop.showsDiveStarBadge)
            Text(
              shop.isDiveStarCertified
                  ? l10n.exploreDiveStarCertified
                  : l10n.exploreDiveStarRenewalNeeded,
            ),
          const SizedBox(height: 8),
          Text(
            _wonTilde(_perPersonPrice(offer)),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (intro.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(intro),
          ],
          if (offer.product.detail.trim().isNotEmpty &&
              offer.product.detail.trim() != intro) ...[
            const SizedBox(height: 8),
            Text(offer.product.detail.trim()),
          ],
          const SizedBox(height: 16),
          _FlagDeadlineNote(deadline: deadline, shortened: shortened),
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 12,
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const Key('same-boat-detail-party-minus'),
                      onPressed: seats <= 1 ? null : () => _setSeats(seats - 1),
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '$seats',
                      key: const Key('same-boat-detail-party-count'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      key: const Key('same-boat-detail-party-plus'),
                      onPressed: widget.open < 1 || seats >= widget.open
                          ? null
                          : () => _setSeats(seats + 1),
                      icon: const Icon(Icons.add),
                    ),
                    const Spacer(),
                    Text(
                      l10n.communityFlagPartyTotal(_won(total)),
                      key: const Key('same-boat-detail-party-total'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('same-boat-detail-plant-pay'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE07A1F),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: widget.open < 1
                        ? null
                        : () => Navigator.pop(context, seats),
                    child: Text(l10n.communityFlagPlantAndPay),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TideHeader extends StatelessWidget {
  const _TideHeader({
    required this.openSeats,
    required this.departureCount,
    required this.lastCallCount,
  });

  final int openSeats;
  final int departureCount;
  final int lastCallCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.communityTideKicker,
          style: const TextStyle(
            color: AppTheme.ocean,
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.communityTideHeadline,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                height: 1.2,
                color: AppTheme.navy,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.communityTideBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                value: '$openSeats',
                label: l10n.communityStatOpenSeats,
                accent: AppTheme.ocean,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                value: '$departureCount',
                label: l10n.communityFilterAll,
                accent: AppTheme.navy,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStat(
                value: '$lastCallCount',
                label: l10n.communityFilterLastCall,
                accent: lastCallCount > 0
                    ? const Color(0xFFB42318)
                    : AppTheme.muted,
                warn: lastCallCount > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.accent,
    this.warn = false,
  });

  final String value;
  final String label;
  final Color accent;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: warn ? const Color(0xFFFBE9E7) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: warn ? const Color(0xFFF2C4BE) : const Color(0xFFE8EBEE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: accent,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentStrip extends StatelessWidget {
  const _UrgentStrip({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: const Color(0xFFFBE9E7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                color: Color(0xFFB42318),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.communityUrgentBanner(count),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB42318),
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFB42318)),
            ],
          ),
        ),
      ),
    );
  }
}

class SameBoatSearchSliver extends SliverPersistentHeaderDelegate {
  SameBoatSearchSliver({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AppTheme.canvas,
      child: SizedBox(height: height, child: child),
    );
  }

  @override
  bool shouldRebuild(SameBoatSearchSliver oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}


