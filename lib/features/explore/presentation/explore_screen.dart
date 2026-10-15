import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/travel_style.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/features/bookings/presentation/my_bookings_section.dart';
import 'package:dive_travel_app/features/explore/presentation/continent_atlas_rail.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
import 'package:dive_travel_app/features/home/presentation/home_stay_card.dart';
import 'package:dive_travel_app/features/shell/presentation/main_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String _continent = ContinentFilter.all;

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
        final isInstructor = store.stats.isInstructor;
        final needle = _search.text.trim().toLowerCase();
        // One card per resort (hull). Live public products replace catalog
        // shells; never expand every SKU into duplicate tiles.
        final shops = DiveShopCatalog.hulls([
          for (final shop in store.shops)
            if ((_continent == ContinentFilter.all ||
                    shop.continent == _continent) &&
                (needle.isEmpty || shop.searchBlob.contains(needle)) &&
                _showsOnExplore(shop, store))
              shop,
        ])
          ..sort(
            (a, b) => store
                .latestPublicProductAt(b.hullId)
                .compareTo(store.latestPublicProductAt(a.hullId)),
          );
        final nextTrip = TravelStyleAnalyzer.nextTrip(store.bookings);
        final daysUntil = nextTrip == null
            ? null
            : TravelStyleAnalyzer.daysUntil(nextTrip.scheduledFor);

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                const SizedBox(height: 12),
                ContinentAtlasRail(
                  selectedId: _continent,
                  onSelected: (id) => setState(() => _continent = id),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _PriceRoleBanner(isInstructor: isInstructor),
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
                  child: shops.isEmpty
                      ? Center(child: Text(l10n.exploreNoResults))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                          children: [
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: shops.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 18,
                                    crossAxisSpacing: 8,
                                    mainAxisExtent:
                                        ListingCover.cardExtent(context),
                                  ),
                              itemBuilder: (context, index) {
                                final shop = shops[index];
                                return HomeStayCard(
                                  key: Key('shop-card-${shop.id}'),
                                  shop: shop,
                                  quote: store.quoteFor(shop),
                                  onDetails: () => openResortDetail(
                                    context,
                                    shop.hullId,
                                  ),
                                );
                              },
                            ),
                          ],
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

class _PriceRoleBanner extends StatelessWidget {
  const _PriceRoleBanner({required this.isInstructor});

  final bool isInstructor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = isInstructor
        ? AppTheme.goldSoft
        : theme.colorScheme.primaryContainer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusTight),
      ),
      child: Row(
        children: [
          Icon(
            isInstructor ? Icons.verified_outlined : Icons.payments_outlined,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isInstructor ? l10n.exploreProBanner : l10n.exploreConsumerBanner,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
