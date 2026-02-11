import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:elyf_groupe_app/features/immobilier/application/controllers/payment_controller.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/repositories/payment_repository.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/services/immobilier_validation_service.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/payment.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';
import 'package:elyf_groupe_app/features/audit_trail/domain/services/audit_trail_service.dart';

import 'payment_controller_test.mocks.dart';

class MockAuditTrailService extends Mock implements AuditTrailService {
  @override
  Future<String> logAction({
    required String? enterpriseId,
    required String? userId,
    required String? module,
    required String? action,
    required String? entityId,
    required String? entityType,
    Map<String, dynamic>? metadata,
  }) =>
      super.noSuchMethod(
        Invocation.method(#logAction, [], {
          #enterpriseId: enterpriseId,
          #userId: userId,
          #module: module,
          #action: action,
          #entityId: entityId,
          #entityType: entityType,
          #metadata: metadata,
        }),
        returnValue: Future.value('test-log-id'),
      );
}

@GenerateMocks([PaymentRepository, ImmobilierValidationService])
void main() {
  late PaymentController controller;
  late MockPaymentRepository mockRepository;
  late MockImmobilierValidationService mockValidationService;
  late MockAuditTrailService mockAuditService;

  setUp(() {
    mockRepository = MockPaymentRepository();
    mockValidationService = MockImmobilierValidationService();
    mockAuditService = MockAuditTrailService();
    controller = PaymentController(
      mockRepository,
      mockValidationService,
      mockAuditService,
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
