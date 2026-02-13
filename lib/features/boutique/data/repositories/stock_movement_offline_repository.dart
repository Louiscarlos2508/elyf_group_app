import 'dart:convert';
import 'package:elyf_groupe_app/core/offline/offline_repository.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/stock_movement_repository.dart';
import 'package:elyf_groupe_app/features/audit_trail/domain/repositories/audit_trail_repository.dart';

class StockMovementOfflineRepository extends OfflineRepository<StockMovement>
    implements StockMovementRepository {
  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  StockMovementOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
    required this.auditTrailRepository,
    required this.userId,
  });

  @override
  String get collectionName => 'stock_movements';

  @override
  Future<List<StockMovement>> getAllForEnterprise(String enterpriseId) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson)))
        .toList(); // StockMovements usually don't have soft delete check here unless specific
  }

  @override
  Future<StockMovement?> getByLocalId(String localId) async {
    final record = await driftService.records.findByLocalId(
      collectionName: collectionName,
      localId: localId,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    if (record != null) {
      return fromMap(jsonDecode(record.dataJson));
    }
    return null;
  }

  @override
  StockMovement fromMap(Map<String, dynamic> map) => StockMovement.fromMap(map);

  @override
  Map<String, dynamic> toMap(StockMovement entity) => entity.toMap();

  @override
  String getLocalId(StockMovement entity) => entity.id.isEmpty ? LocalIdGenerator.generate() : entity.id;

  @override
  String? getRemoteId(StockMovement entity) => entity.id.startsWith('local_') ? null : entity.id;

  @override
  String? getEnterpriseId(StockMovement entity) => enterpriseId;

  @override
  Future<void> saveToLocal(StockMovement entity) async {
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
  Future<void> deleteFromLocal(StockMovement entity) async {
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: getLocalId(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<List<StockMovement>> fetchMovements({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    StockMovementType? type,
  }) async {
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    
    var movements = rows
        .map((r) => fromMap(jsonDecode(r.dataJson)))
        .where((m) => m.deletedAt == null)
        .toList();

    if (productId != null) {
      movements = movements.where((m) => m.productId == productId).toList();
    }

    if (startDate != null) {
      movements = movements.where((m) => m.date.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      movements = movements.where((m) => m.date.isBefore(endDate)).toList();
    }

    if (type != null) {
      movements = movements.where((m) => m.type == type).toList();
    }

    movements.sort((a, b) => b.date.compareTo(a.date));
    return movements;
  }

  @override
  Future<void> recordMovement(StockMovement movement) async {
    await save(movement);
  }

  @override
  Stream<List<StockMovement>> watchMovements({String? productId}) {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          var movements = rows
            .map((r) => fromMap(jsonDecode(r.dataJson)))
            .where((m) => m.deletedAt == null)
            .toList();
            
          if (productId != null) {
            return movements.where((m) => m.productId == productId).toList();
          }
          return movements;
        });
  }
}
