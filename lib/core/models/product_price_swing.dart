import 'package:dive_travel_app/core/models/shop_product.dart';

/// One unit-price field that moved by at least [thresholdRatio] vs previous.
class ProductPriceSwing {
  const ProductPriceSwing({
    required this.labelKey,
    required this.oldPrice,
    required this.newPrice,
  });

  /// Stable key for UI (e.g. `base_consumer`, `guest_nondiver`, `option:<id>`).
  final String labelKey;
  final int oldPrice;
  final int newPrice;

  double get ratio {
    if (oldPrice <= 0) {
      return newPrice > 0 ? double.infinity : 0;
    }
    return (newPrice - oldPrice).abs() / oldPrice;
  }

  double get percent => ratio * 100;
}

/// ±30% (default) gate for partner live saves — no approval, confirm only.
abstract final class ProductPriceSwingGate {
  static const defaultThresholdRatio = 0.30;

  /// Compares base, professional, guest_rates, and every option unit price.
  static List<ProductPriceSwing> findSwings({
    required ShopProduct previous,
    required ShopProduct next,
    double thresholdRatio = defaultThresholdRatio,
  }) {
    final out = <ProductPriceSwing>[];

    void check(String key, int oldP, int newP) {
      if (oldP == newP) {
        return;
      }
      if (oldP <= 0) {
        if (newP > 0) {
          out.add(
            ProductPriceSwing(labelKey: key, oldPrice: oldP, newPrice: newP),
          );
        }
        return;
      }
      final ratio = (newP - oldP).abs() / oldP;
      if (ratio >= thresholdRatio) {
        out.add(
          ProductPriceSwing(labelKey: key, oldPrice: oldP, newPrice: newP),
        );
      }
    }

    check('base_consumer', previous.consumerPrice, next.consumerPrice);
    check(
      'base_professional',
      previous.professionalPrice,
      next.professionalPrice,
    );

    final prevRates = {
      for (final r in previous.guestRates) r.role: r,
    };
    for (final rate in next.guestRates) {
      final prev = prevRates[rate.role];
      final oldC = prev?.consumer ?? 0;
      final oldP = prev?.professional ?? 0;
      check('guest_${rate.role.firestoreValue}_consumer', oldC, rate.consumer);
      check(
        'guest_${rate.role.firestoreValue}_professional',
        oldP,
        rate.professional,
      );
    }

    final prevOpts = {
      for (final o in previous.options)
        if (o.id.isNotEmpty) o.id: o,
    };
    for (final option in next.options) {
      if (option.id.isEmpty) {
        continue;
      }
      final prev = prevOpts[option.id];
      final oldC = prev?.consumerPrice ?? 0;
      final oldP = prev?.professionalPrice ?? 0;
      check('option_${option.id}_consumer', oldC, option.consumerPrice);
      check('option_${option.id}_professional', oldP, option.professionalPrice);
    }

    return out;
  }

  static bool needsConfirm({
    required ShopProduct previous,
    required ShopProduct next,
    double thresholdRatio = defaultThresholdRatio,
  }) {
    return findSwings(
      previous: previous,
      next: next,
      thresholdRatio: thresholdRatio,
    ).isNotEmpty;
  }
}
