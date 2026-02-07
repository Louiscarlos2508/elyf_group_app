import '../entities/payment.dart';

/// Repository abstrait pour la gestion des paiements.
abstract class PaymentRepository {
  /// Récupère tous les paiements.
  Future<List<Payment>> getAllPayments();

  /// Récupère un paiement par son ID.
  Future<Payment?> getPaymentById(String id);

  /// Récupère les paiements par contrat.
  Future<List<Payment>> getPaymentsByContract(String contractId);

  /// Récupère les paiements par période.
  Future<List<Payment>> getPaymentsByPeriod(DateTime start, DateTime end);

  /// Crée un nouveau paiement.
  Future<Payment> createPayment(Payment payment);

  /// Met à jour un paiement existant.
  Future<Payment> updatePayment(Payment payment);

  /// Observe les paiements.
  Stream<List<Payment>> watchPayments();

  /// Observe les paiements supprimés.
  Stream<List<Payment>> watchDeletedPayments();

  /// Supprime un paiement.
  Future<void> deletePayment(String id);

  /// Restaure un paiement supprimé.
  Future<void> restorePayment(String id);
}
