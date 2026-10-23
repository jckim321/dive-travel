/// Whether save should keep existing durable photo URLs instead of writing
/// an empty gallery (seed/load miss or untouched empty editor).
bool shouldPreserveExistingPhotos({
  required bool galleryEmpty,
  required bool userClearedGallery,
  required bool existingHasPhotos,
}) {
  return galleryEmpty && !userClearedGallery && existingHasPhotos;
}

bool existingProductHasPhotos({
  required List<String> photoUrls,
  required String coverUrl,
}) {
  if (coverUrl.trim().isNotEmpty) {
    return true;
  }
  for (final url in photoUrls) {
    if (url.trim().isNotEmpty) {
      return true;
    }
  }
  return false;
}
