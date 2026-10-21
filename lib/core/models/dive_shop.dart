import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/instructor_discount.dart';

/// 제휴 리조트/다이브샵이 등록한 예약 상품입니다.
class DiveShop {
  const DiveShop({
    required this.id,
    required this.name,
    required this.location,
    required this.country,
    required this.continent,
    required this.sites,
    required this.productName,
    required this.stars,
    required this.rating,
    required this.reviewCount,
    required this.amenities,
    required this.consumerPrice,
    required this.professionalPrice,
    this.accentColor = 0xFF0B1F33,
    this.departure,
    this.intro = '',
    this.address = '',
    this.blurb = '',
    this.durationLabel = '',
    this.coverUrl = '',
    this.galleryUrls = const [],
    this.diveStarExpiresAt,
  });

  final String id;
  final String name;
  final String location;
  final String country;
  final String continent;
  final List<String> sites;
  final String productName;

  /// Admin-assigned Dive Star grade 0–3 (`dive_star_grade`), not guest ★ average.
  final int stars;
  final double rating;
  final int reviewCount;
  final DateTime? diveStarExpiresAt;
  final List<String> amenities;

  /// 샵이 등록한 정상 소비자가. 일반 다이버 세션에 그대로 노출됩니다.
  final int consumerPrice;

  /// 강사 자격 검증 유저에게만 치환되는 우대 단가입니다.
  final int professionalPrice;
  final int accentColor;
  final TourDeparture? departure;
  final String intro;
  final String address;
  final String blurb;
  final String durationLabel;
  final String coverUrl;
  final List<String> galleryUrls;

  /// Cover first, then the rest of the gallery (deduped).
  List<String> get displayGallery {
    if (galleryUrls.isNotEmpty) {
      return galleryUrls;
    }
    if (coverUrl.isNotEmpty) {
      return [coverUrl];
    }
    return const [];
  }

  /// 상품 SKU가 여러 개여도 같은 리조트(호텔)로 묶입니다.
  String get hullId {
    final cut = id.indexOf('--');
    return cut < 0 ? id : id.substring(0, cut);
  }

  /// Listing cards encode the live product as `{hullId}--{productId}`.
  String? get listingProductId {
    final cut = id.indexOf('--');
    if (cut < 0 || cut + 2 >= id.length) {
      return null;
    }
    return id.substring(cut + 2);
  }

  DiveShop copyWith({
    String? id,
    String? name,
    String? location,
    String? productName,
    int? stars,
    double? rating,
    int? reviewCount,
    int? consumerPrice,
    int? professionalPrice,
    TourDeparture? departure,
    String? intro,
    String? address,
    String? blurb,
    String? durationLabel,
    String? coverUrl,
    List<String>? galleryUrls,
    List<String>? amenities,
    DateTime? diveStarExpiresAt,
    bool clearDiveStarExpiresAt = false,
  }) {
    return DiveShop(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      country: country,
      continent: continent,
      sites: sites,
      productName: productName ?? this.productName,
      stars: stars ?? this.stars,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      amenities: amenities ?? this.amenities,
      consumerPrice: consumerPrice ?? this.consumerPrice,
      professionalPrice: professionalPrice ?? this.professionalPrice,
      accentColor: accentColor,
      departure: departure ?? this.departure,
      intro: intro ?? this.intro,
      address: address ?? this.address,
      blurb: blurb ?? this.blurb,
      durationLabel: durationLabel ?? this.durationLabel,
      coverUrl: coverUrl ?? this.coverUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      diveStarExpiresAt: clearDiveStarExpiresAt
          ? null
          : (diveStarExpiresAt ?? this.diveStarExpiresAt),
    );
  }

  DiveShop overlay(ShopLiveStats? live) {
    if (live == null) {
      return copyWith(
        stars: 0,
        rating: 0,
        reviewCount: 0,
        clearDiveStarExpiresAt: true,
      );
    }
    final liveCover = live.coverUrl;
    return copyWith(
      stars: live.diveStar,
      diveStarExpiresAt: live.diveStarExpiresAt,
      clearDiveStarExpiresAt: live.diveStarExpiresAt == null,
      rating: live.reviewCount > 0 ? live.avgOverall : 0,
      reviewCount: live.reviewCount,
      name: live.name,
      location: live.location,
      productName: live.productName,
      consumerPrice: live.consumerPrice,
      professionalPrice: live.professionalPrice,
      intro: live.intro,
      address: live.address,
      coverUrl: (liveCover != null && liveCover.isNotEmpty) ? liveCover : coverUrl,
      galleryUrls: live.galleryUrls.isNotEmpty ? live.galleryUrls : galleryUrls,
      amenities: live.amenities.isNotEmpty ? live.amenities : amenities,
    );
  }

  DiveShop withLiveProduct(ShopLiveStats? live) {
    if (live == null) {
      return this;
    }
    final sku = id.contains('--') ? id.split('--').last : null;
    for (final product in live.products) {
      final match =
          product.name == productName || (sku != null && product.id == sku);
      if (match && product.coverUrl.isNotEmpty) {
        return copyWith(coverUrl: product.coverUrl);
      }
    }
    return copyWith(coverUrl: live.coverUrl ?? coverUrl);
  }

  String get searchBlob {
    return [
      name,
      location,
      country,
      productName,
      ...sites,
      ...amenities,
    ].join(' ').toLowerCase();
  }

  /// Active admin Dive Star (grade 1–3 and not past [diveStarExpiresAt]).
  bool get isDiveStarCertified => stars > 0 && !isDiveStarExpired;

  /// Grade assigned but past expiry — show faded badge + renewal needed.
  bool get isDiveStarExpired {
    if (stars <= 0) {
      return false;
    }
    final expires = diveStarExpiresAt;
    if (expires == null) {
      return false;
    }
    return !expires.isAfter(DateTime.now().toUtc());
  }

  /// Show a Dive Star badge (valid or expired); hide when grade is 0.
  bool get showsDiveStarBadge => stars > 0;

  bool get isNewListing => reviewCount <= 0 && stars <= 0;
}

/// 샵이 실제로 파는 출발. 포스터가 아니라 날짜와 빈자리입니다.
class TourDeparture {
  const TourDeparture({
    required this.start,
    required this.windowLabel,
    this.capacity = 6,
    this.bookedSeats = 0,
    this.lookingSeats = 0,
    this.lastCall = false,
    this.soloShare = false,
  });

  final DateTime start;
  final String windowLabel;
  final int capacity;
  final int bookedSeats;
  final int lookingSeats;
  final bool lastCall;
  final bool soloShare;

  int get emptySeats {
    final left = capacity - bookedSeats - lookingSeats;
    return left < 0 ? 0 : left;
  }
}

/// 세션의 강사 여부에 따라 노출 단가를 고릅니다.
class TourPriceQuote {
  const TourPriceQuote({
    required this.amount,
    required this.isProfessional,
    this.compareAtAmount,
  });

  final int amount;
  final bool isProfessional;
  final int? compareAtAmount;

  bool get hasDiscount =>
      isProfessional && compareAtAmount != null && compareAtAmount! > amount;
}

abstract final class TourPricePolicy {
  static TourPriceQuote quote(
    DiveShop shop, {
    required bool isInstructor,
    InstructorDiscount discount = InstructorDiscount.standard,
  }) {
    if (isInstructor) {
      return TourPriceQuote(
        amount: discount.apply(shop.consumerPrice),
        isProfessional: true,
        compareAtAmount: shop.consumerPrice,
      );
    }
    return TourPriceQuote(
      amount: shop.consumerPrice,
      isProfessional: false,
    );
  }
}

abstract final class ContinentFilter {
  static const all = 'all';

  static const values = <String>[
    all,
    ContinentId.asia,
    ContinentId.africa,
    ContinentId.oceania,
    ContinentId.americas,
    ContinentId.europe,
  ];
}
