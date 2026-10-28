/// One call a real payment provider can replace later.
abstract interface class PaymentGateway {
  /// True only when the charge of [amountWon] succeeds.
  Future<bool> pay({required int amountWon, required String title});
}

/// Mock charge. The wait lives here so the checkout screen does not time it.
class SimPayGateway implements PaymentGateway {
  const SimPayGateway({this.delay = const Duration(milliseconds: 700)});

  final Duration delay;

  @override
  Future<bool> pay({required int amountWon, required String title}) async {
    await Future<void>.delayed(delay);
    return true;
  }
}
