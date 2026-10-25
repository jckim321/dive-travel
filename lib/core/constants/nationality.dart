/// Easy-Korean consent copy for optional nationality.
/// Edit this string when the legal wording changes.
const String nationalityConsentKo =
    '국적은 관리자 통계에만 씁니다. 다른 회원에게는 보이지 않고, 고르지 않으면 저장하지 않습니다.';

class Nationality {
  const Nationality(this.code, this.nameKo);

  final String code;
  final String nameKo;
}

/// ISO country codes with Korean labels. Korea stays first in [nationalityChoices].
const List<Nationality> nationalities = [
  Nationality('KR', '대한민국'),
  Nationality('JP', '일본'),
  Nationality('CN', '중국'),
  Nationality('TW', '대만'),
  Nationality('HK', '홍콩'),
  Nationality('MO', '마카오'),
  Nationality('US', '미국'),
  Nationality('CA', '캐나다'),
  Nationality('MX', '멕시코'),
  Nationality('GB', '영국'),
  Nationality('IE', '아일랜드'),
  Nationality('FR', '프랑스'),
  Nationality('DE', '독일'),
  Nationality('IT', '이탈리아'),
  Nationality('ES', '스페인'),
  Nationality('PT', '포르투갈'),
  Nationality('NL', '네덜란드'),
  Nationality('BE', '벨기에'),
  Nationality('CH', '스위스'),
  Nationality('AT', '오스트리아'),
  Nationality('SE', '스웨덴'),
  Nationality('NO', '노르웨이'),
  Nationality('DK', '덴마크'),
  Nationality('FI', '핀란드'),
  Nationality('PL', '폴란드'),
  Nationality('CZ', '체코'),
  Nationality('HU', '헝가리'),
  Nationality('GR', '그리스'),
  Nationality('RU', '러시아'),
  Nationality('UA', '우크라이나'),
  Nationality('TR', '튀르키예'),
  Nationality('IL', '이스라엘'),
  Nationality('AE', '아랍에미리트'),
  Nationality('SA', '사우디아라비아'),
  Nationality('IN', '인도'),
  Nationality('NP', '네팔'),
  Nationality('LK', '스리랑카'),
  Nationality('TH', '태국'),
  Nationality('VN', '베트남'),
  Nationality('LA', '라오스'),
  Nationality('KH', '캄보디아'),
  Nationality('MM', '미얀마'),
  Nationality('MY', '말레이시아'),
  Nationality('SG', '싱가포르'),
  Nationality('ID', '인도네시아'),
  Nationality('PH', '필리핀'),
  Nationality('BN', '브루나이'),
  Nationality('AU', '호주'),
  Nationality('NZ', '뉴질랜드'),
  Nationality('PG', '파푸아뉴기니'),
  Nationality('FJ', '피지'),
  Nationality('BR', '브라질'),
  Nationality('AR', '아르헨티나'),
  Nationality('CL', '칠레'),
  Nationality('PE', '페루'),
  Nationality('ZA', '남아프리카공화국'),
  Nationality('EG', '이집트'),
  Nationality('MA', '모로코'),
  Nationality('KE', '케냐'),
  Nationality('MN', '몽골'),
  Nationality('KZ', '카자흐스탄'),
];

/// Korea first, then the rest by Korean name.
List<Nationality> nationalityChoices() {
  final rest = [
    for (final item in nationalities)
      if (item.code != 'KR') item,
  ]..sort((a, b) => a.nameKo.compareTo(b.nameKo));
  return [
    nationalities.firstWhere((item) => item.code == 'KR'),
    ...rest,
  ];
}

/// Empty or unknown codes become null so nothing is stored.
String? normalizeNationalityCode(String? raw) {
  final code = (raw ?? '').trim().toUpperCase();
  if (code.isEmpty) {
    return null;
  }
  for (final item in nationalities) {
    if (item.code == code) {
      return code;
    }
  }
  return null;
}

String nationalityNameKo(String code) {
  for (final item in nationalities) {
    if (item.code == code) {
      return item.nameKo;
    }
  }
  return code;
}
