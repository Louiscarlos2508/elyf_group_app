import 'dart:convert';
import 'dart:developer' as developer;

import '../../../../core/errors/error_handler.dart';
import '../../../../core/offline/offline_repository.dart';
import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/bobine_stock_movement.dart';
import '../../domain/repositories/bobine_stock_quantity_repository.dart';

/// Offline-first repository for BobineStock entities.
class BobineStockOfflineRepository extends OfflineRepository<BobineStock>
    implements BobineStockQuantityRepository {
  BobineStockOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
  });

  final String enterpriseId;
  final String moduleType;

  @override
  String get collectionName => 'bobine_stocks';

  String get movementsCollection => 'bobine_stock_movements';

  @override
  BobineStock fromMap(Map<String, dynamic> map) {
    return BobineStock(
      id: map['id'] as String? ?? map['localId'] as String,
      type: map['type'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unit: map['unit'] as String? ?? 'unités',
      seuilAlerte: (map['seuilAlerte'] as num?)?.toInt(),
      fournisseur: map['fournisseur'] as String?,
      prixUnitaire: (map['prixUnitaire'] as num?)?.toInt(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap(BobineStock entity) {
    return {
      'id': entity.id,
      'type': entity.type,
      'quantity': entity.quantity,
      'unit': entity.unit,
      'seuilAlerte': entity.seuilAlerte,
      'fournisseur': entity.fournisseur,
      'prixUnitaire': entity.prixUnitaire,
      'createdAt': entity.createdAt?.toIso8601String(),
      'updatedAt': entity.updatedAt?.toIso8601String(),
    };
  }

  @override
  String getLocalId(BobineStock entity) {
    if (entity.id.startsWith('local_')) return entity.id;
    return LocalIdGenerator.generate();
  }

  @override
  String? getRemoteId(BobineStock entity) {
    if (!entity.id.startsWith('local_')) return entity.id;
    return null;
  }

  @override
  String? getEnterpriseId(BobineStock entity) => enterpriseId;

  @override
  Future<void> saveToLocal(BobineStock entity) async {
    final localId = getLocalId(entity);
    final remoteId = getRemoteId(entity);
    final map = toMap(entity)..['localId'] = localId;
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
  Future<void> deleteFromLocal(BobineStock entity) async {
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
  Future<BobineStock?> getByLocalId(String localId) async {
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
  Future<List<BobineStock>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson) as Map<String, dynamic>))
        .toList();
  }

  // BobineStockQuantityRepository implementation

  @override
  Future<List<BobineStock>> fetchAll() async {
    try {
      return await getAllForEnterprise(enterpriseId);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching bobine stocks',
        name: 'BobineStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<BobineStock?> fetchById(String id) async {
    try {
      return await getByLocalId(id);
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching bobine stock: $id',
        name: 'BobineStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<BobineStock?> fetchByType(String type) async {
    try {
      final stocks = await fetchAll();
      try {
        return stocks.firstWhere((s) => s.type == type);
      } catch (_) {
        return null;
      }
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching bobine stock by type: $type',
        name: 'BobineStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<BobineStock> save(BobineStock entity) async {
    try {
      final localId = getLocalId(entity);
      final stockWithLocalId = entity.copyWith(
        id: localId,
        updatedAt: DateTime.now(),
        createdAt: entity.createdAt ?? DateTime.now(),
      );
      await super.save(stockWithLocalId);
      return stockWithLocalId;
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error saving bobine stock',
        name: 'BobineStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<void> recordMovement(BobineStockMovement movement) async {
    try {
      final localId = movement.id.startsWith('local_')
          ? movement.id
          : LocalIdGenerator.generate();
      final map = {
        'id': localId,
        'localId': localId,
        'bobineId': movement.bobineId,
        'bobineReference': movement.bobineReference,
        'type': movement.type.name,
        'quantite': movement.quantite,
        'date': movement.date.toIso8601String(),
        'raison': movement.raison,
        'productionId': movement.productionId,
        'machineId': movement.machineId,
        'notes': movement.notes,
        'createdAt': movement.createdAt?.toIso8601String(),
      };

      await driftService.records.upsert(
        collectionName: movementsCollection,
        localId: localId,
        remoteId: null,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
        dataJson: jsonEncode(map),
        localUpdatedAt: DateTime.now(),
      );
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error recording bobine movement',
        name: 'BobineStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<BobineStockMovement>> fetchMovements({
    String? bobineStockId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final rows = await driftService.records.listForEnterprise(
        collectionName: movementsCollection,
        enterpriseId: enterpriseId,
        moduleType: moduleType,
      );
      final movements = rows.map((r) {
        final map = jsonDecode(r.dataJson) as Map<String, dynamic>;
        return BobineStockMovement(
          id: map['id'] as String,
          bobineId:
              map['bobineId'] as String? ??
              map['bobineStockId'] as String? ??
              '',
          bobineReference: map['bobineReference'] as String? ?? '',
          type: BobineMovementType.values.firstWhere(
            (e) => e.name == map['type'],
            orElse: () => BobineMovementType.entree,
          ),
          quantite:
              (map['quantite'] as num?)?.toDouble() ??
              (map['quantity'] as num?)?.toDouble() ??
              0.0,
          date: DateTime.parse(map['date'] as String),
          raison: map['raison'] as String? ?? map['reason'] as String? ?? '',
          productionId: map['productionId'] as String?,
          machineId: map['machineId'] as String?,
          notes: map['notes'] as String?,
          createdAt: map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String)
              : null,
        );
      }).toList();

      return movements.where((m) {
        if (bobineStockId != null && m.bobineId != bobineStockId) {
          return false;
        }
        if (startDate != null && m.date.isBefore(startDate)) return false;
        if (endDate != null && m.date.isAfter(endDate)) return false;
        return true;
      }).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching bobine movements',
        name: 'BobineStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }

  @override
  Future<List<BobineStock>> fetchLowStockAlerts() async {
    try {
      final stocks = await fetchAll();
      return stocks.where((s) => s.estStockFaible).toList();
    } catch (error, stackTrace) {
      final appException = ErrorHandler.instance.handleError(error, stackTrace);
      developer.log(
        'Error fetching low stock alerts',
        name: 'BobineStockOfflineRepository',
        error: error,
        stackTrace: stackTrace,
      );
      throw appException;
    }
  }
}
