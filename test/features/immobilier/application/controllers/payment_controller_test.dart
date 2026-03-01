import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/immobilier/application/controllers/payment_controller.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/payment_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/contract_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/tenant_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/property_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/application/services/receipt_service.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/services/immobilier_validation_service.dart';
import 'package:elyf_groupe_app/features/immobilier/application/controllers/immobilier_treasury_controller.dart';
import 'package:elyf_groupe_app/features/audit_trail/domain/services/audit_trail_service.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/payment.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

import 'payment_controller_test.mocks.dart';



@GenerateMocks([
  PaymentRepository,
  ContractRepository,
  TenantRepository,
  PropertyRepository,
  ReceiptService,
  ImmobilierValidationService,
  AuditTrailService,
  ImmobilierTreasuryController,
])
void main() {
  late PaymentController controller;
  late MockPaymentRepository mockRepository;
  late MockContractRepository mockContractRepository;
  late MockTenantRepository mockTenantRepository;
  late MockPropertyRepository mockPropertyRepository;
  late MockReceiptService mockReceiptService;
  late MockImmobilierValidationService mockValidationService;
  late MockAuditTrailService mockAuditService;
  late MockImmobilierTreasuryController mockTreasuryController;

  setUp(() {
    mockRepository = MockPaymentRepository();
    mockContractRepository = MockContractRepository();
    mockTenantRepository = MockTenantRepository();
    mockPropertyRepository = MockPropertyRepository();
    mockReceiptService = MockReceiptService();
    mockValidationService = MockImmobilierValidationService();
    mockAuditService = MockAuditTrailService();
    mockTreasuryController = MockImmobilierTreasuryController();

    controller = PaymentController(
      mockRepository,
      mockContractRepository,
      mockTenantRepository,
      mockPropertyRepository,
      mockReceiptService,
      mockValidationService,
      mockAuditService,
      mockTreasuryController,
      'test-enterprise',
      'test-user',
    );
  });

  group('PaymentController', () {
    group('fetchPayments', () {
      test('should return list of payments from repository', () async {
        // Arrange
        final payments = <Payment>[];
        when(mockRepository.getAllPayments()).thenAnswer((_) async => payments);

        // Act
        final result = await controller.fetchPayments();

        // Assert
        expect(result, equals(payments));
        verify(mockRepository.getAllPayments()).called(1);
      });
    });

    group('createPayment', () {
      test('should create payment when validation passes', () async {
        // Arrange
        final payment = Payment(
          id: 'payment-1',
          enterpriseId: 'test-enterprise',
          contractId: 'contract-1',
          amount: 50000,
          paidAmount: 50000,
          paymentDate: DateTime(2026, 1, 1),
          paymentMethod: PaymentMethod.cash,
          status: PaymentStatus.paid,
        );
        when(mockValidationService.validatePaymentCreation(any))
            .thenAnswer((_) async => null);
        when(mockRepository.createPayment(any)).thenAnswer((_) async => payment);

        // Act
        final result = await controller.createPayment(payment);

        // Assert
        expect(result, equals(payment));
        verify(mockValidationService.validatePaymentCreation(payment)).called(1);
        verify(mockRepository.createPayment(payment)).called(1);
      });

      test('should throw exception when validation fails', () async {
        // Arrange
        final payment = Payment(
          id: 'payment-1',
          enterpriseId: 'test-enterprise',
          contractId: 'contract-1',
          amount: 50000,
          paidAmount: 0,
          paymentDate: DateTime(2026, 1, 1),
          paymentMethod: PaymentMethod.cash,
          status: PaymentStatus.paid,
        );
        when(mockValidationService.validatePaymentCreation(any))
            .thenAnswer((_) async => 'Validation error');

        // Act & Assert
        expect(
          () => controller.createPayment(payment),
          throwsA(isA<Exception>()),
        );
        verifyNever(mockRepository.createPayment(any));
      });
    });
  });
}
