import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/exploration_map.dart';
import 'package:dive_travel_app/core/widgets/travel_title_bar.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
import 'package:dive_travel_app/features/home/presentation/for_you_section.dart';
import 'package:dive_travel_app/features/home/presentation/home_stay_card.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  void _openShop(BuildContext context, DiveShop shop) {
    openResortDetail(context, shop.hullId);
  }

  void _openCaptainForm(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const TravelProductRegistrationScreen(
          creatorMode: true,
        ),
      ),
    );
  }

  List<Widget> _homeShelves(
    BuildContext context, {
    required AppLocalizations l10n,
    required ThemeData theme,
    required bool canCaptain,
    required List<DiveShop> diveStarShops,
    required List<DiveShop> lastCallShops,
    required List<DiveShop> hotShops,
    required List<DiveShop> curatedShops,
    required List<DiveShop> plannedShops,
  }) {
    final shelves = <Widget>[
      if (diveStarShops.isNotEmpty)
        HomeDiscoverySection(
          key: const Key('home-section-dive-star'),
          title: l10n.homeDiveStarTitle,
          shops: diveStarShops,
          onOpen: (shop) => _openShop(context, shop),
        ),
      if (lastCallShops.isNotEmpty)
        HomeDiscoverySection(
          key: const Key('home-section-same-boat'),
          title: l10n.homeNextDepartures,
          shops: lastCallShops,
          onOpen: (shop) => _openShop(context, shop),
        ),
      if (hotShops.isNotEmpty)
        HomeDiscoverySection(
          key: const Key('home-section-hot'),
          title: l10n.homePopularTitle,
          shops: hotShops,
          onOpen: (shop) => _openShop(context, shop),
        ),
      if (curatedShops.isNotEmpty)
        HomeDiscoverySection(
          key: const Key('home-section-curated'),
          title: l10n.homeCuratedTitle,
          shops: curatedShops,
          onOpen: (shop) => _openShop(context, shop),
        ),
      if (plannedShops.isNotEmpty || canCaptain)
        HomeDiscoverySection(
          key: const Key('home-section-captain'),
          title: l10n.homeFavoritesTitle,
          subtitle: l10n.homeDiverPlannedSubtitle,
          shops: plannedShops,
          showWhenEmpty: canCaptain,
          belowSubtitle: canCaptain
              ? null
              : Text(
                  l10n.homeCaptainNeedsGold,
                  key: const Key('home-captain-needs-gold'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                    fontSize: 12,
                  ),
                ),
          headerAction: canCaptain
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    key: const Key('home-become-captain'),
                    onPressed: () => _openCaptainForm(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.ocean,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(l10n.homeBecomeCaptain),
                  ),
                )
              : null,
          onOpen: (shop) => _openShop(context, shop),
        ),
    ];
    final spaced = <Widget>[];
    for (final shelf in shelves) {
      if (spaced.isNotEmpty) {
        spaced.add(const SizedBox(height: 24));
      }
      spaced.add(shelf);
    }
    return spaced;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = lookupAppLocalizations(const Locale('en'));
    final store = DiverStoreScope.of(context);
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
    final canCaptain =
        store.stats.memberGrade.rank >= MemberGrade.gold.rank;

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
                ..._homeShelves(
                  context,
                  l10n: l10n,
                  theme: theme,
                  canCaptain: canCaptain,
                  diveStarShops: diveStarShops,
                  lastCallShops: lastCallShops,
                  hotShops: hotShops,
                  curatedShops: curatedShops,
                  plannedShops: plannedShops,
                ),
                const ForYouSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
