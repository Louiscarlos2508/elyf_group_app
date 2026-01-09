/// Optimized query helpers for Drift repositories.
/// 
/// Contains optimized query patterns for common operations.
class OptimizedQueries {
  OptimizedQueries._();

  /// Maximum items to return in search results.
  static const int maxSearchResults = 100;

  /// Default pagination size.
  static const int defaultPageSize = 50;

  /// Maximum pagination size.
  static const int maxPageSize = 200;

  /// Calculates the offset for pagination.
  static int calculateOffset(int page, int limit) {
    return page * limit;
  }

  /// Validates and clamps pagination parameters.
  static ({int page, int limit}) validatePagination({
    required int page,
    required int limit,
  }) {
    final validPage = page < 0 ? 0 : page;
    final validLimit = limit.clamp(1, maxPageSize);
    return (page: validPage, limit: validLimit);
  }
}

