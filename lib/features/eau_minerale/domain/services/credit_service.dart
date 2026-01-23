import '../../../../core/errors/app_exceptions.dart';
import '../entities/credit_payment.dart';
import '../repositories/credit_repository.dart';
import '../repositories/sale_repository.dart';

/// Business logic service for credit payments.
class CreditService {
  const CreditService({
    required this.creditRepository,
    required this.saleRepository,
  });

  final CreditRepository creditRepository;
  final SaleRepository saleRepository;

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

    // Update sale amountPaid to include the new payment
    final newAmountPaid = sale.amountPaid + payment.amount;
    await saleRepository.updateSaleAmountPaid(payment.saleId, newAmountPaid);

    return paymentId;
  }
}
