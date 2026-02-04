import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/repositories/gas_repository.dart';

/// Offline-first repository for GasSale and Cylinder entities.
class GasSaleOfflineRepository extends OfflineRepository<GasSale>
    implements GasRepository {
  GasSaleOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'gas_sales';

  String get cylindersCollectionName => 'cylinders';

  @override
  GasSale fromMap(Map<String, dynamic> map) {
    return GasSale(
      id: map['id'] as String? ?? map['localId'] as String,
      cylinderId: map['cylinderId'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      saleDate: DateTime.parse(map['saleDate'] as String),
      saleType: SaleType.values.firstWhere(
        (e) => e.name == map['saleType'],
        orElse: () => SaleType.retail,
      ),
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      notes: map['notes'] as String?,
      tourId: map['tourId'] as String?,
      wholesalerId: map['wholesalerId'] as String?,
      wholesalerName: map['wholesalerName'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(GasSale entity) {
    return {
      'id': entity.id,
      'cylinderId': entity.cylinderId,
      'quantity': entity.quantity,
      'unitPrice': entity.unitPrice,
      'totalAmount': entity.totalAmount,
      'saleDate': entity.saleDate.toIso8601String(),
      'saleType': entity.saleType.name,
      'customerName': entity.customerName,
      'customerPhone': entity.customerPhone,
      'notes': entity.notes,
      'tourId': entity.tourId,
      'wholesalerId': entity.wholesalerId,
      'wholesalerName': entity.wholesalerName,
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(GasSale entity) {
    if (entity.id.isNotEmpty) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(GasSale entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(GasSale entity) => enterpriseId;

  @override
  Future<void> saveToLocal(GasSale entity) async {
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
  Future<void> deleteFromLocal(GasSale entity) async {
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
  Future<GasSale?> getByLocalId(String localId) async {
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
  Future<List<GasSale>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    final sales = rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
    
    // Dédupliquer par remoteId pour éviter les doublons
    return deduplicateByRemoteId(sales);
  }

  // GasRepository - Sales implementation

  @override
  Future<List<GasSale>> getSales({DateTime? from, DateTime? to}) async {
    try {
      final sales = await getAllForEnterprise(enterpriseId);
      return sales.where((sale) {
        if (from != null && sale.saleDate.isBefore(from)) return false;
        if (to != null && sale.saleDate.isAfter(to)) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting sales',
        name: 'GasSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<GasSale?> getSaleById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting sale: $id - ${appException.message}',
        name: 'GasSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> addSale(GasSale sale) async {
    try {
      final localId = getLocalId(sale);
      final saleWithLocalId = sale.copyWith(
        id: localId,
        updatedAt: DateTime.now(),
      );
      await save(saleWithLocalId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error adding sale',
        name: 'GasSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateSale(GasSale sale) async {
    try {
      final updatedSale = sale.copyWith(updatedAt: DateTime.now());
      await save(updatedSale);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating sale: ${sale.id} - ${appException.message}',
        name: 'GasSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteSale(String id) async {
    try {
      final sale = await getSaleById(id);
      if (sale != null) {
        await delete(sale);
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting sale: $id - ${appException.message}',
        name: 'GasSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  // GasRepository - Cylinders implementation

  Cylinder _cylinderFromMap(Map<String, dynamic> map) {
    return Cylinder(
      id: map['id'] as String? ?? map['localId'] as String,
      weight: (map['weight'] as num).toInt(),
      buyPrice: (map['buyPrice'] as num).toDouble(),
      sellPrice: (map['sellPrice'] as num).toDouble(),
      enterpriseId: map['enterpriseId'] as String,
      moduleId: map['moduleId'] as String,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> _cylinderToMap(Cylinder entity) {
    return {
      'id': entity.id,
      'weight': entity.weight,
      'buyPrice': entity.buyPrice,
      'sellPrice': entity.sellPrice,
      'enterpriseId': entity.enterpriseId,
      'moduleId': entity.moduleId,
      'stock': entity.stock,
    };
  }

  @override
  Future<List<Cylinder>> getCylinders() async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: cylindersCollectionName,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      return rows
          .map(
            (r) => _cylinderFromMap(
              jsonDecode(r.dataJson) as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting cylinders: ${appException.message}',
        name: 'GasSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<Cylinder?> getCylinderById(String id) async {
    try {
      final byRemote = await driftService.records.findByRemoteId(
        collectionName: cylindersCollectionName,
        remoteId: id,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      if (byRemote != null) {
        return _cylinderFromMap(
          jsonDecode(byRemote.dataJson) as Map<String, dynamic>,
        );
      }
      final byLocal = await driftService.records.findByLocalId(
        collectionName: cylindersCollectionName,
        localId: id,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      if (byLocal == null) return null;
      return _cylinderFromMap(
        jsonDecode(byLocal.dataJson) as Map<String, dynamic>,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting cylinder: $id - ${appException.message}',
        name: 'GasSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> addCylinder(Cylinder cylinder) async {
    try {
      final localId = cylinder.id.isNotEmpty
          ? cylinder.id
          : LocalIdGenerator.generate();
      final map = _cylinderToMap(cylinder)..['localId'] = localId;
      await driftService.records.upsert(
        collectionName: cylindersCollectionName,
        localId: localId,
        remoteId: cylinder.id.startsWith('local_') ? null : cylinder.id,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error adding cylinder: ${appException.message}',
        name: 'GasSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> updateCylinder(Cylinder cylinder) async {
    try {
      await addCylinder(cylinder);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating cylinder: ${cylinder.id} - ${appException.message}',
        name: 'GasSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> deleteCylinder(String id) async {
    try {
      await driftService.records.deleteByRemoteId(
        collectionName: cylindersCollectionName,
        remoteId: id,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      await driftService.records.deleteByLocalId(
        collectionName: cylindersCollectionName,
        localId: id,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting cylinder: $id - ${appException.message}',
        name: 'GasSaleOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
