
import 'dart:convert';

import 'package:elyf_groupe_app/core/errors/app_exceptions.dart';
import 'package:elyf_groupe_app/core/errors/error_handler.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/core/offline/connectivity_service.dart';
import 'package:elyf_groupe_app/core/offline/drift_service.dart';
import 'package:elyf_groupe_app/core/offline/drift/app_database.dart';
import 'package:elyf_groupe_app/core/offline/offline_repository.dart';
import 'package:elyf_groupe_app/core/offline/sync_manager.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/gas_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/cylinder_stock_repository.dart';

/// Offline-first repository for Gas entities (gaz module).
///
/// Gère les bouteilles (Cylinder) et les ventes (GasSale).
class GasOfflineRepository implements GasRepository {
  GasOfflineRepository({
    required this.driftService,
    required this.syncManager,
    required this.connectivityService,
    required this.enterpriseId,
    required this.cylinderStockRepository,
  });

  final DriftService driftService;
  final SyncManager syncManager;
  final ConnectivityService connectivityService;
  final String enterpriseId;
  final CylinderStockRepository cylinderStockRepository;

  // Collections séparées pour chaque type d'entité
  static const String _cylindersCollection = 'cylinders';
  static const String _salesCollection = 'gas_sales';

  // Cylinder Helpers
  Map<String, dynamic> _cylinderToMap(Cylinder entity) => entity.toMap();
  Cylinder _cylinderFromMap(Map<String, dynamic> map) => Cylinder.fromMap(map, enterpriseId);

  // GasSale Helpers
  Map<String, dynamic> _gasSaleToMap(GasSale entity) => entity.toMap();
  GasSale _gasSaleFromMap(Map<String, dynamic> map) => GasSale.fromMap(map, enterpriseId);

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
          .where((c) => !c.isDeleted)
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
              .where((c) => !c.isDeleted)
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
          if (cylinder.id == id && !cylinder.isDeleted) {
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
          AppLogger.debug(
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
            AppLogger.debug(
              'Cylinder existant trouvé par weight+enterprise lors de l\'ajout, utilisation du localId: $localId',
              name: 'GasOfflineRepository.addCylinder',
            );
          } else {
            // Nouveau cylinder, générer un nouveau localId
            localId = LocalIdGenerator.generate();
            AppLogger.debug(
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
      
      AppLogger.debug(
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

      // Soft-delete: update with deletedAt instead of actual deletion
      final deletedCylinder = cylinder.copyWith(
        deletedAt: DateTime.now(),
      );
      
      final localId = deletedCylinder.id;
      final remoteId = cylinder.id.startsWith('local_') ? null : cylinder.id;
      final map = _cylinderToMap(deletedCylinder);

      await driftService.records.upsert(
        collectionName: _cylindersCollection,
        localId: localId,
        remoteId: remoteId,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );

      // Sync automatique (update au lieu de delete pour soft-delete)
      await syncManager.queueUpdate(
        collectionName: _cylindersCollection,
        localId: localId,
        remoteId: remoteId ?? localId,
        data: map,
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
  Future<List<GasSale>> getSales({DateTime? from, DateTime? to, List<String>? enterpriseIds}) async {
    try {
      final List<OfflineRecord> rows;
      if (enterpriseIds != null && enterpriseIds.isNotEmpty) {
        rows = await driftService.records.listForEnterprises(
          collectionName: _salesCollection,
          enterpriseIds: enterpriseIds,
          moduleType: 'gaz',
        );
      } else {
        rows = await driftService.records.listForEnterprise(
          collectionName: _salesCollection,
          enterpriseId: enterpriseId,
          moduleType: 'gaz',
        );
      }

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
          .where((s) => !s.isDeleted)
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
  Stream<List<GasSale>> watchSales({DateTime? from, DateTime? to, List<String>? enterpriseIds}) {
    final Stream<List<OfflineRecord>> stream;
    if (enterpriseIds != null && enterpriseIds.isNotEmpty) {
      stream = driftService.records.watchForEnterprises(
        collectionName: _salesCollection,
        enterpriseIds: enterpriseIds,
        moduleType: 'gaz',
      );
    } else {
      stream = driftService.records.watchForEnterprise(
        collectionName: _salesCollection,
        enterpriseId: enterpriseId,
        moduleType: 'gaz',
      );
    }

    return stream.map((rows) {
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
              .where((s) => !s.isDeleted)
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
          if (sale.id == id && !sale.isDeleted) {
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

      // Soft-delete
      final deletedSale = sale.copyWith(
        deletedAt: DateTime.now(),
      );

      final localId = deletedSale.id;
      final remoteId = sale.id.startsWith('local_') ? null : sale.id;
      final map = _gasSaleToMap(deletedSale);

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
        'Error deleting sale: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> executeSaleTransaction(GasSale sale) async {
    try {
      // 1. Enregistrer la vente
      await addSale(sale);

      // 2. Mettre à jour le stock bi-modal
      final cylinders = await getCylinders();
      final cylinder = cylinders.firstWhere((c) => c.id == sale.cylinderId);
      
      // Récupérer les stocks actuels (Pleines et Vides)
      final allStocks = await cylinderStockRepository.getAllForEnterprise(enterpriseId);
      
      // Stock Pleines
      final fullStock = allStocks.firstWhere(
        (s) => s.cylinderId == sale.cylinderId && s.status == CylinderStatus.full,
        orElse: () => throw BusinessException('Stock plein introuvable pour cette bouteille'),
      );

      // Mettre à jour les Pleines (décrémenter)
      await cylinderStockRepository.updateStockQuantity(
        fullStock.id,
        fullStock.quantity - sale.quantity,
      );

      // Si c'est un échange, mettre à jour les Vides (incrémenter)
      if (sale.isExchange) {
        final emptyStock = allStocks.firstWhere(
          (s) => s.cylinderId == sale.cylinderId && s.status == CylinderStatus.emptyAtStore,
          orElse: () => throw BusinessException('Stock vide introuvable pour cette bouteille'),
        );

        await cylinderStockRepository.updateStockQuantity(
          emptyStock.id,
          emptyStock.quantity + sale.emptyReturnedQuantity,
        );
      }
      
      AppLogger.info(
        'Vente exécutée avec succès - Bouteille: ${cylinder.weight}kg, Qté: ${sale.quantity}, Type: ${sale.dealType.label}',
        name: 'GasOfflineRepository',
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      AppLogger.error(
        'Erreur lors de l\'exécution de la transaction de vente: ${appException.message}',
        name: 'GasOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
