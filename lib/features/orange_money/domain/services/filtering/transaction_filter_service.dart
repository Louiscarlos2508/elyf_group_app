import 'package:elyf_groupe_app/shared/domain/services/filtering/generic_list_filter_service.dart';

/// Service for filtering transactions in Orange Money module.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class TransactionFilterService {
  TransactionFilterService();

  /// Filters transactions by search query.
  List<T> filterBySearch<T>({
    required List<T> transactions,
    required String searchQuery,
    required List<String> Function(T) getSearchableFields,
  }) {
    final genericFilter = GenericListFilterService<T>();
    return genericFilter.filterBySearch(
      items: transactions,
      searchQuery: searchQuery,
      getSearchableFields:
          getSearchableFields as List<String> Function(dynamic),
    );
  }

  /// Filters transactions by date range.
  List<T> filterByDateRange<T>({
    required List<T> transactions,
    DateTime? startDate,
    DateTime? endDate,
    required DateTime Function(T) getDate,
  }) {
    return transactions.where((t) {
      final date = getDate(t);
      if (startDate != null && date.isBefore(startDate)) return false;
      if (endDate != null && date.isAfter(endDate)) return false;
      return true;
    }).toList();
  }
}
