import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/storage/r2_photo_storage.dart';

void main() {
  test('objectKeyFromStoredUrl parses r2.dev public URLs', () {
    const url =
        'https://pub-293653a06490483d9731dcb57edb09cc.r2.dev/shops/curated-1/products/p-1.jpg';
    expect(
      R2PhotoStorage.objectKeyFromStoredUrl(url),
      'shops/curated-1/products/p-1.jpg',
    );
  });

  test('objectKeyFromStoredUrl ignores memory and empty', () {
    expect(R2PhotoStorage.objectKeyFromStoredUrl(''), isNull);
    expect(R2PhotoStorage.objectKeyFromStoredUrl('memory://x'), isNull);
    expect(
      R2PhotoStorage.objectKeyFromStoredUrl('https://example.com/a.jpg'),
      isNull,
    );
  });
}
