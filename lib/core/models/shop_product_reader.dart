import 'package:dive_travel_app/core/models/shop_product.dart';

/// Public resort shelves. Empty-seat products stay on the same-boat board.
bool isCustomerShelfProduct(ShopProduct product) {
  return product.isListedPublicly && !product.openEmptySeats;
}

/// Reader catalog: product documents when the shop has any, otherwise the
/// shop `products` array. `booked_seats` and `flag_holds` always come from
/// the array row with the same id, including option rows.
List<ShopProduct> productsForReaders({
  required List<ShopProduct> arrayProducts,
  required List<ShopProduct> documentProducts,
}) {
  if (documentProducts.isEmpty) {
    return arrayProducts;
  }
  final seats = {for (final product in arrayProducts) product.id: product};
  return [
    for (final document in documentProducts)
      _withArraySeats(document, seats[document.id]),
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
