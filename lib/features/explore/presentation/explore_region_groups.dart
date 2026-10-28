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

/// Bundle shops by continent, using the same ids as the atlas rail.
/// A known place alias wins, including when the country text is a region name.
/// Rows with the most shops come first. Unmatched shops are one trailing group.
/// Continents with no shops are omitted.
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
      return _continentOrder(a.id).compareTo(_continentOrder(b.id));
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

String? _continentForShop(DiveShop shop) {
  final region = _knownPlace(shop.location) ?? _knownPlace(shop.country);
  if (region != null && _isContinent(region.continent)) {
    return region.continent;
  }
  if (_isContinent(shop.continent)) {
    return shop.continent;
  }
  return null;
}

int _continentOrder(String id) {
  final menu = ContinentFilter.values.indexOf(id);
  if (menu >= 0) {
    return menu;
  }
  final known = ContinentId.all.indexOf(id);
  return known < 0 ? 99 : ContinentFilter.values.length + known;
}

bool _isContinent(String id) => ContinentId.all.contains(id);

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
