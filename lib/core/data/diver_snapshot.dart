import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/region_catalog.dart';
import 'package:dive_travel_app/core/models/dive_log.dart';
import 'package:dive_travel_app/core/models/dive_region.dart';
import 'package:dive_travel_app/core/models/diver_stats.dart';
import 'package:dive_travel_app/core/models/member_grade.dart';
import 'package:dive_travel_app/core/models/pro_verification.dart';

class DiverSnapshot {
  const DiverSnapshot({
    required this.stats,
    required this.regions,
    required this.logs,
  });

  factory DiverSnapshot.empty({
    String displayName = '다이버',
    bool isInstructor = false,
    ProVerificationStatus proStatus = ProVerificationStatus.none,
    bool isAdmin = false,
    bool isBusiness = false,
    String? ownedShopId,
    MemberGrade memberGrade = MemberGrade.member,
  }) {
    return DiverSnapshot(
      stats: DiverStats(
        displayName: displayName,
        totalLogCount: 0,
        uniqueRegionsCount: 0,
        isInstructor: isInstructor,
        proStatus: proStatus,
        isAdmin: isAdmin,
        isBusiness: isBusiness,
        ownedShopId: ownedShopId,
        memberGrade: memberGrade,
      ),
      regions: const [],
      logs: const [],
    );
  }

  /// Firestore `users/{uid}` 문서의 집계 필드를 지도·산소통의 기준으로 씁니다.
  factory DiverSnapshot.fromUserDocument({
    required Map<String, dynamic> data,
    required List<DiveLog> logs,
  }) {
    final visited = [
      for (final value in (data['visited_regions'] as List<dynamic>? ?? const []))
        if (value is String && value.trim().isNotEmpty) value.trim(),
    ];
    final counts = Map<String, dynamic>.from(
      data['region_log_counts'] as Map<String, dynamic>? ?? const {},
    );
    final regions = [
      for (final name in visited)
        RegionCatalog.resolve(
          name,
          (counts[name] as num?)?.toInt() ?? 1,
        ),
    ];

    if (regions.isEmpty && logs.isNotEmpty) {
      return DiverSnapshot.fromLogs(
        displayName: _displayNameOf(data),
        isInstructor: data['is_instructor'] == true,
        proStatus: ProVerificationStatus.parse(data['is_verified_pro']),
        isAdmin: _isAdminOf(data),
        isBusiness: _isBusinessOf(data),
        ownedShopId: data['owned_shop_id'] as String?,
        memberGrade: _memberGradeOf(data),
        logs: logs,
      );
    }

    return DiverSnapshot(
      stats: DiverStats(
        displayName: _displayNameOf(data),
        totalLogCount:
            (data['total_log_count'] as num?)?.toInt() ?? logs.length,
        uniqueRegionsCount:
            (data['unique_regions_count'] as num?)?.toInt() ?? regions.length,
        isInstructor: data['is_instructor'] == true,
        proStatus: ProVerificationStatus.parse(data['is_verified_pro']),
        isAdmin: _isAdminOf(data),
        isBusiness: _isBusinessOf(data),
        ownedShopId: data['owned_shop_id'] as String?,
        memberGrade: _memberGradeOf(data),
      ),
      regions: regions,
      logs: logs,
    );
  }

  /// 지도 마커는 카탈로그 시드가 아니라 실제 로그에서만 만듭니다.
  factory DiverSnapshot.fromLogs({
    required String displayName,
    required bool isInstructor,
    required ProVerificationStatus proStatus,
    required List<DiveLog> logs,
    bool isAdmin = false,
    bool isBusiness = false,
    String? ownedShopId,
    MemberGrade memberGrade = MemberGrade.member,
  }) {
    final grouped = <String, DiveRegion>{};
    for (final log in logs) {
      final resolved = RegionCatalog.resolve(log.siteName, 1);
      final current = grouped[resolved.id];
      grouped[resolved.id] = resolved.copyWith(
        logCount: (current?.logCount ?? 0) + 1,
      );
    }
    final regions = grouped.values.toList();
    return DiverSnapshot(
      stats: DiverStats(
        displayName: displayName,
        totalLogCount: logs.length,
        uniqueRegionsCount: regions.length,
        isInstructor: isInstructor,
        proStatus: proStatus,
        isAdmin: isAdmin,
        isBusiness: isBusiness,
        ownedShopId: ownedShopId,
        memberGrade: memberGrade,
      ),
      regions: regions,
      logs: logs,
    );
  }

  static MemberGrade _memberGradeOf(Map<String, dynamic> data) {
    return MemberGrade.parse(
      data['member_grade'] ?? data['memberGrade'],
      isInstructor: data['is_instructor'] == true,
    );
  }

  static bool _isAdminOf(Map<String, dynamic> data) {
    return data['is_admin'] == true ||
        data['isAdmin'] == true ||
        AppOwner.isOwnerEmail(data['email'] as String?) ||
        AppConstants.grantAdminToCurrentSession;
  }

  static bool _isBusinessOf(Map<String, dynamic> data) {
    return data['is_business'] == true ||
        data['isBusiness'] == true ||
        (data['user_role'] as String?) == 'business' ||
        AppConstants.grantBusinessToCurrentSession;
  }

  static String _displayNameOf(Map<String, dynamic> data) {
    return (data['display_name'] as String?) ??
        (data['email'] as String?)?.split('@').first ??
        '다이버';
  }

  final DiverStats stats;
  final List<DiveRegion> regions;
  final List<DiveLog> logs;
}
