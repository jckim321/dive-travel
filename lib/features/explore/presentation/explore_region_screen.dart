import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/widgets/listing_cover.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_detail_screen.dart';
import 'package:dive_travel_app/features/home/presentation/home_stay_card.dart';

/// Full vertical grid for one travel-tab region. The app bar pops back.
class ExploreRegionScreen extends StatelessWidget {
  const ExploreRegionScreen({
    super.key,
    required this.title,
    required this.shops,
  });

  final String title;
  final List<DiveShop> shops;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('explore-region-screen'),
      appBar: AppBar(title: Text(title)),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        itemCount: shops.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 18,
          crossAxisSpacing: 8,
          mainAxisExtent: ListingCover.travelCardExtent(context),
        ),
        itemBuilder: (context, index) => exploreStayCard(context, shops[index]),
      ),
    );
  }
}

Widget exploreStayCard(BuildContext context, DiveShop shop) {
  return HomeStayCard(
    key: Key('shop-card-${shop.id}'),
    shop: shop,
    travelTab: true,
    onDetails: () => openResortDetail(context, shop.hullId),
  );
}

/// Same cell width as the 2-column travel grid (20+20 padding, 8 gap).
double exploreCardWidth(BuildContext context) {
  return (MediaQuery.sizeOf(context).width - 48) / 2;
}
