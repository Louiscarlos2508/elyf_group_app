import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../../../core/offline/drift_service.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../../../core/offline/sync_manager.dart';
import '../../domain/entities/cylinder.dart';
import '../../domain/entities/gas_sale.dart';
import '../../domain/repositories/gas_repository.dart';

/// Offline-first repository for Gas entities (gaz module).
///
/// Gère les bouteilles (Cylinder) et les ventes (GasSale).
class GasOfflineRepository implements GasRepository {
  GasOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    required this.enterpriseId,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final String enterpriseId;

  // Collections séparées pour chaque type d'entité
  static const String _cylindersCollection = 'cylinders';
  static const String _salesCollection = 'gas_sales';

  // Helpers pour Cylinder

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

  Cylinder _cylinderFromMap(Map<String, dynamic> map) {
    return Cylinder(
      id: map['id'] as String? ?? map['localId'] as String,
      weight: (map['weight'] as num?)?.toInt() ?? 0,
      buyPrice: (map['buyPrice'] as num?)?.toDouble() ?? 0.0,
      sellPrice: (map['sellPrice'] as num?)?.toDouble() ?? 0.0,
      enterpriseId: map['enterpriseId'] as String? ?? enterpriseId,
      moduleId: map['moduleId'] as String? ?? 'gaz',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
    );
  }

  // Helpers pour GasSale

  Map<String, dynamic> _gasSaleToMap(GasSale entity) {
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
    };
  }

  GasSale _gasSaleFromMap(Map<String, dynamic> map) {
    return GasSale(
      id: map['id'] as String? ?? map['localId'] as String,
      cylinderId: map['cylinderId'] as String,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      saleDate: DateTime.parse(map['saleDate'] as String),
      saleType: _parseSaleType(map['saleType'] as String? ?? 'retail'),
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      notes: map['notes'] as String?,
      tourId: map['tourId'] as String?,
      wholesalerId: map['wholesalerId'] as String?,
      wholesalerName: map['wholesalerName'] as String?,
    );
  }

  // Implémentation de GasRepository - Cylinders

  @override
  Future<List<Cylinder>> getCylinders() async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _cylindersCollection,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      return rows
          .map((row) {
            try {
              final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
              return _cylinderFromMap(map);
            } catch (e) {
              developer.log(
                'Error parsing cylinder: $e',
                name: 'GasOfflineRepository',
              );
              return null;
            }
          })
          .whereType<Cylinder>()
          .toList();
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching cylinders',
        name: 'GasOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<Cylinder?> getCylinderById(String id) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _cylindersCollection,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      for (final row in rows) {
        try {
          final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
          final cylinder = _cylinderFromMap(map);
          if (cylinder.id == id) {
            return cylinder;
          }
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting cylinder',
        name: 'GasOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<void> addCylinder(Cylinder cylinder) async {
    try {
      final localId = cylinder.id.startsWith('local_')
          ? cylinder.id
          : LocalIdGenerator.generate();
      final remoteId = cylinder.id.startsWith('local_') ? null : cylinder.id;

      final map = _cylinderToMap(cylinder)..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: _cylindersCollection,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.queueCreate(
        collectionName: _cylindersCollection,
        localId: localId,
        data: map,
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error adding cylinder',
        name: 'GasOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateCylinder(Cylinder cylinder) async {
    try {
      final localId = cylinder.id.startsWith('local_')
          ? cylinder.id
          : LocalIdGenerator.generate();
      final remoteId = cylinder.id.startsWith('local_') ? null : cylinder.id;

      final map = _cylinderToMap(cylinder)..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: _cylindersCollection,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.queueUpdate(
        collectionName: _cylindersCollection,
        localId: localId,
        remoteId: remoteId ?? localId,
        data: map,
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating cylinder',
        name: 'GasOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteCylinder(String id) async {
    try {
      final cylinder = await getCylinderById(id);
      if (cylinder == null) return;

      final localId = cylinder.id.startsWith('local_')
          ? cylinder.id
          : LocalIdGenerator.generate();
      final remoteId = cylinder.id.startsWith('local_') ? null : cylinder.id;

      if (remoteId != null) {
        await driftService.records.deleteByRemoteId(
          collectionName: _cylindersCollection,
          remoteId: remoteId,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        );
      } else {
        await driftService.records.deleteByLocalId(
          collectionName: _cylindersCollection,
          localId: localId,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        );
      }

      // Sync automatique
      await syncManager.queueDelete(
        collectionName: _cylindersCollection,
        localId: localId,
        remoteId: remoteId ?? localId,
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting cylinder',
        name: 'GasOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  // Implémentation de GasRepository - Sales

  @override
  Future<List<GasSale>> getSales({DateTime? from, DateTime? to}) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _salesCollection,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      var sales = rows
          .map((row) {
            try {
              final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
              return _gasSaleFromMap(map);
            } catch (e) {
              developer.log(
                'Error parsing gas sale: $e',
                name: 'GasOfflineRepository',
              );
              return null;
            }
          })
          .whereType<GasSale>()
          .toList();

      // Filtrer par date
      if (from != null) {
        sales = sales
            .where((s) => s.saleDate.isAfter(from) || s.saleDate.isAtSameMomentAs(from))
            .toList();
      }

      if (to != null) {
        sales = sales
            .where((s) => s.saleDate.isBefore(to) || s.saleDate.isAtSameMomentAs(to))
            .toList();
      }

      sales.sort((a, b) => b.saleDate.compareTo(a.saleDate));
      return sales;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching sales',
        name: 'GasOfflineRepository',
        error: appException,
      );
      return [];
    }
  }

  @override
  Future<GasSale?> getSaleById(String id) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: _salesCollection,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );

      for (final row in rows) {
        try {
          final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
          final sale = _gasSaleFromMap(map);
          if (sale.id == id) {
            return sale;
          }
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error getting sale',
        name: 'GasOfflineRepository',
        error: appException,
      );
      return null;
    }
  }

  @override
  Future<void> addSale(GasSale sale) async {
    try {
      final localId = sale.id.startsWith('local_')
          ? sale.id
          : LocalIdGenerator.generate();
      final remoteId = sale.id.startsWith('local_') ? null : sale.id;

      final map = _gasSaleToMap(sale)..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: _salesCollection,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.queueCreate(
        collectionName: _salesCollection,
        localId: localId,
        data: map,
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error adding sale',
        name: 'GasOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateSale(GasSale sale) async {
    try {
      final localId = sale.id.startsWith('local_')
          ? sale.id
          : LocalIdGenerator.generate();
      final remoteId = sale.id.startsWith('local_') ? null : sale.id;

      final map = _gasSaleToMap(sale)..['localId'] = localId;

      await driftService.records.upsert(
        collectionName: _salesCollection,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique
      await syncManager.queueUpdate(
        collectionName: _salesCollection,
        localId: localId,
        remoteId: remoteId ?? localId,
        data: map,
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error updating sale',
        name: 'GasOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteSale(String id) async {
    try {
      final sale = await getSaleById(id);
      if (sale == null) return;

      final localId = sale.id.startsWith('local_')
          ? sale.id
          : LocalIdGenerator.generate();
      final remoteId = sale.id.startsWith('local_') ? null : sale.id;

      if (remoteId != null) {
        await driftService.records.deleteByRemoteId(
          collectionName: _salesCollection,
          remoteId: remoteId,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        );
      } else {
        await driftService.records.deleteByLocalId(
          collectionName: _salesCollection,
          localId: localId,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        );
      }

      // Sync automatique
      await syncManager.queueDelete(
        collectionName: _salesCollection,
        localId: localId,
        remoteId: remoteId ?? localId,
        enterpriseId: enterpriseId,
      );
    } catch (error, stackTrace) {
      final appException =
          ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error deleting sale',
        name: 'GasOfflineRepository',
        error: appException,
      );
      rethrow;
    }
  }

  SaleType _parseSaleType(String type) {
    switch (type.toLowerCase()) {
      case 'retail':
      case 'detail':
        return SaleType.retail;
      case 'wholesale':
      case 'gros':
        return SaleType.wholesale;
      default:
        return SaleType.retail;
    }
  }
}

