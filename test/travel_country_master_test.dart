import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/travel_country_master.dart';

void main() {
  test('나라 마스터는 6권역과 해역·구역·별칭을 가진다', () {
    expect(TravelRegionId.menu, [
      TravelRegionId.all,
      TravelRegionId.asia,
      TravelRegionId.pacific,
      TravelRegionId.europe,
      TravelRegionId.africa,
      TravelRegionId.northAmerica,
      TravelRegionId.southAmerica,
    ]);

    final names = TravelCountryMaster.countries.map((country) => country.name).toSet();
    expect(names, containsAll(const [
      '한국', '일본', '필리핀', '인도네시아', '말레이시아', '태국', '몰디브', '인도', '동티모르',
      '베트남', '스리랑카', '미얀마', '대만',
      '팔라우', '얍', '추크', '폰페이', '괌', '북마리아나', '마셜',
      '피지', '파푸아뉴기니', '솔로몬', '바누아투', '뉴칼레도니아',
      '프랑스령 폴리네시아', '통가', '쿡제도',
      '호주', '뉴질랜드',
      '몰타', '그리스', '이탈리아', '스페인', '포르투갈', '크로아티아', '키프로스', '노르웨이',
      '튀르키예', '프랑스', '영국', '아이슬란드',
      '이집트', '남아공', '모잠비크', '탄자니아', '케냐', '세이셸', '모리셔스', '마다가스카르',
      '수단', '지부티', '카보베르데',
      '미국', '멕시코', '바하마', '벨리즈', '온두라스', '케이맨', '보네르',
      '코스타리카', '파나마', '도미니카공화국', '쿠바', '터크스케이커스', '퀴라소', '캐나다',
      '에콰도르', '콜롬비아', '브라질', '칠레', '페루', '아르헨티나',
    ]));
    expect(names.length, 73);

    for (final country in TravelCountryMaster.countries) {
      expect(TravelRegionId.menu.contains(country.regionId), isTrue);
      expect(country.regionId, isNot(TravelRegionId.all));
      if (country.sea != null) {
        expect(TravelSea.all, contains(country.sea));
      }
      if (country.regionId == TravelRegionId.pacific) {
        expect(country.zone, isNotNull);
      } else {
        expect(country.zone, isNull);
      }
    }

    expect(
      TravelCountryMaster.countries.singleWhere((c) => c.id == 'maldives').sea,
      TravelSea.indian,
    );
    expect(
      TravelCountryMaster.countries.singleWhere((c) => c.id == 'egypt').sea,
      TravelSea.red,
    );
    expect(
      TravelCountryMaster.countries.singleWhere((c) => c.id == 'fiji').sea,
      TravelSea.southPacific,
    );
    expect(
      TravelCountryMaster.countries.singleWhere((c) => c.id == 'bahamas').sea,
      TravelSea.caribbean,
    );
    expect(
      TravelCountryMaster.countries.singleWhere((c) => c.id == 'canada').sea,
      isNull,
    );
    expect(
      TravelCountryMaster.countries.singleWhere((c) => c.id == 'australia').zone,
      TravelZone.other,
    );
    expect(
      TravelCountryMaster.countries.singleWhere((c) => c.id == 'chuuk').zone,
      TravelZone.micronesia,
    );
  });

  test('별칭과 권역 이름은 나라보다 긴 이름이 이기고 권역으로 모인다', () {
    expect(TravelCountryMaster.match('트럭')?.id, 'chuuk');
    expect(TravelCountryMaster.match('하와이')?.id, 'usa');
    expect(TravelCountryMaster.match('하와이')?.regionId, TravelRegionId.northAmerica);
    expect(TravelCountryMaster.match('코코스')?.id, 'costaRica');
    expect(TravelCountryMaster.match('코코스')?.sea, TravelSea.caribbean);
    expect(TravelCountryMaster.match('갈라파고스')?.regionId, TravelRegionId.southAmerica);
    expect(TravelCountryMaster.match('프랑스')?.id, 'france');
    expect(TravelCountryMaster.match('프랑스령 폴리네시아')?.id, 'frenchPolynesia');
    expect(TravelCountryMaster.match('인도네시아')?.id, 'indonesia');
    expect(TravelCountryMaster.match('인도양'), isNull);
    expect(TravelCountryMaster.match('마이크로네시아'), isNull);
    expect(
      TravelCountryMaster.regionIdFor('마이크로네시아'),
      TravelRegionId.pacific,
    );
    expect(
      TravelCountryMaster.regionIdFor('미크로네시아'),
      TravelRegionId.pacific,
    );
    expect(TravelCountryMaster.regionIdFor('폴리네시아'), TravelRegionId.pacific);
    expect(TravelCountryMaster.match('타히티')?.id, 'frenchPolynesia');
    expect(TravelCountryMaster.match('사이판')?.id, 'northernMariana');
  });

  test('검색은 나라 이름과 별칭을 거르고 권역·해역은 고른 나라에 있다', () {
    final byAlias = TravelCountryMaster.search('트럭');
    expect(byAlias.map((country) => country.id), ['chuuk']);
    expect(TravelCountryMaster.aliasHit(byAlias.single, '트럭'), '트럭');
    expect(byAlias.single.regionId, TravelRegionId.pacific);
    expect(byAlias.single.sea, isNull);

    final hawaii = TravelCountryMaster.search('하와이');
    expect(hawaii.map((country) => country.id), ['usa']);
    expect(hawaii.single.regionId, TravelRegionId.northAmerica);

    final maldives = TravelCountryMaster.search('몰디');
    expect(maldives.map((country) => country.id), ['maldives']);
    expect(maldives.single.sea, TravelSea.indian);

    final india = TravelCountryMaster.search('인도');
    expect(india.map((country) => country.id), containsAll(['india', 'indonesia']));

    expect(TravelCountryMaster.search('없는나라'), isEmpty);
    expect(TravelCountryMaster.search(''), TravelCountryMaster.countries);
  });
}
