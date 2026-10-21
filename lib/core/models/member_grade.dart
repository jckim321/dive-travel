/// 신규 가입 기본값은 [silver]. 승급은 관리자가 활동 기준으로 조정합니다.
enum MemberGrade {
  silver,
  gold,
  diamond,
  platinum;

  static const valuesInOrder = [
    MemberGrade.silver,
    MemberGrade.gold,
    MemberGrade.diamond,
    MemberGrade.platinum,
  ];

  static MemberGrade parse(dynamic value, {bool isInstructor = false}) {
    final parsed = switch (value) {
      'silver' || 'member' => MemberGrade.silver,
      'gold' || 'special' => MemberGrade.gold,
      'diamond' || 'vip' => MemberGrade.diamond,
      'platinum' || 'instructor' => MemberGrade.platinum,
      _ => MemberGrade.silver,
    };
    // Legacy docs sometimes omit grade; instructor role alone does not change tier.
    return isInstructor && value == null ? MemberGrade.silver : parsed;
  }

  String get firestoreValue {
    switch (this) {
      case MemberGrade.silver:
        return 'silver';
      case MemberGrade.gold:
        return 'gold';
      case MemberGrade.diamond:
        return 'diamond';
      case MemberGrade.platinum:
        return 'platinum';
    }
  }

  /// 자동 승급이 아니라 관리자 화면의 참고용입니다.
  static MemberGrade suggested({
    required int totalLogCount,
    required int uniqueRegionsCount,
    required bool isInstructor,
  }) {
    // Role (instructor) is separate from membership tier.
    if (totalLogCount >= 50 || uniqueRegionsCount >= 5) {
      return MemberGrade.platinum;
    }
    if (totalLogCount >= 25 || uniqueRegionsCount >= 3) {
      return MemberGrade.diamond;
    }
    if (totalLogCount >= 10) {
      return MemberGrade.gold;
    }
    return MemberGrade.silver;
  }
}

/// 상단 프로필에만 보이는 이용 등급. 저장된 [MemberGrade]는 바꾸지 않습니다.
enum ProfileDisplayGrade {
  silver,
  gold,
  diamond,
  platinum,
  instructor;

  static ProfileDisplayGrade fromUse({
    required int paidBookings,
    required bool isInstructor,
  }) {
    if (isInstructor) {
      return ProfileDisplayGrade.instructor;
    }
    if (paidBookings >= 10) {
      return ProfileDisplayGrade.platinum;
    }
    if (paidBookings >= 5) {
      return ProfileDisplayGrade.diamond;
    }
    if (paidBookings >= 1) {
      return ProfileDisplayGrade.gold;
    }
    return ProfileDisplayGrade.silver;
  }
}
