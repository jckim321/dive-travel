import 'package:dive_travel_app/core/data/travel_country_master.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';

/// Region, country, and search all have to match.
bool exploreShopMatches({
  required DiveShop shop,
  required String regionId,
  String? countryId,
  String needle = '',
}) {
  if (needle.isNotEmpty && !shop.searchBlob.contains(needle)) {
    return false;
  }
  final country = travelCountryForShop(shop);
  if (regionId != TravelRegionId.all) {
    final region = country?.regionId ?? travelRegionForShop(shop);
    if (region != regionId) {
      return false;
    }
  }
  if (countryId != null && country?.id != countryId) {
    return false;
  }
  return true;
}
