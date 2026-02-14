import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/repositories/contract_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/property_repository.dart';
import '../../domain/repositories/tenant_repository.dart';
import '../../domain/services/immobilier_validation_service.dart';
import 'immobilier_treasury_controller.dart';
import '../services/receipt_service.dart';

class PaymentController {
  PaymentController(
    this._paymentRepository,
    this._contractRepository,
    this._tenantRepository,
    this._propertyRepository,
    this._receiptService,
    this._validationService,
    this._auditTrailService,
    this._treasuryController,
    this._enterpriseId,
    this._userId,
  );

  final PaymentRepository _paymentRepository;
  final ContractRepository _contractRepository;
  final TenantRepository _tenantRepository;
  final PropertyRepository _propertyRepository;
  final ReceiptService _receiptService;
  final ImmobilierValidationService _validationService;
  final AuditTrailService _auditTrailService;
  final ImmobilierTreasuryController _treasuryController;
  final String _enterpriseId;
  final String _userId;

  Future<List<Payment>> fetchPayments({bool? isDeleted = false}) async {
    return await _paymentRepository.getAllPayments(isDeleted: isDeleted);
  }

  Stream<List<Payment>> watchPayments({bool? isDeleted = false}) {
    return _paymentRepository.watchPayments(isDeleted: isDeleted);
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

    // Record Treasury Operation
    if (created.status == PaymentStatus.paid) {
      await _treasuryController.recordIncome(
        amount: created.amount,
        method: created.paymentMethod,
        reason: 'Loyer ${created.month ?? ""}/${created.year ?? ""}',
        referenceEntityId: created.id,
        notes: 'Paiement Loyer',
      );
    }

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

  /// Imprime un reçu pour un paiement donné.
  Future<bool> printReceipt(String paymentId) async {
    final payment = await _paymentRepository.getPaymentById(paymentId);
    if (payment == null) {
      throw NotFoundException(
        'Le paiement n\'existe pas',
        'PAYMENT_NOT_FOUND',
      );
    }

    final contract = await _contractRepository.getContractById(payment.contractId);
    if (contract == null) {
      throw NotFoundException(
        'Le contrat lié au paiement n\'existe pas',
        'CONTRACT_NOT_FOUND',
      );
    }

    final tenant = await _tenantRepository.getTenantById(contract.tenantId);
    if (tenant == null) {
      throw NotFoundException(
        'Le locataire lié au paiement n\'existe pas',
        'TENANT_NOT_FOUND',
      );
    }

    final property = await _propertyRepository.getPropertyById(contract.propertyId);
    if (property == null) {
      throw NotFoundException(
        'La propriété liée au paiement n\'existe pas',
        'PROPERTY_NOT_FOUND',
      );
    }

    final success = await _receiptService.printReceipt(
      payment: payment,
      tenant: tenant,
      property: property,
    );
    
    if (success) {
      await _logAction('print_receipt', paymentId);
    }
    
    return success;
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
