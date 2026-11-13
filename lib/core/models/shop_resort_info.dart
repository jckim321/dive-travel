// Shop-level resort intro fields (shops/{id} only — never products[]).

import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Max list sizes written from the resort desk.
const kMaxAccessRoutes = 5;
const kMaxNearbySpots = 10;
const kMaxFeatureTags = 10;
const kMaxAmenities = 30;

/// String length caps (characters after trim).
const kMaxShortLine = 100;
const kMaxTipsBody = 500;
const kMaxIntroBody = 2000;
const kMaxMapUrl = 500;

/// Allowed map hosts (https only). Checked against URI host (lowercase).
const kAllowedMapHosts = <String>[
  'google.com',
  'www.google.com',
  'maps.google.com',
  'maps.app.goo.gl',
  'goo.gl',
  'map.naver.com',
  'naver.me',
  'map.kakao.com',
  'kko.to',
];

/// Transport chip codes stored in [AccessRoute.transport].
const kAccessTransportCodes = <String>[
  'pickup',
  'taxi',
  'bus',
  'rental_car',
  'boat',
];

/// Empty map_url is OK. Non-empty must be https + allowlisted host/path.
String? validateShopMapUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.length > kMaxMapUrl) {
    return 'map_url_too_long';
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return 'map_url_invalid';
  }
  if (uri.scheme.toLowerCase() != 'https') {
    return 'map_url_https_only';
  }
  final host = uri.host.toLowerCase();
  if (!_hostAllowed(host, uri.path)) {
    return 'map_url_domain';
  }
  return null;
}

bool _hostAllowed(String host, String path) {
  final pathLower = path.toLowerCase();
  if (host == 'google.com' || host == 'www.google.com') {
    return pathLower.contains('/maps');
  }
  if (host == 'goo.gl') {
    return pathLower.startsWith('/maps');
  }
  const exact = <String>{
    'maps.google.com',
    'maps.app.goo.gl',
    'map.naver.com',
    'naver.me',
    'map.kakao.com',
    'kko.to',
  };
  return exact.contains(host);
}

bool isShopMapUrlValid(String raw) => validateShopMapUrl(raw) == null;

/// Google Maps search for a resort address. Nothing is written to `map_url`.
Uri googleMapsSearchUri(String query) {
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query.trim(),
  });
}

/// Three-letter airport code. Anything else, including blank, is empty.
String normalizeNearestAirport(String raw) {
  final code = raw.trim().toUpperCase();
  if (code.length != 3) {
    return '';
  }
  for (final unit in code.codeUnits) {
    if (unit < 65 || unit > 90) {
      return '';
    }
  }
  return code;
}

String clampShort(String raw, [int max = kMaxShortLine]) {
  final t = raw.trim();
  if (t.length <= max) {
    return t;
  }
  return t.substring(0, max);
}

String clampTips(String raw) => clampShort(raw, kMaxTipsBody);

class AccessRoute {
  const AccessRoute({
    this.from = '',
    this.transport = const [],
    this.duration = '',
    this.cost = '',
    this.tips = '',
  });

  factory AccessRoute.fromMap(Map<String, dynamic> data) {
    final transport = <String>[
      for (final item in (data['transport'] as List<dynamic>? ?? const []))
        if (item is String && kAccessTransportCodes.contains(item)) item,
    ];
    return AccessRoute(
      from: clampShort(data['from'] as String? ?? ''),
      transport: transport,
      duration: clampShort(data['duration'] as String? ?? ''),
      cost: clampShort(data['cost'] as String? ?? ''),
      tips: clampTips(data['tips'] as String? ?? ''),
    );
  }

  final String from;
  final List<String> transport;
  final String duration;
  final String cost;
  final String tips;

  bool get isEmpty =>
      from.isEmpty &&
      transport.isEmpty &&
      duration.isEmpty &&
      cost.isEmpty &&
      tips.isEmpty;

  Map<String, dynamic> toMap() => {
        'from': from,
        'transport': transport,
        'duration': duration,
        'cost': cost,
        'tips': tips,
      };

  static List<AccessRoute> listFrom(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <AccessRoute>[];
    for (final item in raw) {
      if (out.length >= kMaxAccessRoutes) {
        break;
      }
      if (item is Map) {
        final route = AccessRoute.fromMap(Map<String, dynamic>.from(item));
        if (!route.isEmpty) {
          out.add(route);
        }
      }
    }
    return out;
  }
}

class NearbySpot {
  const NearbySpot({
    this.name = '',
    this.distance = '',
    this.blurb = '',
  });

  factory NearbySpot.fromMap(Map<String, dynamic> data) {
    return NearbySpot(
      name: clampShort(data['name'] as String? ?? ''),
      distance: clampShort(data['distance'] as String? ?? ''),
      blurb: clampShort(data['blurb'] as String? ?? ''),
    );
  }

  final String name;
  final String distance;
  final String blurb;

  bool get isEmpty => name.isEmpty && distance.isEmpty && blurb.isEmpty;

  Map<String, dynamic> toMap() => {
        'name': name,
        'distance': distance,
        'blurb': blurb,
      };

  static List<NearbySpot> listFrom(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final out = <NearbySpot>[];
    for (final item in raw) {
      if (out.length >= kMaxNearbySpots) {
        break;
      }
      if (item is Map) {
        final spot = NearbySpot.fromMap(Map<String, dynamic>.from(item));
        if (!spot.isEmpty) {
          out.add(spot);
        }
      }
    }
    return out;
  }
}

List<String> stringListFrom(
  dynamic raw, {
  required int maxItems,
  int maxLen = kMaxShortLine,
}) {
  if (raw is! List) {
    return const [];
  }
  final out = <String>[];
  for (final item in raw) {
    if (out.length >= maxItems) {
      break;
    }
    if (item is String) {
      final t = clampShort(item, maxLen);
      if (t.isNotEmpty) {
        out.add(t);
      }
    }
  }
  return out;
}

/// Stored spoken-language codes. Display names stay in l10n.
const kShopLanguageCodes = <String>[
  'ko',
  'en',
  'ja',
  'zh',
  'th',
  'id',
  'es',
];

List<String> shopLanguageCodesFrom(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  final out = <String>[];
  for (final item in raw) {
    if (item is! String || !kShopLanguageCodes.contains(item)) {
      continue;
    }
    if (!out.contains(item)) {
      out.add(item);
    }
  }
  return out;
}

List<int> shopMonthsFrom(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  final months = <int>{};
  for (final item in raw) {
    final month = item is num ? item.toInt() : null;
    if (month != null && month >= 1 && month <= 12) {
      months.add(month);
    }
  }
  final sorted = months.toList()..sort();
  return sorted;
}

List<int> shopClosedDaysFrom(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  final days = <int>{};
  for (final item in raw) {
    final day = item is num ? item.toInt() : null;
    if (day != null && day >= 1 && day <= 7) {
      days.add(day);
    }
  }
  final sorted = days.toList()..sort();
  return sorted;
}

/// One span is `3월 ~ 11월`. A gap is `3~6월, 9~11월`. A lone month is `3월`.
/// English is `Mar–Nov`, `Mar–Jun, Sep–Nov`, or `Mar`.
/// December does not join January.
String summarizeOperatingMonths(List<int> months, [AppLocalizations? l10n]) {
  final sorted = shopMonthsFrom(months);
  if (sorted.isEmpty) {
    return '';
  }
  final ranges = <(int, int)>[];
  var start = sorted.first;
  var previous = sorted.first;
  for (final month in sorted.skip(1)) {
    if (month == previous + 1) {
      previous = month;
      continue;
    }
    ranges.add((start, previous));
    start = month;
    previous = month;
  }
  ranges.add((start, previous));
  final english = l10n != null && l10n.localeName.startsWith('en');
  if (english) {
    return [
      for (final range in ranges)
        _englishMonthRange(l10n, range.$1, range.$2),
    ].join(', ');
  }
  if (ranges.length == 1) {
    final range = ranges.first;
    if (range.$1 == range.$2) {
      return '${range.$1}월';
    }
    return '${range.$1}월 ~ ${range.$2}월';
  }
  return [
    for (final range in ranges)
      if (range.$1 == range.$2) '${range.$1}월' else '${range.$1}~${range.$2}월',
  ].join(', ');
}

String _englishMonthRange(AppLocalizations l10n, int start, int end) {
  final first = _englishMonth(l10n, start);
  if (start == end) {
    return first;
  }
  return '$first–${_englishMonth(l10n, end)}';
}

String _englishMonth(AppLocalizations l10n, int month) {
  return switch (month) {
    1 => l10n.exploreShopMonth1,
    2 => l10n.exploreShopMonth2,
    3 => l10n.exploreShopMonth3,
    4 => l10n.exploreShopMonth4,
    5 => l10n.exploreShopMonth5,
    6 => l10n.exploreShopMonth6,
    7 => l10n.exploreShopMonth7,
    8 => l10n.exploreShopMonth8,
    9 => l10n.exploreShopMonth9,
    10 => l10n.exploreShopMonth10,
    11 => l10n.exploreShopMonth11,
    12 => l10n.exploreShopMonth12,
    _ => '$month',
  };
}

/// Guest label for a stored Korean amenity. Unknown shop text stays as stored.
String localizedAmenityLabel(AppLocalizations l10n, String stored) {
  return switch (stored) {
    '풀장' => l10n.exploreAmenityPool,
    '와이파이' => l10n.exploreAmenityWifi,
    '식당' => l10n.exploreAmenityRestaurant,
    '장비 렌탈' => l10n.exploreAmenityGearRental,
    '나이트록스' => l10n.exploreAmenityNitrox,
    '쇼어 다이빙' => l10n.exploreAmenityShoreDiving,
    '스피드보트' => l10n.exploreAmenitySpeedboat,
    '세탁' => l10n.exploreAmenityLaundry,
    '주차' => l10n.exploreAmenityParking,
    '에어컨' => l10n.exploreAmenityAirConditioning,
    '공항 픽업' => l10n.exploreAmenityAirportPickup,
    '장비 세척장' => l10n.exploreAmenityGearRinse,
    '짐 보관' => l10n.exploreAmenityLuggageStorage,
    _ => stored,
  };
}
