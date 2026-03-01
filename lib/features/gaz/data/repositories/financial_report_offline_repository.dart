import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/financial_report.dart';
import '../../domain/repositories/financial_report_repository.dart';

/// Offline-first repository for FinancialReport entities.
class FinancialReportOfflineRepository
    extends OfflineRepository<FinancialReport>
    implements FinancialReportRepository {
  FinancialReportOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'financial_reports';

  @override
  FinancialReport fromMap(Map<String, dynamic> map) =>
      FinancialReport.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(FinancialReport entity) => entity.toMap();

  @override
  String getLocalId(FinancialReport entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(FinancialReport entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(FinancialReport entity) => entity.enterpriseId;

  @override
  Future<void> saveToLocal(FinancialReport entity, {String? userId}) async {
    // Utiliser la méthode utilitaire pour trouver le localId existant
    final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId..['id'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
      collectionName: collectionName,
      localId: localId,
      remoteId: remoteId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(FinancialReport entity, {String? userId}) async {
    // Soft-delete
    final deletedReport = entity.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveToLocal(deletedReport, userId: syncManager.getUserId() ?? '');
    
    AppLogger.info(
      'Soft-deleted financial report: ${entity.id}',
      name: 'FinancialReportOfflineRepository',
    );
  }

  @override
  Future<FinancialReport?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote != null) {
      final report = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return report.isDeleted ? null : report;
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    final report = fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    return report.isDeleted ? null : report;
  }

  @override
  Future<List<FinancialReport>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final entities = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .where((r) => !r.isDeleted)
        .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  @override
  Future<List<FinancialReport>> getReports(
    String enterpriseId, {
    ReportPeriod? period,
    DateTime? from,
    DateTime? to,
    ReportStatus? status,
  }) async {
    try {
      final all = await getAllForEnterprise(enterpriseId);
      return all.where((report) {
        if (period != null && report.period != period) return false;
        if (status != null && report.status != status) return false;
        if (from != null && report.reportDate.isBefore(from)) return false;
        if (to != null && report.reportDate.isAfter(to)) return false;
        return true;
      }).toList()
        ..sort((a, b) => b.reportDate.compareTo(a.reportDate));
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting reports: ${appException.message}',
        name: 'FinancialReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // FinancialReportRepository implementation

  @override
  Stream<List<FinancialReport>> watchReports(
    String enterpriseId, {
    ReportPeriod? period,
    DateTime? from,
    DateTime? to,
    ReportStatus? status,
  }) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          final entities = rows
              .map((r) {
                try {
                  final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
                  return fromMap(map);
                } catch (e) {
                  return null;
                }
              })
              .whereType<FinancialReport>()
              .where((r) => !r.isDeleted)
              .toList();

          final deduplicated = deduplicateByRemoteId(entities);
          return deduplicated.where((report) {
            if (period != null && report.period != period) return false;
            if (status != null && report.status != status) return false;
            if (from != null && report.reportDate.isBefore(from)) return false;
            if (to != null && report.reportDate.isAfter(to)) return false;
            return true;
          }).toList()
            ..sort((a, b) => b.reportDate.compareTo(a.reportDate));
        });
  }

  @override
  Future<FinancialReport?> getReportById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting report: $id',
        name: 'FinancialReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> generateReport(FinancialReport report) async {
    try {
      final localId = getLocalId(report);
      final reportToSave = report.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(reportToSave);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error generating report: ${appException.message}',
        name: 'FinancialReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateReport(FinancialReport report) async {
    try {
      final updated = report.copyWith(
        enterpriseId: enterpriseId,
        updatedAt: DateTime.now(),
      );
      await save(updated);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating report: ${report.id} - ${appException.message}',
        name: 'FinancialReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> finalizeReport(String reportId) async {
    try {
      final report = await getReportById(reportId);
      if (report != null) {
        final finalized = report.copyWith(status: ReportStatus.finalized);
        await save(finalized);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error finalizing report: $reportId - ${appException.message}',
        name: 'FinancialReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<double> calculateNetAmount(
    String enterpriseId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final reports = await getReports(
        enterpriseId,
        from: startDate,
        to: endDate,
        status: ReportStatus.finalized,
      );
      return reports.fold<double>(0.0, (sum, r) => sum + r.netAmount);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error calculating net amount: ${appException.message}',
        name: 'FinancialReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteReport(String id) async {
    try {
      final report = await getReportById(id);
      if (report != null) {
        await delete(report);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting report: $id - ${appException.message}',
        name: 'FinancialReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
