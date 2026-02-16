import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/payment_splitter_service.dart';
import 'package:elyf_groupe_app/shared/domain/entities/payment_method.dart';

void main() {
  group('PaymentSplitterService', () {
    group('splitPayment', () {
      test('should split payment correctly for cash method', () {
        final result = PaymentSplitterService.splitPayment(
          method: PaymentMethod.cash,
          totalAmount: 10000,
        );

        expect(result.cashAmount, 10000);
        expect(result.orangeMoneyAmount, 0);
        expect(result.total, 10000);
      });

      test('should split payment correctly for mobileMoney method', () {
        final result = PaymentSplitterService.splitPayment(
          method: PaymentMethod.mobileMoney,
          totalAmount: 10000,
        );

        expect(result.cashAmount, 0);
        expect(result.orangeMoneyAmount, 10000);
        expect(result.total, 10000);
      });

      test('should split payment correctly for both method', () {
        final result = PaymentSplitterService.splitPayment(
          method: PaymentMethod.both,
          totalAmount: 10000,
          cashAmount: 6000,
          orangeMoneyAmount: 4000,
        );

        expect(result.cashAmount, 6000);
        expect(result.orangeMoneyAmount, 4000);
        expect(result.total, 10000);
      });

      test('should default to 0 for both when amounts not provided', () {
        final result = PaymentSplitterService.splitPayment(
          method: PaymentMethod.both,
          totalAmount: 10000,
        );

        expect(result.cashAmount, 0);
        expect(result.orangeMoneyAmount, 0);
        expect(result.total, 0);
      });
    });

    group('validateSplit', () {
      test('should return null for valid split', () {
        final error = PaymentSplitterService.validateSplit(
          cashAmount: 6000,
          orangeMoneyAmount: 4000,
          totalAmount: 10000,
        );
        expect(error, isNull);
      });

      test('should return error when cash is negative', () {
        final error = PaymentSplitterService.validateSplit(
          cashAmount: -1000,
          orangeMoneyAmount: 4000,
          totalAmount: 10000,
        );
        expect(error, isNotNull);
      });

      test('should return error when orangeMoney is negative', () {
        final error = PaymentSplitterService.validateSplit(
          cashAmount: 6000,
          orangeMoneyAmount: -1000,
          totalAmount: 10000,
        );
        expect(error, isNotNull);
      });

      test('should return error when total exceeds amount', () {
        final error = PaymentSplitterService.validateSplit(
          cashAmount: 7000,
          orangeMoneyAmount: 5000,
          totalAmount: 10000,
        );
        expect(error, isNotNull);
      });
    });

    group('isSplitComplete', () {
      test('should return true when split is complete', () {
        final isComplete = PaymentSplitterService.isSplitComplete(
          cashAmount: 6000,
          orangeMoneyAmount: 4000,
          totalAmount: 10000,
        );
        expect(isComplete, isTrue);
      });

      test('should return false when split is incomplete', () {
        final isComplete = PaymentSplitterService.isSplitComplete(
          cashAmount: 6000,
          orangeMoneyAmount: 3000,
          totalAmount: 10000,
        );
        expect(isComplete, isFalse);
      });
    });
  });
}
