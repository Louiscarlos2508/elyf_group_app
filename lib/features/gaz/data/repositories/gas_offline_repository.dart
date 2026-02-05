import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
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
              return _cylinderFromMap(map).copyWith(id: row.localId);
            } catch (e) {
              return null;
            }
          })
          .whereType<Cylinder>()
          .toList()
        ..sort((a, b) => a.weight.compareTo(b.weight));
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting cylinders: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Stream<List<Cylinder>> watchCylinders() {
    return driftService.records
        .watchForEnterprise(
          collectionName: _cylindersCollection,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        )
        .map((rows) {
          return rows
              .map((row) {
                try {
                  final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
                  return _cylinderFromMap(map).copyWith(id: row.localId);
                } catch (e) {
                  return null;
                }
              })
              .whereType<Cylinder>()
              .toList()
            ..sort((a, b) => a.weight.compareTo(b.weight));
        });
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
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting cylinder: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> addCylinder(Cylinder cylinder) async {
    try {
      String localId;
      String? remoteId;
      
      // Si l'ID commence par 'local_', c'est déjà un localId
      if (cylinder.id.startsWith('local_')) {
        localId = cylinder.id;
        remoteId = null;
      } else {
        remoteId = cylinder.id;
        
        // Chercher d'abord par remoteId pour éviter les duplications
        final byRemote = await driftService.records.findByRemoteId(
          collectionName: _cylindersCollection,
          remoteId: remoteId,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        );
        
        if (byRemote != null) {
          // Cylinder existant trouvé, utiliser son localId
          localId = byRemote.localId;
          developer.log(
            'Cylinder existant trouvé par remoteId lors de l\'ajout, utilisation du localId: $localId',
            name: 'GasOfflineRepository.addCylinder',
          );
        } else {
          // Chercher par weight + enterpriseId (un cylinder est unique par poids et entreprise)
          final rows = await driftService.records.listForEnterprise(
            collectionName: _cylindersCollection,
            enterpriseId: enterpriseId,
            moduleType: 'gaz',
          );
          final found = rows.where((r) {
            try {
              final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
              final cyl = _cylinderFromMap(map);
              return cyl.weight == cylinder.weight &&
                  cyl.enterpriseId == cylinder.enterpriseId;
            } catch (_) {
              return false;
            }
          }).firstOrNull;
          
          if (found != null) {
            localId = found.localId;
            developer.log(
              'Cylinder existant trouvé par weight+enterprise lors de l\'ajout, utilisation du localId: $localId',
              name: 'GasOfflineRepository.addCylinder',
            );
          } else {
            // Nouveau cylinder, générer un nouveau localId
            localId = LocalIdGenerator.generate();
            developer.log(
              'Nouveau cylinder, génération du localId: $localId',
              name: 'GasOfflineRepository.addCylinder',
            );
          }
        }
      }

      final map = _cylinderToMap(cylinder)..['localId'] = localId..['id'] = localId;

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
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error adding cylinder: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateCylinder(Cylinder cylinder) async {
    try {
      String localId;
      String? remoteId;
      
      // Si l'ID commence par 'local_', c'est déjà un localId
      if (cylinder.id.startsWith('local_')) {
        localId = cylinder.id;
        remoteId = null;
      } else {
        remoteId = cylinder.id;
        
        // Chercher d'abord par remoteId
        final byRemote = await driftService.records.findByRemoteId(
          collectionName: _cylindersCollection,
          remoteId: remoteId,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        );
        
        if (byRemote != null) {
          localId = byRemote.localId;
        } else {
          // Chercher par l'ID
          final existingCylinder = await getCylinderById(cylinder.id);
          if (existingCylinder != null) {
            if (existingCylinder.id.startsWith('local_')) {
              localId = existingCylinder.id;
            } else {
              // Chercher dans la base pour trouver le localId
              final rows = await driftService.records.listForEnterprise(
                collectionName: _cylindersCollection,
                enterpriseId: enterpriseId,
                moduleType: 'gaz',
              );
              final found = rows.firstWhere(
                (r) {
                  try {
                    final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
                    final cyl = _cylinderFromMap(map);
                    return cyl.id == cylinder.id;
                  } catch (_) {
                    return false;
                  }
                },
                orElse: () => throw NotFoundException(
                  'Cylinder not found',
                  'CYLINDER_NOT_FOUND',
                ),
              );
              localId = found.localId;
            }
          } else {
            // Si on ne trouve pas par ID, chercher par weight + enterpriseId
            final rows = await driftService.records.listForEnterprise(
              collectionName: _cylindersCollection,
              enterpriseId: enterpriseId,
              moduleType: 'gaz',
            );
            final found = rows.firstWhere(
              (r) {
                try {
                  final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
                  final cyl = _cylinderFromMap(map);
                  return cyl.weight == cylinder.weight &&
                      cyl.enterpriseId == cylinder.enterpriseId;
                } catch (_) {
                  return false;
                }
              },
              orElse: () => throw NotFoundException(
                'Cylinder not found for weight ${cylinder.weight} and enterprise ${cylinder.enterpriseId}',
                'CYLINDER_NOT_FOUND',
              ),
            );
            localId = found.localId;
          }
        }
      }

      final map = _cylinderToMap(cylinder)..['localId'] = localId..['id'] = localId;

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
      
      developer.log(
        'Cylinder sauvegardé - localId: $localId, remoteId: $remoteId, cylinder.id: ${cylinder.id}',
        name: 'GasOfflineRepository.updateCylinder',
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating cylinder: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
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
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting cylinder: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
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
              return null;
            }
          })
          .whereType<GasSale>()
          .toList();

      if (from != null) {
        sales = sales.where((s) => s.saleDate.isAfter(from)).toList();
      }
      if (to != null) {
        sales = sales.where((s) => s.saleDate.isBefore(to)).toList();
      }

      return sales..sort((a, b) => b.saleDate.compareTo(a.saleDate));
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting sales: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Stream<List<GasSale>> watchSales({DateTime? from, DateTime? to}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: _salesCollection,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        )
        .map((rows) {
          var sales = rows
              .map((row) {
                try {
                  final map = jsonDecode(row.dataJson) as Map<String, dynamic>;
                  return _gasSaleFromMap(map);
                } catch (e) {
                  return null;
                }
              })
              .whereType<GasSale>()
              .toList();

          if (from != null) {
            sales = sales.where((s) => s.saleDate.isAfter(from)).toList();
          }
          if (to != null) {
            sales = sales.where((s) => s.saleDate.isBefore(to)).toList();
          }

          return sales..sort((a, b) => b.saleDate.compareTo(a.saleDate));
        });
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
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error getting sale: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
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
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error adding sale: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
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
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error updating sale: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
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
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Error deleting sale: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
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
