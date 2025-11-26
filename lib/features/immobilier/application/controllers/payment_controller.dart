import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../services/immobilier_validation_service.dart';

class PaymentController {
  PaymentController(
    this._paymentRepository,
    this._validationService,
  );

  final PaymentRepository _paymentRepository;
  final ImmobilierValidationService _validationService;

  Future<List<Payment>> fetchPayments() async {
    return await _paymentRepository.getAllPayments();
  }

  Future<Payment?> getPayment(String id) async {
    return await _paymentRepository.getPaymentById(id);
  }

  Future<List<Payment>> getPaymentsByContract(String contractId) async {
    return await _paymentRepository.getPaymentsByContract(contractId);
  }

  Future<List<Payment>> getPaymentsByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return await _paymentRepository.getPaymentsByPeriod(start, end);
  }

  /// Crée un paiement après validation.
  Future<Payment> createPayment(Payment payment) async {
    // Valider le paiement
    final validationError = await _validationService.validatePaymentCreation(payment);
    if (validationError != null) {
      throw Exception(validationError);
    }

    return await _paymentRepository.createPayment(payment);
  }

  /// Met à jour un paiement après validation.
  Future<Payment> updatePayment(Payment payment) async {
    // Valider le paiement
    final validationError = await _validationService.validatePaymentCreation(payment);
    if (validationError != null) {
      throw Exception(validationError);
    }

    return await _paymentRepository.updatePayment(payment);
  }

  Future<void> deletePayment(String id) async {
    await _paymentRepository.deletePayment(id);
  }
}

