import 'package:dive_travel_app/core/models/shop_product.dart';

/// Public guest shelves (explore and home).
/// Partner empty-seat products stay on the same-boat board only.
/// A planned trip can be on the shelf and the same-boat board together.
bool isCustomerShelfProduct(ShopProduct product) {
  if (!product.isListedPublicly) {
    return false;
  }
  if (!product.openEmptySeats) {
    return true;
  }
  return product.listingKind == ProductListingKind.curated ||
      product.listingKind == ProductListingKind.diverPlanned;
}

/// Reader catalog merges product documents with the shop `products` array
/// by id. A shared id uses the document. Array rows with no document stay.
/// `booked_seats` and `flag_holds` always come from the array row with the
/// same id, including option rows.
List<ShopProduct> productsForReaders({
  required List<ShopProduct> arrayProducts,
  required List<ShopProduct> documentProducts,
}) {
  if (documentProducts.isEmpty) {
    return arrayProducts;
  }
  final seats = {for (final product in arrayProducts) product.id: product};
  final documentIds = {for (final document in documentProducts) document.id};
  return [
    for (final document in documentProducts)
      _withArraySeats(document, seats[document.id]),
    for (final array in arrayProducts)
      if (!documentIds.contains(array.id)) array,
  ];
}

ShopProduct _withArraySeats(ShopProduct document, ShopProduct? array) {
  if (array == null) {
    return document;
  }
  final optionSeats = {for (final option in array.options) option.id: option};
  return document.copyWith(
    bookedSeats: array.bookedSeats,
    flagHolds: array.flagHolds,
    options: [
      for (final option in document.options)
        if (optionSeats[option.id] case final seats?)
          option.copyWith(
            bookedSeats: seats.bookedSeats,
            flagHolds: seats.flagHolds,
          )
        else
          option,
    ],
  );
}
