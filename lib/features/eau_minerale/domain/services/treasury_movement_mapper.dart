import '../entities/sale.dart';
import '../entities/credit_payment.dart';
import '../entities/treasury_movement.dart';
import '../../../../shared/domain/entities/treasury_operation.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../entities/expense_record.dart';

/// Maps raw business entities (sales, payments, expenses, manual ops)
/// into a unified, sorted list of [TreasuryMovement] for the treasury UI.
///
/// This is a pure domain-layer service with no Flutter or Riverpod dependencies,
/// making it straightforward to unit test.
class TreasuryMovementMapper {
  const TreasuryMovementMapper();

  /// Combines and sorts all treasury movement sources into a single list.
  ///
  /// - [sales] : all sales (may include credit sales)
  /// - [payments] : credit payments received
  /// - [expenses] : operational expenses
  /// - [manualOps] : manually entered treasury operations (supply, removal, transfer)
  /// - [limit] : optional cap on the returned list length (default 100)
  List<TreasuryMovement> mapToMovements({
    required List<Sale> sales,
    required List<CreditPayment> payments,
    required List<ExpenseRecord> expenses,
    required List<TreasuryOperation> manualOps,
    int limit = 100,
  }) {
    final movements = <TreasuryMovement>[];

    // 1. Sales — may be split into Cash and Mobile Money
    for (final sale in sales) {
      if (sale.cashAmount > 0) {
        movements.add(TreasuryMovement(
          id: 'sale_cash_${sale.id}',
          date: sale.date,
          amount: sale.cashAmount,
          label: 'Vente: ${sale.customerName}',
          category: 'Vente',
          method: PaymentMethod.cash,
          isIncome: true,
          originalEntity: sale,
        ));
      }
      if (sale.orangeMoneyAmount > 0) {
        movements.add(TreasuryMovement(
          id: 'sale_mm_${sale.id}',
          date: sale.date,
          amount: sale.orangeMoneyAmount,
          label: 'Vente: ${sale.customerName}',
          category: 'Vente',
          method: PaymentMethod.mobileMoney,
          isIncome: true,
          originalEntity: sale,
        ));
      }
    }

    // 2. Credit recoveries
    for (final payment in payments) {
      if (payment.cashAmount > 0) {
        movements.add(TreasuryMovement(
          id: 'pay_cash_${payment.id}',
          date: payment.date,
          amount: payment.cashAmount,
          label: 'Recouvrement',
          category: 'Crédit',
          method: PaymentMethod.cash,
          isIncome: true,
          originalEntity: payment,
        ));
      }
      if (payment.orangeMoneyAmount > 0) {
        movements.add(TreasuryMovement(
          id: 'pay_mm_${payment.id}',
          date: payment.date,
          amount: payment.orangeMoneyAmount,
          label: 'Recouvrement',
          category: 'Crédit',
          method: PaymentMethod.mobileMoney,
          isIncome: true,
          originalEntity: payment,
        ));
      }
    }

    // 3. Expenses
    for (final expense in expenses) {
      movements.add(TreasuryMovement(
        id: 'exp_${expense.id}',
        date: expense.date,
        amount: expense.amountCfa,
        label: expense.label,
        category: 'Dépense',
        method: expense.paymentMethod,
        isIncome: false,
        originalEntity: expense,
      ));
    }

    // 4. Manual operations — skip those linked to a business entity to avoid duplicates
    for (final op in manualOps) {
      if (op.referenceEntityId != null && op.referenceEntityId!.isNotEmpty) {
        continue;
      }

      final isIncome = op.type == TreasuryOperationType.supply ||
          (op.type == TreasuryOperationType.transfer &&
              op.toAccount != null &&
              op.fromAccount == null);

      movements.add(TreasuryMovement(
        id: 'manual_${op.id}',
        date: op.date,
        amount: op.amount,
        label: op.reason ?? _labelForOperationType(op.type),
        category: 'Trésorerie',
        method: op.toAccount ?? op.fromAccount ?? PaymentMethod.cash,
        isIncome: isIncome,
        originalEntity: op,
      ));
    }

    // Sort by date descending and cap
    movements.sort((a, b) => b.date.compareTo(a.date));
    return movements.take(limit).toList();
  }

  String _labelForOperationType(TreasuryOperationType type) {
    switch (type) {
      case TreasuryOperationType.supply:
        return 'Apport';
      case TreasuryOperationType.removal:
        return 'Retrait';
      case TreasuryOperationType.transfer:
        return 'Transfert';
      case TreasuryOperationType.adjustment:
        return 'Ajustement';
    }
  }
}
