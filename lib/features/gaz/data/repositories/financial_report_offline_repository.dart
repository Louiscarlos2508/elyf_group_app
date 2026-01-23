import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
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
  FinancialReport fromMap(Map<String, dynamic> map) {
    return FinancialReport(
      id: map['id'] as String? ?? map['localId'] as String,
      enterpriseId: map['enterpriseId'] as String,
      reportDate: DateTime.parse(map['reportDate'] as String),
      period: ReportPeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => ReportPeriod.daily,
      ),
      totalRevenue: (map['totalRevenue'] as num).toDouble(),
      totalExpenses: (map['totalExpenses'] as num).toDouble(),
      loadingEventExpenses: (map['loadingEventExpenses'] as num).toDouble(),
      fixedCharges: (map['fixedCharges'] as num).toDouble(),
      variableCharges: (map['variableCharges'] as num).toDouble(),
      salaries: (map['salaries'] as num).toDouble(),
      netAmount: (map['netAmount'] as num).toDouble(),
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.draft,
      ),
    );
  }

  @override
  Map<String, dynamic> toMap(FinancialReport entity) {
    return {
      'id': entity.id,
      'enterpriseId': entity.enterpriseId,
      'reportDate': entity.reportDate.toIso8601String(),
      'period': entity.period.name,
      'totalRevenue': entity.totalRevenue,
      'totalExpenses': entity.totalExpenses,
      'loadingEventExpenses': entity.loadingEventExpenses,
      'fixedCharges': entity.fixedCharges,
      'variableCharges': entity.variableCharges,
      'salaries': entity.salaries,
      'netAmount': entity.netAmount,
      'status': entity.status.name,
    };
  }

  @override
  String getLocalId(FinancialReport entity) {
    if (entity.id.startsWith('local_')) return entity.id;
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
  Future<void> saveToLocal(FinancialReport entity) async {
    // Utiliser la méthode utilitaire pour trouver le localId existant
    final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
    final localId = existingLocalId ?? getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId..['id'] = localId;
    await driftService.records.upsert(
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
  Future<void> deleteFromLocal(FinancialReport entity) async {
    final remoteId = getRemoteId(entity);
    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    final localId = getLocalId(entity);
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
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
      return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
    }
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal == null) return null;
    return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
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

        .toList();

    

    // Dédupliquer par remoteId pour éviter les doublons

    return deduplicateByRemoteId(entities);
  }

  // FinancialReportRepository implementation

  @override
  Future<List<FinancialReport>> getReports(
    String enterpriseId, {
    ReportPeriod? period,
    DateTime? from,
    DateTime? to,
    ReportStatus? status,
  }) async {
    try {
      final reports = await getAllForEnterprise(enterpriseId);
      return reports.where((report) {
        if (period != null && report.period != period) return false;
        if (status != null && report.status != status) return false;
        if (from != null && report.reportDate.isBefore(from)) return false;
        if (to != null && report.reportDate.isAfter(to)) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting reports',
        name: 'FinancialReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<FinancialReport?> getReportById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
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
      final reportWithLocalId = report.copyWith(id: localId);
      await save(reportWithLocalId);
      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error generating report',
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
      await save(report);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating report: ${report.id}',
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
      developer.log(
        'Error finalizing report: $reportId',
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
      developer.log(
        'Error calculating net amount',
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
      developer.log(
        'Error deleting report: $id',
        name: 'FinancialReportOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
