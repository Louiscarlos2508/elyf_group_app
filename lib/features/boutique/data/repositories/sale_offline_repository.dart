import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../audit_trail/domain/entities/audit_record.dart';
import '../../../audit_trail/domain/repositories/audit_trail_repository.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

/// Offline-first repository for Sale entities.
class SaleOfflineRepository extends OfflineRepository<Sale>
    implements SaleRepository {
  SaleOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
    required this.auditTrailRepository,
    this.userId = 'system',
  });

  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  @override
  String get collectionName => 'sales';

  @override
  Sale fromMap(Map<String, dynamic> map) {
    return Sale.fromMap(map, enterpriseId);
  }

  @override
  Map<String, dynamic> toMap(Sale entity) {
    return entity.toMap();
  }

  @override
  String getLocalId(Sale entity) {
    if (entity.id.startsWith('local_')) {
      return entity.id;
    }
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Sale entity) {
    if (!entity.id.startsWith('local_')) {
      return entity.id;
    }
    return null;
  }

  @override
  String? getEnterpriseId(Sale entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Sale entity) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Sale entity) async {
    final remoteId = getRemoteId(entity);
    final localId = getLocalId(entity);

    if (remoteId != null) {
      await driftService.records.deleteByRemoteId(
        collectionName: collectionName,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return;
    }
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<Sale?> getByLocalId(String localId) async {
    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byLocal != null) {
      return fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    }

    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (byRemote == null) return null;
    return fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
  }

  @override
  Future<List<Sale>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final sales = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
    
    // Dédupliquer par remoteId pour éviter les doublons
    final deduplicatedSales = deduplicateByRemoteId(sales);
    
    // Trier par date décroissante
    deduplicatedSales.sort((a, b) => b.date.compareTo(a.date));

    // Filtrer les ventes supprimées (soft delete)
    return deduplicatedSales.where((sale) => !sale.isDeleted).toList();
  }

  // SaleRepository interface implementation

  @override
  Future<List<Sale>> fetchRecentSales({int limit = 50}) async {
    try {
      AppLogger.debug(
        'Fetching recent sales for enterprise: $enterpriseId',
        name: 'SaleOfflineRepository',
      );
      final allSales = await getAllForEnterprise(enterpriseId);
      return allSales.take(limit).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching recent sales: ${appException.message}',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Sale>> getSalesInPeriod(DateTime start, DateTime end) async {
    try {
      final allSales = await getAllForEnterprise(enterpriseId);
      return allSales.where((sale) {
        return sale.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            sale.date.isBefore(end.add(const Duration(seconds: 1)));
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching sales in period: ${appException.message}',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<String> createSale(Sale sale) async {
    try {
      final localId = getLocalId(sale);
      final saleWithLocalId = sale.copyWith(
        id: localId,
        enterpriseId: enterpriseId,
        updatedAt: DateTime.now(),
      );
      await save(saleWithLocalId);
      
      // Audit Log
      await _logAudit(
        action: 'create_sale',
        entityId: localId,
        metadata: {'totalAmount': sale.totalAmount, 'customerName': sale.customerName},
      );

      return localId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error creating sale: ${appException.message}',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Sale?> getSale(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting sale: $id - ${appException.message}',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Sale>> watchRecentSales({int limit = 50}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      final sales = rows
          .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
          .toList();
      final deduplicatedSales = deduplicateByRemoteId(sales);
      deduplicatedSales.sort((a, b) => b.date.compareTo(a.date));
      // Filtrer les ventes actives
      return deduplicatedSales.where((s) => !s.isDeleted).toList();
    });
  }

  @override
  Future<void> deleteSale(String id, {String? deletedBy}) async {
    try {
      final sale = await getSale(id);
      if (sale != null && !sale.isDeleted) {
        final deletedSale = sale.copyWith(
          deletedAt: DateTime.now(),
          deletedBy: deletedBy,
          updatedAt: DateTime.now(),
        );
        await save(deletedSale);

        // Audit Log
        await _logAudit(
          action: 'delete_sale',
          entityId: id,
          metadata: {'deletedBy': deletedBy},
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting sale: $id',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> restoreSale(String id) async {
    try {
      final sale = await getSale(id);
      if (sale != null && sale.isDeleted) {
        final restoredSale = sale.copyWith(
          deletedAt: null,
          deletedBy: null,
          updatedAt: DateTime.now(),
        );
        await save(restoredSale);

        // Audit Log
        await _logAudit(
          action: 'restore_sale',
          entityId: id,
        );
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error restoring sale: $id',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<Sale>> getDeletedSales() async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: collectionName,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      final sales = <Sale>[];
      for (final row in rows) {
        final map = safeDecodeJson(row.dataJson, row.localId);
        if (map == null) continue;
        try {
          final sale = fromMap(map);
          if (sale.isDeleted) {
            sales.add(sale);
          }
        } catch (_) {}
      }
      final deduplicatedSales = deduplicateByRemoteId(sales);
      deduplicatedSales.sort((a, b) => b.date.compareTo(a.date));
      return deduplicatedSales;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching deleted sales',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Sale>> watchDeletedSales() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
      final sales = <Sale>[];
      for (final row in rows) {
        final map = safeDecodeJson(row.dataJson, row.localId);
        if (map == null) continue;
        try {
          final sale = fromMap(map);
          if (sale.isDeleted) {
            sales.add(sale);
          }
        } catch (_) {}
      }
      final deduplicatedSales = deduplicateByRemoteId(sales);
      deduplicatedSales.sort((a, b) => b.date.compareTo(a.date));
      return deduplicatedSales;
    });
  }

  Future<void> _logAudit({
    required String action,
    required String entityId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await auditTrailRepository.log(
        AuditRecord(
          id: '', 
          enterpriseId: enterpriseId,
          userId: userId, 
          module: 'boutique',
          action: action,
          entityId: entityId,
          entityType: 'sale',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to log sale audit: $action', error: e);
    }
  }
}
