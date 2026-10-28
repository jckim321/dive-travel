import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';

/// One horizontal row on the travel tab. [id] `other` is the unmatched tail.
class ExploreRegionGroup {
  const ExploreRegionGroup({
    required this.id,
    required this.title,
    required this.shops,
  });

  final String id;
  final String title;
  final List<DiveShop> shops;
}

const exploreOtherRegionId = 'other';

/// Bundle shops by the six travel regions in [TravelCountryMaster].
/// Country text is matched through aliases. A bare zone name such as
/// 미크로네시아 still lands in the Pacific. Unmatched shops trail as 기타.
/// Regions with no shops are omitted.
List<ExploreRegionGroup> exploreRegionGroups(
  List<DiveShop> shops, {
  required String otherLabel,
  required String Function(String continentId) continentLabel,
}) {
  final buckets = <String, List<DiveShop>>{};
  final other = <DiveShop>[];
  for (final shop in shops) {
    final continent = _continentForShop(shop);
    if (continent == null) {
      other.add(shop);
      continue;
    }
    (buckets[continent] ??= <DiveShop>[]).add(shop);
  }
  final groups = [
    for (final entry in buckets.entries)
      if (entry.value.isNotEmpty)
        ExploreRegionGroup(
          id: entry.key,
          title: continentLabel(entry.key),
          shops: entry.value,
        ),
  ]..sort((a, b) {
      final byCount = b.shops.length.compareTo(a.shops.length);
      if (byCount != 0) {
        return byCount;
      }
      return _regionOrder(a.id).compareTo(_regionOrder(b.id));
    });
  if (other.isNotEmpty) {
    groups.add(
      ExploreRegionGroup(
        id: exploreOtherRegionId,
        title: otherLabel,
        shops: other,
      ),
    );
  }
  return groups;
}

String? _continentForShop(DiveShop shop) => travelRegionForShop(shop);

int _regionOrder(String id) {
  final menu = TravelRegionId.menu.indexOf(id);
  return menu < 0 ? 99 : menu;
}
