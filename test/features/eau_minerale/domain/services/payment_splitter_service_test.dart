import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/payment_splitter_service.dart';

void main() {
  group('PaymentSplitterService', () {
    late PaymentSplitterService service;

    setUp(() {
      service = PaymentSplitterService();
    });

    group('splitPayment', () {
      test('should split payment correctly between cash and orange money', () {
        final result = service.splitPayment(
          totalAmount: 10000,
          cashAmount: 6000,
        );

        expect(result.cashAmount, 6000);
        expect(result.orangeMoneyAmount, 4000);
        expect(result.isValid, true);
      });

      test('should return all cash when orange money is 0', () {
        final result = service.splitPayment(
          totalAmount: 10000,
          cashAmount: 10000,
        );

        expect(result.cashAmount, 10000);
        expect(result.orangeMoneyAmount, 0);
        expect(result.isValid, true);
      });

      test('should return all orange money when cash is 0', () {
        final result = service.splitPayment(
          totalAmount: 10000,
          cashAmount: 0,
        );

        expect(result.cashAmount, 0);
        expect(result.orangeMoneyAmount, 10000);
        expect(result.isValid, true);
      });

      test('should return invalid when cash exceeds total', () {
        final result = service.splitPayment(
          totalAmount: 10000,
          cashAmount: 15000,
        );

        expect(result.isValid, false);
      });

      test('should return invalid when cash is negative', () {
        final result = service.splitPayment(
          totalAmount: 10000,
          cashAmount: -1000,
        );

        expect(result.isValid, false);
      });
    });

    group('getPaymentMethod', () {
      test('should return cash when only cash', () {
        final method = service.getPaymentMethod(
          cashAmount: 10000,
          orangeMoneyAmount: 0,
        );
        expect(method, PaymentMethod.cash);
      });

      test('should return orangeMoney when only orange money', () {
        final method = service.getPaymentMethod(
          cashAmount: 0,
          orangeMoneyAmount: 10000,
        );
        expect(method, PaymentMethod.orangeMoney);
      });

      test('should return mixed when both present', () {
        final method = service.getPaymentMethod(
          cashAmount: 6000,
          orangeMoneyAmount: 4000,
        );
        expect(method, PaymentMethod.mixed);
      });
    });
  });
}

