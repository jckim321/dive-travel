class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.shopId,
    required this.name,
    required this.consumerPrice,
    required this.professionalPrice,
    this.active = true,
    this.blurb = '',
    this.durationLabel = '',
    this.coverUrl = '',
  });

  factory ShopProduct.fromMap(String shopId, Map<String, dynamic> data) {
    return ShopProduct(
      id: data['id'] as String? ?? '',
      shopId: shopId,
      name: data['name'] as String? ?? '',
      consumerPrice: (data['consumer_price'] as num?)?.toInt() ?? 0,
      professionalPrice: (data['professional_price'] as num?)?.toInt() ?? 0,
      active: data['active'] != false,
      blurb: data['blurb'] as String? ?? '',
      durationLabel: data['duration_label'] as String? ?? '',
      coverUrl: data['cover_url'] as String? ?? '',
    );
  }

  final String id;
  final String shopId;
  final String name;
  final int consumerPrice;
  final int professionalPrice;
  final bool active;
  final String blurb;
  final String durationLabel;
  final String coverUrl;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'consumer_price': consumerPrice,
      'professional_price': professionalPrice,
      'active': active,
      'blurb': blurb,
      'duration_label': durationLabel,
      if (coverUrl.isNotEmpty) 'cover_url': coverUrl,
    };
  }
}
