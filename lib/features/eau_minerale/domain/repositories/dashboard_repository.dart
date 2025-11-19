import '../entities/dashboard_stats.dart';

/// Dashboard statistics repository.
abstract class DashboardRepository {
  Future<DashboardStats> getDashboardStats();
}
