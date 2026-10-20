import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/exploration_map.dart';
import 'package:dive_travel_app/core/widgets/travel_title_bar.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
import 'package:dive_travel_app/features/home/presentation/for_you_section.dart';
import 'package:dive_travel_app/features/home/presentation/home_stay_card.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openShop(BuildContext context, DiveShop shop) {
    openResortDetail(context, shop.hullId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = lookupAppLocalizations(const Locale('en'));
    final store = DiverStoreScope.of(context);
    final stats = store.stats;
    final theme = Theme.of(context);
    final explored = store.regions.length;
    final diveStarShops = store.resortsFeaturedAs(ProductListingKind.diveStar);
    final claimed = <String>{
      for (final shop in diveStarShops) shop.hullId,
    };
    final plannedShops = store.resortsFeaturedAs(
      ProductListingKind.diverPlanned,
      excludeHullIds: claimed,
    );
    claimed.addAll(plannedShops.map((shop) => shop.hullId));
    final hotShops = store.resortsFeaturedAs(
      ProductListingKind.hotSpot,
      excludeHullIds: claimed,
    );
    claimed.addAll(hotShops.map((shop) => shop.hullId));
    final lastCallShops = store.resortsFeaturedAs(
      ProductListingKind.nextDeparture,
      excludeHullIds: claimed,
    );
    claimed.addAll(lastCallShops.map((shop) => shop.hullId));
    final curatedShops = store.resortsFeaturedAs(
      ProductListingKind.curated,
      excludeHullIds: claimed,
    );

    return Scaffold(
      body: ListView(
        key: const Key('home-scroll'),
        padding: EdgeInsets.zero,
        children: [
          const TravelPosterHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (store.loading) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 16),
                ],
                if (stats.isVerifiedPro) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: const Icon(
                        Icons.verified_outlined,
                        size: 16,
                        color: AppTheme.navy,
                      ),
                      label: Text(l10n.profileProBadge),
                      backgroundColor: AppTheme.goldSoft,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ExplorationMap(
                  regions: store.regions,
                  titleEnglish: english.homeMapTitle,
                  titleLocalized: l10n.homeMapTitle,
                  exploredEnglish: english.homeMapExplored(explored),
                  exploredLocalized: l10n.homeMapExplored(explored),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.homeMapTip,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                HomeDiscoverySection(
                  title: l10n.homeDiveStarTitle,
                  shops: diveStarShops,
                  onOpen: (shop) => _openShop(context, shop),
                ),
                const SizedBox(height: 24),
                HomeDiscoverySection(
                  title: l10n.homeFavoritesTitle,
                  shops: plannedShops,
                  emptyText: l10n.homeShelfEmpty,
                  onOpen: (shop) => _openShop(context, shop),
                ),
                const SizedBox(height: 24),
                HomeDiscoverySection(
                  title: l10n.homePopularTitle,
                  shops: hotShops,
                  emptyText: l10n.homeShelfEmpty,
                  onOpen: (shop) => _openShop(context, shop),
                ),
                const SizedBox(height: 24),
                HomeDiscoverySection(
                  title: l10n.homeNextDepartures,
                  shops: lastCallShops,
                  emptyText: l10n.homeShelfEmpty,
                  onOpen: (shop) => _openShop(context, shop),
                ),
                const SizedBox(height: 24),
                HomeDiscoverySection(
                  title: l10n.homeCuratedTitle,
                  shops: curatedShops,
                  emptyText: l10n.homeShelfEmpty,
                  onOpen: (shop) => _openShop(context, shop),
                ),
                const SizedBox(height: 32),
                ForYouSection(
                  onOpenShop: (shop) => _openShop(context, shop),
                  onOpenProfile: () => MainShell.goToTab(context, 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
