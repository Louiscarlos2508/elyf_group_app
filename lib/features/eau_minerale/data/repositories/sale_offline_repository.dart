import 'dart:convert';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';

/// Offline-first repository for Sale entities (eau_minerale module).
class SaleOfflineRepository extends OfflineRepository<Sale>
    implements SaleRepository {
  SaleOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
  });

  final String enterpriseId;

  @override
  String get collectionName => 'sales';

  @override
  String getLocalId(Sale entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(Sale entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(Sale entity) => enterpriseId;

  @override
  Sale fromMap(Map<String, dynamic> map) => Sale.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(Sale entity) => entity.toMap();

  @override
  Future<void> saveToLocal(Sale entity) async {
    final map = toMap(entity);
    final localId = getLocalId(entity);
    map['localId'] = localId; // Ensure localId is present in map for some legacy consumers
    
    await driftService.records.upsert(
      collectionName: collectionName,
      localId: localId,
      remoteId: getRemoteId(entity),
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
      dataJson: jsonEncode(map),
      localUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFromLocal(Sale entity) async {
    // Soft-delete: update the record with deletedAt instead of removing it
    final deletedSale = entity.copyWith(
      deletedAt: DateTime.now(),
      // deletedBy could be added here if we had the current user
    );
    await saveToLocal(deletedSale);
    
    AppLogger.info(
      'Soft-deleted sale: ${entity.id} (enterprise: $enterpriseId)',
      name: 'SaleOfflineRepository',
    );
  }

  @override
  Future<Sale?> getByLocalId(String localId) async {
    final byRemote = await driftService.records.findByRemoteId(
      collectionName: collectionName,
      remoteId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byRemote != null) {
      final sale = fromMap(jsonDecode(byRemote.dataJson) as Map<String, dynamic>);
      return sale.isDeleted ? null : sale;
    }

    final byLocal = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );
    if (byLocal == null) return null;
    final sale = fromMap(jsonDecode(byLocal.dataJson) as Map<String, dynamic>);
    return sale.isDeleted ? null : sale;
  }

  @override
  Future<List<Sale>> fetchRecentSales({int limit = 50}) async {
    final all = await getAllForEnterprise(enterpriseId);
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.take(limit).toList();
  }

  @override
  Future<List<Sale>> getAllForEnterprise(String enterpriseId) async {
    AppLogger.debug(
      'Fetching all sales for enterprise: $enterpriseId (module: eau_minerale)',
      name: 'SaleOfflineRepository',
    );

    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: 'eau_minerale',
    );

    AppLogger.debug(
      'Found ${rows.length} records for $collectionName / $enterpriseId',
      name: 'SaleOfflineRepository',
    );

    final sales = rows
        .map((row) => safeDecodeJson(row.dataJson, row.localId))
        .where((map) => map != null)
        .map((map) => fromMap(map!))
        .where((sale) => !sale.isDeleted)
        .toList();

    AppLogger.debug(
        'Successfully decoded ${sales.length} sales',
        name: 'SaleOfflineRepository',
    );

    return deduplicateByRemoteId(sales);
  }

  // SaleRepository interface implementation

  @override
  Future<List<Sale>> fetchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleStatus? status,
    String? customerId,
  }) async {
    try {
      AppLogger.debug(
        'Fetching sales for enterprise: $enterpriseId',
        name: 'SaleOfflineRepository',
      );
      var allSales = await getAllForEnterprise(enterpriseId);

      if (startDate != null) {
        allSales = allSales
            .where(
              (s) =>
                  s.date.isAfter(startDate) ||
                  s.date.isAtSameMomentAs(startDate),
            )
            .toList();
      }

      if (endDate != null) {
        allSales = allSales
            .where(
              (s) =>
                  s.date.isBefore(endDate) || s.date.isAtSameMomentAs(endDate),
            )
            .toList();
      }

      if (status != null) {
        allSales = allSales.where((s) => s.status == status).toList();
      }

      if (customerId != null) {
        allSales = allSales.where((s) => s.customerId == customerId).toList();
      }

      // Sort by date descending
      allSales.sort((a, b) => b.date.compareTo(a.date));

      return allSales;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error fetching sales: ${appException.message}',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Stream<List<Sale>> watchSales({
    DateTime? startDate,
    DateTime? endDate,
    SaleStatus? status,
    String? customerId,
  }) {
    AppLogger.debug(
      'Watching sales for enterprise: $enterpriseId',
      name: 'SaleOfflineRepository',
    );

    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: 'eau_minerale',
        )
        .map((rows) {
          var sales = rows
              .map((row) => safeDecodeJson(row.dataJson, row.localId))
              .where((map) => map != null)
              .map((map) => fromMap(map!))
              .where((sale) => !sale.isDeleted)
              .toList();

          if (startDate != null) {
            sales = sales
                .where(
                  (s) =>
                      s.date.isAfter(startDate) ||
                      s.date.isAtSameMomentAs(startDate),
                )
                .toList();
          }

          if (endDate != null) {
            sales = sales
                .where(
                  (s) =>
                      s.date.isBefore(endDate) || s.date.isAtSameMomentAs(endDate),
                )
                .toList();
          }

          if (status != null) {
            sales = sales.where((s) => s.status == status).toList();
          }

          if (customerId != null) {
            sales = sales.where((s) => s.customerId == customerId).toList();
          }

          // Sort by date descending
          sales.sort((a, b) => b.date.compareTo(a.date));

          return sales;
        });
  }
  @override
  Future<Sale?> getSale(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting sale: $id',
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
      final saleToSave = sale.copyWith(
        id: getLocalId(sale),
        enterpriseId: enterpriseId,
        createdAt: sale.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(saleToSave);
      return saleToSave.id;
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
  Future<void> updateSale(Sale sale) async {
    try {
      final saleToUpdate = sale.copyWith(
        updatedAt: DateTime.now(),
      );
      await save(saleToUpdate);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating sale: ${appException.message}',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteSale(String saleId) async {
    try {
      final sale = await getSale(saleId);
      if (sale != null) {
        await delete(sale);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting sale: $saleId',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateSaleAmountPaid(String saleId, int newAmountPaid) async {
    try {
      final sale = await getSale(saleId);
      if (sale != null) {
        final updatedSale = sale.copyWith(
          amountPaid: newAmountPaid,
          status: newAmountPaid >= sale.totalPrice
              ? SaleStatus.fullyPaid
              : SaleStatus.validated,
          updatedAt: DateTime.now(),
        );
        // Utiliser la méthode save de la classe de base pour gérer la sync correctement
        await save(updatedSale);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating sale amount paid: $saleId - ${appException.message}',
        name: 'SaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
