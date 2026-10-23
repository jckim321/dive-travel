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

  test('한글·공백이 인코딩된 경로는 그대로 유지한다', () {
    // "한글 사진.jpg" → %ED%95%9C%EA%B8%80%20%EC%82%AC%EC%A7%84.jpg
    const encoded =
        'shops/x/%ED%95%9C%EA%B8%80%20%EC%82%AC%EC%A7%84.jpg';
    expect(
      normalizeR2PublicUrl(
        'https://pub-old.r2.dev/$encoded',
        publicBaseUrl: newBase,
      ),
      'https://pub-new.r2.dev/$encoded',
    );
  });

  test('경로의 %20·%25 등 퍼센트 인코딩을 재디코딩하지 않는다', () {
    const encoded = 'shops/x/photo%20name%25tag.jpg';
    expect(
      normalizeR2PublicUrl(
        'https://pub-old.r2.dev/$encoded',
        publicBaseUrl: newBase,
      ),
      'https://pub-new.r2.dev/$encoded',
    );
  });

  test('특수문자 인코딩 경로도 유지한다', () {
    // "a+b&c=#.jpg" style object key percent-encoded
    const encoded = 'shops/x/a%2Bb%26c%3D%23.jpg';
    expect(
      normalizeR2PublicUrl(
        'https://pub-old.r2.dev/$encoded',
        publicBaseUrl: newBase,
      ),
      'https://pub-new.r2.dev/$encoded',
    );
  });
}
