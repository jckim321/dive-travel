/// 신규 가입 기본값은 [silver]. 활동 기준 자동 승급 + 관리자 수동 조정.
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

  int get rank => valuesInOrder.indexOf(this);

  static MemberGrade parse(dynamic value, {bool isInstructor = false}) {
    final parsed = switch (value) {
      'silver' || 'member' => MemberGrade.silver,
      'gold' || 'special' => MemberGrade.gold,
      'diamond' || 'vip' => MemberGrade.diamond,
      'platinum' || 'instructor' => MemberGrade.platinum,
      _ => MemberGrade.silver,
    };
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

  /// 구매·리뷰 동시충족(AND). 골드 3/1, 다이아 10/5, 플래티넘 30/15.
  static MemberGrade fromActivity({
    required int paidPurchases,
    required int reviews,
  }) {
    if (paidPurchases >= 30 && reviews >= 15) {
      return MemberGrade.platinum;
    }
    if (paidPurchases >= 10 && reviews >= 5) {
      return MemberGrade.diamond;
    }
    if (paidPurchases >= 3 && reviews >= 1) {
      return MemberGrade.gold;
    }
    return MemberGrade.silver;
  }

  /// 관리자 참고용 — [fromActivity]와 동일.
  static MemberGrade suggested({
    required int paidPurchases,
    required int reviews,
    int totalLogCount = 0,
    int uniqueRegionsCount = 0,
    bool isInstructor = false,
  }) {
    return fromActivity(paidPurchases: paidPurchases, reviews: reviews);
  }

  static MemberGrade higher(MemberGrade a, MemberGrade b) {
    return a.rank >= b.rank ? a : b;
  }

  /// 다음 등급까지 부족한 구매·리뷰. 이미 플래티넘이면 (0,0).
  static (int purchases, int reviews) deficitToNext({
    required MemberGrade current,
    required int paidPurchases,
    required int reviews,
  }) {
    final target = switch (current) {
      MemberGrade.silver => (3, 1),
      MemberGrade.gold => (10, 5),
      MemberGrade.diamond => (30, 15),
      MemberGrade.platinum => (0, 0),
    };
    if (target.$1 == 0 && target.$2 == 0) {
      return (0, 0);
    }
    final needP = (target.$1 - paidPurchases).clamp(0, 999);
    final needR = (target.$2 - reviews).clamp(0, 999);
    return (needP, needR);
  }
}

/// 마이페이지 표시용. 저장된 [MemberGrade] (+강사 역할)을 따릅니다.
enum ProfileDisplayGrade {
  silver,
  gold,
  diamond,
  platinum,
  instructor;

  static ProfileDisplayGrade fromMember({
    required MemberGrade grade,
    required bool isInstructor,
  }) {
    if (isInstructor) {
      return ProfileDisplayGrade.instructor;
    }
    return switch (grade) {
      MemberGrade.silver => ProfileDisplayGrade.silver,
      MemberGrade.gold => ProfileDisplayGrade.gold,
      MemberGrade.diamond => ProfileDisplayGrade.diamond,
      MemberGrade.platinum => ProfileDisplayGrade.platinum,
    };
  }

  /// 레거시 호출 호환 — [fromMember] 사용을 권장.
  static ProfileDisplayGrade fromUse({
    required int paidBookings,
    required bool isInstructor,
    MemberGrade? memberGrade,
  }) {
    if (memberGrade != null) {
      return fromMember(grade: memberGrade, isInstructor: isInstructor);
    }
    if (isInstructor) {
      return ProfileDisplayGrade.instructor;
    }
    return fromMember(
      grade: MemberGrade.fromActivity(
        paidPurchases: paidBookings,
        reviews: paidBookings > 0 ? 1 : 0,
      ),
      isInstructor: false,
    );
  }
}
