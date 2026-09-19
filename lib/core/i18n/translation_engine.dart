import 'dart:convert';

import 'package:http/http.dart' as http;

/// 글의 주 언어를 스크립트 기준으로 추정합니다.
abstract final class LanguageDetector {
  static String detect(String text) {
    final sample = text.trim();
    if (sample.isEmpty) {
      return 'und';
    }
    if (RegExp(r'[\uac00-\ud7af]').hasMatch(sample)) {
      return 'ko';
    }
    if (RegExp(r'[\u3040-\u30ff]').hasMatch(sample)) {
      return 'ja';
    }
    if (RegExp(r'[\u0e00-\u0e7f]').hasMatch(sample)) {
      return 'th';
    }
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(sample)) {
      return 'zh';
    }
    if (RegExp(r'[àáâãäåèéêëìíîïòóôõöùúûüñ¿¡]', caseSensitive: false)
        .hasMatch(sample)) {
      return 'es';
    }
    return 'en';
  }

  static bool needsTranslation({
    required String text,
    required String targetLanguage,
    String? storedLanguage,
  }) {
    final source = (storedLanguage ?? '').trim().isEmpty
        ? detect(text)
        : storedLanguage!.trim().toLowerCase();
    if (source == 'und') {
      return false;
    }
    return source != targetLanguage.toLowerCase();
  }
}

/// DeepL / Google 번역 API를 같은 인터페이스로 바꿉니다.
abstract class TranslationEngine {
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  });
}

/// 시드·다이빙 상용구를 즉시 바꾸고, 없으면 Google Translate 공개 엔드포인트를 시도합니다.
class GoogleStyleTranslationEngine implements TranslationEngine {
  GoogleStyleTranslationEngine({
    http.Client? client,
    this.allowNetwork = true,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final bool allowNetwork;

  static const bundled = <String, Map<String, String>>{
    'en': {
      'ko': '주말 다합 버디 크루 — 자리 1명 남음. 싱글차지 없이 합류하세요.',
      'ja': 'ダハブ週末バディクルー、残り1名。シングルチャージなし。',
    },
    'ja': {
      'ko': '케라마에서 주말 버디 구합니다. 초보 환영, 보트 2탱크.',
      'en': 'Looking for a weekend buddy in Kerama. Beginners welcome, 2-tank boat.',
    },
    'ko': {
      'en': 'Official group tour · Bohol 3-day fun diving. Shop-led, 2–6 divers.',
      'ja': '公式グループツアー・ボホール3日ファンダイビング。',
    },
  };

  @override
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final source = sourceLanguage.toLowerCase();
    final target = targetLanguage.toLowerCase();
    if (source == target) {
      return text;
    }
    final bundledHit = _bundledMatch(text, source, target);
    if (bundledHit != null) {
      return bundledHit;
    }
    if (!allowNetwork) {
      return text;
    }
    try {
      final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
        'client': 'gtx',
        'sl': source,
        'tl': target,
        'dt': 't',
        'q': text,
      });
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return text;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is List && decoded.isNotEmpty && decoded.first is List) {
        final chunks = decoded.first as List<dynamic>;
        final buffer = StringBuffer();
        for (final chunk in chunks) {
          if (chunk is List && chunk.isNotEmpty && chunk.first is String) {
            buffer.write(chunk.first);
          }
        }
        final translated = buffer.toString().trim();
        if (translated.isNotEmpty) {
          return translated;
        }
      }
    } catch (_) {
      return text;
    }
    return text;
  }

  String? _bundledMatch(String text, String source, String target) {
    final table = bundled[source]?[target];
    if (table == null) {
      return null;
    }
    final needle = text.trim();
    if (needle.contains('Dahab') || needle.contains('dahab') || needle.contains('weekend buddy')) {
      return bundled['en']?[target];
    }
    if (needle.contains('ケラマ') || needle.contains('バディ')) {
      return bundled['ja']?[target];
    }
    if (needle.contains('보홀') || needle.contains('공식 그룹')) {
      return bundled['ko']?[target];
    }
    if (needle.contains('다합') || needle.contains('소셜 버디')) {
      if (source == 'ko') {
        return bundled['ko']?[target];
      }
      return table;
    }
    return null;
  }
}
