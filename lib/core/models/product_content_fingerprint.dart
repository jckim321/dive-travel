import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/r2_photo_storage.dart';

/// Stable content fingerprint for reject → resubmit change detection.
///
/// Includes listing content only (name, copy, prices, photos, schedule, …).
/// Excludes publish/review metadata, seats, same-boat, FOC, and guest ratings.
/// Photo URLs are compared by object key only (host / signature / query stripped).
///
/// When [pendingGallery] is set (save-time slots), local bytes and URL order are
/// included so add / remove / cover reorder count as changes before R2 upload.
String productContentFingerprint(
  ShopProduct product, {
  List<ShopGallerySlot>? pendingGallery,
}) {
  final payload = jsonEncode(_canonicalContent(product, pendingGallery));
  return sha256.convert(utf8.encode(payload)).toString();
}

/// Normalize a stored photo URL to a durable object path for fingerprinting.
///
/// Prefers [R2PhotoStorage.objectKeyFromStoredUrl]; falls back to URI path
/// without query/fragment so signed hosts do not change the fingerprint.
String contentFingerprintPhotoRef(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.startsWith('memory://')) {
    return '';
  }
  final key = R2PhotoStorage.objectKeyFromStoredUrl(trimmed);
  if (key != null && key.isNotEmpty) {
    final q = key.indexOf('?');
    return q < 0 ? key : key.substring(0, q);
  }
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.path.isNotEmpty) {
    var path = uri.path;
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.isNotEmpty) {
      return path;
    }
  }
  final bare = trimmed.split('?').first.split('#').first;
  return bare;
}

/// Stable ref for one gallery slot (remote key or hash of pending bytes).
String contentFingerprintGallerySlot(ShopGallerySlot slot) {
  if (slot.hasBytes) {
    return 'local:${sha256.convert(slot.bytes!).toString()}';
  }
  if (slot.hasUrl) {
    return contentFingerprintPhotoRef(slot.url!);
  }
  return '';
}

Map<String, Object?> _canonicalContent(
  ShopProduct product,
  List<ShopGallerySlot>? pendingGallery,
) {
  late final String cover;
  late final List<String> photos;
  if (pendingGallery != null) {
    final ordered = <String>[
      for (final slot in pendingGallery)
        if (contentFingerprintGallerySlot(slot).isNotEmpty)
          contentFingerprintGallerySlot(slot),
    ];
    cover = ordered.isEmpty ? '' : ordered.first;
    photos = [...ordered]..sort();
  } else {
    photos = [
      for (final url in product.photoUrls)
        if (contentFingerprintPhotoRef(url).isNotEmpty)
          contentFingerprintPhotoRef(url),
    ]..sort();
    cover = contentFingerprintPhotoRef(product.coverUrl);
  }
  final rates = [
    for (final rate in [...product.guestRates]
      ..sort((a, b) => a.role.firestoreValue.compareTo(b.role.firestoreValue)))
      {
        'role': rate.role.firestoreValue,
        'enabled': rate.enabled,
        'consumer': rate.consumer,
        'professional': rate.professional,
      },
  ];
  final days = [
    for (final day in [...product.itineraryDays]
      ..sort((a, b) => a.day.compareTo(b.day)))
      {
        'day': day.day,
        'title': day.title,
        'body': day.body,
      },
  ];
  final options = [
    for (final option in [...product.options]
      ..sort((a, b) => a.id.compareTo(b.id)))
      {
        'id': option.id,
        'name': option.name,
        'description': option.description,
        'consumer_price': option.consumerPrice,
        'professional_price': option.professionalPrice,
        'kind': option.kind.firestoreValue,
      },
  ];
  return {
    'name': product.name,
    'blurb': product.blurb,
    'detail': product.detail,
    'consumer_price': product.consumerPrice,
    'professional_price': product.professionalPrice,
    'cover_url': cover,
    'photo_urls': photos,
    'schedule': product.schedule,
    'includes': product.includes,
    'excludes': product.excludes,
    'itinerary_days': days,
    'meeting_point': product.meetingPoint,
    'duration_label': product.durationLabel,
    'difficulty': product.difficulty,
    'cancellation_note': product.cancellationNote,
    'guest_rates': rates,
    'options': options,
  };
}
