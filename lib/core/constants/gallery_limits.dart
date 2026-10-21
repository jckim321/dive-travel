/// Shared caps for product / shop photo galleries.
abstract final class GalleryLimits {
  /// Max photos per product or shop gallery.
  ///
  /// Raised with client-side resize/compress so web memory stays manageable.
  static const int maxProductPhotos = 30;

  /// Longest edge after client compress (px).
  ///
  /// Kept high for travel listing sharpness; still caps raw multi‑MB phone dumps.
  static const int maxEdgePx = 2048;

  /// JPEG quality for compressed uploads (0–100). Favor clarity over tiny files.
  static const int jpegQuality = 92;

  /// Concurrent R2 uploads when saving a gallery.
  static const int uploadConcurrency = 3;
}
