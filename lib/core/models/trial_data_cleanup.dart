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
    );
  }
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
  });

  final int successCount;
  final int failureCount;
  final List<String> notes;
  final List<String> failedIds;
}

/// Exact display name used to resolve the live protected shop.
const String kJejuOrangeShopName = '제주 오렌지';

/// Confirmation phrase the admin must type (Korean).
const String kTrialDeleteConfirmPhrase = '삭제합니다';
