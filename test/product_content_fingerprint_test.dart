import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/models/product_content_fingerprint.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';

ShopProduct _base({
  String name = 'Trip',
  int consumerPrice = 100000,
  String blurb = 'hello',
  String coverUrl = '',
  List<String> photoUrls = const ['https://cdn.example/a.jpg'],
}) {
  return ShopProduct(
    id: 'p1',
    shopId: 'shop',
    name: name,
    consumerPrice: consumerPrice,
    professionalPrice: consumerPrice,
    blurb: blurb,
    coverUrl: coverUrl,
    photoUrls: photoUrls,
    publishStatus: ProductPublishStatus.pending,
    active: false,
  );
}

void main() {
  test('동일 콘텐츠는 같은 지문', () {
    expect(
      productContentFingerprint(_base()),
      productContentFingerprint(_base()),
    );
  });

  test('이름·가격·사진 변경 시 지문이 달라진다', () {
    final a = productContentFingerprint(_base());
    expect(
      productContentFingerprint(_base(name: 'Other')),
      isNot(a),
    );
    expect(
      productContentFingerprint(_base(consumerPrice: 200000)),
      isNot(a),
    );
    expect(
      productContentFingerprint(
        _base(photoUrls: const ['https://cdn.example/b.jpg']),
      ),
      isNot(a),
    );
  });

  test('publish/review 메타는 지문에 영향 없음', () {
    final a = productContentFingerprint(_base());
    final b = productContentFingerprint(
      _base().copyWith(
        publishStatus: ProductPublishStatus.rejected,
        reviewNote: 'bad photos',
        rejectedContentHash: 'old',
        resubmitCount: 2,
        resubmitNote: 'fixed',
      ),
    );
    expect(b, a);
  });

  test('photo_urls 순서가 달라도 같은 지문', () {
    final a = productContentFingerprint(
      _base(photoUrls: const ['https://a/1.jpg', 'https://a/2.jpg']),
    );
    final b = productContentFingerprint(
      _base(photoUrls: const ['https://a/2.jpg', 'https://a/1.jpg']),
    );
    expect(b, a);
  });

  test('같은 사진에서 호스트·서명·쿼리만 달라도 지문 동일', () {
    const key = 'shops/shop1/products/p1/cover.jpg';
    final a = productContentFingerprint(
      _base(
        coverUrl: 'https://cdn.example/$key',
        photoUrls: [
          'https://cdn.example/$key',
          'https://cdn.example/gallery/one.jpg',
        ],
      ),
    );
    final b = productContentFingerprint(
      _base(
        coverUrl: 'https://signed.example/$key'
            '?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=abc',
        photoUrls: [
          'https://other-host.example/$key?token=1',
          'https://mirror.example/gallery/one.jpg#frag',
        ],
      ),
    );
    expect(b, a);
  });

  test('contentFingerprintPhotoRef strips query and prefers path', () {
    expect(
      contentFingerprintPhotoRef(
        'https://cdn.example/shops/x/a.jpg?X-Amz-Signature=zz',
      ),
      'shops/x/a.jpg',
    );
  });
}
