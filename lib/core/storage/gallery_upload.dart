import 'dart:typed_data';

import 'package:dive_travel_app/core/constants/gallery_limits.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';

typedef GalleryUploader = Future<String> Function({
  required String objectKey,
  required Uint8List bytes,
  required String contentType,
  bool requirePublicUrl,
});

/// Uploads gallery slots with bounded concurrency, preserving order.
Future<List<String>> uploadGallerySlots({
  required List<ShopGallerySlot> gallery,
  required String keyPrefix,
  required GalleryUploader upload,
  int concurrency = GalleryLimits.uploadConcurrency,
}) async {
  if (gallery.isEmpty) {
    return const [];
  }
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final urls = List<String?>.filled(gallery.length, null);
  var next = 0;

  Future<void> worker() async {
    while (true) {
      final i = next;
      next += 1;
      if (i >= gallery.length) {
        return;
      }
      final slot = gallery[i];
      if (slot.hasBytes) {
        final name = slot.fileName ?? 'photo.jpg';
        final lower = name.toLowerCase();
        final extension = lower.endsWith('.png')
            ? '.png'
            : lower.endsWith('.webp')
                ? '.webp'
                : lower.endsWith('.gif')
                    ? '.gif'
                    : lower.endsWith('.heic') || lower.endsWith('.heif')
                        ? '.heic'
                        : '.jpg';
        urls[i] = await upload(
          objectKey: '$keyPrefix/${stamp}_$i$extension',
          bytes: slot.bytes!,
          contentType: slot.contentType ?? 'image/jpeg',
          requirePublicUrl: true,
        );
      } else if (slot.hasUrl) {
        urls[i] = slot.url!.trim();
      } else {
        urls[i] = '';
      }
    }
  }

  final workers = concurrency < 1 ? 1 : concurrency;
  await Future.wait([
    for (var w = 0; w < workers && w < gallery.length; w++) worker(),
  ]);
  return [
    for (final url in urls)
      if (url != null && url.isNotEmpty) url,
  ];
}
