import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

/// 전 세계 제휴 다이브 포인트 / 리조트 카탈로그. 결제 연동 전 단계의 상점 목록입니다.
abstract final class DiveShopCatalog {
  static const shops = <DiveShop>[
    DiveShop(
      id: 'bohol-hideout',
      name: '보홀 오션 하이드아웃',
      location: '필리핀 보홀',
      country: '필리핀',
      continent: ContinentId.asia,
      sites: ['발리카삭', '팡라오', '발리카삭 난파선'],
      productName: '2탱크 펀다이빙',
      stars: 3,
      rating: 4.9,
      reviewCount: 312,
      amenities: ['안전 장비', '가이드', '스피드보트'],
      consumerPrice: 180000,
      professionalPrice: 126000,
      accentColor: 0xFF0B1F33,
    ),
    DiveShop(
      id: 'dahab-bluehole',
      name: '다합 블루홀 다이브 센터',
      location: '이집트 다합',
      country: '이집트',
      continent: ContinentId.africa,
      sites: ['블루홀', '캐년', '아일랜드'],
      productName: '쇼어 2탱크',
      stars: 2,
      rating: 4.7,
      reviewCount: 188,
      amenities: ['쇼어 다이빙', '나이트록스'],
      consumerPrice: 95000,
      professionalPrice: 66500,
      accentColor: 0xFF16344A,
    ),
    DiveShop(
      id: 'kerama-okinawa',
      name: '케라마 아일랜드 다이브',
      location: '일본 오키나와',
      country: '일본',
      continent: ContinentId.asia,
      sites: ['케라마', '자메슨', '만자모'],
      productName: '보트 2탱크',
      stars: 2,
      rating: 4.6,
      reviewCount: 141,
      amenities: ['소그룹', '수온 안내'],
      consumerPrice: 220000,
      professionalPrice: 154000,
      accentColor: 0xFF1A3D52,
    ),
    DiveShop(
      id: 'similan-liveaboard',
      name: '시밀란 리브어보드',
      location: '태국 시밀란',
      country: '태국',
      continent: ContinentId.asia,
      sites: ['리치혼', '엘리펀트헤드', '웨스턴 록'],
      productName: '3일 리브어보드',
      stars: 3,
      rating: 4.8,
      reviewCount: 96,
      amenities: ['리브어보드', '나이트록스', '카메라 테이블'],
      consumerPrice: 890000,
      professionalPrice: 623000,
      accentColor: 0xFF12384A,
    ),
    DiveShop(
      id: 'palau-rock-islands',
      name: '팔라우 록아일랜드 다이브',
      location: '팔라우',
      country: '팔라우',
      continent: ContinentId.oceania,
      sites: ['블루코너', '저먼채널', '밀키웨이'],
      productName: '2탱크 펀다이빙',
      stars: 3,
      rating: 4.9,
      reviewCount: 254,
      amenities: ['유네스코 해역', '유조'],
      consumerPrice: 310000,
      professionalPrice: 217000,
      accentColor: 0xFF0E2F3C,
    ),
    DiveShop(
      id: 'komodo-comel',
      name: '코모도 코멜 다이브 리조트',
      location: '인도네시아 코모도',
      country: '인도네시아',
      continent: ContinentId.asia,
      sites: ['코멜', '만타포인트', '바투볼롱'],
      productName: '2탱크 펀다이빙',
      stars: 2,
      rating: 4.7,
      reviewCount: 167,
      amenities: ['만타', '조류 다이빙'],
      consumerPrice: 165000,
      professionalPrice: 115500,
      accentColor: 0xFF1B3F3A,
    ),
    DiveShop(
      id: 'sipadan-borneo',
      name: '시파단 보르네오 다이브',
      location: '말레이시아 시파단',
      country: '말레이시아',
      continent: ContinentId.asia,
      sites: ['배런드아일랜드', '터틀캐번', '사우스포인트'],
      productName: '허가제 2탱크',
      stars: 3,
      rating: 4.9,
      reviewCount: 203,
      amenities: ['입장 허가', '거북이'],
      consumerPrice: 420000,
      professionalPrice: 294000,
      accentColor: 0xFF0B1F33,
    ),
    DiveShop(
      id: 'raja-ampat',
      name: '라자암팟 코랄 가든',
      location: '인도네시아 라자암팟',
      country: '인도네시아',
      continent: ContinentId.asia,
      sites: ['카펠', '미요스콘', '블루매직'],
      productName: '하우스리프 + 보트 2탱크',
      stars: 3,
      rating: 4.8,
      reviewCount: 121,
      amenities: ['하우스리프', '생물 다양성'],
      consumerPrice: 245000,
      professionalPrice: 171500,
      accentColor: 0xFF143A48,
    ),
    DiveShop(
      id: 'cozumel-reef',
      name: '코즈멜 리프 다이브',
      location: '멕시코 코즈멜',
      country: '멕시코',
      continent: ContinentId.americas,
      sites: ['팔랑카르', '컬럼비아', '산타로사'],
      productName: '드리프트 2탱크',
      stars: 2,
      rating: 4.6,
      reviewCount: 178,
      amenities: ['드리프트', '월다이빙'],
      consumerPrice: 175000,
      professionalPrice: 122500,
      accentColor: 0xFF1A4548,
    ),
    DiveShop(
      id: 'cairns-gbr',
      name: '케언즈 그레이트리프',
      location: '호주 케언즈',
      country: '호주',
      continent: ContinentId.oceania,
      sites: ['노먼리프', '오스틴리프', '무어리프'],
      productName: '외곽 리프 2탱크',
      stars: 2,
      rating: 4.5,
      reviewCount: 134,
      amenities: ['외곽 리프', '해양공원'],
      consumerPrice: 260000,
      professionalPrice: 182000,
      accentColor: 0xFF0B1F33,
    ),
    DiveShop(
      id: 'maldives-ari',
      name: '몰디브 아리 아톨 센터',
      location: '몰디브 아리 아톨',
      country: '몰디브',
      continent: ContinentId.asia,
      sites: ['마칸두라', '헐후마시', '만타포인트'],
      productName: '리조트 2탱크',
      stars: 3,
      rating: 4.8,
      reviewCount: 89,
      amenities: ['만타', '고래상어'],
      consumerPrice: 280000,
      professionalPrice: 196000,
      accentColor: 0xFF0F2A40,
    ),
    DiveShop(
      id: 'malta-gozo',
      name: '고조 블루홀 다이브',
      location: '몰타 고조',
      country: '몰타',
      continent: ContinentId.europe,
      sites: ['인랜드시', '블루홀', '레퀴아'],
      productName: '쇼어 2탱크',
      stars: 2,
      rating: 4.6,
      reviewCount: 77,
      amenities: ['난파선', '쇼어'],
      consumerPrice: 140000,
      professionalPrice: 98000,
      accentColor: 0xFF0B1F33,
    ),
  ];

  static List<DiveShop> search({
    required String query,
    required String continent,
    List<ShopLiveStats> live = const [],
  }) {
    final merged = withLiveStats(live);
    final needle = query.trim().toLowerCase();
    return [
      for (final shop in merged)
        if ((continent == ContinentFilter.all || shop.continent == continent) &&
            (needle.isEmpty || shop.searchBlob.contains(needle)))
          shop,
    ];
  }

  static List<DiveShop> withLiveStats(List<ShopLiveStats> live) {
    final map = {for (final stats in live) stats.shopId: stats};
    final result = <DiveShop>[];
    for (final shop in shops) {
      final stats = map[shop.id];
      final merged = shop.overlay(stats);
      final products = [
        for (final product in stats?.products ?? const <ShopProduct>[])
          if (product.isListedPublicly) product,
      ];
      if (products.isEmpty) {
        result.add(_withDeparture(merged));
        continue;
      }
      for (var i = 0; i < products.length; i++) {
        final product = products[i];
        result.add(
          _withDeparture(
            merged.copyWith(
              id: i == 0 ? shop.id : '${shop.id}--${product.id}',
              productName: product.name,
              consumerPrice: product.consumerPrice,
              professionalPrice: product.professionalPrice,
              blurb: product.blurb,
              durationLabel: product.durationLabel,
              coverUrl: product.coverUrl.isNotEmpty
                  ? product.coverUrl
                  : merged.coverUrl,
            ),
          ),
        );
      }
    }
    return result;
  }

  static List<DiveShop> ranked(List<DiveShop> shops, {int limit = 3}) {
    final copy = [...shops];
    copy.sort((a, b) {
      final byStar = b.stars.compareTo(a.stars);
      if (byStar != 0) {
        return byStar;
      }
      final byRating = b.rating.compareTo(a.rating);
      if (byRating != 0) {
        return byRating;
      }
      return b.reviewCount.compareTo(a.reviewCount);
    });
    if (copy.length <= limit) {
      return copy;
    }
    return copy.sublist(0, limit);
  }

  /// 여행상품 목록은 리조트 단위. 객실(상품)은 리조트 안에서 고릅니다.
  static List<DiveShop> hulls(List<DiveShop> shops) {
    final seen = <String>{};
    return [
      for (final shop in shops)
        if (seen.add(shop.hullId)) shop,
    ];
  }

  static List<DiveShop> listingsOnHull(List<DiveShop> shops, String hullId) {
    final onHull = [
      for (final shop in shops)
        if (shop.hullId == hullId) shop,
    ];
    if (onHull.isEmpty) {
      return const [];
    }
    final extras = _menuExtras(onHull.first);
    final ids = {for (final shop in onHull) shop.id};
    return [
      ...onHull,
      for (final extra in extras)
        if (ids.add(extra.id)) extra,
    ];
  }

  static List<DiveShop> _menuExtras(DiveShop hull) {
    switch (hull.hullId) {
      case 'bohol-hideout':
        return [
          hull.copyWith(
            id: '${hull.hullId}--night',
            productName: '나이트 1탱크',
            consumerPrice: 90000,
            professionalPrice: 63000,
            durationLabel: '야간 90분',
            blurb: '해가 진 뒤 플랑크톤과 작은 생물을 손전등로 따라갑니다.',
          ),
        ];
      case 'palau-rock-islands':
        return [
          hull.copyWith(
            id: '${hull.hullId}--liveaboard',
            productName: '5일 록아일랜드 리브어보드',
            consumerPrice: 2100000,
            professionalPrice: 1470000,
            durationLabel: '5일 4박',
            blurb: '블루코너와 저먼채널을 배로 잇습니다. 빈 선실이 있으면 같은배에 올립니다.',
          ),
        ];
      default:
        return const [];
    }
  }

  static DiveShop? byId(String id) {
    for (final shop in shops) {
      if (shop.id == id) {
        return _withDeparture(shop);
      }
    }
    return null;
  }

  static DiveShop _withDeparture(DiveShop shop) {
    final story = ResortCopy.of(shop);
    return shop.copyWith(
      departure: shop.departure ?? DepartureCatalog.of(shop.id),
      intro: shop.intro.isEmpty ? story.intro : shop.intro,
      address: shop.address.isEmpty ? story.address : shop.address,
      blurb: shop.blurb.isEmpty ? story.defaultBlurb : shop.blurb,
      durationLabel:
          shop.durationLabel.isEmpty ? story.defaultDuration : shop.durationLabel,
    );
  }
}

class ResortCopy {
  const ResortCopy({
    required this.intro,
    required this.address,
    this.defaultBlurb = '',
    this.defaultDuration = '반나절',
  });

  final String intro;
  final String address;
  final String defaultBlurb;
  final String defaultDuration;

  static ResortCopy of(DiveShop shop) {
    return _byHull[shop.hullId] ??
        ResortCopy(
          intro:
              '${shop.name}는 ${shop.location}에서 ${shop.sites.take(2).join(', ')}를 운영합니다. 수심보다 가이드와 장비가 먼저입니다.',
          address: '${shop.location}, ${shop.country}',
          defaultBlurb: '${shop.productName} · ${shop.amenities.take(2).join(' · ')}',
        );
  }

  static const _byHull = <String, ResortCopy>{
    'bohol-hideout': ResortCopy(
      intro:
          '팡라오 앞바다를 작은 보트로 나갑니다. 발리카삭 조류는 가이드가 읽고, 난파선은 자격과 컨디션이 맞을 때만 엽니다. 깊이 경쟁은 하지 않습니다.',
      address: 'Panglao Island, Bohol, Philippines',
      defaultBlurb: '체크다이브 후 2탱크. 같은 밴이 먼저이고 물속 버디는 샵이 배정합니다.',
      defaultDuration: '오전 반나절',
    ),
    'dahab-bluehole': ResortCopy(
      intro:
          '블루홀은 쇼어로 들어갑니다. 아치 너머는 강사와 컨디션이 맞을 때만, 캐년과 아일랜드는 매일 열립니다.',
      address: 'Blue Hole Road, Dahab, South Sinai, Egypt',
      defaultBlurb: '쇼어 2탱크. 싱글차지를 나누고 싶은 솔로는 같은배에 깃발을 꽂습니다.',
      defaultDuration: '쇼어 반나절',
    ),
    'palau-rock-islands': ResortCopy(
      intro:
          '록아일랜드 채널을 스피드보트로 잇습니다. 밀키웨이는 사진, 블루코너는 조류. 출항은 날씨가 허가할 때만입니다.',
      address: 'Koror, Palau',
      defaultBlurb: '2탱크 펀다이빙. 기상 취소 시 전액 환불이 상품 조건입니다.',
      defaultDuration: '종일',
    ),
  };
}

/// 시드 출발일. 실재고 연동 전까지 상품이 날짜를 갖게 합니다.
abstract final class DepartureCatalog {
  static TourDeparture? of(String shopId) {
    final id = shopId.split('--').first;
    return _byShop[id];
  }

  static final _byShop = <String, TourDeparture>{
    'bohol-hideout': TourDeparture(
      start: DateTime(2026, 10, 3),
      windowLabel: '10.03 – 10.06',
      capacity: 6,
      bookedSeats: 4,
      lookingSeats: 1,
    ),
    'dahab-bluehole': TourDeparture(
      start: DateTime(2026, 9, 20),
      windowLabel: '09.20 – 09.23',
      capacity: 4,
      bookedSeats: 3,
      lastCall: true,
      soloShare: true,
    ),
    'kerama-okinawa': TourDeparture(
      start: DateTime(2026, 10, 11),
      windowLabel: '10.11 – 10.12',
      capacity: 6,
      bookedSeats: 2,
      lookingSeats: 2,
    ),
    'similan-liveaboard': TourDeparture(
      start: DateTime(2026, 11, 8),
      windowLabel: '11.08 – 11.11',
      capacity: 12,
      bookedSeats: 9,
      lastCall: true,
    ),
    'palau-rock-islands': TourDeparture(
      start: DateTime(2026, 12, 8),
      windowLabel: '12.08 – 12.14',
      capacity: 6,
      bookedSeats: 5,
      lastCall: true,
    ),
    'komodo-comel': TourDeparture(
      start: DateTime(2026, 11, 2),
      windowLabel: '11.02 – 11.05',
      capacity: 8,
      bookedSeats: 5,
      lookingSeats: 2,
      soloShare: true,
    ),
    'sipadan-borneo': TourDeparture(
      start: DateTime(2026, 10, 18),
      windowLabel: '10.18 – 10.21',
      capacity: 6,
      bookedSeats: 3,
    ),
    'raja-ampat': TourDeparture(
      start: DateTime(2026, 11, 16),
      windowLabel: '11.16 – 11.22',
      capacity: 8,
      bookedSeats: 6,
      lastCall: true,
    ),
    'cozumel-reef': TourDeparture(
      start: DateTime(2026, 10, 24),
      windowLabel: '10.24 – 10.26',
      capacity: 6,
      bookedSeats: 2,
    ),
    'cairns-gbr': TourDeparture(
      start: DateTime(2026, 10, 9),
      windowLabel: '10.09 – 10.12',
      capacity: 8,
      bookedSeats: 4,
    ),
    'maldives-ari': TourDeparture(
      start: DateTime(2026, 11, 20),
      windowLabel: '11.20 – 11.26',
      capacity: 10,
      bookedSeats: 7,
    ),
    'malta-gozo': TourDeparture(
      start: DateTime(2026, 10, 15),
      windowLabel: '10.15 – 10.17',
      capacity: 6,
      bookedSeats: 1,
    ),
  };
}
