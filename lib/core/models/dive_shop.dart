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
  });

  final String id;
  final String name;
  final String location;
  final String country;
  final String continent;
  final List<String> sites;
  final String productName;
  final int stars;
  final double rating;
  final int reviewCount;
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

  /// 상품 SKU가 여러 개여도 같은 리조트(호텔)로 묶입니다.
  String get hullId {
    final cut = id.indexOf('--');
    return cut < 0 ? id : id.substring(0, cut);
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
      amenities: amenities,
      consumerPrice: consumerPrice ?? this.consumerPrice,
      professionalPrice: professionalPrice ?? this.professionalPrice,
      accentColor: accentColor,
      departure: departure ?? this.departure,
      intro: intro ?? this.intro,
      address: address ?? this.address,
      blurb: blurb ?? this.blurb,
      durationLabel: durationLabel ?? this.durationLabel,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }

  DiveShop overlay(ShopLiveStats? live) {
    var next = this;
    if (live != null && live.reviewCount > 0) {
      next = next.copyWith(
        stars: live.diveStar,
        rating: live.avgOverall,
        reviewCount: live.reviewCount,
      );
    } else {
      next = next.copyWith(stars: 0, rating: 0, reviewCount: 0);
    }
    if (live == null) {
      return next;
    }
    return next.copyWith(
      name: live.name,
      location: live.location,
      productName: live.productName,
      consumerPrice: live.consumerPrice,
      professionalPrice: live.professionalPrice,
      intro: live.intro,
      address: live.address,
      coverUrl: live.coverUrl ?? coverUrl,
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

  /// 스타가 있으면 인증, 리뷰가 없으면 신규, 리뷰만 있으면 평가 전입니다.
  bool get isDiveStarCertified => stars > 0;

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
