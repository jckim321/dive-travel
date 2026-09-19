import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/refund_policy.dart';
import 'package:dive_travel_app/core/i18n/translation_engine.dart';

void main() {
  test('유저 변심 취소는 7일 전 100%, 3일 전 50%, 당일 0%', () {
    final tour = DateTime(2026, 10, 10);
    expect(
      RefundPolicy.forUserCancel(
        tourDate: tour,
        now: DateTime(2026, 10, 1),
      ).percent,
      100,
    );
    expect(
      RefundPolicy.forUserCancel(
        tourDate: tour,
        now: DateTime(2026, 10, 7),
      ).percent,
      50,
    );
    expect(
      RefundPolicy.forUserCancel(
        tourDate: tour,
        now: DateTime(2026, 10, 10),
      ).percent,
      0,
    );
  });

  test('기상 악화 취소는 항상 100% 환불', () {
    final quote = RefundPolicy.weatherCancel();
    expect(quote.percent, 100);
    expect(quote.weather, isTrue);
    expect(quote.amountFor(180000), 180000);
  });

  test('정산 수수료는 10~15% 구간에서 기본 12%', () {
    expect(RefundPolicy.commissionOn(100000), 12000);
    expect(RefundPolicy.netPayout(100000), 88000);
  });

  test('영어 게시글은 한국어 기기에서 번역이 필요하다', () {
    expect(
      LanguageDetector.needsTranslation(
        text: 'Weekend buddy crew in Dahab',
        targetLanguage: 'ko',
        storedLanguage: 'en',
      ),
      isTrue,
    );
    expect(LanguageDetector.detect('ケラマで週末バディ募集'), 'ja');
  });

  test('번들 번역 엔진은 영어 다합 글을 한국어로 바꾼다', () async {
    final engine = GoogleStyleTranslationEngine(allowNetwork: false);
    final translated = await engine.translate(
      text: 'Weekend buddy crew in Dahab — 1 spot left',
      sourceLanguage: 'en',
      targetLanguage: 'ko',
    );
    expect(translated.contains('다합'), isTrue);
  });
}
