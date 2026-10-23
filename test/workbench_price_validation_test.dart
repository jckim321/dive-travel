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

    test('비숫자는 null', () {
      expect(parsePositivePrice('abc'), isNull);
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
          namedOptionPriceRaws: const [],
        ).isOk,
        isTrue,
      );
      expect(
        checkWorkbenchPrices(
          diverRaw: '',
          hasNondivers: false,
          nondiverRaw: '',
          childRaw: '',
          namedOptionPriceRaws: const [],
        ).target,
        WorkbenchPriceTarget.diver,
      );
      expect(
        checkWorkbenchPrices(
          diverRaw: '0',
          hasNondivers: false,
          nondiverRaw: '999',
          childRaw: '999',
          namedOptionPriceRaws: const [],
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
          namedOptionPriceRaws: const [],
        ).target,
        WorkbenchPriceTarget.nondiver,
      );
      expect(
        checkWorkbenchPrices(
          diverRaw: '100000',
          hasNondivers: true,
          nondiverRaw: '80000',
          childRaw: '0',
          namedOptionPriceRaws: const [],
        ).target,
        WorkbenchPriceTarget.child,
      );
      expect(
        checkWorkbenchPrices(
          diverRaw: '100000',
          hasNondivers: true,
          nondiverRaw: '80000',
          childRaw: '50000',
          namedOptionPriceRaws: const [],
        ).isOk,
        isTrue,
      );
    });

    test('이름 있는 옵션 가격도 필수', () {
      expect(
        checkWorkbenchPrices(
          diverRaw: '100000',
          hasNondivers: false,
          nondiverRaw: '',
          childRaw: '',
          namedOptionPriceRaws: const [''],
        ).target,
        WorkbenchPriceTarget.option,
      );
      expect(
        checkWorkbenchPrices(
          diverRaw: '100000',
          hasNondivers: false,
          nondiverRaw: '',
          childRaw: '',
          namedOptionPriceRaws: const ['30000'],
        ).isOk,
        isTrue,
      );
    });
  });
}
