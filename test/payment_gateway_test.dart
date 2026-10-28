import 'package:flutter_test/flutter_test.dart';

import 'package:dive_travel_app/core/payments/payment_gateway.dart';

void main() {
  test('SimPayGateway returns true after its own wait', () async {
    final paid = await const SimPayGateway(delay: Duration.zero).pay(
      amountWon: 300000,
      title: '인원 시험 상품',
    );
    expect(paid, isTrue);
  });
}
