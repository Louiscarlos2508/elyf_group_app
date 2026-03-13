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
  List<TreasuryMovement> mapToMovements(
    List<TreasuryOperation> treasuryOperations, {
    int limit = 100,
  }) {
    final movements = <TreasuryMovement>[];

    for (final op in treasuryOperations) {
      final isIncome = op.type == TreasuryOperationType.supply ||
          op.type == TreasuryOperationType.adjustment ||
          (op.type == TreasuryOperationType.transfer &&
              op.toAccount != null &&
              op.fromAccount == null);

      movements.add(TreasuryMovement(
        id: op.id,
        date: op.date,
        amount: op.amount,
        label: op.reason ?? _labelForOperationType(op.type),
        category: _categoryForReferenceType(op.referenceEntityType),
        method: op.toAccount ?? op.fromAccount ?? PaymentMethod.cash,
        isIncome: isIncome,
        originalEntity: op,
      ));
    }

    // Sort by date descending and cap
    movements.sort((a, b) => b.date.compareTo(a.date));
    return movements.take(limit).toList();
  }

  String _categoryForReferenceType(String? type) {
    if (type == null) return 'Trésorerie';
    switch (type) {
      case 'sale':
        return 'Vente';
      case 'expense':
        return 'Dépense';
      case 'credit_payment':
        return 'Crédit';
      case 'sale_void':
        return 'Annulation';
      default:
        return 'Trésorerie';
    }
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
