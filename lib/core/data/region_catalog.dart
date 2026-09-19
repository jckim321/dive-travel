import 'package:dive_travel_app/core/models/dive_region.dart';

/// 지명 → 실제 위경도. 카탈로그에 없는 이름은 더 이상 해시로 찍지 않습니다.
abstract final class RegionCatalog {
  static const known = <DiveRegion>[
    DiveRegion(
      id: 'bohol',
      name: '필리핀 보홀',
      latitude: 9.83,
      longitude: 124.14,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'cebu',
      name: '필리핀 세부',
      latitude: 10.29,
      longitude: 123.90,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'malapascua',
      name: '필리핀 말라파스쿠아',
      latitude: 11.33,
      longitude: 124.12,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'coron',
      name: '필리핀 코론',
      latitude: 12.00,
      longitude: 120.20,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'el-nido',
      name: '필리핀 엘니도',
      latitude: 11.18,
      longitude: 119.39,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'anilao',
      name: '필리핀 아닐라오',
      latitude: 13.76,
      longitude: 120.89,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'puerto-galera',
      name: '필리핀 푸에르토갈레라',
      latitude: 13.50,
      longitude: 120.95,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'moalboal',
      name: '필리핀 모알보알',
      latitude: 9.94,
      longitude: 123.40,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'dumaguete',
      name: '필리핀 두마게테',
      latitude: 9.31,
      longitude: 123.31,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'apo-island',
      name: '필리핀 아포섬',
      latitude: 9.08,
      longitude: 123.27,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'tubbataha',
      name: '필리핀 투바타하',
      latitude: 8.85,
      longitude: 119.92,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'boracay',
      name: '필리핀 보라카이',
      latitude: 11.97,
      longitude: 121.92,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'okinawa',
      name: '일본 오키나와',
      latitude: 26.33,
      longitude: 127.80,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'ishigaki',
      name: '일본 이시가키',
      latitude: 24.34,
      longitude: 124.16,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'miyako',
      name: '일본 미야코',
      latitude: 24.80,
      longitude: 125.28,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'kerama',
      name: '일본 케라마',
      latitude: 26.20,
      longitude: 127.35,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'yonaguni',
      name: '일본 요나구니',
      latitude: 24.45,
      longitude: 123.00,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'jeju',
      name: '한국 제주',
      latitude: 33.38,
      longitude: 126.54,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'dahab',
      name: '이집트 다합',
      latitude: 28.50,
      longitude: 34.52,
      logCount: 0,
      continent: ContinentId.africa,
    ),
    DiveRegion(
      id: 'sharm',
      name: '이집트 샤름엘셰이크',
      latitude: 27.92,
      longitude: 34.33,
      logCount: 0,
      continent: ContinentId.africa,
    ),
    DiveRegion(
      id: 'hurghada',
      name: '이집트 후르가다',
      latitude: 27.26,
      longitude: 33.81,
      logCount: 0,
      continent: ContinentId.africa,
    ),
    DiveRegion(
      id: 'marsa-alam',
      name: '이집트 마르사알람',
      latitude: 25.07,
      longitude: 34.90,
      logCount: 0,
      continent: ContinentId.africa,
    ),
    DiveRegion(
      id: 'similan',
      name: '태국 시밀란',
      latitude: 8.65,
      longitude: 97.65,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'phuket',
      name: '태국 푸켓',
      latitude: 7.88,
      longitude: 98.39,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'koh-tao',
      name: '태국 코타오',
      latitude: 10.10,
      longitude: 99.84,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'palau',
      name: '팔라우',
      latitude: 7.33,
      longitude: 134.48,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'yap',
      name: '얍',
      latitude: 9.52,
      longitude: 138.13,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'chuuk',
      name: '축(트룩)',
      latitude: 7.45,
      longitude: 151.85,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'guam',
      name: '괌',
      latitude: 13.44,
      longitude: 144.79,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'saipan',
      name: '사이판',
      latitude: 15.21,
      longitude: 145.75,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'sipadan',
      name: '말레이시아 시파단',
      latitude: 4.11,
      longitude: 118.63,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'mabul',
      name: '말레이시아 마불',
      latitude: 4.25,
      longitude: 118.63,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'tioman',
      name: '말레이시아 티오만',
      latitude: 2.79,
      longitude: 104.17,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'komodo',
      name: '인도네시아 코모도',
      latitude: -8.55,
      longitude: 119.49,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'raja-ampat',
      name: '인도네시아 라자암팟',
      latitude: -0.58,
      longitude: 130.51,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'bali',
      name: '인도네시아 발리',
      latitude: -8.41,
      longitude: 115.19,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'gili',
      name: '인도네시아 길리',
      latitude: -8.35,
      longitude: 116.07,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'bunaken',
      name: '인도네시아 부나켄',
      latitude: 1.61,
      longitude: 124.76,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'lembeh',
      name: '인도네시아 렘베',
      latitude: 1.44,
      longitude: 125.23,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'wakatobi',
      name: '인도네시아 와카토비',
      latitude: -5.32,
      longitude: 123.59,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'maldives',
      name: '몰디브',
      latitude: 3.20,
      longitude: 73.22,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'andaman',
      name: '인도 안다만',
      latitude: 11.74,
      longitude: 92.72,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'nha-trang',
      name: '베트남 나트랑',
      latitude: 12.24,
      longitude: 109.20,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'cozumel',
      name: '멕시코 코수멜',
      latitude: 20.42,
      longitude: -86.92,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'cabo',
      name: '멕시코 카보',
      latitude: 22.89,
      longitude: -109.91,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'socorro',
      name: '멕시코 소코로',
      latitude: 18.78,
      longitude: -110.95,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'galapagos',
      name: '갈라파고스',
      latitude: -0.95,
      longitude: -90.97,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'belize',
      name: '벨리즈',
      latitude: 17.31,
      longitude: -87.53,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'roatan',
      name: '온두라스 로아탄',
      latitude: 16.35,
      longitude: -86.50,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'bonaire',
      name: '보나이어',
      latitude: 12.20,
      longitude: -68.26,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'cayman',
      name: '케이맨',
      latitude: 19.30,
      longitude: -81.25,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'bahamas',
      name: '바하마',
      latitude: 24.55,
      longitude: -77.78,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'florida-keys',
      name: '플로리다키',
      latitude: 24.70,
      longitude: -81.05,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'hawaii-kona',
      name: '하와이 코나',
      latitude: 19.64,
      longitude: -155.99,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'maui',
      name: '하와이 마우이',
      latitude: 20.80,
      longitude: -156.33,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'gbr-cairns',
      name: '호주 케언스',
      latitude: -16.92,
      longitude: 145.78,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'ningaloo',
      name: '호주 닝갈루',
      latitude: -22.70,
      longitude: 113.65,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'fiji',
      name: '피지',
      latitude: -17.71,
      longitude: 178.07,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'rangiroa',
      name: '랑기로아',
      latitude: -15.13,
      longitude: -147.64,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'fakarava',
      name: '파카라바',
      latitude: -16.35,
      longitude: -145.60,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'png-kimbe',
      name: '파푸아뉴기니 킴베',
      latitude: -5.55,
      longitude: 150.14,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'solomon',
      name: '솔로몬제도',
      latitude: -9.43,
      longitude: 160.00,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'aliwal',
      name: '남아공 알리왈',
      latitude: -30.26,
      longitude: 30.82,
      logCount: 0,
      continent: ContinentId.africa,
    ),
    DiveRegion(
      id: 'nosy-be',
      name: '마다가스카르 노시베',
      latitude: -13.32,
      longitude: 48.27,
      logCount: 0,
      continent: ContinentId.africa,
    ),
    DiveRegion(
      id: 'seychelles',
      name: '세이셸',
      latitude: -4.68,
      longitude: 55.49,
      logCount: 0,
      continent: ContinentId.africa,
    ),
    DiveRegion(
      id: 'malta',
      name: '몰타',
      latitude: 35.90,
      longitude: 14.45,
      logCount: 0,
      continent: ContinentId.europe,
    ),
    DiveRegion(
      id: 'gozo',
      name: '고조',
      latitude: 36.04,
      longitude: 14.24,
      logCount: 0,
      continent: ContinentId.europe,
    ),
    DiveRegion(
      id: 'azores',
      name: '아조레스',
      latitude: 38.72,
      longitude: -27.22,
      logCount: 0,
      continent: ContinentId.europe,
    ),
  ];

  static const aliases = <String, List<String>>{
    'bohol': ['필리핀보홀', 'panglao', 'balicasag', '발리카삭', '팡라오', '보홀', 'bohol'],
    'cebu': ['필리핀 세부', 'mactan', '막탄', '세부', 'cebu'],
    'malapascua': ['말라파스쿠아', 'malapascua', '모노섬'],
    'coron': ['코론', 'coron', '버스앙가'],
    'el-nido': ['엘니도', 'el nido', 'elnido'],
    'anilao': ['아닐라오', 'anilao'],
    'puerto-galera': ['푸에르토갈레라', '푸에르토 갈레라', 'puerto galera'],
    'moalboal': ['모알보알', 'moalboal', '판가스'],
    'dumaguete': ['두마게테', 'dumaguete', '다우인'],
    'apo-island': ['아포섬', 'apo island', 'apo'],
    'tubbataha': ['투바타하', 'tubbataha'],
    'boracay': ['보라카이', 'boracay'],
    'okinawa': ['오키나와', 'okinawa', '나하', '온나손'],
    'ishigaki': ['이시가키', 'ishigaki', '야에야마', '만타레이'],
    'miyako': ['미야코', 'miyako'],
    'kerama': ['케라마', 'kerama'],
    'yonaguni': ['요나구니', 'yonaguni'],
    'jeju': ['제주', 'jeju', '서귀포', '김녕'],
    'dahab': ['다합', 'dahab', '블루홀'],
    'sharm': ['샤름', 'sharm', 'ras mohammed', '라스모하메드'],
    'hurghada': ['후르가다', 'hurghada'],
    'marsa-alam': ['마르사알람', 'marsa alam', '엘피네'],
    'similan': ['시밀란', 'similan', '리치혼'],
    'phuket': ['푸켓', 'phuket', '라차노이', '라차야이'],
    'koh-tao': ['코타오', 'koh tao', '타오섬'],
    'palau': ['팔라우', 'palau', '블루코너', '록아일랜드', '저먼채널'],
    'yap': ['얍', 'yap', '만타레이 패스'],
    'chuuk': ['축', '트룩', 'chuuk', 'truk'],
    'guam': ['괌', 'guam', '투몬'],
    'saipan': ['사이판', 'saipan', '마나가하'],
    'sipadan': ['시파단', 'sipadan'],
    'mabul': ['마불', 'mabul', '카팔라이'],
    'tioman': ['티오만', 'tioman'],
    'komodo': ['코모도', 'komodo', '라부안바조', '파다르'],
    'raja-ampat': ['라자암팟', '라자 암팟', 'raja ampat'],
    'bali': ['발리', 'bali', '툴람벤', '누사페니다', '아메드'],
    'gili': ['길리', 'gili', '길리트라왕', '길리메노'],
    'bunaken': ['부나켄', 'bunaken', '마나도'],
    'lembeh': ['렘베', 'lembeh'],
    'wakatobi': ['와카토비', 'wakatobi'],
    'maldives': ['몰디브', 'maldives', '아리환초', '바아환초'],
    'andaman': ['안다만', 'andaman', '하브록'],
    'nha-trang': ['나트랑', 'nha trang', '윈아일랜드'],
    'cozumel': ['코수멜', '코멜', 'cozumel', '코즈멜'],
    'cabo': ['카보', 'cabo', '로스카보스'],
    'socorro': ['소코로', 'socorro', '레비야히헤도'],
    'galapagos': ['갈라파고스', 'galapagos', '다윈섬', '울프섬'],
    'belize': ['벨리즈', 'belize', '블루홀 벨리즈'],
    'roatan': ['로아탄', 'roatan', '유틸라'],
    'bonaire': ['보나이어', 'bonaire'],
    'cayman': ['케이맨', 'cayman', '그랜드케이맨'],
    'bahamas': ['바하마', 'bahamas', '타이거비치'],
    'florida-keys': ['플로리다키', 'florida keys', '키웨스트'],
    'hawaii-kona': ['하와이코나', '코나', 'kona', '빅아일랜드'],
    'maui': ['하와이마우이', '마우이', 'maui', '몰로키니'],
    'gbr-cairns': ['케언스', 'cairns', '그레이트배리어리프', '대보초', '포트더글라스'],
    'ningaloo': ['닝갈루', 'ningaloo'],
    'fiji': ['피지', 'fiji', '베카', '타베우니'],
    'rangiroa': ['랑기로아', 'rangiroa'],
    'fakarava': ['파카라바', 'fakarava'],
    'png-kimbe': ['킴베', 'kimbe', '파푸아뉴기니', 'png'],
    'solomon': ['솔로몬', 'solomon'],
    'aliwal': ['알리왈', 'aliwal', '사드와나'],
    'nosy-be': ['노시베', 'nosy be'],
    'seychelles': ['세이셸', 'seychelles'],
    'malta': ['몰타', 'malta'],
    'gozo': ['고조', 'gozo'],
    'azores': ['아조레스', 'azores'],
  };

  static const _siteCountries = <String, String>{
    'bohol': '필리핀',
    'cebu': '필리핀',
    'malapascua': '필리핀',
    'coron': '필리핀',
    'el-nido': '필리핀',
    'anilao': '필리핀',
    'puerto-galera': '필리핀',
    'moalboal': '필리핀',
    'dumaguete': '필리핀',
    'apo-island': '필리핀',
    'tubbataha': '필리핀',
    'boracay': '필리핀',
    'okinawa': '일본',
    'ishigaki': '일본',
    'miyako': '일본',
    'kerama': '일본',
    'yonaguni': '일본',
    'jeju': '한국',
    'dahab': '이집트',
    'sharm': '이집트',
    'hurghada': '이집트',
    'marsa-alam': '이집트',
    'similan': '태국',
    'phuket': '태국',
    'koh-tao': '태국',
    'palau': '팔라우',
    'yap': '미크로네시아',
    'chuuk': '미크로네시아',
    'guam': '괌',
    'saipan': '사이판',
    'sipadan': '말레이시아',
    'mabul': '말레이시아',
    'tioman': '말레이시아',
    'komodo': '인도네시아',
    'raja-ampat': '인도네시아',
    'bali': '인도네시아',
    'gili': '인도네시아',
    'bunaken': '인도네시아',
    'lembeh': '인도네시아',
    'wakatobi': '인도네시아',
    'maldives': '몰디브',
    'andaman': '인도',
    'nha-trang': '베트남',
    'cozumel': '멕시코',
    'cabo': '멕시코',
    'socorro': '멕시코',
    'galapagos': '에콰도르',
    'belize': '벨리즈',
    'roatan': '온두라스',
    'bonaire': '보나이어',
    'cayman': '케이맨',
    'bahamas': '바하마',
    'florida-keys': '미국',
    'hawaii-kona': '하와이',
    'maui': '하와이',
    'gbr-cairns': '호주',
    'ningaloo': '호주',
    'fiji': '피지',
    'rangiroa': '프랑스령폴리네시아',
    'fakarava': '프랑스령폴리네시아',
    'png-kimbe': '파푸아뉴기니',
    'solomon': '솔로몬제도',
    'aliwal': '남아공',
    'nosy-be': '마다가스카르',
    'seychelles': '세이셸',
    'malta': '몰타',
    'gozo': '몰타',
    'azores': '포르투갈',
  };

  static const _countryFallbacks = <DiveRegion>[
    DiveRegion(
      id: 'philippines',
      name: '필리핀',
      latitude: 11.50,
      longitude: 123.50,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'japan',
      name: '일본',
      latitude: 26.20,
      longitude: 127.70,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'korea',
      name: '한국',
      latitude: 33.38,
      longitude: 126.54,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'indonesia',
      name: '인도네시아',
      latitude: -2.50,
      longitude: 118.00,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'malaysia',
      name: '말레이시아',
      latitude: 4.20,
      longitude: 118.50,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'thailand',
      name: '태국',
      latitude: 8.00,
      longitude: 98.30,
      logCount: 0,
      continent: ContinentId.asia,
    ),
    DiveRegion(
      id: 'egypt',
      name: '이집트',
      latitude: 27.40,
      longitude: 34.00,
      logCount: 0,
      continent: ContinentId.africa,
    ),
    DiveRegion(
      id: 'mexico',
      name: '멕시코',
      latitude: 20.50,
      longitude: -86.90,
      logCount: 0,
      continent: ContinentId.americas,
    ),
    DiveRegion(
      id: 'australia',
      name: '호주',
      latitude: -16.90,
      longitude: 145.80,
      logCount: 0,
      continent: ContinentId.oceania,
    ),
    DiveRegion(
      id: 'hawaii',
      name: '하와이',
      latitude: 20.80,
      longitude: -156.50,
      logCount: 0,
      continent: ContinentId.americas,
    ),
  ];

  static const _countryAliases = <String, List<String>>{
    'philippines': ['필리핀', 'philippines'],
    'japan': ['일본', 'japan'],
    'korea': ['한국', '대한민국', 'korea'],
    'indonesia': ['인도네시아', 'indonesia'],
    'malaysia': ['말레이시아', 'malaysia'],
    'thailand': ['태국', 'thailand'],
    'egypt': ['이집트', 'egypt', '홍해'],
    'mexico': ['멕시코', 'mexico'],
    'australia': ['호주', '오스트레일리아', 'australia'],
    'hawaii': ['하와이', 'hawaii'],
  };

  static String countryOf(DiveRegion region) {
    final mapped = _siteCountries[region.id];
    if (mapped != null) {
      return mapped;
    }
    for (final country in _countryFallbacks) {
      if (country.id == region.id) {
        return country.name;
      }
    }
    final first = region.name.trim().split(RegExp(r'\s+')).first;
    if (_countryFallbacks.any((item) => item.name == first)) {
      return first;
    }
    return region.name.trim();
  }

  static List<PassportCountry> get passportCountries {
    final seen = <String>{};
    final countries = <PassportCountry>[];
    void add(String name, String continent) {
      if (name.isEmpty || !seen.add(name)) {
        return;
      }
      countries.add(PassportCountry(name: name, continent: continent));
    }

    for (final site in known) {
      add(_siteCountries[site.id] ?? site.name, site.continent);
    }
    for (final country in _countryFallbacks) {
      add(country.name, country.continent);
    }
    return countries;
  }

  static DiveRegion resolve(String rawName, int logCount) {
    final label = rawName.trim();
    final query = _normalize(label);
    final site = _bestMatch(query, known, aliases);
    if (site != null) {
      return site.copyWith(name: label, logCount: logCount);
    }
    final country = _bestMatch(query, _countryFallbacks, _countryAliases);
    if (country != null) {
      return country.copyWith(name: label, logCount: logCount);
    }
    return DiveRegion(
      id: 'region-${label.hashCode}',
      name: label,
      latitude: 0,
      longitude: 0,
      logCount: logCount,
      continent: ContinentId.asia,
    );
  }

  static DiveRegion? _bestMatch(
    String query,
    List<DiveRegion> regions,
    Map<String, List<String>> aliasMap,
  ) {
    var bestScore = 0;
    DiveRegion? best;
    for (final region in regions) {
      final names = <String>[
        region.name,
        ...aliasMap[region.id] ?? const <String>[],
      ];
      for (final alias in names) {
        final needle = _normalize(alias);
        if (needle.length < 2) {
          continue;
        }
        if (query.contains(needle) && needle.length > bestScore) {
          bestScore = needle.length;
          best = region;
        }
      }
    }
    return best;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s\-_,./]+'), '');
  }
}

class PassportCountry {
  const PassportCountry({required this.name, required this.continent});

  final String name;
  final String continent;
}
