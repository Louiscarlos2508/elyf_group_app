import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/services/immobilier_validation_service.dart';

class PaymentController {
  PaymentController(
    this._paymentRepository,
    this._validationService,
    this._auditTrailService,
    this._enterpriseId,
    this._userId,
  );

  final PaymentRepository _paymentRepository;
  final ImmobilierValidationService _validationService;
  final AuditTrailService _auditTrailService;
  final String _enterpriseId;
  final String _userId;

  Future<List<Payment>> fetchPayments() async {
    return await _paymentRepository.getAllPayments();
  }

  Stream<List<Payment>> watchPayments() {
    return _paymentRepository.watchPayments();
  }

  Stream<List<Payment>> watchDeletedPayments() {
    return _paymentRepository.watchDeletedPayments();
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
    final validationError = await _validationService.validatePaymentCreation(
      payment,
    );
    if (validationError != null) {
      throw ValidationException(
        validationError,
        'PAYMENT_VALIDATION_FAILED',
      );
    }

    final created = await _paymentRepository.createPayment(payment);
    await _logAction('create', created.id, metadata: created.toMap());
    return created;
  }

  /// Met à jour un paiement après validation.
  Future<Payment> updatePayment(Payment payment) async {
    // Valider le paiement
    final validationError = await _validationService.validatePaymentCreation(
      payment,
    );
    if (validationError != null) {
      throw ValidationException(
        validationError,
        'PAYMENT_VALIDATION_FAILED',
      );
    }

    final updated = await _paymentRepository.updatePayment(payment);
    await _logAction('update', updated.id, metadata: updated.toMap());
    return updated;
  }

  Future<void> deletePayment(String id) async {
    await _paymentRepository.deletePayment(id);
    await _logAction('delete', id);
  }

  Future<void> restorePayment(String id) async {
    await _paymentRepository.restorePayment(id);
    await _logAction('restore', id);
  }

  Future<void> _logAction(
    String action,
    String entityId, {
    Map<String, dynamic>? metadata,
  }) async {
    await _auditTrailService.logAction(
      enterpriseId: _enterpriseId,
      userId: _userId,
      module: 'immobilier',
      action: action,
      entityId: entityId,
      entityType: 'payment',
      metadata: metadata,
    );
  }
}
