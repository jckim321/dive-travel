import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/refund_policy.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/core/widgets/app_card.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/features/community/presentation/open_tide_room.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
import 'package:dive_travel_app/features/home/presentation/home_stay_card.dart';
import 'package:dive_travel_app/features/reviews/presentation/operation_review_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final isInstructor = store.stats.isInstructor;
        final needle = _search.text.trim().toLowerCase();
        final shops = DiveShopCatalog.hulls([
          for (final shop in store.shops)
            if ((_continent == ContinentFilter.all ||
                    shop.continent == _continent) &&
                (needle.isEmpty || shop.searchBlob.contains(needle)))
              shop,
        ]);
        final bookings = store.bookings;

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
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: ContinentFilter.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final id = ContinentFilter.values[index];
                      return ChoiceChip(
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(_continentLabel(l10n, id)),
                        selected: _continent == id,
                        onSelected: (_) => setState(() => _continent = id),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _PriceRoleBanner(isInstructor: isInstructor),
                ),
                Expanded(
                  child: shops.isEmpty && bookings.isEmpty
                      ? Center(child: Text(l10n.exploreNoResults))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                          children: [
                            if (bookings.isNotEmpty) ...[
                              AppSectionHeader(title: l10n.exploreMyBookings),
                              const SizedBox(height: 14),
                              for (final booking in bookings) ...[
                                AppCard(
                                  onTap: booking.reviewed
                                      ? null
                                      : () => openOperationReview(
                                          context,
                                          shopId: booking.shopId,
                                          bookingId: booking.id,
                                        ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              booking.shopName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${booking.productName}\n${_bookingStatus(l10n, booking)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (booking.isActive)
                                        Column(
                                          children: [
                                            TextButton(
                                              onPressed: () =>
                                                  openTideRoomForBooking(
                                                context: context,
                                                booking: booking,
                                              ),
                                              child: Text(l10n.communityPlantFlag),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  DiverStoreScope.of(
                                                context,
                                              ).cancelBookingAsGuest(booking.id),
                                              child: Text(l10n.bookingCancel),
                                            ),
                                          ],
                                        )
                                      else
                                        Text(
                                          booking.isWeatherCancelled
                                              ? l10n.bookingWeatherCancelled
                                              : l10n.bookingCancelled,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              const SizedBox(height: 8),
                            ],
                            if (shops.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Center(
                                  child: Text(l10n.exploreNoResults),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: shops.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 18,
                                      crossAxisSpacing: 12,
                                      mainAxisExtent:
                                          ListingCover.cardExtent(context),
                                    ),
                                itemBuilder: (context, index) {
                                  final shop = shops[index];
                                  return HomeStayCard(
                                    key: Key('shop-card-${shop.id}'),
                                    shop: shop,
                                    quote: store.quoteFor(shop),
                                    productCount:
                                        store.listingsOnHull(shop.hullId).length,
                                    onDetails: () => openResortDetail(
                                      context,
                                      shop.hullId,
                                    ),
                                    onBuy: () => openResortDetail(
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

  String _continentLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case ContinentFilter.all:
        return l10n.exploreFilterAll;
      case ContinentId.asia:
        return l10n.exploreContinentAsia;
      case ContinentId.africa:
        return l10n.exploreContinentAfrica;
      case ContinentId.oceania:
        return l10n.exploreContinentOceania;
      case ContinentId.americas:
        return l10n.exploreContinentAmericas;
      case ContinentId.europe:
        return l10n.exploreContinentEurope;
      default:
        return id;
    }
  }

  String _bookingStatus(AppLocalizations l10n, TourBooking booking) {
    switch (booking.status) {
      case BookingStatus.cancelled:
        return l10n.bookingCancelledRefund(booking.refundPercent);
      case BookingStatus.weatherCancelled:
        return l10n.bookingWeatherCancelled;
      case BookingStatus.confirmed:
        final quote = RefundPolicy.forUserCancel(
          tourDate: booking.scheduledFor,
        );
        return '${l10n.bookingConfirmed} · ${l10n.refundPolicyHint(quote.percent)}';
    }
  }
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
