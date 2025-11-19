import 'dart:async';

import '../../domain/entities/activity_summary.dart';
import '../../domain/repositories/activity_repository.dart';

class MockActivityRepository implements ActivityRepository {
  @override
  Future<ActivitySummary> fetchTodaySummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return ActivitySummary.placeholder();
  }

  @override
  Future<ActivitySummary> fetchMonthlySummary(DateTime month) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return ActivitySummary.placeholder();
  }
}
