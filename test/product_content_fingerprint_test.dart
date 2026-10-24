import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
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

  test('pendingGallery: 사진만 추가하면 지문이 달라진다', () {
    final empty = _base(coverUrl: '', photoUrls: const []);
    final baseHash = productContentFingerprint(empty);
    final withLocal = productContentFingerprint(
      empty,
      pendingGallery: [
        ShopGallerySlot(bytes: Uint8List.fromList([1, 2, 3, 4])),
      ],
    );
    expect(withLocal, isNot(baseHash));
  });

  test('pendingGallery: 사진만 삭제하면 지문이 달라진다', () {
    final withPhotos = _base(
      coverUrl: 'https://cdn.example/a.jpg',
      photoUrls: const ['https://cdn.example/a.jpg'],
    );
    final baseHash = productContentFingerprint(withPhotos);
    final cleared = productContentFingerprint(
      withPhotos,
      pendingGallery: const [],
    );
    expect(cleared, isNot(baseHash));
  });

  test('pendingGallery: 대표 사진만 바꾸면 지문이 달라진다', () {
    final slotsA = [
      const ShopGallerySlot(url: 'https://cdn.example/a.jpg'),
      const ShopGallerySlot(url: 'https://cdn.example/b.jpg'),
    ];
    final slotsB = [
      const ShopGallerySlot(url: 'https://cdn.example/b.jpg'),
      const ShopGallerySlot(url: 'https://cdn.example/a.jpg'),
    ];
    final product = _base(
      coverUrl: 'https://cdn.example/a.jpg',
      photoUrls: const [
        'https://cdn.example/a.jpg',
        'https://cdn.example/b.jpg',
      ],
    );
    expect(
      productContentFingerprint(product, pendingGallery: slotsA),
      isNot(productContentFingerprint(product, pendingGallery: slotsB)),
    );
  });

  test('pendingGallery: 아무것도 안 바꾸면 지문 동일', () {
    final product = _base(
      coverUrl: 'https://cdn.example/a.jpg',
      photoUrls: const ['https://cdn.example/a.jpg'],
    );
    final hash = productContentFingerprint(product);
    final same = productContentFingerprint(
      product,
      pendingGallery: const [
        ShopGallerySlot(url: 'https://cdn.example/a.jpg'),
      ],
    );
    expect(same, hash);
  });

  test('섹션 지문: 가격만 바꾸면 price만 changed', () {
    final base = _base();
    final prev = productSectionFingerprints(base);
    final flags = sectionChangeFlags(
      prev,
      _base(consumerPrice: 200000),
    );
    expect(flags['price'], SectionChangeFlag.changed);
    expect(flags['photos'], SectionChangeFlag.same);
    expect(flags['copy'], SectionChangeFlag.same);
    expect(flags['options'], SectionChangeFlag.same);
  });

  test('섹션 지문: 사진만 바꾸면 photos만 changed', () {
    final base = _base();
    final prev = productSectionFingerprints(base);
    final flags = sectionChangeFlags(
      prev,
      _base(photoUrls: const ['https://cdn.example/b.jpg']),
    );
    expect(flags['photos'], SectionChangeFlag.changed);
    expect(flags['price'], SectionChangeFlag.same);
  });

  test('섹션 지문: 이름만 바꾸면 copy만 changed', () {
    final base = _base();
    final prev = productSectionFingerprints(base);
    final flags = sectionChangeFlags(prev, _base(name: 'Other'));
    expect(flags['copy'], SectionChangeFlag.changed);
    expect(flags['price'], SectionChangeFlag.same);
  });

  test('섹션 지문: pendingGallery bytes는 photos changed', () {
    final empty = _base(coverUrl: '', photoUrls: const []);
    final prev = productSectionFingerprints(empty);
    final flags = sectionChangeFlags(
      prev,
      empty,
      pendingGallery: [
        ShopGallerySlot(bytes: Uint8List.fromList([9, 8, 7])),
      ],
    );
    expect(flags['photos'], SectionChangeFlag.changed);
    expect(flags['price'], SectionChangeFlag.same);
  });

  test('섹션 지문: 이전 해시 없으면 전부 unknown', () {
    final flags = sectionChangeFlags(const {}, _base());
    for (final key in productContentSectionKeys) {
      expect(flags[key], SectionChangeFlag.unknown);
    }
  });

  test('섹션 지문: _fp 없는 옛 맵은 전부 unknown', () {
    final base = _base();
    final legacy = Map<String, String>.from(productSectionFingerprints(base))
      ..remove(productSectionFpSchemaKey);
    final flags = sectionChangeFlags(legacy, base);
    for (final key in productContentSectionKeys) {
      expect(flags[key], SectionChangeFlag.unknown);
    }
    expect(productSectionHashesComparable(legacy), isFalse);
  });

  test('섹션 지문: base_package 가격만 바뀌면 price만 changed', () {
    final withBase = _base(consumerPrice: 100000).copyWith(
      options: const [
        ShopProductOption(
          id: 'base',
          name: '기본',
          consumerPrice: 100000,
          professionalPrice: 100000,
          kind: ProductOptionKind.basePackage,
        ),
        ShopProductOption(
          id: 'addon1',
          name: '나이트',
          consumerPrice: 30000,
          professionalPrice: 30000,
          kind: ProductOptionKind.addon,
        ),
      ],
    );
    final prev = productSectionFingerprints(withBase);
    final next = withBase.copyWith(
      consumerPrice: 150000,
      professionalPrice: 150000,
      options: [
        withBase.options.first.copyWith(
          consumerPrice: 150000,
          professionalPrice: 150000,
        ),
        withBase.options.last,
      ],
    );
    final flags = sectionChangeFlags(prev, next);
    expect(flags['price'], SectionChangeFlag.changed);
    expect(flags['options'], SectionChangeFlag.same);
    // Full hash (build 2) still sees base_package price change.
    expect(
      productContentFingerprint(next),
      isNot(productContentFingerprint(withBase)),
    );
  });

  test('섹션 지문: addon만 바꾸면 options만 changed', () {
    final withBase = _base(consumerPrice: 100000).copyWith(
      options: const [
        ShopProductOption(
          id: 'base',
          name: '기본',
          consumerPrice: 100000,
          professionalPrice: 100000,
          kind: ProductOptionKind.basePackage,
        ),
        ShopProductOption(
          id: 'addon1',
          name: '나이트',
          consumerPrice: 30000,
          professionalPrice: 30000,
          kind: ProductOptionKind.addon,
        ),
      ],
    );
    final prev = productSectionFingerprints(withBase);
    final next = withBase.copyWith(
      options: [
        withBase.options.first,
        withBase.options.last.copyWith(consumerPrice: 50000),
      ],
    );
    final flags = sectionChangeFlags(prev, next);
    expect(flags['options'], SectionChangeFlag.changed);
    expect(flags['price'], SectionChangeFlag.same);
  });

  test('섹션 지문에 _fp 스키마 키가 포함된다', () {
    final fp = productSectionFingerprints(_base());
    expect(fp[productSectionFpSchemaKey], productSectionFpSchemaVersion);
  });
}
