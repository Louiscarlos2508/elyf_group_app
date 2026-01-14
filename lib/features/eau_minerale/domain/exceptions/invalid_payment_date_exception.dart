/// Exception thrown when a payment date is invalid.
class InvalidPaymentDateException implements Exception {
  const InvalidPaymentDateException({required this.reason});

  final String reason;

  @override
  String toString() {
    return 'Date de paiement invalide: $reason';
  }
}
