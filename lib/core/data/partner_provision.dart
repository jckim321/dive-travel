import 'dart:math';

import 'package:dive_travel_app/core/auth/auth_identity.dart';
import 'package:dive_travel_app/core/models/partner_meeting_report.dart';
import 'package:dive_travel_app/core/models/shop_hull_id.dart';

/// A users doc already stored for this login id.
class PartnerLoginHit {
  const PartnerLoginHit({
    required this.uid,
    required this.isBusiness,
    required this.ownedShopId,
    required this.hasUserDoc,
  });

  final String uid;
  final bool isBusiness;
  final String ownedShopId;
  final bool hasUserDoc;
}

/// Auth user the secondary app just created or signed in.
class ProvisionedDiver {
  const ProvisionedDiver({required this.uid, required this.createdAuth});

  final String uid;

  /// True only when Auth `createUser` ran. A resume sign-in is false.
  final bool createdAuth;
}

/// What [runPartnerProvision] hands the secondary app. The password lives
/// only for this call.
class PartnerDiverDraft {
  const PartnerDiverDraft({
    required this.email,
    required this.password,
    required this.displayName,
    required this.storedLoginId,
    required this.signInExisting,
  });

  final String email;
  final String password;
  final String displayName;
  final String storedLoginId;
  final bool signInExisting;
}

/// Returned to the caller. [password] is the typed value, never read back
/// from storage. A shop-name choice leaves it empty.
class PartnerProvisionResult {
  const PartnerProvisionResult.ready({
    required this.loginId,
    required this.password,
    required this.hullId,
    required this.uid,
    required this.createdAccount,
  }) : choices = const [];

  const PartnerProvisionResult.choose(this.choices)
      : loginId = '',
        password = '',
        hullId = '',
        uid = '',
        createdAccount = false;

  final String loginId;
  final String password;
  final String hullId;
  final String uid;
  final bool createdAccount;
  final List<ShopHullChoice> choices;

  bool get needsChoice => choices.length > 1;
}

/// Which provision write failed. [none] is a check before those writes.
enum PartnerProvisionStep { none, shop, account, link }

/// The step that failed, plus the underlying code and message.
class PartnerProvisionFailure implements Exception {
  const PartnerProvisionFailure({
    required this.step,
    required this.code,
    required this.message,
    this.accountCreated = false,
  });

  factory PartnerProvisionFailure.wrap(
    Object error, {
    PartnerProvisionStep step = PartnerProvisionStep.none,
    bool accountCreated = false,
  }) {
    if (error is PartnerProvisionFailure) {
      return error;
    }
    return PartnerProvisionFailure(
      step: step,
      code: partnerProvisionErrorCode(error),
      message: partnerProvisionErrorMessage(error),
      accountCreated: accountCreated,
    );
  }

  final PartnerProvisionStep step;
  final String code;
  final String message;
  final bool accountCreated;
}

String partnerProvisionErrorCode(Object error) {
  if (error is StateError) {
    return error.message;
  }
  final code = _field(error, 'code');
  if (code is String && code.trim().isNotEmpty) {
    return code.trim();
  }
  return error.runtimeType.toString();
}

String partnerProvisionErrorMessage(Object error) {
  if (error is StateError) {
    return error.message;
  }
  final message = _field(error, 'message');
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }
  final text = '$error'.trim();
  return text.isEmpty ? partnerProvisionErrorCode(error) : text;
}

Object? _field(Object error, String name) {
  try {
    final dynamic blown = error;
    return name == 'code' ? blown.code : blown.message;
  } catch (_) {
    return null;
  }
}

/// Validate, resolve one shop hull, create a diver only when missing, then
/// promote that hull. Does not write the password anywhere.
Future<PartnerProvisionResult> runPartnerProvision({
  required String shopName,
  required String loginId,
  required String password,
  required String actorUid,
  required String actorName,
  String? selectedHullId,
  required Future<ShopHullResolve> Function(String name) ensureShop,
  required Future<PartnerLoginHit?> Function(String storedLoginId) findLogin,
  required Future<bool> Function(String hullId, String exceptUid) hullClaimedByOther,
  required Future<ProvisionedDiver> Function(PartnerDiverDraft draft) createDiver,
  required Future<void> Function({
    required String uid,
    required String hullId,
    required String actorUid,
    required String actorName,
  }) promote,
  required String? Function() primaryUid,
}) async {
  final name = shopName.trim();
  if (name.isEmpty) {
    throw StateError('SHOP_NAME_REQUIRED');
  }
  final issue = AuthIdentity.nameTagIssue(loginId);
  if (issue != null) {
    throw StateError(_loginIssueCode(issue));
  }
  if (password.length < 6) {
    throw StateError('WEAK_PASSWORD');
  }
  final stored = AuthIdentity.storedLoginId(loginId);
  final email = AuthIdentity.toAuthEmail(loginId);
  final String hull;
  final selected = selectedHullId?.trim() ?? '';
  if (selected.isNotEmpty) {
    hull = partnerShopHull(selected);
  } else {
    final shop = await _guard(PartnerProvisionStep.shop, () => ensureShop(name));
    if (shop.needsChoice) {
      return PartnerProvisionResult.choose(shop.choices);
    }
    hull = shop.hullId.trim();
  }
  if (hull.isEmpty || hull.contains('--')) {
    throw StateError('SHOP_HULL_EMPTY');
  }
  final existing = await _guard(
    PartnerProvisionStep.account,
    () => findLogin(stored),
  );
  if (existing != null && existing.isBusiness) {
    if (partnerShopHull(existing.ownedShopId) == hull) {
      return PartnerProvisionResult.ready(
        loginId: stored,
        password: password,
        hullId: hull,
        uid: existing.uid,
        createdAccount: false,
      );
    }
    throw StateError('ALREADY_PARTNER');
  }
  if (await _guard(
    PartnerProvisionStep.account,
    () => hullClaimedByOther(hull, existing?.uid ?? ''),
  )) {
    throw StateError('SHOP_ALREADY_OWNED');
  }
  final adminUid = primaryUid();
  late final String uid;
  var createdAccount = false;
  if (existing == null || !existing.hasUserDoc) {
    final made = await _guard(PartnerProvisionStep.account, () {
      return createDiver(
        PartnerDiverDraft(
          email: email,
          password: password,
          displayName: name,
          storedLoginId: stored,
          signInExisting: existing != null && !existing.hasUserDoc,
        ),
      );
    });
    if (primaryUid() != adminUid) {
      throw const PartnerProvisionFailure(
        step: PartnerProvisionStep.account,
        code: 'ADMIN_SESSION_LOST',
        message: 'ADMIN_SESSION_LOST',
      );
    }
    uid = made.uid;
    createdAccount = made.createdAuth;
  } else {
    uid = existing.uid;
  }
  try {
    await promote(
      uid: uid,
      hullId: hull,
      actorUid: actorUid,
      actorName: actorName,
    );
  } catch (error) {
    throw PartnerProvisionFailure.wrap(
      error,
      step: PartnerProvisionStep.link,
      accountCreated: createdAccount,
    );
  }
  return PartnerProvisionResult.ready(
    loginId: stored,
    password: password,
    hullId: hull,
    uid: uid,
    createdAccount: createdAccount,
  );
}

/// 12 characters the admin can edit. Not stored.
String generatePartnerPassword() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  final random = Random.secure();
  return List.generate(
    12,
    (_) => alphabet[random.nextInt(alphabet.length)],
  ).join();
}

Future<T> _guard<T>(
  PartnerProvisionStep step,
  Future<T> Function() body,
) async {
  try {
    return await body();
  } catch (error) {
    throw PartnerProvisionFailure.wrap(error, step: step);
  }
}

String _loginIssueCode(NameTagIssue issue) {
  return switch (issue) {
    NameTagIssue.empty => 'LOGIN_ID_EMPTY',
    NameTagIssue.reserved => 'LOGIN_ID_RESERVED',
    NameTagIssue.format => 'LOGIN_ID_FORMAT',
    NameTagIssue.tooLong => 'LOGIN_ID_TOO_LONG',
  };
}
