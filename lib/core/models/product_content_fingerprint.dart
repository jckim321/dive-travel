import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/models/shop_product.dart';
import 'package:dive_travel_app/core/storage/r2_photo_storage.dart';

/// Section keys stored in [ShopProduct.rejectedSectionHashes].
const productContentSectionKeys = <String>[
  'photos',
  'price',
  'options',
  'copy',
  'schedule',
  'cancel',
];

/// Schema marker in [ShopProduct.rejectedSectionHashes] (not a content section).
///
/// Bump [productSectionFpSchemaVersion] when section slice rules change so
/// legacy maps compare as unknown (UI: 비교 불가) instead of false "changed".
const productSectionFpSchemaKey = '_fp';

/// Current section-fingerprint schema (`base_package` excluded from options).
const productSectionFpSchemaVersion = '2';

/// Result of comparing a section hash from the last reject to current content.
enum SectionChangeFlag {
  changed,
  same,
  unknown,
}

/// True when [hashes] were written with the current section schema.
bool productSectionHashesComparable(Map<String, String> hashes) {
  if (hashes.isEmpty) {
    return false;
  }
  return hashes[productSectionFpSchemaKey]?.trim() ==
      productSectionFpSchemaVersion;
}

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

/// Per-section sha256 fingerprints (same payload rules as the full hash).
///
/// Includes [productSectionFpSchemaKey] so rejects can be version-gated.
/// Options section omits `base_package` (price section owns base price).
Map<String, String> productSectionFingerprints(
  ShopProduct product, {
  List<ShopGallerySlot>? pendingGallery,
}) {
  final canonical = _canonicalContent(product, pendingGallery);
  return {
    for (final key in productContentSectionKeys)
      key: sha256
          .convert(utf8.encode(jsonEncode(_sectionSlice(canonical, key))))
          .toString(),
    productSectionFpSchemaKey: productSectionFpSchemaVersion,
  };
}

/// Compare [previousHashes] (from last reject) to current product sections.
///
/// Empty map or wrong/missing schema → every key [SectionChangeFlag.unknown].
Map<String, SectionChangeFlag> sectionChangeFlags(
  Map<String, String> previousHashes,
  ShopProduct product, {
  List<ShopGallerySlot>? pendingGallery,
}) {
  if (!productSectionHashesComparable(previousHashes)) {
    return {
      for (final key in productContentSectionKeys) key: SectionChangeFlag.unknown,
    };
  }
  final current = productSectionFingerprints(
    product,
    pendingGallery: pendingGallery,
  );
  return {
    for (final key in productContentSectionKeys)
      key: () {
        final prev = previousHashes[key]?.trim() ?? '';
        if (prev.isEmpty) {
          return SectionChangeFlag.unknown;
        }
        return prev == current[key]
            ? SectionChangeFlag.same
            : SectionChangeFlag.changed;
      }(),
  };
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

Map<String, Object?> _sectionSlice(Map<String, Object?> canonical, String key) {
  switch (key) {
    case 'photos':
      return {
        'cover_url': canonical['cover_url'],
        'photo_urls': canonical['photo_urls'],
      };
    case 'price':
      return {
        'consumer_price': canonical['consumer_price'],
        'professional_price': canonical['professional_price'],
        'guest_rates': canonical['guest_rates'],
      };
    case 'options':
      // base_package mirrors product base price (price section); exclude here.
      final raw = canonical['options'];
      final filtered = <Object?>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map && item['kind'] == 'base_package') {
            continue;
          }
          filtered.add(item);
        }
      }
      return {'options': filtered};
    case 'copy':
      return {
        'name': canonical['name'],
        'blurb': canonical['blurb'],
        'detail': canonical['detail'],
      };
    case 'schedule':
      return {
        'schedule': canonical['schedule'],
        'includes': canonical['includes'],
        'excludes': canonical['excludes'],
        'itinerary_days': canonical['itinerary_days'],
        'meeting_point': canonical['meeting_point'],
        'duration_label': canonical['duration_label'],
        'difficulty': canonical['difficulty'],
      };
    case 'cancel':
      return {'cancellation_note': canonical['cancellation_note']};
    default:
      return const {};
  }
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
