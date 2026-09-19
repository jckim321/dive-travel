/// 유저 변심 취소와 기상 악화 취소의 환불 비율을 계산합니다.
class RefundQuote {
  const RefundQuote({
    required this.percent,
    required this.reason,
    required this.weather,
  });

  final int percent;
  final String reason;
  final bool weather;

  int amountFor(int price) => ((price * percent) / 100).round();

  bool get isFullRefund => percent >= 100;
  bool get isNonRefundable => percent <= 0;
}

abstract final class RefundPolicy {
  static const double minCommissionRate = 0.10;
  static const double maxCommissionRate = 0.15;
  static const double defaultCommissionRate = 0.12;

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int daysUntilTour(DateTime tourDate, {DateTime? now}) {
    return dateOnly(tourDate).difference(dateOnly(now ?? DateTime.now())).inDays;
  }

  /// 단순 변심: 7일 전 100%, 3일 전 50%, 당일(및 2일 이내) 환불 불가.
  static RefundQuote forUserCancel({
    required DateTime tourDate,
    DateTime? now,
  }) {
    final days = daysUntilTour(tourDate, now: now);
    if (days >= 7) {
      return const RefundQuote(
        percent: 100,
        reason: 'guest_7d',
        weather: false,
      );
    }
    if (days >= 3) {
      return const RefundQuote(
        percent: 50,
        reason: 'guest_3d',
        weather: false,
      );
    }
    return const RefundQuote(
      percent: 0,
      reason: 'guest_same_day',
      weather: false,
    );
  }

  static RefundQuote weatherCancel() {
    return const RefundQuote(
      percent: 100,
      reason: 'weather',
      weather: true,
    );
  }

  static int commissionOn(int gross, {double rate = defaultCommissionRate}) {
    final clamped = rate.clamp(minCommissionRate, maxCommissionRate);
    return (gross * clamped).round();
  }

  static int netPayout(int gross, {double rate = defaultCommissionRate}) {
    return gross - commissionOn(gross, rate: rate);
  }
}
