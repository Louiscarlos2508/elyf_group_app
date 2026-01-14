/// Service for pagination calculations.
///
/// Helps paginate large datasets efficiently.
class PaginationService {
  PaginationService();

  /// Calculates pagination info.
  PaginationInfo calculatePagination({
    required int totalItems,
    required int currentPage,
    required int itemsPerPage,
  }) {
    final totalPages = (totalItems / itemsPerPage).ceil();
    final hasNextPage = currentPage < totalPages - 1;
    final hasPreviousPage = currentPage > 0;
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, totalItems);

    return PaginationInfo(
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      itemsPerPage: itemsPerPage,
      startIndex: startIndex,
      endIndex: endIndex,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
    );
  }

  /// Gets items for a specific page.
  List<T> getPageItems<T>({
    required List<T> allItems,
    required int page,
    required int itemsPerPage,
  }) {
    final info = calculatePagination(
      totalItems: allItems.length,
      currentPage: page,
      itemsPerPage: itemsPerPage,
    );

    if (info.startIndex >= allItems.length) {
      return [];
    }

    return allItems.sublist(info.startIndex, info.endIndex);
  }
}

/// Pagination information.
class PaginationInfo {
  const PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.startIndex,
    required this.endIndex,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final int startIndex;
  final int endIndex;
  final bool hasNextPage;
  final bool hasPreviousPage;
}
