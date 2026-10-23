import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/features/admin/presentation/workbench_price_validation.dart';

void main() {
  group('parsePositivePrice', () {
    test('빈 값·공백은 null', () {
      expect(parsePositivePrice(''), isNull);
      expect(parsePositivePrice('   '), isNull);
    });

    test('0과 00은 null', () {
      expect(parsePositivePrice('0'), isNull);
      expect(parsePositivePrice('00'), isNull);
    });

    test('음수는 null', () {
      expect(parsePositivePrice('-1'), isNull);
      expect(parsePositivePrice('-150000'), isNull);
    });

    test('정상 양수는 값을 반환', () {
      expect(parsePositivePrice('150000'), 150000);
      expect(parsePositivePrice(' 1 '), 1);
    });

    test('쉼표·공백·원을 제거하고 인식', () {
      expect(parsePositivePrice('20,000'), 20000);
      expect(parsePositivePrice('20000원'), 20000);
      expect(parsePositivePrice(' 20 000 '), 20000);
      expect(parsePositivePrice('1,500,000원'), 1500000);
    });

    test('숫자 없으면 null', () {
      expect(parsePositivePrice('abc'), isNull);
      expect(parsePositivePrice('원'), isNull);
    });

    test('자릿수 12자리 이상이면 null', () {
      expect(parsePositivePrice('123456789012'), isNull);
      expect(parsePositivePrice('12,345,678,9012'), isNull);
    });

    test('상한 초과면 null', () {
      expect(parsePositivePrice('10000000001'), isNull);
      expect(parsePositivePrice('10,000,000,001'), isNull);
    });

    test('상한 이내(10,000,000,000)는 허용', () {
      expect(parsePositivePrice('9999999999'), 9999999999);
      expect(parsePositivePrice('10,000,000,000'), 10000000000);
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
        ).target,
        WorkbenchPriceTarget.diver,
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
}
