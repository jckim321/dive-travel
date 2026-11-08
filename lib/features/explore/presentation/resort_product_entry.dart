import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/features/admin/presentation/planner_trip_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/travel_product_form.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/features/partner/presentation/partner_form_focus.dart';

/// A product that belongs to a resort shop, not a planned or self-made trip.
bool productBelongsToResort(ShopProduct product) {
  final shopId = product.shopId.trim();
  if (shopId.isEmpty || shopId.startsWith('curated-')) {
    return false;
  }
  if (product.listingKind == ProductListingKind.diverPlanned ||
      product.listingKind == ProductListingKind.curated) {
    return false;
  }
  return true;
}

/// Resort products open the resort desk. Planned trips open the planner.
Widget resortProductEditor({
  required ShopProduct product,
  bool startEditing = false,
  bool partnerMode = false,
  bool lockShop = false,
  PartnerFormFocus partnerFocus = PartnerFormFocus.none,
}) {
  if (productBelongsToResort(product)) {
    return ResortDeskScreen(
      shopId: product.shopId.trim(),
      partnerMode: partnerMode,
      focusProduct: partnerMode ? product : null,
    );
  }
  return PlannerTripScreen(existing: product);
}

/// Registering against a resort shop opens that shop's desk.
Widget resortRegistrationEntry({
  required String shopId,
  bool partnerMode = false,
  ShopProduct? existing,
  bool startEditing = false,
  PartnerFormFocus partnerFocus = PartnerFormFocus.none,
}) {
  final id = shopId.trim();
  if (productBelongsToResort(
    ShopProduct(
      id: existing?.id ?? 'new',
      shopId: id,
      name: existing?.name ?? '',
      consumerPrice: existing?.consumerPrice ?? 0,
      professionalPrice: existing?.professionalPrice ?? 0,
      listingKind: existing?.listingKind ?? ProductListingKind.exploreOnly,
    ),
  )) {
    return ResortDeskScreen(
      shopId: id,
      partnerMode: partnerMode,
      focusProduct: partnerMode ? existing : null,
      creatingProduct: partnerMode && existing == null,
    );
  }
  return TravelProductRegistrationScreen(
    lockedShopId: id.isEmpty ? null : id,
    partnerMode: partnerMode,
    existing: existing,
    startEditing: startEditing,
    partnerFocus: partnerFocus,
  );
}
