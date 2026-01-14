import 'package:elyf_groupe_app/shared/domain/services/filtering/generic_list_filter_service.dart';
import '../../entities/expense.dart';
import '../../entities/gas_sale.dart';
import '../../entities/cylinder_stock.dart';
import '../../entities/cylinder.dart';

/// Service for filtering and sorting Gaz module lists.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class GazFilterService {
  GazFilterService();

  final _genericFilter = GenericListFilterService<dynamic>();

  /// Filters sales by date range.
  List<GasSale> filterSalesByDateRange({
    required List<GasSale> sales,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return sales.where((s) {
      if (startDate != null && s.saleDate.isBefore(startDate)) return false;
      if (endDate != null && s.saleDate.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  /// Filters sales by type.
  List<GasSale> filterSalesByType({
    required List<GasSale> sales,
    required SaleType? saleType,
  }) {
    if (saleType == null) return sales;
    return sales.where((s) => s.saleType == saleType).toList();
  }

  /// Filters sales by search query.
  List<GasSale> filterSalesBySearch({
    required List<GasSale> sales,
    required String searchQuery,
  }) {
    return _genericFilter.filterBySearch(
          items: sales,
          searchQuery: searchQuery,
          getSearchableFields: (sale) => [
            sale.customerName ?? '',
            sale.customerPhone ?? '',
            sale.id,
            sale.notes ?? '',
          ],
        )
        as List<GasSale>;
  }

  /// Filters expenses by date range.
  List<GazExpense> filterExpensesByDateRange({
    required List<GazExpense> expenses,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return expenses.where((e) {
      if (startDate != null && e.date.isBefore(startDate)) return false;
      if (endDate != null && e.date.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  /// Filters expenses by category.
  List<GazExpense> filterExpensesByCategory({
    required List<GazExpense> expenses,
    required ExpenseCategory? category,
  }) {
    if (category == null) return expenses;
    return expenses.where((e) => e.category == category).toList();
  }

  /// Filters expenses by search query.
  List<GazExpense> filterExpensesBySearch({
    required List<GazExpense> expenses,
    required String searchQuery,
  }) {
    return _genericFilter.filterBySearch(
          items: expenses,
          searchQuery: searchQuery,
          getSearchableFields: (expense) => [
            expense.description,
            expense.id,
            expense.notes ?? '',
          ],
        )
        as List<GazExpense>;
  }

  /// Filters stock by status.
  List<CylinderStock> filterStockByStatus({
    required List<CylinderStock> stock,
    required CylinderStatus? status,
  }) {
    if (status == null) return stock;
    return stock.where((s) => s.status == status).toList();
  }

  /// Filters stock by cylinder.
  List<CylinderStock> filterStockByCylinder({
    required List<CylinderStock> stock,
    required String? cylinderId,
  }) {
    if (cylinderId == null) return stock;
    return stock.where((s) => s.cylinderId == cylinderId).toList();
  }

  /// Sorts sales by date (newest first).
  List<GasSale> sortSalesByDateDesc(List<GasSale> sales) {
    final sorted = List<GasSale>.from(sales);
    sorted.sort((a, b) => b.saleDate.compareTo(a.saleDate));
    return sorted;
  }

  /// Sorts sales by date (oldest first).
  List<GasSale> sortSalesByDateAsc(List<GasSale> sales) {
    final sorted = List<GasSale>.from(sales);
    sorted.sort((a, b) => a.saleDate.compareTo(b.saleDate));
    return sorted;
  }

  /// Sorts expenses by date (newest first).
  List<GazExpense> sortExpensesByDateDesc(List<GazExpense> expenses) {
    final sorted = List<GazExpense>.from(expenses);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// Sorts expenses by amount (highest first).
  List<GazExpense> sortExpensesByAmountDesc(List<GazExpense> expenses) {
    final sorted = List<GazExpense>.from(expenses);
    sorted.sort((a, b) => b.amount.compareTo(a.amount));
    return sorted;
  }
}
