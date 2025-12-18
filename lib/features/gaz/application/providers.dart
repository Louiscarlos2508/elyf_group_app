import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers/cylinder_controller.dart';
import 'controllers/expense_controller.dart';
import 'controllers/gas_controller.dart';
import '../data/repositories/mock_expense_repository.dart';
import '../data/repositories/mock_gas_repository.dart';
import '../domain/entities/cylinder.dart';
import '../domain/entities/expense.dart';
import '../domain/entities/gas_sale.dart';
import '../domain/entities/report_data.dart';
import '../domain/repositories/expense_repository.dart';
import '../domain/repositories/gas_repository.dart';

// Repositories
final gasRepositoryProvider = Provider<GasRepository>((ref) {
  return MockGasRepository();
});

final gazExpenseRepositoryProvider = Provider<GazExpenseRepository>((ref) {
  return MockGazExpenseRepository();
});

// Controllers
final cylinderControllerProvider = Provider<CylinderController>((ref) {
  final repo = ref.watch(gasRepositoryProvider);
  return CylinderController(repo);
});

final gasControllerProvider = Provider<GasController>((ref) {
  final repo = ref.watch(gasRepositoryProvider);
  return GasController(repo);
});

final expenseControllerProvider =
    Provider<GazExpenseController>((ref) {
  final repo = ref.watch(gazExpenseRepositoryProvider);
  return GazExpenseController(repo);
});

// Cylinders
final cylindersProvider = FutureProvider<List<Cylinder>>((ref) async {
  final repo = ref.watch(gasRepositoryProvider);
  return repo.getCylinders();
});

// Sales
final gasSalesProvider = FutureProvider<List<GasSale>>((ref) async {
  final repo = ref.watch(gasRepositoryProvider);
  return repo.getSales();
});

// Expenses
final gazExpensesProvider = FutureProvider<List<GazExpense>>((ref) async {
  final repo = ref.watch(gazExpenseRepositoryProvider);
  return repo.getExpenses();
});

// KPIs
final gazTotalSalesProvider = FutureProvider<double>((ref) async {
  final sales = await ref.watch(gasSalesProvider.future);
  return sales.fold<double>(0.0, (sum, s) => sum + s.totalAmount);
});

final gazTotalExpensesProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(gazExpenseRepositoryProvider);
  return repo.getTotalExpenses();
});

final gazProfitProvider = FutureProvider<double>((ref) async {
  final totalSales = await ref.watch(gazTotalSalesProvider.future);
  final totalExpenses = await ref.watch(gazTotalExpensesProvider.future);
  return totalSales - totalExpenses;
});

// Report Data Provider
final gazReportDataProvider = FutureProvider.family.autoDispose<
    GazReportData,
    ({
      GazReportPeriod period,
      DateTime? startDate,
      DateTime? endDate,
    })>((ref, params) async {
  final salesAsync = ref.watch(gasSalesProvider);
  final expensesAsync = ref.watch(gazExpensesProvider);

  final sales = await salesAsync.when(
    data: (data) async => data,
    loading: () async => <GasSale>[],
    error: (_, __) async => <GasSale>[],
  );

  final expenses = await expensesAsync.when(
    data: (data) async => data,
    loading: () async => <GazExpense>[],
    error: (_, __) async => <GazExpense>[],
  );

  // Calculate date range
  DateTime rangeStart;
  DateTime rangeEnd;

  final now = DateTime.now();
  switch (params.period) {
    case GazReportPeriod.today:
      rangeStart = DateTime(now.year, now.month, now.day);
      rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;
    case GazReportPeriod.week:
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      rangeStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
      rangeEnd = now;
      break;
    case GazReportPeriod.month:
      rangeStart = DateTime(now.year, now.month, 1);
      rangeEnd = now;
      break;
    case GazReportPeriod.year:
      rangeStart = DateTime(now.year, 1, 1);
      rangeEnd = now;
      break;
    case GazReportPeriod.custom:
      rangeStart = params.startDate ?? DateTime(now.year, now.month, 1);
      rangeEnd = params.endDate ?? now;
      break;
  }

  // Filter sales and expenses by date range
  final filteredSales = sales.where((s) {
    return s.saleDate.isAfter(rangeStart.subtract(const Duration(days: 1))) &&
        s.saleDate.isBefore(rangeEnd.add(const Duration(days: 1)));
  }).toList();

  final filteredExpenses = expenses.where((e) {
    return e.date.isAfter(rangeStart.subtract(const Duration(days: 1))) &&
        e.date.isBefore(rangeEnd.add(const Duration(days: 1)));
  }).toList();

  // Calculate totals
  final salesRevenue =
      filteredSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
  final expensesAmount =
      filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);
  final profit = salesRevenue - expensesAmount;

  // Count by type
  final retailCount =
      filteredSales.where((s) => s.saleType == SaleType.retail).length;
  final wholesaleCount = filteredSales.length - retailCount;

  return GazReportData(
    period: params.period,
    salesRevenue: salesRevenue,
    expensesAmount: expensesAmount,
    profit: profit,
    salesCount: filteredSales.length,
    expensesCount: filteredExpenses.length,
    retailSalesCount: retailCount,
    wholesaleSalesCount: wholesaleCount,
  );
});
