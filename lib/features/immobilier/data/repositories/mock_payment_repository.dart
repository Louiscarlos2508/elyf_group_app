import '../../../../shared/domain/entities/payment_method.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

class MockPaymentRepository implements PaymentRepository {
  final _payments = <String, Payment>{};

  MockPaymentRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    final payments = [
      Payment(
        id: 'payment-1',
        contractId: 'contract-1',
        amount: 100000,
        paymentDate: now.subtract(const Duration(days: 30)),
        paymentMethod: PaymentMethod.mobileMoney,
        status: PaymentStatus.paid,
        month: now.month - 1,
        year: now.year,
        receiptNumber: 'REC-001',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Payment(
        id: 'payment-2',
        contractId: 'contract-1',
        amount: 100000,
        paymentDate: now.subtract(const Duration(days: 60)),
        paymentMethod: PaymentMethod.cash,
        status: PaymentStatus.paid,
        month: now.month - 2,
        year: now.year,
        receiptNumber: 'REC-002',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
    ];

    for (final payment in payments) {
      _payments[payment.id] = payment;
    }
  }

  @override
  Future<List<Payment>> getAllPayments() async {
    return _payments.values.toList();
  }

  @override
  Future<Payment?> getPaymentById(String id) async {
    return _payments[id];
  }

  @override
  Future<List<Payment>> getPaymentsByContract(String contractId) async {
    return _payments.values
        .where((p) => p.contractId == contractId)
        .toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  @override
  Future<List<Payment>> getPaymentsByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return _payments.values.where((p) {
      return p.paymentDate.isAfter(start.subtract(const Duration(days: 1))) &&
          p.paymentDate.isBefore(end.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  @override
  Future<Payment> createPayment(Payment payment) async {
    final now = DateTime.now();
    final newPayment = Payment(
      id: payment.id,
      contractId: payment.contractId,
      amount: payment.amount,
      paymentDate: payment.paymentDate,
      paymentMethod: payment.paymentMethod,
      status: payment.status,
      contract: payment.contract,
      month: payment.month,
      year: payment.year,
      receiptNumber: payment.receiptNumber,
      notes: payment.notes,
      createdAt: now,
      updatedAt: now,
    );
    _payments[payment.id] = newPayment;
    return newPayment;
  }

  @override
  Future<Payment> updatePayment(Payment payment) async {
    final existing = _payments[payment.id];
    if (existing == null) {
      throw Exception('Payment not found');
    }
    final updated = Payment(
      id: payment.id,
      contractId: payment.contractId,
      amount: payment.amount,
      paymentDate: payment.paymentDate,
      paymentMethod: payment.paymentMethod,
      status: payment.status,
      contract: payment.contract,
      month: payment.month,
      year: payment.year,
      receiptNumber: payment.receiptNumber,
      notes: payment.notes,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _payments[payment.id] = updated;
    return updated;
  }

  @override
  Future<void> deletePayment(String id) async {
    _payments.remove(id);
  }
}

