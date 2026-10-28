import 'package:dive_travel_app/core/models/dive_shop.dart';

/// Six travel-product regions. The atlas rail and the row list share these ids.
abstract final class TravelRegionId {
  static const all = 'all';
  static const asia = 'asia';
  static const pacific = 'pacific';
  static const europe = 'europe';
  static const africa = 'africa';
  static const northAmerica = 'northAmerica';
  static const southAmerica = 'southAmerica';

  static const menu = <String>[
    all,
    asia,
    pacific,
    europe,
    africa,
    northAmerica,
    southAmerica,
  ];
}

/// Optional sea tag. A country may have none.
abstract final class TravelSea {
  static const indian = 'indian';
  static const red = 'red';
  static const caribbean = 'caribbean';
  static const southPacific = 'southPacific';

  static const all = <String>[indian, red, caribbean, southPacific];
}

/// Pacific sub-area. [other] is Australia and New Zealand.
abstract final class TravelZone {
  static const micronesia = 'micronesia';
  static const melanesia = 'melanesia';
  static const polynesia = 'polynesia';
  static const other = 'other';
}

class TravelCountry {
  const TravelCountry({
    required this.id,
    required this.name,
    required this.regionId,
    this.zone,
    this.sea,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final String regionId;
  final String? zone;
  final String? sea;
  final List<String> aliases;
}

/// Country master for the travel tab. One region each, optional sea, aliases.
abstract final class TravelCountryMaster {
  static const countries = <TravelCountry>[
    // 아시아
    TravelCountry(
      id: 'korea',
      name: '한국',
      regionId: TravelRegionId.asia,
      aliases: ['대한민국', 'korea', 'south korea'],
    ),
    TravelCountry(
      id: 'japan',
      name: '일본',
      regionId: TravelRegionId.asia,
      aliases: ['japan'],
    ),
    TravelCountry(
      id: 'philippines',
      name: '필리핀',
      regionId: TravelRegionId.asia,
      aliases: ['philippines'],
    ),
    TravelCountry(
      id: 'indonesia',
      name: '인도네시아',
      regionId: TravelRegionId.asia,
      aliases: ['indonesia'],
    ),
    TravelCountry(
      id: 'malaysia',
      name: '말레이시아',
      regionId: TravelRegionId.asia,
      aliases: ['malaysia'],
    ),
    TravelCountry(
      id: 'thailand',
      name: '태국',
      regionId: TravelRegionId.asia,
      aliases: ['thailand'],
    ),
    TravelCountry(
      id: 'maldives',
      name: '몰디브',
      regionId: TravelRegionId.asia,
      sea: TravelSea.indian,
      aliases: ['maldives'],
    ),
    TravelCountry(
      id: 'india',
      name: '인도',
      regionId: TravelRegionId.asia,
      sea: TravelSea.indian,
      aliases: ['india'],
    ),
    TravelCountry(
      id: 'timor',
      name: '동티모르',
      regionId: TravelRegionId.asia,
      aliases: ['timor-leste', 'east timor', '티모르'],
    ),
    TravelCountry(
      id: 'vietnam',
      name: '베트남',
      regionId: TravelRegionId.asia,
      aliases: ['vietnam'],
    ),
    TravelCountry(
      id: 'sriLanka',
      name: '스리랑카',
      regionId: TravelRegionId.asia,
      sea: TravelSea.indian,
      aliases: ['sri lanka'],
    ),
    TravelCountry(
      id: 'myanmar',
      name: '미얀마',
      regionId: TravelRegionId.asia,
      aliases: ['myanmar', '버마', 'burma'],
    ),
    TravelCountry(
      id: 'taiwan',
      name: '대만',
      regionId: TravelRegionId.asia,
      aliases: ['taiwan'],
    ),

    // 태평양·오세아니아 — 미크로네시아
    TravelCountry(
      id: 'palau',
      name: '팔라우',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.micronesia,
      aliases: ['palau'],
    ),
    TravelCountry(
      id: 'yap',
      name: '얍',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.micronesia,
      aliases: ['yap'],
    ),
    TravelCountry(
      id: 'chuuk',
      name: '추크',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.micronesia,
      aliases: ['트럭', '트룩', '축', 'chuuk', 'truk'],
    ),
    TravelCountry(
      id: 'pohnpei',
      name: '폰페이',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.micronesia,
      aliases: ['pohnpei', '폰페이'],
    ),
    TravelCountry(
      id: 'guam',
      name: '괌',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.micronesia,
      aliases: ['guam'],
    ),
    TravelCountry(
      id: 'northernMariana',
      name: '북마리아나',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.micronesia,
      aliases: ['사이판', '로타', '사이판·로타', 'saipan', 'rota', 'northern mariana'],
    ),
    TravelCountry(
      id: 'marshall',
      name: '마셜',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.micronesia,
      aliases: ['마셜제도', 'marshall', 'marshall islands'],
    ),

    // 멜라네시아
    TravelCountry(
      id: 'fiji',
      name: '피지',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.melanesia,
      sea: TravelSea.southPacific,
      aliases: ['fiji'],
    ),
    TravelCountry(
      id: 'png',
      name: '파푸아뉴기니',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.melanesia,
      aliases: ['papua new guinea', 'png'],
    ),
    TravelCountry(
      id: 'solomon',
      name: '솔로몬',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.melanesia,
      aliases: ['솔로몬제도', 'solomon', 'solomon islands'],
    ),
    TravelCountry(
      id: 'vanuatu',
      name: '바누아투',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.melanesia,
      sea: TravelSea.southPacific,
      aliases: ['vanuatu'],
    ),
    TravelCountry(
      id: 'newCaledonia',
      name: '뉴칼레도니아',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.melanesia,
      aliases: ['new caledonia'],
    ),

    // 폴리네시아
    TravelCountry(
      id: 'frenchPolynesia',
      name: '프랑스령 폴리네시아',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.polynesia,
      sea: TravelSea.southPacific,
      aliases: [
        '프랑스령폴리네시아',
        '타히티',
        '보라보라',
        'tahiti',
        'bora bora',
        'french polynesia',
      ],
    ),
    TravelCountry(
      id: 'tonga',
      name: '통가',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.polynesia,
      sea: TravelSea.southPacific,
      aliases: ['tonga'],
    ),
    TravelCountry(
      id: 'cook',
      name: '쿡제도',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.polynesia,
      sea: TravelSea.southPacific,
      aliases: ['쿡 제도', 'cook islands'],
    ),

    // 그 밖
    TravelCountry(
      id: 'australia',
      name: '호주',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.other,
      aliases: ['오스트레일리아', 'australia'],
    ),
    TravelCountry(
      id: 'newZealand',
      name: '뉴질랜드',
      regionId: TravelRegionId.pacific,
      zone: TravelZone.other,
      aliases: ['new zealand'],
    ),

    // 유럽
    TravelCountry(
      id: 'malta',
      name: '몰타',
      regionId: TravelRegionId.europe,
      aliases: ['malta'],
    ),
    TravelCountry(
      id: 'greece',
      name: '그리스',
      regionId: TravelRegionId.europe,
      aliases: ['greece'],
    ),
    TravelCountry(
      id: 'italy',
      name: '이탈리아',
      regionId: TravelRegionId.europe,
      aliases: ['italy'],
    ),
    TravelCountry(
      id: 'spain',
      name: '스페인',
      regionId: TravelRegionId.europe,
      aliases: ['spain'],
    ),
    TravelCountry(
      id: 'portugal',
      name: '포르투갈',
      regionId: TravelRegionId.europe,
      aliases: ['portugal'],
    ),
    TravelCountry(
      id: 'croatia',
      name: '크로아티아',
      regionId: TravelRegionId.europe,
      aliases: ['croatia'],
    ),
    TravelCountry(
      id: 'cyprus',
      name: '키프로스',
      regionId: TravelRegionId.europe,
      aliases: ['cyprus'],
    ),
    TravelCountry(
      id: 'norway',
      name: '노르웨이',
      regionId: TravelRegionId.europe,
      aliases: ['norway'],
    ),
    TravelCountry(
      id: 'turkiye',
      name: '튀르키예',
      regionId: TravelRegionId.europe,
      aliases: ['터키', 'turkey', 'turkiye'],
    ),
    TravelCountry(
      id: 'france',
      name: '프랑스',
      regionId: TravelRegionId.europe,
      aliases: ['france'],
    ),
    TravelCountry(
      id: 'uk',
      name: '영국',
      regionId: TravelRegionId.europe,
      aliases: ['uk', 'united kingdom', 'britain'],
    ),
    TravelCountry(
      id: 'iceland',
      name: '아이슬란드',
      regionId: TravelRegionId.europe,
      aliases: ['iceland'],
    ),

    // 아프리카·홍해
    TravelCountry(
      id: 'egypt',
      name: '이집트',
      regionId: TravelRegionId.africa,
      sea: TravelSea.red,
      aliases: ['egypt'],
    ),
    TravelCountry(
      id: 'southAfrica',
      name: '남아공',
      regionId: TravelRegionId.africa,
      aliases: ['남아프리카', 'south africa'],
    ),
    TravelCountry(
      id: 'mozambique',
      name: '모잠비크',
      regionId: TravelRegionId.africa,
      sea: TravelSea.indian,
      aliases: ['mozambique'],
    ),
    TravelCountry(
      id: 'tanzania',
      name: '탄자니아',
      regionId: TravelRegionId.africa,
      sea: TravelSea.indian,
      aliases: ['tanzania'],
    ),
    TravelCountry(
      id: 'kenya',
      name: '케냐',
      regionId: TravelRegionId.africa,
      aliases: ['kenya'],
    ),
    TravelCountry(
      id: 'seychelles',
      name: '세이셸',
      regionId: TravelRegionId.africa,
      sea: TravelSea.indian,
      aliases: ['seychelles'],
    ),
    TravelCountry(
      id: 'mauritius',
      name: '모리셔스',
      regionId: TravelRegionId.africa,
      sea: TravelSea.indian,
      aliases: ['mauritius'],
    ),
    TravelCountry(
      id: 'madagascar',
      name: '마다가스카르',
      regionId: TravelRegionId.africa,
      sea: TravelSea.indian,
      aliases: ['madagascar'],
    ),
    TravelCountry(
      id: 'sudan',
      name: '수단',
      regionId: TravelRegionId.africa,
      sea: TravelSea.red,
      aliases: ['sudan'],
    ),
    TravelCountry(
      id: 'djibouti',
      name: '지부티',
      regionId: TravelRegionId.africa,
      sea: TravelSea.red,
      aliases: ['djibouti'],
    ),
    TravelCountry(
      id: 'capeVerde',
      name: '카보베르데',
      regionId: TravelRegionId.africa,
      aliases: ['cape verde', 'cabo verde'],
    ),

    // 북·중미
    TravelCountry(
      id: 'usa',
      name: '미국',
      regionId: TravelRegionId.northAmerica,
      aliases: ['usa', 'united states', '하와이', 'hawaii'],
    ),
    TravelCountry(
      id: 'mexico',
      name: '멕시코',
      regionId: TravelRegionId.northAmerica,
      aliases: ['mexico'],
    ),
    TravelCountry(
      id: 'bahamas',
      name: '바하마',
      regionId: TravelRegionId.northAmerica,
      sea: TravelSea.caribbean,
      aliases: ['bahamas'],
    ),
    TravelCountry(
      id: 'belize',
      name: '벨리즈',
      regionId: TravelRegionId.northAmerica,
      sea: TravelSea.caribbean,
      aliases: ['belize'],
    ),
    TravelCountry(
      id: 'honduras',
      name: '온두라스',
      regionId: TravelRegionId.northAmerica,
      sea: TravelSea.caribbean,
      aliases: ['honduras'],
    ),
    TravelCountry(
      id: 'cayman',
      name: '케이맨',
      regionId: TravelRegionId.northAmerica,
      sea: TravelSea.caribbean,
      aliases: ['케이맨제도', 'cayman'],
    ),
    TravelCountry(
      id: 'bonaire',
      name: '보네르',
      regionId: TravelRegionId.northAmerica,
      sea: TravelSea.caribbean,
      aliases: ['보나이어', 'bonaire'],
    ),
    TravelCountry(
      id: 'costaRica',
      name: '코스타리카',
      regionId: TravelRegionId.northAmerica,
      sea: TravelSea.caribbean,
      aliases: ['코코스', 'cocos', 'costa rica'],
    ),
    TravelCountry(
      id: 'panama',
      name: '파나마',
      regionId: TravelRegionId.northAmerica,
      sea: TravelSea.caribbean,
      aliases: ['panama'],
    ),
    TravelCountry(
      id: 'dominican',
      name: '도미니카공화국',
      regionId: TravelRegionId.northAmerica,
      sea: TravelSea.caribbean,
      aliases: ['도미니카 공화국', 'dominican republic'],
    ),
    TravelCountry(
      id: 'cuba',
      name: '쿠바',
      regionId: TravelRegionId.northAmerica,
      sea: TravelSea.caribbean,
      aliases: ['cuba'],
    ),
    TravelCountry(
      id: 'turks',
      name: '터크스케이커스',
      regionId: TravelRegionId.northAmerica,
      sea: TravelSea.caribbean,
      aliases: ['터크스 케이커스', 'turks and caicos'],
    ),
    TravelCountry(
      id: 'curacao',
      name: '퀴라소',
      regionId: TravelRegionId.northAmerica,
      sea: TravelSea.caribbean,
      aliases: ['쿠라사오', 'curacao', 'curaçao'],
    ),
    TravelCountry(
      id: 'canada',
      name: '캐나다',
      regionId: TravelRegionId.northAmerica,
      aliases: ['canada'],
    ),

    // 남미
    TravelCountry(
      id: 'ecuador',
      name: '에콰도르',
      regionId: TravelRegionId.southAmerica,
      aliases: ['갈라파고스', 'galapagos', 'ecuador'],
    ),
    TravelCountry(
      id: 'colombia',
      name: '콜롬비아',
      regionId: TravelRegionId.southAmerica,
      aliases: ['colombia'],
    ),
    TravelCountry(
      id: 'brazil',
      name: '브라질',
      regionId: TravelRegionId.southAmerica,
      aliases: ['brazil'],
    ),
    TravelCountry(
      id: 'chile',
      name: '칠레',
      regionId: TravelRegionId.southAmerica,
      aliases: ['chile'],
    ),
    TravelCountry(
      id: 'peru',
      name: '페루',
      regionId: TravelRegionId.southAmerica,
      aliases: ['peru'],
    ),
    TravelCountry(
      id: 'argentina',
      name: '아르헨티나',
      regionId: TravelRegionId.southAmerica,
      aliases: ['argentina'],
    ),
  ];

  /// Zone names are not countries. They still resolve to the Pacific region.
  static const zoneLabels = <String, String>{
    '미크로네시아': TravelRegionId.pacific,
    '마이크로네시아': TravelRegionId.pacific,
    'micronesia': TravelRegionId.pacific,
    '멜라네시아': TravelRegionId.pacific,
    'melanesia': TravelRegionId.pacific,
    '폴리네시아': TravelRegionId.pacific,
    'polynesia': TravelRegionId.pacific,
  };

  static const _seaOnly = ['인도양', '홍해', '카리브해', '남태평양'];

  static TravelCountry? match(String raw) {
    final query = _normalize(raw);
    if (query.isEmpty || _isSeaOnly(query)) {
      return null;
    }
    TravelCountry? best;
    var bestScore = 0;
    for (final country in countries) {
      for (final alias in [country.name, ...country.aliases]) {
        final needle = _normalize(alias);
        if (needle.length < 2) {
          continue;
        }
        if (query.contains(needle) && needle.length > bestScore) {
          bestScore = needle.length;
          best = country;
        }
      }
    }
    return best;
  }

  /// Country alias first. A bare zone name such as 미크로네시아 still maps.
  static String? regionIdFor(String raw) {
    return match(raw)?.regionId ?? _zoneRegion(raw);
  }

  static String? _zoneRegion(String raw) {
    final query = _normalize(raw);
    if (query.isEmpty || _isSeaOnly(query)) {
      return null;
    }
    String? best;
    var bestScore = 0;
    for (final entry in zoneLabels.entries) {
      final needle = _normalize(entry.key);
      if (needle.length >= 2 &&
          query.contains(needle) &&
          needle.length > bestScore) {
        bestScore = needle.length;
        best = entry.value;
      }
    }
    return best;
  }

  static bool _isSeaOnly(String query) {
    for (final sea in _seaOnly) {
      if (query == _normalize(sea)) {
        return true;
      }
    }
    return false;
  }

  /// Countries whose name or alias contains [raw]. Empty text returns the full list.
  static List<TravelCountry> search(String raw) {
    final needle = _normalize(raw);
    if (needle.isEmpty) {
      return countries;
    }
    return [
      for (final country in countries)
        if (_normalize(country.name).contains(needle) ||
            country.aliases.any((alias) => _normalize(alias).contains(needle)))
          country,
    ];
  }

  /// Alias that contains [raw], when the country name itself does not.
  static String? aliasHit(TravelCountry country, String raw) {
    final needle = _normalize(raw);
    if (needle.isEmpty || _normalize(country.name).contains(needle)) {
      return null;
    }
    for (final alias in country.aliases) {
      if (_normalize(alias).contains(needle)) {
        return alias;
      }
    }
    return null;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s\-_,./·]+'), '');
  }
}

/// A listed country, ignoring bare zone names such as 미크로네시아.
TravelCountry? travelCountryForShop(DiveShop shop) {
  for (final raw in [shop.country, shop.location, ...shop.sites]) {
    final country = TravelCountryMaster.match(raw);
    if (country != null) {
      return country;
    }
  }
  return null;
}

/// Match a shop's country, then its place text, against the master list.
String? travelRegionForShop(DiveShop shop) {
  final country = travelCountryForShop(shop);
  if (country != null) {
    return country.regionId;
  }
  for (final raw in [shop.country, shop.location, ...shop.sites]) {
    final id = TravelCountryMaster.regionIdFor(raw);
    if (id != null) {
      return id;
    }
  }
  return null;
}
