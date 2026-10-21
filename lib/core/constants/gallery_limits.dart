/// Shared caps for product / shop photo galleries.
abstract final class GalleryLimits {
  /// Max photos per product or shop gallery.
  ///
  /// Raised with client-side resize/compress so web memory stays manageable.
  static const int maxProductPhotos = 30;

  /// Longest edge after client compress (px). Phone-friendly listing size.
  static const int maxEdgePx = 1280;

  /// JPEG quality for compressed uploads (0–100).
  static const int jpegQuality = 85;

  /// Concurrent R2 uploads when saving a gallery.
  static const int uploadConcurrency = 3;
}
