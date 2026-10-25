import 'package:dive_travel_app/core/models/shop_product.dart';

/// One stored line in shops/{shopId}/product_changes.
class ProductChangeRecord {
  const ProductChangeRecord({
    required this.shopId,
    required this.productId,
    required this.optionId,
    required this.field,
    required this.before,
    required this.after,
    required this.actorUid,
    required this.createdAt,
  });

  final String shopId;
  final String productId;
  final String optionId;
  final String field;
  final int before;
  final int after;
  final String actorUid;
  final DateTime createdAt;

  static const consumerPrice = 'consumer_price';
  static const professionalPrice = 'professional_price';
  static const capacity = 'capacity';
}

class ProductChangeDraft {
  const ProductChangeDraft({
    required this.productId,
    required this.optionId,
    required this.field,
    required this.before,
    required this.after,
  });

  final String productId;
  final String optionId;
  final String field;
  final int before;
  final int after;
}

/// Price and capacity diffs only. Booked seats are not a product edit.
List<ProductChangeDraft> productPriceCapacityChanges({
  required ShopProduct? previous,
  required ShopProduct next,
}) {
  final lines = <ProductChangeDraft>[];
  void add({
    required String optionId,
    required String field,
    required int before,
    required int after,
  }) {
    if (before == after) {
      return;
    }
    lines.add(
      ProductChangeDraft(
        productId: next.id,
        optionId: optionId,
        field: field,
        before: before,
        after: after,
      ),
    );
  }

  add(
    optionId: '',
    field: ProductChangeRecord.consumerPrice,
    before: previous?.consumerPrice ?? 0,
    after: next.consumerPrice,
  );
  add(
    optionId: '',
    field: ProductChangeRecord.professionalPrice,
    before: previous?.professionalPrice ?? 0,
    after: next.professionalPrice,
  );
  add(
    optionId: '',
    field: ProductChangeRecord.capacity,
    before: previous?.capacity ?? 0,
    after: next.capacity,
  );

  final previousOptions = <String, ShopProductOption>{
    for (final option in previous?.options ?? const <ShopProductOption>[])
      if (option.id.isNotEmpty) option.id: option,
  };
  final nextOptions = <String, ShopProductOption>{
    for (final option in next.options)
      if (option.id.isNotEmpty) option.id: option,
  };
  final ids = {...previousOptions.keys, ...nextOptions.keys};
  for (final id in ids) {
    final before = previousOptions[id];
    final after = nextOptions[id];
    add(
      optionId: id,
      field: ProductChangeRecord.consumerPrice,
      before: before?.consumerPrice ?? 0,
      after: after?.consumerPrice ?? 0,
    );
    add(
      optionId: id,
      field: ProductChangeRecord.professionalPrice,
      before: before?.professionalPrice ?? 0,
      after: after?.professionalPrice ?? 0,
    );
    add(
      optionId: id,
      field: ProductChangeRecord.capacity,
      before: before?.capacity ?? 0,
      after: after?.capacity ?? 0,
    );
  }
  return lines;
}
