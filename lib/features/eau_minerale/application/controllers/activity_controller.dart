import '../../domain/entities/activity_summary.dart';
import '../../domain/repositories/activity_repository.dart';

class ActivityController {
  ActivityController(this._repository);

  final ActivityRepository _repository;

  Future<ActivitySummary> fetchTodaySummary() =>
      _repository.fetchTodaySummary();

  Future<ActivitySummary> fetchMonthlySummary(DateTime month) =>
      _repository.fetchMonthlySummary(month);
}
