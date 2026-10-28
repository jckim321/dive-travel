import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
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

/// Bundle shops by the home-map country (continent + country from [RegionCatalog]).
/// Rows with the most shops come first. Unmatched shops are one trailing group.
/// Countries with no shops are omitted.
List<ExploreRegionGroup> exploreRegionGroups(
  List<DiveShop> shops, {
  required String otherLabel,
}) {
  final buckets = <String, List<DiveShop>>{};
  final titles = <String, String>{};
  final other = <DiveShop>[];
  for (final shop in shops) {
    final region = _regionForShop(shop);
    if (region == null) {
      other.add(shop);
      continue;
    }
    final country = RegionCatalog.countryOf(region);
    final id = '${region.continent}|$country';
    titles[id] = country;
    (buckets[id] ??= <DiveShop>[]).add(shop);
  }
  final groups = [
    for (final entry in buckets.entries)
      if (entry.value.isNotEmpty)
        ExploreRegionGroup(
          id: entry.key,
          title: titles[entry.key] ?? entry.key,
          shops: entry.value,
        ),
  ]..sort((a, b) {
      final byCount = b.shops.length.compareTo(a.shops.length);
      if (byCount != 0) {
        return byCount;
      }
      return a.title.compareTo(b.title);
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

DiveRegion? _regionForShop(DiveShop shop) {
  return _knownPlace(shop.location) ?? _knownPlace(shop.country);
}

/// Same resolver the home map uses. A synthetic id means the name is unknown.
DiveRegion? _knownPlace(String raw) {
  final label = raw.trim();
  if (label.isEmpty) {
    return null;
  }
  final resolved = RegionCatalog.resolve(label, 0);
  if (resolved.id.startsWith('region-')) {
    return null;
  }
  return resolved;
}
