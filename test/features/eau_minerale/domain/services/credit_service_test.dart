import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/core/errors/app_exceptions.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/credit_payment.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/credit_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/repositories/sale_repository.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/credit_service.dart';

class MockCreditRepository implements CreditRepository {
  String? lastRecordedPaymentSaleId;
  int? lastRecordedPaymentAmount;
  String recordPaymentResult = 'payment-id-1';

  @override
  Future<String> recordPayment(CreditPayment payment) async {
    lastRecordedPaymentSaleId = payment.saleId;
    lastRecordedPaymentAmount = payment.amount;
    return recordPaymentResult;
  }

  @override
  Future<List<Sale>> fetchCreditSales() async => [];

  @override
  Future<List<Sale>> fetchCustomerCredits(String customerId) async => [];

  @override
  Future<List<Sale>> fetchCustomerAllCredits(String customerId) async => [];

  @override
  Future<List<CreditPayment>> fetchSalePayments(String saleId) async => [];

  @override
  Future<List<CreditPayment>> fetchPayments({
    DateTime? startDate,
    DateTime? endDate,
  }) async =>
      [];

  @override
  Stream<List<CreditPayment>> watchPayments({
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      Stream.value([]);

  @override
  Future<int> getTotalCredits() async => 0;

  @override
  Future<int> getCreditCustomersCount() async => 0;
}

class MockSaleRepository implements SaleRepository {
  Sale? saleToReturn;
  String? lastUpdatedSaleId;
  int? lastUpdatedAmountPaid;

  @override
  Future<Sale?> getSale(String id) async => saleToReturn;

  @override
  Future<void> updateSaleAmountPaid(String saleId, int newAmountPaid) async {
    lastUpdatedSaleId = saleId;
    lastUpdatedAmountPaid = newAmountPaid;
  }

  @override
  Future<List<Sale>> fetchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleStatus? status,
    String? customerId,
  }) async =>
      [];

  @override
  Stream<List<Sale>> watchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleStatus? status,
    String? customerId,
  }) =>
      Stream.value([]);

  @override
  Future<List<Sale>> fetchRecentSales({int limit = 50}) async => [];

  @override
  Future<String> createSale(Sale sale) async => 'created-id';

  @override
  Future<void> deleteSale(String saleId) async {}
}

void main() {
  group('CreditService', () {
    late CreditService service;
    late MockCreditRepository mockCreditRepo;
    late MockSaleRepository mockSaleRepo;

    setUp(() {
      mockCreditRepo = MockCreditRepository();
      mockSaleRepo = MockSaleRepository();
      service = CreditService(
        creditRepository: mockCreditRepo,
        saleRepository: mockSaleRepo,
      );
    });

    group('recordPayment', () {
      test('throws NotFoundException when sale does not exist', () async {
        mockSaleRepo.saleToReturn = null;
        final payment = CreditPayment(
          id: 'pay-1',
          saleId: 'sale-unknown',
          amount: 1000,
          date: DateTime(2026, 1, 15),
          notes: null,
        );

        expect(
          () => service.recordPayment(payment),
          throwsA(isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            'Vente introuvable',
          )),
        );
        expect(mockCreditRepo.lastRecordedPaymentSaleId, isNull);
      });

      test('throws ValidationException when amount exceeds remaining amount',
          () async {
        mockSaleRepo.saleToReturn = Sale(
          id: 'sale-1',
          enterpriseId: 'test-enterprise',
          productId: 'p1',
          productName: 'Product',
          quantity: 1,
          unitPrice: 5000,
          totalPrice: 5000,
          amountPaid: 2000,
          customerName: 'Client',
          customerPhone: '+22670123456',
          customerId: 'c1',
          date: DateTime(2026, 1, 1),
          status: SaleStatus.validated,
          createdBy: 'user-1',
        );
        final payment = CreditPayment(
          id: 'pay-1',
          saleId: 'sale-1',
          amount: 4000,
          date: DateTime(2026, 1, 15),
          notes: null,
        );

        expect(
          () => service.recordPayment(payment),
          throwsA(isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'PAYMENT_AMOUNT_EXCEEDS_REMAINING',
          )),
        );
      });

      test('throws ValidationException when amount is zero or negative',
          () async {
        mockSaleRepo.saleToReturn = Sale(
          id: 'sale-1',
          enterpriseId: 'test-enterprise',
          productId: 'p1',
          productName: 'Product',
          quantity: 1,
          unitPrice: 5000,
          totalPrice: 5000,
          amountPaid: 0,
          customerName: 'Client',
          customerPhone: '+22670123456',
          customerId: 'c1',
          date: DateTime(2026, 1, 1),
          status: SaleStatus.validated,
          createdBy: 'user-1',
        );
        final payment = CreditPayment(
          id: 'pay-1',
          saleId: 'sale-1',
          amount: 0,
          date: DateTime(2026, 1, 15),
          notes: null,
        );

        expect(
          () => service.recordPayment(payment),
          throwsA(isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'INVALID_PAYMENT_AMOUNT',
          )),
        );
      });

      test('records payment and updates sale amountPaid when valid', () async {
        mockSaleRepo.saleToReturn = Sale(
          id: 'sale-1',
          enterpriseId: 'test-enterprise',
          productId: 'p1',
          productName: 'Product',
          quantity: 1,
          unitPrice: 5000,
          totalPrice: 5000,
          amountPaid: 2000,
          customerName: 'Client',
          customerPhone: '+22670123456',
          customerId: 'c1',
          date: DateTime(2026, 1, 1),
          status: SaleStatus.validated,
          createdBy: 'user-1',
        );
        final payment = CreditPayment(
          id: 'pay-1',
          saleId: 'sale-1',
          amount: 1500,
          date: DateTime(2026, 1, 15),
          notes: 'Partial payment',
        );

        final result = await service.recordPayment(payment);

        expect(result, mockCreditRepo.recordPaymentResult);
        expect(mockCreditRepo.lastRecordedPaymentSaleId, 'sale-1');
        expect(mockCreditRepo.lastRecordedPaymentAmount, 1500);
        expect(mockSaleRepo.lastUpdatedSaleId, 'sale-1');
        expect(mockSaleRepo.lastUpdatedAmountPaid, 3500);
      });
    });
  });
}
