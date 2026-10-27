import 'package:dive_travel_app/core/models/partner_meeting_report.dart';

/// One shop document whose `name` matched the requested shop name.
class ShopHullChoice {
  const ShopHullChoice({required this.documentId, required this.name});

  final String documentId;
  final String name;

  /// Document id with any `--product` suffix removed.
  String get hullId => partnerShopHull(documentId);
}

/// Result of finding or creating the single hull for a shop name.
class ShopHullResolve {
  const ShopHullResolve.existing(this.hullId)
      : created = false,
        choices = const [];

  const ShopHullResolve.created(this.hullId)
      : created = true,
        choices = const [];

  const ShopHullResolve.choose(this.choices)
      : hullId = '',
        created = false;

  final String hullId;
  final bool created;
  final List<ShopHullChoice> choices;

  bool get needsChoice => choices.length > 1;
}

/// What [decideShopHull] tells the repository to do. No writes happen here.
class ShopHullDecision {
  const ShopHullDecision.use(this.hullId)
      : createId = null,
        choices = const [];

  const ShopHullDecision.create(this.createId)
      : hullId = '',
        choices = const [];

  const ShopHullDecision.choose(this.choices)
      : hullId = '',
        createId = null;

  final String hullId;
  final String? createId;
  final List<ShopHullChoice> choices;
}

/// Slug used as a shop document id. `--` never appears; non-latin names
/// become `shop`.
String shopHullSlug(String name) {
  final slug = name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final base = slug.isEmpty ? 'shop' : slug;
  if (base.contains('--')) {
    throw StateError('SHOP_HULL_INVALID');
  }
  return base;
}

/// Id for a new shop. If [documentExists] is true for the slug, append
/// [collisionSuffix] (and a counter) so the id stays one hull.
String freshShopHullId({
  required String name,
  required bool Function(String id) documentExists,
  required String collisionSuffix,
}) {
  final base = shopHullSlug(name);
  if (!documentExists(base)) {
    return base;
  }
  final suffix = collisionSuffix.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '',
  );
  final stem = suffix.isEmpty ? '$base-2' : '$base-$suffix';
  if (!documentExists(stem)) {
    return stem;
  }
  var n = 2;
  while (documentExists('$stem-$n')) {
    n += 1;
    if (n > 50) {
      throw StateError('SHOP_HULL_EXHAUSTED');
    }
  }
  return '$stem-$n';
}

/// One same-name document: use its hull, or create that hull doc if missing.
/// Several: do not create. None: a new hull id that is not already taken.
ShopHullDecision decideShopHull({
  required String name,
  required List<ShopHullChoice> sameName,
  required bool Function(String documentId) documentExists,
  required String collisionSuffix,
}) {
  if (name.trim().isEmpty) {
    throw StateError('SHOP_NAME_REQUIRED');
  }
  if (sameName.length > 1) {
    return ShopHullDecision.choose(sameName);
  }
  if (sameName.length == 1) {
    final hull = sameName.single.hullId.trim();
    if (hull.isEmpty || hull.contains('--')) {
      throw StateError('SHOP_HULL_EMPTY');
    }
    if (documentExists(hull)) {
      return ShopHullDecision.use(hull);
    }
    return ShopHullDecision.create(hull);
  }
  return ShopHullDecision.create(
    freshShopHullId(
      name: name,
      documentExists: documentExists,
      collisionSuffix: collisionSuffix,
    ),
  );
}
