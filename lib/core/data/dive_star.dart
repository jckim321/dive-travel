import 'dart:typed_data';

import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/models/shop_resort_info.dart';

/// Legacy helper: once used to auto-grade shops from operation-review averages.
/// Shop Dive Star grade is now admin-assigned (`dive_star_grade`); do not use
/// [fromAverages] to overwrite that field.
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

  /// Historical auto-grade thresholds (tests / reference only).
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

  /// Parses Firestore Timestamp / DateTime / ISO string; otherwise null.
  static DateTime? parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc();
    }
    try {
      final date = (value as dynamic).toDate();
      if (date is DateTime) {
        return date.toUtc();
      }
    } catch (_) {}
    return null;
  }

  static int clampGrade(int raw) => raw.clamp(0, 3);
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
    this.diveStarReviewedAt,
    this.diveStarExpiresAt,
    this.plaqueStatus = PlaqueStatus.none,
    this.name,
    this.location,
    this.country,
    this.continent,
    this.curated = false,
    this.productName,
    this.consumerPrice,
    this.professionalPrice,
    this.commissionRate = 0.12,
    this.internalScore = 0,
    this.products = const [],
    this.intro,
    this.address,
    this.mapUrl = '',
    this.nearestHub = '',
    this.accessRoutes = const [],
    this.featureBlurb = '',
    this.featureTags = const [],
    this.nearbySpots = const [],
    this.localContact = '',
    this.checkIn = '',
    this.checkOut = '',
    this.businessHours = '',
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
    // Admin-assigned grade only. Ignore legacy auto field `dive_star`.
    final grade = DiveStar.clampGrade(
      (data['dive_star_grade'] as num?)?.toInt() ?? 0,
    );
    return ShopLiveStats(
      shopId: id,
      reviewCount: count,
      avgSafety: safety,
      avgGuide: guide,
      avgBoat: boat,
      avgOverall: overall,
      diveStar: grade,
      diveStarReviewedAt: DiveStar.parseDate(data['dive_star_reviewed_at']),
      diveStarExpiresAt: DiveStar.parseDate(data['dive_star_expires_at']),
      plaqueStatus: PlaqueStatus.parse(data['plaque_status']),
      name: data['name'] as String?,
      location: data['location'] as String?,
      country: data['country'] as String?,
      continent: data['continent'] as String?,
      curated: data['curated'] == true || id.startsWith('curated-'),
      productName: data['product_name'] as String?,
      consumerPrice: (data['consumer_price'] as num?)?.toInt(),
      professionalPrice: (data['professional_price'] as num?)?.toInt(),
      commissionRate:
          (data['commission_rate'] as num?)?.toDouble() ?? 0.12,
      internalScore: (data['internal_score'] as num?)?.toInt() ?? 0,
      products: ShopProduct.listFrom(id, data['products']),
      intro: data['intro'] as String?,
      address: data['address'] as String?,
      mapUrl: (data['map_url'] as String? ?? '').trim(),
      nearestHub: (data['nearest_hub'] as String? ?? '').trim(),
      accessRoutes: AccessRoute.listFrom(data['access_routes']),
      featureBlurb: (data['feature_blurb'] as String? ?? '').trim(),
      featureTags: stringListFrom(
        data['feature_tags'],
        maxItems: kMaxFeatureTags,
      ),
      nearbySpots: NearbySpot.listFrom(data['nearby_spots']),
      localContact: (data['local_contact'] as String? ?? '').trim(),
      checkIn: (data['check_in'] as String? ?? '').trim(),
      checkOut: (data['check_out'] as String? ?? '').trim(),
      businessHours: (data['business_hours'] as String? ?? '').trim(),
      coverUrl: () {
        final raw = data['cover_url'] as String?;
        if (raw == null || raw.trim().isEmpty) {
          return null;
        }
        return R2Config.normalizePublicUrl(raw);
      }(),
      galleryUrls: [
        for (final item in (data['gallery_urls'] as List<dynamic>? ?? const []))
          if (item is String && item.trim().isNotEmpty)
            R2Config.normalizePublicUrl(item),
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

  /// Admin-assigned Dive Star grade 0–3 (`dive_star_grade`).
  final int diveStar;
  final DateTime? diveStarReviewedAt;
  final DateTime? diveStarExpiresAt;
  final PlaqueStatus plaqueStatus;
  final String? name;
  final String? location;
  final String? country;
  final String? continent;
  final bool curated;
  final String? productName;
  final int? consumerPrice;
  final int? professionalPrice;
  final double commissionRate;

  /// Admin-only partner quality score (0–100), separate from Dive Star reviews.
  final int internalScore;
  final List<ShopProduct> products;
  final String? intro;
  final String? address;
  final String mapUrl;
  final String nearestHub;
  final List<AccessRoute> accessRoutes;
  final String featureBlurb;
  final List<String> featureTags;
  final List<NearbySpot> nearbySpots;
  final String localContact;
  final String checkIn;
  final String checkOut;
  final String businessHours;
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

  bool get isDiveStarExpired {
    if (diveStar <= 0) {
      return false;
    }
    final expires = diveStarExpiresAt;
    if (expires == null) {
      return false;
    }
    return !expires.isAfter(DateTime.now().toUtc());
  }

  bool get qualifiesForPlaque => diveStar >= 1 && reviewCount > 0;

  ShopLiveStats copyWith({
    int? diveStar,
    DateTime? diveStarReviewedAt,
    DateTime? diveStarExpiresAt,
    bool clearDiveStarDates = false,
    PlaqueStatus? plaqueStatus,
    String? name,
    String? location,
    String? country,
    String? continent,
    bool? curated,
    String? productName,
    int? consumerPrice,
    int? professionalPrice,
    double? commissionRate,
    int? internalScore,
    List<ShopProduct>? products,
    String? intro,
    String? address,
    String? mapUrl,
    String? nearestHub,
    List<AccessRoute>? accessRoutes,
    String? featureBlurb,
    List<String>? featureTags,
    List<NearbySpot>? nearbySpots,
    String? localContact,
    String? checkIn,
    String? checkOut,
    String? businessHours,
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
      diveStar: diveStar ?? this.diveStar,
      diveStarReviewedAt: clearDiveStarDates
          ? null
          : (diveStarReviewedAt ?? this.diveStarReviewedAt),
      diveStarExpiresAt: clearDiveStarDates
          ? null
          : (diveStarExpiresAt ?? this.diveStarExpiresAt),
      plaqueStatus: plaqueStatus ?? this.plaqueStatus,
      name: name ?? this.name,
      location: location ?? this.location,
      country: country ?? this.country,
      continent: continent ?? this.continent,
      curated: curated ?? this.curated,
      productName: productName ?? this.productName,
      consumerPrice: consumerPrice ?? this.consumerPrice,
      professionalPrice: professionalPrice ?? this.professionalPrice,
      commissionRate: commissionRate ?? this.commissionRate,
      internalScore: internalScore ?? this.internalScore,
      products: products ?? this.products,
      intro: intro ?? this.intro,
      address: address ?? this.address,
      mapUrl: mapUrl ?? this.mapUrl,
      nearestHub: nearestHub ?? this.nearestHub,
      accessRoutes: accessRoutes ?? this.accessRoutes,
      featureBlurb: featureBlurb ?? this.featureBlurb,
      featureTags: featureTags ?? this.featureTags,
      nearbySpots: nearbySpots ?? this.nearbySpots,
      localContact: localContact ?? this.localContact,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      businessHours: businessHours ?? this.businessHours,
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
