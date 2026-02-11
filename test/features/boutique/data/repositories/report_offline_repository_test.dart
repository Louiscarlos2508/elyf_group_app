import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/boutique/data/repositories/report_offline_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/report_data.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/sale.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/purchase.dart';
import 'package:elyf_groupe_app/features/boutique/domain/entities/expense.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/sale_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/purchase_repository.dart';
import 'package:elyf_groupe_app/features/boutique/domain/repositories/expense_repository.dart';

class ManualMockSaleRepository implements SaleRepository {
  List<Sale> sales = [];
  @override
  Future<List<Sale>> getSalesInPeriod(DateTime start, DateTime end) async => sales;
  @override
  Future<List<Sale>> fetchRecentSales({int limit = 50}) async => sales;
  @override
  Stream<List<Sale>> watchRecentSales({int limit = 50}) => Stream.value(sales);
  @override
  Future<String> createSale(Sale sale) async => 'id';
  @override
  Future<Sale?> getSale(String id) async => null;
}

class ManualMockPurchaseRepository implements PurchaseRepository {
  List<Purchase> purchases = [];
  @override
  Future<List<Purchase>> getPurchasesInPeriod(DateTime start, DateTime end) async => purchases;
  @override
  Future<List<Purchase>> fetchPurchases({int limit = 50}) async => purchases;
  Future<List<Purchase>> fetchRecentPurchases({int limit = 50}) async => purchases;
  @override
  Stream<List<Purchase>> watchPurchases({int limit = 50}) => Stream.value(purchases);
  @override
  Future<String> createPurchase(Purchase purchase) async => 'id';
  @override
  Future<Purchase?> getPurchase(String id) async => null;
}

class ManualMockExpenseRepository implements ExpenseRepository {
  List<Expense> expenses = [];
  @override
  Future<List<Expense>> getExpensesInPeriod(DateTime start, DateTime end) async => expenses;
  @override
  Future<List<Expense>> fetchExpenses({int limit = 50}) async => expenses;
  Future<List<Expense>> fetchRecentExpenses({int limit = 50}) async => expenses;
  @override
  Stream<List<Expense>> watchExpenses({int limit = 50}) => Stream.value(expenses);
  @override
  Future<String> createExpense(Expense expense) async => 'id';
  @override
  Future<Expense?> getExpense(String id) async => null;
  @override
  Future<void> deleteExpense(String id, {String? deletedBy}) async {}
  @override
  Future<void> restoreExpense(String id) async {}
  @override
  Future<List<Expense>> getDeletedExpenses() async => [];
  @override
  Stream<List<Expense>> watchDeletedExpenses() => Stream.value([]);
}

void main() {
  group('ReportOfflineRepository', () {
    late ReportOfflineRepository repository;
    late ManualMockSaleRepository mockSaleRepository;
    late ManualMockPurchaseRepository mockPurchaseRepository;
    late ManualMockExpenseRepository mockExpenseRepository;

    setUp(() {
      mockSaleRepository = ManualMockSaleRepository();
      mockPurchaseRepository = ManualMockPurchaseRepository();
      mockExpenseRepository = ManualMockExpenseRepository();
      repository = ReportOfflineRepository(
        saleRepository: mockSaleRepository,
        purchaseRepository: mockPurchaseRepository,
        expenseRepository: mockExpenseRepository,
      );
    });

    test('getReportData aggregates data correctly', () async {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 31, 23, 59, 59);

      mockSaleRepository.sales = [
        Sale(id: 's1', enterpriseId: 'test-enterprise', date: DateTime(2025, 1, 10), items: [], totalAmount: 1000, amountPaid: 1000),
        Sale(id: 's2', enterpriseId: 'test-enterprise', date: DateTime(2025, 1, 15), items: [], totalAmount: 2000, amountPaid: 2000),
      ];

      mockPurchaseRepository.purchases = [
        Purchase(id: 'p1', enterpriseId: 'test-enterprise', date: DateTime(2025, 1, 5), items: [], totalAmount: 500),
      ];

      mockExpenseRepository.expenses = [
        Expense(
          id: 'e1', 
          enterpriseId: 'test-enterprise',
          label: 'Rent', 
          amountCfa: 300, 
          category: ExpenseCategory.rent,
          date: DateTime(2025, 1, 20),
        ),
      ];

      final result = await repository.getReportData(
        ReportPeriod.custom,
        startDate: start,
        endDate: end,
      );

      expect(result.salesRevenue, 3000);
      expect(result.purchasesAmount, 500);
      expect(result.expensesAmount, 300);
      expect(result.profit, 2200);
      expect(result.salesCount, 2);
      expect(result.purchasesCount, 1);
      expect(result.expensesCount, 1);
    });
  });
}
