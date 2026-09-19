/// 관리자가 정한 강사 우대 할인. 소비자가에서 비율 또는 정액으로 계산합니다.
enum InstructorDiscountKind { percent, amount }

class InstructorDiscount {
  const InstructorDiscount({
    this.kind = InstructorDiscountKind.percent,
    this.value = defaultPercent,
  });

  static const defaultPercent = 30;

  static const standard = InstructorDiscount();

  factory InstructorDiscount.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return standard;
    }
    final kindRaw = (data['kind'] as String? ?? 'percent').toLowerCase();
    final kind = kindRaw == 'amount'
        ? InstructorDiscountKind.amount
        : InstructorDiscountKind.percent;
    final value = (data['value'] as num?)?.toInt() ?? defaultPercent;
    return InstructorDiscount(kind: kind, value: value.clamp(0, 100000000));
  }

  final InstructorDiscountKind kind;
  final int value;

  int apply(int consumerPrice) {
    if (consumerPrice <= 0) {
      return 0;
    }
    if (kind == InstructorDiscountKind.percent) {
      final pct = value.clamp(0, 90);
      return ((consumerPrice * (100 - pct)) / 100).round();
    }
    return (consumerPrice - value).clamp(0, consumerPrice);
  }

  Map<String, dynamic> toMap() {
    return {
      'kind': kind == InstructorDiscountKind.amount ? 'amount' : 'percent',
      'value': value,
    };
  }

  InstructorDiscount copyWith({
    InstructorDiscountKind? kind,
    int? value,
  }) {
    return InstructorDiscount(
      kind: kind ?? this.kind,
      value: value ?? this.value,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InstructorDiscount &&
        other.kind == kind &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(kind, value);
}
