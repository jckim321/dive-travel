import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/config/r2_public_url.dart';

void main() {
  const newBase = 'https://pub-new.r2.dev';

  test('옛 r2.dev 호스트를 새 publicBaseUrl로 바꾼다', () {
    expect(
      normalizeR2PublicUrl(
        'https://pub-old.r2.dev/shops/x/a.jpg',
        publicBaseUrl: newBase,
      ),
      'https://pub-new.r2.dev/shops/x/a.jpg',
    );
  });

  test('이미 새 호스트면 경로만 유지한 채 동일하다', () {
    expect(
      normalizeR2PublicUrl(
        'https://pub-new.r2.dev/shops/x/a.jpg',
        publicBaseUrl: newBase,
      ),
      'https://pub-new.r2.dev/shops/x/a.jpg',
    );
  });

  test('비 r2.dev 주소는 그대로 둔다', () {
    expect(
      normalizeR2PublicUrl(
        'https://cdn.example.com/x.jpg',
        publicBaseUrl: newBase,
      ),
      'https://cdn.example.com/x.jpg',
    );
    expect(
      normalizeR2PublicUrl(
        'https://abc.r2.cloudflarestorage.com/bucket/key.jpg',
        publicBaseUrl: newBase,
      ),
      'https://abc.r2.cloudflarestorage.com/bucket/key.jpg',
    );
  });

  test('빈 문자열·공백은 빈 문자열', () {
    expect(normalizeR2PublicUrl('', publicBaseUrl: newBase), '');
    expect(normalizeR2PublicUrl('   ', publicBaseUrl: newBase), '');
  });

  test('publicBaseUrl이 비면 원문을 유지한다', () {
    expect(
      normalizeR2PublicUrl(
        'https://pub-old.r2.dev/shops/x/a.jpg',
        publicBaseUrl: '',
      ),
      'https://pub-old.r2.dev/shops/x/a.jpg',
    );
  });

  test('memory:// 는 그대로', () {
    expect(
      normalizeR2PublicUrl('memory://shop-gallery-1', publicBaseUrl: newBase),
      'memory://shop-gallery-1',
    );
  });

  test('커스텀 도메인 base로도 치환한다', () {
    expect(
      normalizeR2PublicUrl(
        'https://pub-old.r2.dev/shops/y/b.png',
        publicBaseUrl: 'https://media.dive.example/',
      ),
      'https://media.dive.example/shops/y/b.png',
    );
  });
}
