import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/features/bookings/presentation/my_bookings_section.dart';
import 'package:dive_travel_app/features/explore/presentation/continent_atlas_rail.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_place_filters.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_region_groups.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_region_screen.dart';
import 'package:dive_travel_app/features/explore/presentation/explore_shop_query.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String _region = TravelRegionId.all;
  String? _menuRegion;
  String? _countryId;
  String? _countryLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(DiverStoreScope.of(context).ensureShopStatsLoaded());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openMyBookings() {
    MainShell.goToTab(context, 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = MyBookingsSection.sectionKey.currentContext;
        if (target == null) {
          return;
        }
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final needle = _search.text.trim().toLowerCase();
        // One card per resort (hull). Live public products replace catalog
        // shells; never expand every SKU into duplicate tiles.
        final listed = [
          for (final shop in store.shops)
            if (_showsOnExplore(shop, store)) shop,
        ];
        final countryIdsWithProducts = <String>{
          for (final shop in listed)
            if (travelCountryForShop(shop) case final country?) country.id,
        };
        final shops = DiveShopCatalog.hulls([
          for (final shop in listed)
            if (exploreShopMatches(
              shop: shop,
              regionId: _region,
              countryId: _countryId,
              needle: needle,
            ))
              shop,
        ])
          ..sort(
            (a, b) => store
                .latestPublicProductAt(b.hullId)
                .compareTo(store.latestPublicProductAt(a.hullId)),
          );
        final groups = _countryLabel == null
            ? exploreRegionGroups(
                shops,
                otherLabel: l10n.exploreOtherRegion,
                continentLabel: (id) => travelRegionLabel(l10n, id),
              )
            : shops.isEmpty
                ? const <ExploreRegionGroup>[]
                : [
                    ExploreRegionGroup(
                      id: _countryId!,
                      title: _countryLabel!,
                      shops: shops,
                    ),
                  ];
        final nextTrip = TravelStyleAnalyzer.nextTrip(store.bookings);
        final daysUntil = nextTrip == null
            ? null
            : TravelStyleAnalyzer.daysUntil(nextTrip.scheduledFor);

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                ContinentAtlasRail(
                  selectedId: _region,
                  menuId: _menuRegion,
                  onSelected: (id) => setState(() {
                    _region = id;
                    _countryId = null;
                    _countryLabel = null;
                    _menuRegion = null;
                  }),
                  onMenu: (id) => setState(() {
                    _menuRegion = _menuRegion == id ? null : id;
                  }),
                ),
                if (_menuRegion != null)
                  ExploreFeaturedMenu(
                    regionId: _menuRegion!,
                    selectedCountryId: _countryId,
                    selectedLabel: _countryLabel,
                    countryIdsWithProducts: countryIdsWithProducts,
                    onPlace: (place) => setState(() {
                      final same = _countryId == place.countryId &&
                          _countryLabel == place.label;
                      if (same) {
                        _countryId = null;
                        _countryLabel = null;
                      } else {
                        _countryId = place.countryId;
                        _countryLabel = place.label;
                        _region = place.regionId;
                      }
                    }),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: TextField(
                    key: const Key('explore-search'),
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.exploreSearchHint,
                      prefixIcon: const Icon(Icons.search, size: 22),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close, size: 20),
                            ),
                    ),
                  ),
                ),
                if (nextTrip != null && daysUntil != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: DepartureTripBanner(
                      days: daysUntil,
                      shopName: nextTrip.shopName,
                      onTap: _openMyBookings,
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: store.refreshShopStats,
                    child: shops.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.4,
                                child: Center(
                                  child: Text(
                                    _countryLabel != null
                                        ? l10n.exploreCountryEmpty
                                        : l10n.exploreNoResults,
                                    key: _countryLabel != null
                                        ? const Key('explore-country-empty')
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            key: const Key('explore-shop-list'),
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                            children: [
                              for (var i = 0; i < groups.length; i++) ...[
                                _ExploreRegionRow(group: groups[i]),
                                if (i != groups.length - 1)
                                  const SizedBox(height: 22),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExploreRegionRow extends StatelessWidget {
  const _ExploreRegionRow({required this.group});

  final ExploreRegionGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cardWidth = exploreCardWidth(context);
    final cardHeight = ListingCover.travelCardExtent(context);

    return Column(
      key: Key('explore-region-row-${group.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                group.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              key: Key('explore-region-more-${group.id}'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ExploreRegionScreen(
                      title: group.title,
                      shops: group.shops,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.navy,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.exploreSeeMore),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: cardHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < group.shops.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  SizedBox(
                    width: cardWidth,
                    child: exploreStayCard(context, group.shops[index]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

bool _showsOnExplore(DiveShop shop, DiverStore store) {
  final live = store.liveStatsFor(shop.hullId);
  final hasPublic =
      live?.products.any((product) => product.isListedPublicly) ?? false;
  if (hasPublic) {
    return true;
  }
  // Once any live product exists, hide empty catalog shells so new
  // registrations aren't buried under seed resorts on PC/web.
  return !store.hasAnyPublicProduct;
}
