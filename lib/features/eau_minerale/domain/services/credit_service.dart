import '../../../../core/errors/app_exceptions.dart';
import '../entities/credit_payment.dart';
import '../repositories/credit_repository.dart';
import '../repositories/sale_repository.dart';
import '../repositories/treasury_repository.dart';
import '../../../../shared/domain/entities/treasury_operation.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../../../../core/logging/app_logger.dart';

/// Business logic service for credit payments.
class CreditService {
  const CreditService({
    required this.creditRepository,
    required this.saleRepository,
    required this.treasuryRepository,
  });

  final CreditRepository creditRepository;
  final SaleRepository saleRepository;
  final TreasuryRepository treasuryRepository;

  /// Records a credit payment and updates sale amountPaid and status if fully paid.
  Future<String> recordPayment(CreditPayment payment) async {
    final sale = await saleRepository.getSale(payment.saleId);
    if (sale == null) {
      throw NotFoundException(
        'Vente introuvable',
        'SALE_NOT_FOUND',
      );
    }

    if (payment.amount > sale.remainingAmount) {
      throw ValidationException(
        'Montant supérieur au reste à payer (${sale.remainingAmount} CFA)',
        'PAYMENT_AMOUNT_EXCEEDS_REMAINING',
      );
    }

    if (payment.amount <= 0) {
      throw ValidationException(
        'Le montant doit être supérieur à 0',
        'INVALID_PAYMENT_AMOUNT',
      );
    }

    final paymentId = await creditRepository.recordPayment(payment);

    // Record in Treasury
    try {
      if (payment.cashAmount > 0) {
        await treasuryRepository.createOperation(TreasuryOperation(
          id: '',
          enterpriseId: payment.enterpriseId,
          userId: 'system',
          amount: payment.cashAmount,
          type: TreasuryOperationType.supply,
          toAccount: PaymentMethod.cash,
          date: payment.date,
          reason: 'Recouvrement Crédit: ${sale.customerName}',
          referenceEntityId: paymentId,
          referenceEntityType: 'credit_payment',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      if (payment.orangeMoneyAmount > 0) {
        await treasuryRepository.createOperation(TreasuryOperation(
          id: '',
          enterpriseId: payment.enterpriseId,
          userId: 'system',
          amount: payment.orangeMoneyAmount,
          type: TreasuryOperationType.supply,
          toAccount: PaymentMethod.mobileMoney,
          date: payment.date,
          reason: 'Recouvrement Crédit: ${sale.customerName} (Orange Money)',
          referenceEntityId: paymentId,
          referenceEntityType: 'credit_payment',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      AppLogger.error('Failed to record treasury operation for credit payment', error: e);
    }

    // Update sale amountPaid to include the new payment
    final newAmountPaid = sale.amountPaid + payment.amount;
    await saleRepository.updateSaleAmountPaid(payment.saleId, newAmountPaid);

    return paymentId;
  }
}
