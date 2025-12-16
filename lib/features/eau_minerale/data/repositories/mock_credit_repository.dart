import 'dart:async';

import '../../domain/entities/credit_payment.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/credit_repository.dart';
import '../../domain/repositories/sale_repository.dart';

/// Mock implementation of CreditRepository for development.
class MockCreditRepository implements CreditRepository {
  MockCreditRepository(this._saleRepository);

  final SaleRepository _saleRepository;
  final List<CreditPayment> _payments = [];

  @override
  Future<List<Sale>> fetchCreditSales() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final allSales = await _saleRepository.fetchSales();
    // Retourne les ventes avec crédit (amountPaid < totalPrice) et validées
    return allSales
        .where((s) => s.isCredit && s.isValidated)
        .toList();
  }

  @override
  Future<List<Sale>> fetchCustomerCredits(String customerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final customerSales = await _saleRepository.fetchSales(customerId: customerId);
    // Retourne les ventes avec crédit pour ce client
    return customerSales
        .where((s) => s.isCredit && s.isValidated)
        .toList();
  }

  @override
  Future<List<CreditPayment>> fetchSalePayments(String saleId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _payments.where((p) => p.saleId == saleId).toList();
  }

  @override
  Future<String> recordPayment(CreditPayment payment) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final sale = await _saleRepository.getSale(payment.saleId);
    if (sale == null) {
      throw Exception('Vente introuvable');
    }

    // Vérifier que le montant ne dépasse pas le reste à payer
    final currentPayments = await fetchSalePayments(payment.saleId);
    final totalPaid = currentPayments.fold<int>(0, (sum, p) => sum + p.amount);
    final remaining = sale.totalPrice - sale.amountPaid - totalPaid;

    if (payment.amount > remaining) {
      throw Exception('Montant supérieur au reste à payer');
    }

    final id = 'payment-${_payments.length + 1}';
    _payments.add(CreditPayment(
      id: id,
      saleId: payment.saleId,
      amount: payment.amount,
      date: payment.date,
      notes: payment.notes,
    ));

    // Note: La mise à jour du montant payé de la vente est gérée par CreditService
    return id;
  }

  @override
  Future<int> getTotalCredits() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final creditSales = await fetchCreditSales();
    return creditSales.fold<int>(
      0,
      (sum, sale) {
        final totalPaid = _payments
            .where((p) => p.saleId == sale.id)
            .fold<int>(0, (s, p) => s + p.amount);
        return sum + (sale.totalPrice - sale.amountPaid - totalPaid);
      },
    );
  }

  @override
  Future<int> getCreditCustomersCount() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final creditSales = await fetchCreditSales();
    final customerIds = creditSales.map((s) => s.customerId).toSet();
    return customerIds.length;
  }
}

