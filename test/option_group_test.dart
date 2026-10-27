import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/constants/option_group.dart';
import 'package:dive_travel_app/core/models/price_revision.dart';
import 'package:dive_travel_app/core/models/product_content_fingerprint.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

ShopProduct _product(List<ShopProductOption> options) {
  return ShopProduct(
    id: 'p1',
    shopId: 'shop-1',
    name: 'Trip',
    consumerPrice: 100000,
    professionalPrice: 80000,
    publishStatus: ProductPublishStatus.approved,
    active: true,
    options: options,
  );
}

void main() {
  test('그룹이 없는 옛 옵션은 비어 있고 저장 키를 만들지 않는다', () {
    final option = ShopProductOption.fromMap({
      'id': 'old',
      'name': '장비',
      'consumer_price': 10000,
    });
    expect(option.group, '');
    expect(option.toMap().containsKey('group'), isFalse);
  });

  test('알려진 그룹만 저장하고 목록 밖 코드는 비운다', () {
    final gear = ShopProductOption(id: 'g', name: '렌탈', group: 'gear');
    final saved = ShopProductOption.fromMap(gear.toMap());
    expect(saved.group, 'gear');
    expect(saved.toMap()['group'], 'gear');
    expect(optionGroupNameKo('gear'), '장비');

    final unknown = ShopProductOption.fromMap({
      'id': 'x',
      'name': '요트',
      'group': 'yacht',
    });
    expect(unknown.group, '');
    expect(unknown.toMap().containsKey('group'), isFalse);
    expect(optionGroups.map((group) => group.id), [
      'stay',
      'gear',
      'media',
      'transfer',
      'meal',
      'activity',
      'other',
    ]);
  });

  test('이름은 앞쪽 규칙으로 분류하고 못 정하면 기타', () {
    expect(classifyOptionGroup('수중 사진'), 'media');
    expect(classifyOptionGroup('BCD 렌탈'), 'gear');
    expect(classifyOptionGroup('공항 픽업'), 'transfer');
    expect(classifyOptionGroup('저녁'), 'meal');
    expect(classifyOptionGroup('호텔 1박'), 'stay');
    expect(classifyOptionGroup('펀다이빙'), 'activity');
    expect(classifyOptionGroup('골프'), 'activity');
    expect(classifyOptionGroup('스파'), 'activity');
    expect(classifyOptionGroup('마사지'), 'activity');
    expect(classifyOptionGroup('낚시'), 'activity');
    expect(classifyOptionGroup('요가'), 'activity');
    expect(classifyOptionGroup('골프 픽업'), 'transfer');
    expect(classifyOptionGroup('요트'), 'other');
    expect(classifyOptionGroup(''), 'other');
    expect(classifyOptionGroup('  '), 'other');
  });

  test('그룹만 바꿔도 가격 지문과 승인 지문은 같다', () {
    final plain = ShopProductOption(id: 'a', name: '픽업', consumerPrice: 5000);
    final grouped = plain.copyWith(group: 'transfer');
    final before = _product([plain]);
    final after = _product([grouped]);
    expect(productPriceFingerprint(before), productPriceFingerprint(after));
    expect(productContentFingerprint(before), productContentFingerprint(after));
  });

  test('가격 대기 중에도 그룹은 바로 반영되고 가격은 기다린다', () {
    final live = ShopProductOption(
      id: 'a',
      name: '장비',
      consumerPrice: 5000,
      professionalPrice: 4000,
    );
    final previous = _product([live]);
    final draft = _product([live.copyWith(consumerPrice: 7000, group: 'gear')]);
    final result = stageApprovedPartnerSave(previous: previous, draft: draft);
    expect(result.stagedPriceOrNewOptions, isTrue);
    expect(result.product.options.single.consumerPrice, 5000);
    expect(result.product.options.single.group, 'gear');
  });
}
