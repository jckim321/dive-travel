import 'dart:typed_data';

import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

/// 오퍼레이션 3대 항목 평균으로 Dive Star 등급을 계산합니다.
abstract final class DiveStar {
  static const double star1Threshold = 4.5;
  static const double star2Threshold = 4.8;
  static const double star3OverallThreshold = 4.9;
  static const double safetyPassThreshold = 4.8;

  static double overall({
    required double safety,
    required double guide,
    required double boat,
  }) {
    return (safety + guide + boat) / 3;
  }

  /// 4.5 이상 1스타, 4.8 이상 2스타, 최고 점수 + 안전 기준 통과 시 3스타.
  static int fromAverages({
    required double safety,
    required double guide,
    required double boat,
    int reviewCount = 0,
  }) {
    if (reviewCount <= 0) {
      return 0;
    }
    final avg = overall(safety: safety, guide: guide, boat: boat);
    final safetyPass = safety >= safetyPassThreshold;
    if (avg >= star3OverallThreshold && safetyPass) {
      return 3;
    }
    if (avg >= star2Threshold) {
      return 2;
    }
    if (avg >= star1Threshold) {
      return 1;
    }
    return 0;
  }
}

class ShopLiveStats {
  const ShopLiveStats({
    required this.shopId,
    required this.reviewCount,
    required this.avgSafety,
    required this.avgGuide,
    required this.avgBoat,
    required this.avgOverall,
    required this.diveStar,
    this.plaqueStatus = PlaqueStatus.none,
    this.name,
    this.location,
    this.productName,
    this.consumerPrice,
    this.professionalPrice,
    this.commissionRate = 0.12,
    this.products = const [],
    this.intro,
    this.address,
    this.coverUrl,
    this.galleryUrls = const [],
    this.amenities = const [],
  });

  factory ShopLiveStats.fromDocument(String id, Map<String, dynamic> data) {
    final count = (data['review_count'] as num?)?.toInt() ?? 0;
    final safety = (data['avg_safety'] as num?)?.toDouble() ?? 0;
    final guide = (data['avg_guide'] as num?)?.toDouble() ?? 0;
    final boat = (data['avg_boat'] as num?)?.toDouble() ?? 0;
    final overall = (data['avg_overall'] as num?)?.toDouble() ??
        DiveStar.overall(safety: safety, guide: guide, boat: boat);
    final storedStar = (data['dive_star'] as num?)?.toInt();
    return ShopLiveStats(
      shopId: id,
      reviewCount: count,
      avgSafety: safety,
      avgGuide: guide,
      avgBoat: boat,
      avgOverall: overall,
      diveStar:
          storedStar ??
          DiveStar.fromAverages(
            safety: safety,
            guide: guide,
            boat: boat,
            reviewCount: count,
          ),
      plaqueStatus: PlaqueStatus.parse(data['plaque_status']),
      name: data['name'] as String?,
      location: data['location'] as String?,
      productName: data['product_name'] as String?,
      consumerPrice: (data['consumer_price'] as num?)?.toInt(),
      professionalPrice: (data['professional_price'] as num?)?.toInt(),
      commissionRate:
          (data['commission_rate'] as num?)?.toDouble() ?? 0.12,
      products: [
        for (final item in (data['products'] as List<dynamic>? ?? const []))
          if (item is Map<String, dynamic>) ShopProduct.fromMap(id, item),
      ],
      intro: data['intro'] as String?,
      address: data['address'] as String?,
      coverUrl: data['cover_url'] as String?,
      galleryUrls: [
        for (final item in (data['gallery_urls'] as List<dynamic>? ?? const []))
          if (item is String && item.trim().isNotEmpty) item.trim(),
      ],
      amenities: [
        for (final item in (data['amenities'] as List<dynamic>? ?? const []))
          if (item is String && item.trim().isNotEmpty) item.trim(),
      ],
    );
  }

  final String shopId;
  final int reviewCount;
  final double avgSafety;
  final double avgGuide;
  final double avgBoat;
  final double avgOverall;
  final int diveStar;
  final PlaqueStatus plaqueStatus;
  final String? name;
  final String? location;
  final String? productName;
  final int? consumerPrice;
  final int? professionalPrice;
  final double commissionRate;
  final List<ShopProduct> products;
  final String? intro;
  final String? address;
  final String? coverUrl;
  final List<String> galleryUrls;
  final List<String> amenities;

  /// Ordered resort photos. First becomes [coverUrl] after save.
  List<String> get displayGallery {
    if (galleryUrls.isNotEmpty) {
      return galleryUrls;
    }
    final cover = coverUrl;
    if (cover != null && cover.isNotEmpty) {
      return [cover];
    }
    return const [];
  }

  bool get qualifiesForPlaque => diveStar >= 1 && reviewCount > 0;

  ShopLiveStats copyWith({
    PlaqueStatus? plaqueStatus,
    String? name,
    String? location,
    String? productName,
    int? consumerPrice,
    int? professionalPrice,
    double? commissionRate,
    List<ShopProduct>? products,
    String? intro,
    String? address,
    String? coverUrl,
    List<String>? galleryUrls,
    List<String>? amenities,
  }) {
    return ShopLiveStats(
      shopId: shopId,
      reviewCount: reviewCount,
      avgSafety: avgSafety,
      avgGuide: avgGuide,
      avgBoat: avgBoat,
      avgOverall: avgOverall,
      diveStar: diveStar,
      plaqueStatus: plaqueStatus ?? this.plaqueStatus,
      name: name ?? this.name,
      location: location ?? this.location,
      productName: productName ?? this.productName,
      consumerPrice: consumerPrice ?? this.consumerPrice,
      professionalPrice: professionalPrice ?? this.professionalPrice,
      commissionRate: commissionRate ?? this.commissionRate,
      products: products ?? this.products,
      intro: intro ?? this.intro,
      address: address ?? this.address,
      coverUrl: coverUrl ?? this.coverUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      amenities: amenities ?? this.amenities,
    );
  }
}

/// One ordered gallery slot for [DiverRepository.saveShopProfile].
/// Prefer [bytes] for new uploads; [url] keeps an existing remote photo.
class ShopGallerySlot {
  const ShopGallerySlot({
    this.url,
    this.bytes,
    this.fileName,
    this.contentType,
  });

  final String? url;
  final Uint8List? bytes;
  final String? fileName;
  final String? contentType;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;

  bool get hasUrl => url != null && url!.trim().isNotEmpty;
}
