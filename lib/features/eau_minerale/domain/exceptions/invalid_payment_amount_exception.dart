/// Exception thrown when a payment amount is invalid.
class InvalidPaymentAmountException implements Exception {
  const InvalidPaymentAmountException({
    required this.expectedAmount,
    required this.actualAmount,
  });

  final int expectedAmount;
  final int actualAmount;

  @override
  String toString() {
    return 'Montant invalide: attendu $expectedAmount FCFA, reçu $actualAmount FCFA';
  }
}

