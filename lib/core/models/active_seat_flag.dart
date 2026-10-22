/// Short index on `users/{uid}.active_seat_flags` for the global live-flag cap.
class ActiveSeatFlag {
  const ActiveSeatFlag({
    required this.shopId,
    required this.productId,
    required this.expiresAt,
    this.optionId = '',
  });

  final String shopId;
  final String productId;
  final String optionId;
  final DateTime expiresAt;

  static const maxLivePerUser = 3;
  static const fieldKey = 'active_seat_flags';

  bool isLiveAt(DateTime now) => expiresAt.isAfter(now);

  Map<String, dynamic> toMap() => {
        'shop_id': shopId,
        'product_id': productId,
        'option_id': optionId,
        'expires_at': expiresAt.toIso8601String(),
      };

  static ActiveSeatFlag? fromMap(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final data = Map<String, dynamic>.from(raw);
    final expiresRaw = data['expires_at'];
    DateTime? expires;
    if (expiresRaw is String) {
      expires = DateTime.tryParse(expiresRaw);
    } else if (expiresRaw is DateTime) {
      expires = expiresRaw;
    }
    final shopId = data['shop_id'] as String? ?? '';
    final productId = data['product_id'] as String? ?? '';
    if (shopId.isEmpty || productId.isEmpty || expires == null) {
      return null;
    }
    return ActiveSeatFlag(
      shopId: shopId,
      productId: productId,
      optionId: data['option_id'] as String? ?? '',
      expiresAt: expires,
    );
  }

  static List<ActiveSeatFlag> listFrom(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (fromMap(item) case final flag?) flag,
    ];
  }

  /// Drop expired rows and return only live flags (also the cleaned list to persist).
  static List<ActiveSeatFlag> liveOnly(
    Iterable<ActiveSeatFlag> flags,
    DateTime now,
  ) {
    return [
      for (final flag in flags)
        if (flag.isLiveAt(now)) flag,
    ];
  }

  static List<Map<String, dynamic>> toMaps(Iterable<ActiveSeatFlag> flags) {
    return [for (final flag in flags) flag.toMap()];
  }

  static bool sameProduct(ActiveSeatFlag a, String shopId, String productId) {
    return a.shopId == shopId && a.productId == productId;
  }

  static List<ActiveSeatFlag> withoutProduct(
    Iterable<ActiveSeatFlag> flags,
    String shopId,
    String productId,
  ) {
    return [
      for (final flag in flags)
        if (!sameProduct(flag, shopId, productId)) flag,
    ];
  }
}
