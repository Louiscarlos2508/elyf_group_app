import 'package:uuid/uuid.dart';
import '../../domain/entities/gaz_salary_payment.dart';
import '../../domain/repositories/gaz_salary_payment_repository.dart';
import '../../domain/repositories/treasury_repository.dart';
import 'package:elyf_groupe_app/shared/domain/entities/treasury_operation.dart';

class GazSalaryPaymentController {
  final GazSalaryPaymentRepository repository;
  final GazTreasuryRepository treasuryRepository;

  GazSalaryPaymentController({
    required this.repository,
    required this.treasuryRepository,
  });

  Stream<List<GazSalaryPayment>> watchPayments(String enterpriseId) {
    return repository.watchPayments(enterpriseId);
  }

  Future<void> recordPayment(GazSalaryPayment payment, String userId) async {
    // 1. Save salary payment record
    await repository.savePayment(payment);

    // 2. Create treasury operation if amount > 0
    if (payment.amount > 0) {
      final operation = TreasuryOperation(
        id: payment.treasuryOperationId ?? const Uuid().v4(),
        enterpriseId: payment.enterpriseId,
        userId: userId,
        amount: payment.amount.toInt(),
        type: TreasuryOperationType.removal,
        fromAccount: payment.paymentMethod,
        date: payment.paymentDate,
        reason: 'Salaire: ${payment.employeeName}${payment.period != null ? " (${payment.period})" : ""}',
        referenceEntityId: payment.id,
        referenceEntityType: 'salary_payment',
        createdAt: DateTime.now(),
      );

      await treasuryRepository.saveOperation(operation);
    }
  }

  Future<List<GazSalaryPayment>> getPaymentsByEmployee(String employeeId) {
    return repository.getPaymentsByEmployee(employeeId);
  }
}
