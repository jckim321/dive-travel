import 'package:dive_travel_app/core/constants/app_constants.dart';

/// H9 admin trial-data inspection / selective delete models.

enum TrialDataBucket {
  usersDiver,
  usersPartner,
  usersAdmin,
  usersTotal,
  shops,
  shopProductsEmbedded,
  shopBookings,
  userBookings,
  shopReviews,
  userReviews,
  partnerContracts,
  partnerContractEvents,
  diveStarAssessments,
  posts,
  postComments,
  diveStarApplications,
  partnerEmailOutbox,
  settingsPricing,
  diveStarForms,
  partnerDocuments,
  documentShares,
  partnerDocConfig,
}

enum TrialCountStatus { ok, unavailable, error }

class TrialCountRow {
  const TrialCountRow({
    required this.bucket,
    required this.label,
    required this.pathHint,
    required this.status,
    this.count,
    this.detail,
    this.deletable = false,
    this.protected = false,
  });

  final TrialDataBucket bucket;
  final String label;
  final String pathHint;
  final TrialCountStatus status;
  final int? count;
  final String? detail;
  final bool deletable;
  final bool protected;
}

enum JejuOrangeResolveKind { exactOne, none, ambiguous }

class JejuOrangeResolve {
  const JejuOrangeResolve({
    required this.kind,
    this.shopId,
    this.shopName,
    this.candidates = const [],
  });

  final JejuOrangeResolveKind kind;
  final String? shopId;
  final String? shopName;
  final List<({String id, String name})> candidates;

  bool get blocksDeletion => kind == JejuOrangeResolveKind.ambiguous;

  String? get protectedShopId =>
      kind == JejuOrangeResolveKind.exactOne ? shopId : null;
}

class TrialDataSnapshot {
  const TrialDataSnapshot({
    required this.rows,
    required this.jejuOrange,
    required this.protectedUserUids,
    required this.fetchedAt,
  });

  final List<TrialCountRow> rows;
  final JejuOrangeResolve jejuOrange;
  final Set<String> protectedUserUids;
  final DateTime fetchedAt;
}

/// Which deletable groups the admin checked.
class TrialDeleteSelection {
  const TrialDeleteSelection({
    this.partnerEmailOutbox = false,
    this.diveStarApplications = false,
    this.postsAndComments = false,
    this.reviews = false,
    this.userBookings = false,
    this.userLogs = false,
    this.clearTrialShopProducts = false,
    this.trialShopBookings = false,
    this.trialShops = false,
    this.trialUsers = false,
    this.unconfirmedAssessments = false,
    this.includeJejuOrange = false,
  });

  final bool partnerEmailOutbox;
  final bool diveStarApplications;
  final bool postsAndComments;
  final bool reviews;
  final bool userBookings;
  final bool userLogs;
  final bool clearTrialShopProducts;
  final bool trialShopBookings;
  final bool trialShops;
  final bool trialUsers;
  final bool unconfirmedAssessments;

  /// This run only. Does not count as a delete group by itself.
  final bool includeJejuOrange;

  bool get anySelected =>
      partnerEmailOutbox ||
      diveStarApplications ||
      postsAndComments ||
      reviews ||
      userBookings ||
      userLogs ||
      clearTrialShopProducts ||
      trialShopBookings ||
      trialShops ||
      trialUsers ||
      unconfirmedAssessments;

  TrialDeleteSelection copyWith({
    bool? partnerEmailOutbox,
    bool? diveStarApplications,
    bool? postsAndComments,
    bool? reviews,
    bool? userBookings,
    bool? userLogs,
    bool? clearTrialShopProducts,
    bool? trialShopBookings,
    bool? trialShops,
    bool? trialUsers,
    bool? unconfirmedAssessments,
    bool? includeJejuOrange,
  }) {
    return TrialDeleteSelection(
      partnerEmailOutbox: partnerEmailOutbox ?? this.partnerEmailOutbox,
      diveStarApplications: diveStarApplications ?? this.diveStarApplications,
      postsAndComments: postsAndComments ?? this.postsAndComments,
      reviews: reviews ?? this.reviews,
      userBookings: userBookings ?? this.userBookings,
      userLogs: userLogs ?? this.userLogs,
      clearTrialShopProducts:
          clearTrialShopProducts ?? this.clearTrialShopProducts,
      trialShopBookings: trialShopBookings ?? this.trialShopBookings,
      trialShops: trialShops ?? this.trialShops,
      trialUsers: trialUsers ?? this.trialUsers,
      unconfirmedAssessments:
          unconfirmedAssessments ?? this.unconfirmedAssessments,
      includeJejuOrange: includeJejuOrange ?? this.includeJejuOrange,
    );
  }
}

typedef TrialOwnedAccount = ({String uid, String email, String ownedShopId});

/// Shop and member ids skipped by one cleanup run.
class TrialDeletionGuard {
  const TrialDeletionGuard({required this.shopId, required this.userUids});

  final String? shopId;
  final Set<String> userUids;
}

/// Exact Jeju Orange is skipped unless [includeJejuOrange] is set for this run.
/// The signed-in admin and the app owner stay protected either way.
TrialDeletionGuard trialDeletionGuard({
  required TrialDataSnapshot snapshot,
  required bool includeJejuOrange,
  required String actorUid,
  required String actorEmail,
  Iterable<TrialOwnedAccount> accounts = const [],
}) {
  final exact = snapshot.jejuOrange.protectedShopId;
  if (!includeJejuOrange || exact == null) {
    return TrialDeletionGuard(
      shopId: exact,
      userUids: snapshot.protectedUserUids,
    );
  }
  final actorMail = actorEmail.trim().toLowerCase();
  final uids = {...snapshot.protectedUserUids, actorUid};
  for (final account in accounts) {
    if (account.ownedShopId.trim() != exact) {
      continue;
    }
    final email = account.email.trim().toLowerCase();
    final keep = account.uid == actorUid ||
        AppOwner.isOwnerEmail(email) ||
        (actorMail.isNotEmpty && email == actorMail);
    if (!keep) {
      uids.remove(account.uid);
    }
  }
  return TrialDeletionGuard(shopId: null, userUids: uids);
}

class TrialDeleteProgress {
  const TrialDeleteProgress({
    required this.message,
    required this.done,
    required this.total,
  });

  final String message;
  final int done;
  final int total;

  double get fraction => total <= 0 ? 0 : done / total;
}

class TrialDeleteResult {
  const TrialDeleteResult({
    required this.successCount,
    required this.failureCount,
    required this.notes,
    this.failedIds = const [],
    this.skippedPaths = const [],
  });

  final int successCount;
  final int failureCount;
  final List<String> notes;
  final List<String> failedIds;

  /// Document or collection paths skipped after permission-denied.
  final List<String> skippedPaths;
}

/// Last collection id in a document path (`shops/a/daily_stats/d` → `daily_stats`)
/// or a collection path (`shops/a/daily_stats` → `daily_stats`).
String trialDeleteCollectionName(String path) {
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return path;
  }
  if (parts.length.isEven) {
    return parts[parts.length - 2];
  }
  return parts.last;
}

/// Error line that names the blocked collection and the path.
String trialDeleteDeniedNote(String path) {
  final name = trialDeleteCollectionName(path);
  if (path == name) {
    return 'permission-denied: $name';
  }
  return 'permission-denied: $name ($path)';
}

/// Counts for one cleanup run. Denied paths are skipped; other deletes continue.
class TrialDeleteLedger {
  int success = 0;
  int failure = 0;
  final notes = <String>[];
  final failedIds = <String>[];
  final skipped = <String>[];

  void deleted(int count, String label) {
    if (count <= 0) {
      return;
    }
    success += count;
    notes.add('$label $count건 삭제');
  }

  void failed(Iterable<String> paths, String label, Object error) {
    final list = paths.toList();
    failure += list.isEmpty ? 1 : list.length;
    failedIds.addAll(list);
    notes.add('$label 실패: $error');
  }

  void denied(String path) {
    failure += 1;
    failedIds.add(path);
    skipped.add(path);
    notes.add(trialDeleteDeniedNote(path));
  }

  void note(String message) {
    notes.add(message);
  }

  void finish() {
    final unique = <String>[];
    for (final path in skipped) {
      if (!unique.contains(path)) {
        unique.add(path);
      }
    }
    notes.add(
      unique.isEmpty ? '건너뛴 항목: 없음' : '건너뛴 항목: ${unique.join(', ')}',
    );
  }

  TrialDeleteResult toResult() {
    return TrialDeleteResult(
      successCount: success,
      failureCount: failure,
      notes: notes,
      failedIds: failedIds,
      skippedPaths: List<String>.from(skipped),
    );
  }
}

/// Exact display name used to resolve the live protected shop.
const String kJejuOrangeShopName = '제주 오렌지';

/// Confirmation phrase the admin must type (Korean).
const String kTrialDeleteConfirmPhrase = '삭제합니다';
