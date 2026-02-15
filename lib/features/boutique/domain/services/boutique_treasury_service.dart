import 'package:rxdart/rxdart.dart';
import '../entities/sale.dart';
import '../entities/expense.dart';
import '../entities/purchase.dart';
import '../entities/treasury_operation.dart';
import '../repositories/sale_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/purchase_repository.dart';
import '../repositories/treasury_repository.dart';

/// Service responsible for aggregating all financial flows into account balances.
class BoutiqueTreasuryService {
  BoutiqueTreasuryService({
    required this.saleRepository,
    required this.expenseRepository,
    required this.purchaseRepository,
    required this.treasuryRepository,
  });

  final SaleRepository saleRepository;
  final ExpenseRepository expenseRepository;
  final PurchaseRepository purchaseRepository;
  final TreasuryRepository treasuryRepository;

  /// Returns a stream of account balances.
  Stream<Map<PaymentMethod, int>> watchBalances() {
    return CombineLatestStream.combine4(
      saleRepository.watchRecentSales(limit: 1000), // Adjust limit if historical depth is needed
      expenseRepository.watchExpenses(limit: 1000),
      purchaseRepository.watchPurchases(limit: 1000),
      treasuryRepository.watchOperations(limit: 1000),
      (sales, expenses, purchases, operations) {
        return _calculateBalances(sales, expenses, purchases, operations);
      },
    ).asBroadcastStream();
  }

  /// Calculates the current balance for each payment method.
  Map<PaymentMethod, int> _calculateBalances(
    List<Sale> sales,
    List<Expense> expenses,
    List<Purchase> purchases,
    List<TreasuryOperation> operations,
  ) {
    int cash = 0;
    int mm = 0;

    // 1. Inflow from Sales
    for (final sale in sales) {
      if (sale.deletedAt != null) continue;
      
      // Handle 'both' or specific methods
      cash += sale.cashAmount;
      mm += sale.mobileMoneyAmount;
      
      // If cashAmount/mmAmount are zero (old schema or single method), fallback to totalAmount
      if (sale.cashAmount == 0 && sale.mobileMoneyAmount == 0) {
        if (sale.paymentMethod == PaymentMethod.cash) {
          cash += sale.totalAmount;
        } else if (sale.paymentMethod == PaymentMethod.mobileMoney) {
          mm += sale.totalAmount;
        }
      }
    }

    // 2. Outflow from Expenses
    for (final expense in expenses) {
      if (expense.isDeleted) continue;
      
      if (expense.paymentMethod == PaymentMethod.cash) {
        cash -= expense.amountCfa;
      } else if (expense.paymentMethod == PaymentMethod.mobileMoney) {
        mm -= expense.amountCfa;
      }
    }

    // 3. Outflow from Purchases
    for (final purchase in purchases) {
      if (purchase.isDeleted) continue;
      
      final amount = purchase.paidAmount ?? purchase.totalAmount;
      if (purchase.paymentMethod == PaymentMethod.cash) {
        cash -= amount;
      } else if (purchase.paymentMethod == PaymentMethod.mobileMoney) {
        mm -= amount;
      }
    }

    // 4. Manual Operations (Supplies, Removals, Transfers)
    for (final op in operations) {
      switch (op.type) {
        case TreasuryOperationType.supply:
          if (op.toAccount == PaymentMethod.cash) cash += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mm += op.amount;
          break;
        case TreasuryOperationType.removal:
          if (op.fromAccount == PaymentMethod.cash) cash -= op.amount;
          if (op.fromAccount == PaymentMethod.mobileMoney) mm -= op.amount;
          break;
        case TreasuryOperationType.transfer:
          // Remove from source
          if (op.fromAccount == PaymentMethod.cash) cash -= op.amount;
          if (op.fromAccount == PaymentMethod.mobileMoney) mm -= op.amount;
          // Add to destination
          if (op.toAccount == PaymentMethod.cash) cash += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mm += op.amount;
          break;
        case TreasuryOperationType.adjustment:
          // Adjustments are deltas
          if (op.toAccount == PaymentMethod.cash) cash += op.amount;
          if (op.toAccount == PaymentMethod.mobileMoney) mm += op.amount;
          break;
      }
    }

    return {
      PaymentMethod.cash: cash,
      PaymentMethod.mobileMoney: mm,
    };
  }
}
