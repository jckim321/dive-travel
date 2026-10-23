import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';

void main() {
  group('parseWorkbenchPrice / parsePositivePrice', () {
    test('빈 값·공백은 emptyOrNonPositive', () {
      expect(
        parseWorkbenchPrice('').failure,
        WorkbenchPriceParseFailure.emptyOrNonPositive,
      );
      expect(parsePositivePrice(''), isNull);
      expect(parsePositivePrice('   '), isNull);
    });

    test('0과 00은 emptyOrNonPositive', () {
      expect(
        parseWorkbenchPrice('0').failure,
        WorkbenchPriceParseFailure.emptyOrNonPositive,
      );
      expect(parsePositivePrice('00'), isNull);
    });

    test('음수는 emptyOrNonPositive', () {
      expect(
        parseWorkbenchPrice('-1').failure,
        WorkbenchPriceParseFailure.emptyOrNonPositive,
      );
      expect(parsePositivePrice('-150000'), isNull);
    });

    test('정상 양수는 값을 반환', () {
      expect(parsePositivePrice('150000'), 150000);
      expect(parsePositivePrice(' 1 '), 1);
      expect(parseWorkbenchPrice('150000').isOk, isTrue);
    });

    test('쉼표·공백·원을 제거하고 인식', () {
      expect(parsePositivePrice('20,000'), 20000);
      expect(parsePositivePrice('20000원'), 20000);
      expect(parsePositivePrice(' 20 000 '), 20000);
      expect(parsePositivePrice('1,500,000원'), 1500000);
    });

    test('숫자 없으면 emptyOrNonPositive', () {
      expect(
        parseWorkbenchPrice('abc').failure,
        WorkbenchPriceParseFailure.emptyOrNonPositive,
      );
      expect(parsePositivePrice('원'), isNull);
    });

    test('자릿수 10자리 이상이면 overCap', () {
      expect(
        parseWorkbenchPrice('1234567890').failure,
        WorkbenchPriceParseFailure.overCap,
      );
      expect(parsePositivePrice('1,234,567,890'), isNull);
    });

    test('1억 초과면 overCap', () {
      expect(
        parseWorkbenchPrice('100000001').failure,
        WorkbenchPriceParseFailure.overCap,
      );
      expect(parsePositivePrice('100,000,001'), isNull);
    });

    test('상한 이내(100,000,000)는 허용', () {
      expect(parsePositivePrice('99999999'), 99999999);
      expect(parsePositivePrice('100,000,000'), 100000000);
      expect(parseWorkbenchPrice('100000000').isOk, isTrue);
    });
  });

  group('checkWorkbenchPrices', () {
    test('다이버만 필수 — 비다이버 스위치 꺼짐', () {
      expect(
        checkWorkbenchPrices(
          diverRaw: '100000',
          hasNondivers: false,
          nondiverRaw: '',
          childRaw: '',
          namedOptions: const [],
        ).isOk,
        isTrue,
      );
      expect(
        checkWorkbenchPrices(
          diverRaw: '',
          hasNondivers: false,
          nondiverRaw: '',
          childRaw: '',
          namedOptions: const [],
        ).failure,
        WorkbenchPriceParseFailure.emptyOrNonPositive,
      );
      expect(
        checkWorkbenchPrices(
          diverRaw: '0',
          hasNondivers: false,
          nondiverRaw: '999',
          childRaw: '999',
          namedOptions: const [],
        ).target,
        WorkbenchPriceTarget.diver,
      );
    });

    test('다이버 상한 초과면 overCap', () {
      final check = checkWorkbenchPrices(
        diverRaw: '100000001',
        hasNondivers: false,
        nondiverRaw: '',
        childRaw: '',
        namedOptions: const [],
      );
      expect(check.target, WorkbenchPriceTarget.diver);
      expect(check.failure, WorkbenchPriceParseFailure.overCap);
    });

    test('비다이버 스위치 켜짐 — 비다이버·아동도 필수', () {
      expect(
        checkWorkbenchPrices(
          diverRaw: '100000',
          hasNondivers: true,
          nondiverRaw: '',
          childRaw: '50000',
          namedOptions: const [],
        ).target,
        WorkbenchPriceTarget.nondiver,
      );
      expect(
        checkWorkbenchPrices(
          diverRaw: '100000',
          hasNondivers: true,
          nondiverRaw: '80000',
          childRaw: '0',
          namedOptions: const [],
        ).target,
        WorkbenchPriceTarget.child,
      );
      expect(
        checkWorkbenchPrices(
          diverRaw: '100000',
          hasNondivers: true,
          nondiverRaw: '80000',
          childRaw: '50000',
          namedOptions: const [],
        ).isOk,
        isTrue,
      );
    });

    test('옵션 이름만 있고 가격 없으면 옵션 이름 반환', () {
      final check = checkWorkbenchPrices(
        diverRaw: '100000',
        hasNondivers: false,
        nondiverRaw: '',
        childRaw: '',
        namedOptions: const [
          WorkbenchNamedOptionPrice(name: '기본패키지', priceRaw: ''),
        ],
      );
      expect(check.target, WorkbenchPriceTarget.option);
      expect(check.optionName, '기본패키지');
      expect(check.failure, WorkbenchPriceParseFailure.emptyOrNonPositive);
    });

    test('옵션 상한 초과면 overCap + 이름', () {
      final check = checkWorkbenchPrices(
        diverRaw: '100000',
        hasNondivers: false,
        nondiverRaw: '',
        childRaw: '',
        namedOptions: const [
          WorkbenchNamedOptionPrice(name: '나이트 다이브', priceRaw: '200000000'),
        ],
      );
      expect(check.target, WorkbenchPriceTarget.option);
      expect(check.optionName, '나이트 다이브');
      expect(check.failure, WorkbenchPriceParseFailure.overCap);
    });

    test('이름 있는 옵션 가격 정상이면 통과', () {
      expect(
        checkWorkbenchPrices(
          diverRaw: '100000',
          hasNondivers: false,
          nondiverRaw: '',
          childRaw: '',
          namedOptions: const [
            WorkbenchNamedOptionPrice(name: '기본패키지', priceRaw: '30,000원'),
          ],
        ).isOk,
        isTrue,
      );
    });
  });

  group('isWorkbenchUnitPriceAllowed', () {
    test('1~1억만 허용', () {
      expect(isWorkbenchUnitPriceAllowed(0), isFalse);
      expect(isWorkbenchUnitPriceAllowed(1), isTrue);
      expect(isWorkbenchUnitPriceAllowed(100000000), isTrue);
      expect(isWorkbenchUnitPriceAllowed(100000001), isFalse);
    });
  });
}
