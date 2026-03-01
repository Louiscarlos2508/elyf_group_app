import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/credit_calculation_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/customer_credit.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/credit_payment.dart';

void main() {
  group('CreditCalculationService', () {
    group('calculateTotalCredit', () {
      test('should calculate total credit correctly', () {
        final credits = [
          CustomerCredit(
            id: '1',
            enterpriseId: 'test',
            saleId: 's1',
            amount: 10000,
            amountPaid: 6000,
            date: DateTime.now(),
            dueDate: DateTime.now().add(const Duration(days: 30)),
          ),
          CustomerCredit(
            id: '2',
            enterpriseId: 'test',
            saleId: 's2',
            amount: 5000,
            amountPaid: 2000,
            date: DateTime.now(),
            dueDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ];

        final total = CreditCalculationService.calculateTotalCredit(credits);
        expect(total, 7000); // 4000 + 3000 (remainingAmount is a getter)
      });

      test('should return 0 when no credits', () {
        expect(CreditCalculationService.calculateTotalCredit([]), 0);
      });
    });

    group('calculateTotalPaid', () {
      test('should calculate total paid correctly', () {
        final payments = [
          CreditPayment(
            id: '1',
            enterpriseId: 'test',
            saleId: 's1',
            amount: 3000,
            date: DateTime.now(),
            notes: 'Payment 1',
          ),
          CreditPayment(
            id: '2',
            enterpriseId: 'test',
            saleId: 's2',
            amount: 2000,
            date: DateTime.now(),
            notes: 'Payment 2',
          ),
        ];

        final total = CreditCalculationService.calculateTotalPaid(payments);
        expect(total, 5000);
      });
    });

    group('calculateRemainingCredit', () {
      test('should calculate remaining credit correctly', () {
        final remaining = CreditCalculationService.calculateRemainingCredit(
          initialCredit: 10000,
          totalPaid: 6000,
        );
        expect(remaining, 4000);
      });

      test('should return 0 when overpaid', () {
        final remaining = CreditCalculationService.calculateRemainingCredit(
          initialCredit: 10000,
          totalPaid: 15000,
        );
        expect(remaining, 0);
      });
    });

    group('validatePaymentAmount', () {
      test('should return null for valid payment', () {
        final result = CreditCalculationService.validatePaymentAmount(
          paymentAmount: 1000,
          remainingCredit: 5000,
        );
        expect(result, isNull);
      });

      test('should return error for null amount', () {
        final result = CreditCalculationService.validatePaymentAmount(
          paymentAmount: null,
          remainingCredit: 5000,
        );
        expect(result, isNotNull);
      });

      test('should return error for amount exceeding remaining', () {
        final result = CreditCalculationService.validatePaymentAmount(
          paymentAmount: 6000,
          remainingCredit: 5000,
        );
        expect(result, isNotNull);
        expect(result, contains('5000'));
      });
    });

    group('isCreditFullyPaid', () {
      test('should return true when remaining is 0', () {
        expect(CreditCalculationService.isCreditFullyPaid(0), isTrue);
      });

      test('should return true when remaining is negative', () {
        expect(CreditCalculationService.isCreditFullyPaid(-100), isTrue);
      });

      test('should return false when remaining is positive', () {
        expect(CreditCalculationService.isCreditFullyPaid(1000), isFalse);
      });
    });

    group('calculatePaymentPercentage', () {
      test('should calculate percentage correctly', () {
        final percentage = CreditCalculationService.calculatePaymentPercentage(
          totalPaid: 5000,
          initialCredit: 10000,
        );
        expect(percentage, 50.0);
      });

      test('should return 0 when initial credit is 0', () {
        final percentage = CreditCalculationService.calculatePaymentPercentage(
          totalPaid: 1000,
          initialCredit: 0,
        );
        expect(percentage, 0.0);
      });
    });
  });
}
