/// Generic service for filtering and sorting lists.
///
/// Extracts business logic from UI widgets to make it testable and reusable.
class GenericListFilterService<T> {
  GenericListFilterService();

  /// Filters a list by text search on multiple fields.
  ///
  /// [items] : List of items to filter
  /// [searchQuery] : Search text
  /// [getSearchableFields] : Function that returns a list of searchable strings for each item
  List<T> filterBySearch({
    required List<T> items,
    required String searchQuery,
    required List<String> Function(T) getSearchableFields,
  }) {
    if (searchQuery.isEmpty) return items;

    final query = searchQuery.toLowerCase();
    return items.where((item) {
      final fields = getSearchableFields(item);
      return fields.any((field) => field.toLowerCase().contains(query));
    }).toList();
  }

  /// Filters a list by a predicate function.
  List<T> filterByPredicate({
    required List<T> items,
    required bool Function(T) predicate,
  }) {
    return items.where(predicate).toList();
  }

  /// Sorts a list by a comparison function.
  List<T> sortBy({
    required List<T> items,
    required int Function(T, T) compare,
  }) {
    final sorted = List<T>.from(items);
    sorted.sort(compare);
    return sorted;
  }

  /// Filters and sorts a list.
  List<T> filterAndSort({
    required List<T> items,
    String? searchQuery,
    List<String> Function(T)? getSearchableFields,
    bool Function(T)? predicate,
    int Function(T, T)? compare,
  }) {
    var result = items;

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty && getSearchableFields != null) {
      result = filterBySearch(
        items: result,
        searchQuery: searchQuery,
        getSearchableFields: getSearchableFields,
      );
    }

    // Apply predicate filter
    if (predicate != null) {
      result = filterByPredicate(items: result, predicate: predicate);
    }

    // Apply sorting
    if (compare != null) {
      result = sortBy(items: result, compare: compare);
    }

    return result;
  }
}

