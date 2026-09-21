/// 신규 가입 기본값은 [member]. 승급은 관리자가 활동 기준으로 조정합니다.
enum MemberGrade {
  member,
  special,
  vip,
  instructor;

  static const valuesInOrder = [
    MemberGrade.member,
    MemberGrade.special,
    MemberGrade.vip,
    MemberGrade.instructor,
  ];

  static MemberGrade parse(dynamic value, {bool isInstructor = false}) {
    switch (value) {
      case 'special':
        return MemberGrade.special;
      case 'vip':
        return MemberGrade.vip;
      case 'instructor':
        return MemberGrade.instructor;
      case 'member':
        return MemberGrade.member;
      default:
        return isInstructor ? MemberGrade.instructor : MemberGrade.member;
    }
  }

  String get firestoreValue {
    switch (this) {
      case MemberGrade.member:
        return 'member';
      case MemberGrade.special:
        return 'special';
      case MemberGrade.vip:
        return 'vip';
      case MemberGrade.instructor:
        return 'instructor';
    }
  }

  /// 자동 승급이 아니라 관리자 화면의 참고용입니다.
  static MemberGrade suggested({
    required int totalLogCount,
    required int uniqueRegionsCount,
    required bool isInstructor,
  }) {
    if (isInstructor) {
      return MemberGrade.instructor;
    }
    if (totalLogCount >= 50 || uniqueRegionsCount >= 5) {
      return MemberGrade.vip;
    }
    if (totalLogCount >= 10) {
      return MemberGrade.special;
    }
    return MemberGrade.member;
  }
}
