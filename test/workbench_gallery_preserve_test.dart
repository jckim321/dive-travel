import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/features/admin/presentation/workbench_gallery_preserve.dart';

void main() {
  group('shouldPreserveExistingPhotos', () {
    test('빈 갤러리 + 기존 URL + 사용자 삭제 아님 → 보존', () {
      expect(
        shouldPreserveExistingPhotos(
          galleryEmpty: true,
          userClearedGallery: false,
          existingHasPhotos: true,
        ),
        isTrue,
      );
    });

    test('사용자가 전부 지웠으면 보존하지 않음', () {
      expect(
        shouldPreserveExistingPhotos(
          galleryEmpty: true,
          userClearedGallery: true,
          existingHasPhotos: true,
        ),
        isFalse,
      );
    });

    test('갤러리에 항목이 있으면 보존하지 않음', () {
      expect(
        shouldPreserveExistingPhotos(
          galleryEmpty: false,
          userClearedGallery: false,
          existingHasPhotos: true,
        ),
        isFalse,
      );
    });

    test('기존 사진 없으면 보존 불필요', () {
      expect(
        shouldPreserveExistingPhotos(
          galleryEmpty: true,
          userClearedGallery: false,
          existingHasPhotos: false,
        ),
        isFalse,
      );
    });
  });

  group('existingProductHasPhotos', () {
    test('photo_urls 또는 cover_url', () {
      expect(
        existingProductHasPhotos(photoUrls: const ['https://x/a.jpg'], coverUrl: ''),
        isTrue,
      );
      expect(
        existingProductHasPhotos(photoUrls: const [], coverUrl: 'https://x/c.jpg'),
        isTrue,
      );
      expect(
        existingProductHasPhotos(photoUrls: const ['  '], coverUrl: ''),
        isFalse,
      );
    });
  });
}
