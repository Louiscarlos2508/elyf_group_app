import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/services/calculation/immobilier_report_calculation_service.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/payment.dart';
import 'package:elyf_groupe_app/features/immobilier/domain/entities/expense.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

void main() {
  late ImmobilierReportCalculationService service;

  setUp(() {
    service = ImmobilierReportCalculationService();
  });

  group('ImmobilierReportCalculationService', () {
    group('calculateTotalRevenue', () {
      test('should calculate total revenue from payments', () {
        // Arrange
        final payments = [
          Payment(
            id: 'payment-1',
            enterpriseId: 'test-enterprise',
            contractId: 'contract-1',
            amount: 50000,
            paymentDate: DateTime(2026, 1, 1),
            paymentMethod: PaymentMethod.cash,
            status: PaymentStatus.paid,
          ),
          Payment(
            id: 'payment-2',
            enterpriseId: 'test-enterprise',
            contractId: 'contract-2',
            amount: 75000,
            paymentDate: DateTime(2026, 1, 2),
            paymentMethod: PaymentMethod.cash,
            status: PaymentStatus.paid,
          ),
        ];

        // Act
        final result = service.calculateTotalRevenue(payments);

        // Assert
        expect(result, equals(125000));
      });
    });

    group('calculateTotalExpenses', () {
      test('should calculate total expenses', () {
        // Arrange
        final expenses = [
          PropertyExpense(
            id: 'expense-1',
            enterpriseId: 'test-enterprise',
            propertyId: 'property-1',
            amount: 10000,
            expenseDate: DateTime(2026, 1, 1),
            category: ExpenseCategory.maintenance,
            description: 'Test',
          ),
          PropertyExpense(
            id: 'expense-2',
            enterpriseId: 'test-enterprise',
            propertyId: 'property-2',
            amount: 15000,
            expenseDate: DateTime(2026, 1, 2),
            category: ExpenseCategory.repair,
            description: 'Test',
          ),
        ];

        // Act
        final result = service.calculateTotalExpenses(expenses);

        // Assert
        expect(result, equals(25000));
      });
    });
  });
}
