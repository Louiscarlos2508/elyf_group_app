import '../entities/activity_summary.dart';

/// Aggregates KPIs for dashboards.
abstract class ActivityRepository {
  Future<ActivitySummary> fetchTodaySummary();
  Future<ActivitySummary> fetchMonthlySummary(DateTime month);
}
