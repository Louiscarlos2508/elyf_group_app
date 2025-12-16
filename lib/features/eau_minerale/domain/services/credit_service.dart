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
    if (sale == null) throw Exception('Vente introuvable');

    if (payment.amount > sale.remainingAmount) {
      throw Exception(
        'Montant supérieur au reste à payer (${sale.remainingAmount} CFA)',
      );
    }

    if (payment.amount <= 0) {
      throw Exception('Le montant doit être supérieur à 0');
    }

    final paymentId = await creditRepository.recordPayment(payment);

    // Update sale amountPaid to include the new payment
    final newAmountPaid = sale.amountPaid + payment.amount;
    await saleRepository.updateSaleAmountPaid(payment.saleId, newAmountPaid);

    return paymentId;
  }
}
