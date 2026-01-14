import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../domain/entities/activity_summary.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/credit_repository.dart';
import '../../domain/repositories/production_session_repository.dart';
import '../../domain/repositories/sale_repository.dart';

/// Offline-first repository for ActivitySummary.
///
/// This repository aggregates data from other repositories to compute KPIs.
class ActivityOfflineRepository implements ActivityRepository {
  ActivityOfflineRepository({
    required this.saleRepository,
    required this.productionSessionRepository,
    required this.creditRepository,
  });

  final SaleRepository saleRepository;
  final ProductionSessionRepository productionSessionRepository;
  final CreditRepository creditRepository;

  @override
  Future<ActivitySummary> fetchTodaySummary() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final sales = await saleRepository.fetchRecentSales(limit: 1000);
      final todaySales = sales
          .where(
            (s) =>
                s.date.isAfter(
                  startOfDay.subtract(const Duration(seconds: 1)),
                ) &&
                s.date.isBefore(endOfDay.add(const Duration(seconds: 1))),
          )
          .toList();

      final sessions = await productionSessionRepository.fetchSessions(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      final totalSales = todaySales.fold<int>(
        0,
        (sum, s) => sum + s.totalPrice,
      );
      final totalProduction = sessions.fold<int>(
        0,
        (sum, s) => sum + s.quantiteProduite,
      );
      final pendingCredits = await creditRepository.getTotalCredits();

      return ActivitySummary(
        date: today,
        totalProduction: totalProduction,
        totalSales: totalSales,
        pendingCredits: pendingCredits,
        rawMaterialDays: 7.0,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching today summary',
        name: 'ActivityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<ActivitySummary> fetchMonthlySummary(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final sales = await saleRepository.fetchRecentSales(limit: 5000);
      final monthlySales = sales
          .where(
            (s) =>
                s.date.isAfter(
                  startOfMonth.subtract(const Duration(seconds: 1)),
                ) &&
                s.date.isBefore(endOfMonth.add(const Duration(seconds: 1))),
          )
          .toList();

      final sessions = await productionSessionRepository.fetchSessions(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      final totalSales = monthlySales.fold<int>(
        0,
        (sum, s) => sum + s.totalPrice,
      );
      final totalProduction = sessions.fold<int>(
        0,
        (sum, s) => sum + s.quantiteProduite,
      );
      final pendingCredits = await creditRepository.getTotalCredits();

      return ActivitySummary(
        date: month,
        totalProduction: totalProduction,
        totalSales: totalSales,
        pendingCredits: pendingCredits,
        rawMaterialDays: 30.0,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching monthly summary',
        name: 'ActivityOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
