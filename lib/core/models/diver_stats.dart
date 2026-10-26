import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';

class DiverStats {
  const DiverStats({
    required this.displayName,
    required this.totalLogCount,
    required this.uniqueRegionsCount,
    required this.isInstructor,
    this.proStatus = ProVerificationStatus.none,
    this.isAdmin = false,
    this.isBusiness = false,
    this.ownedShopId,
    this.memberGrade = MemberGrade.silver,
    this.paidPurchaseCount = 0,
    this.reviewCount = 0,
    this.gradeLocked = false,
    this.gradeCelebrationPending = false,
    this.gradeCelebrationTo,
    this.nationality = '',
    this.nationalityConsentAt,
    this.birthDate = '',
    this.phone = '',
  });

  final String displayName;
  final int totalLogCount;
  final int uniqueRegionsCount;
  final bool isInstructor;
  final ProVerificationStatus proStatus;
  final bool isAdmin;
  final bool isBusiness;
  final String? ownedShopId;
  final MemberGrade memberGrade;
  final int paidPurchaseCount;
  final int reviewCount;
  final bool gradeLocked;
  final bool gradeCelebrationPending;
  final MemberGrade? gradeCelebrationTo;
  final String nationality;
  final DateTime? nationalityConsentAt;

  /// Profile birth date (`yyyy-MM-dd`) when the user document has one.
  final String birthDate;

  /// Profile phone when the user document has one.
  final String phone;

  bool get isVerifiedPro => proStatus == ProVerificationStatus.approved;
  bool get isProPending => proStatus == ProVerificationStatus.pending;

  static const int masterLogTarget = 100;
  static const int tankRackCount = 10;
  static const int logsPerTank = 10;
  static const int centuryLogs = 100;
  static const int legendLogTarget = 1000;
  static const int centuryRackCount = 10;

  double get masterProgress =>
      (totalLogCount / masterLogTarget).clamp(0.0, 1.0);

  bool get hasReachedMaster => totalLogCount >= masterLogTarget;

  bool get hasReachedLegend => totalLogCount >= legendLogTarget;

  /// 지금 채우는 100로그 구간의 목표 (100, 200, … 1000).
  int get currentCenturyTarget {
    if (totalLogCount >= legendLogTarget) {
      return legendLogTarget;
    }
    if (totalLogCount <= 0) {
      return masterLogTarget;
    }
    if (totalLogCount % centuryLogs == 0) {
      return totalLogCount;
    }
    return ((totalLogCount ~/ centuryLogs) + 1) * centuryLogs;
  }

  /// 현재 100로그 구간이 찬 비율. 100, 200처럼 딱 맞으면 1.0입니다.
  double get centuryProgress {
    if (totalLogCount >= legendLogTarget) {
      return 1;
    }
    if (totalLogCount <= 0) {
      return 0;
    }
    if (totalLogCount % centuryLogs == 0) {
      return 1;
    }
    return (totalLogCount % centuryLogs) / centuryLogs;
  }

  int get logsToNextCentury {
    if (hasReachedLegend) {
      return 0;
    }
    return currentCenturyTarget - totalLogCount;
  }

  /// 탱크 [index](0~9)가 10로그씩 채워지는 비율입니다.
  double tankFill(int index) {
    final start = index * logsPerTank;
    return ((totalLogCount - start) / logsPerTank).clamp(0.0, 1.0);
  }

  /// 100·200·…·1000 칸의 채움 비율입니다.
  double centuryFill(int index) {
    final start = index * centuryLogs;
    return ((totalLogCount - start) / centuryLogs).clamp(0.0, 1.0);
  }

  DiverStats copyWith({
    int? totalLogCount,
    int? uniqueRegionsCount,
    ProVerificationStatus? proStatus,
    bool? isInstructor,
    bool? isAdmin,
    bool? isBusiness,
    String? ownedShopId,
    MemberGrade? memberGrade,
    int? paidPurchaseCount,
    int? reviewCount,
    bool? gradeLocked,
    bool? gradeCelebrationPending,
    MemberGrade? gradeCelebrationTo,
    String? nationality,
    DateTime? nationalityConsentAt,
    String? birthDate,
    String? phone,
    bool clearCelebrationTo = false,
    bool clearNationalityConsentAt = false,
    bool clearOwnedShopId = false,
  }) {
    return DiverStats(
      displayName: displayName,
      totalLogCount: totalLogCount ?? this.totalLogCount,
      uniqueRegionsCount: uniqueRegionsCount ?? this.uniqueRegionsCount,
      isInstructor: isInstructor ?? this.isInstructor,
      proStatus: proStatus ?? this.proStatus,
      isAdmin: isAdmin ?? this.isAdmin,
      isBusiness: isBusiness ?? this.isBusiness,
      ownedShopId: clearOwnedShopId
          ? null
          : (ownedShopId ?? this.ownedShopId),
      memberGrade: memberGrade ?? this.memberGrade,
      paidPurchaseCount: paidPurchaseCount ?? this.paidPurchaseCount,
      reviewCount: reviewCount ?? this.reviewCount,
      gradeLocked: gradeLocked ?? this.gradeLocked,
      gradeCelebrationPending:
          gradeCelebrationPending ?? this.gradeCelebrationPending,
      gradeCelebrationTo: clearCelebrationTo
          ? null
          : (gradeCelebrationTo ?? this.gradeCelebrationTo),
      nationality: nationality ?? this.nationality,
      nationalityConsentAt: clearNationalityConsentAt
          ? null
          : (nationalityConsentAt ?? this.nationalityConsentAt),
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
    );
  }
}
