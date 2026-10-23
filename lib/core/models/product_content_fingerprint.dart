import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:dive_travel_app/core/models/shop_product.dart';

/// Stable content fingerprint for reject → resubmit change detection.
///
/// Includes listing content only (name, copy, prices, photos, schedule, …).
/// Excludes publish/review metadata, seats, same-boat, FOC, and guest ratings.
String productContentFingerprint(ShopProduct product) {
  final payload = jsonEncode(_canonicalContent(product));
  return sha256.convert(utf8.encode(payload)).toString();
}

Map<String, Object?> _canonicalContent(ShopProduct product) {
  final photos = [...product.photoUrls]..sort();
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
    'cover_url': product.coverUrl,
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
