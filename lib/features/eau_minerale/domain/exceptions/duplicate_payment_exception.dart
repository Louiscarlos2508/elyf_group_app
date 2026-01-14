/// Exception thrown when attempting to create a duplicate payment
/// for the same employee and period.
class DuplicatePaymentException implements Exception {
  const DuplicatePaymentException({
    required this.employeeName,
    required this.period,
  });

  final String employeeName;
  final String period;

  @override
  String toString() {
    return 'Un paiement existe déjà pour $employeeName pour la période $period';
  }
}
