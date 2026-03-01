import 'dart:convert';
import 'package:elyf_groupe_app/core/offline/offline_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import 'package:elyf_groupe_app/features/audit_trail/domain/repositories/audit_trail_repository.dart';

class CategoryOfflineRepository extends OfflineRepository<Category>
    implements CategoryRepository {
  final String enterpriseId;
  final String moduleType;
  final AuditTrailRepository auditTrailRepository;
  final String userId;

  CategoryOfflineRepository({
    required super.driftService,
    required super.syncManager,
    required super.connectivityService,
    required this.enterpriseId,
    required this.moduleType,
    required this.auditTrailRepository,
    required this.userId,
  });

  @override
  String get collectionName => 'categories';

  @override
  Category fromMap(Map<String, dynamic> map) => Category.fromMap(map, enterpriseId);

  @override
  Map<String, dynamic> toMap(Category entity) => entity.toMap();

  @override
  String getLocalId(Category entity) => entity.id.isEmpty ? LocalIdGenerator.generate() : entity.id;

  @override
  String? getRemoteId(Category entity) => entity.id.startsWith('local_') ? null : entity.id;

  @override
  String? getEnterpriseId(Category entity) => enterpriseId;

  @override
  Future<void> saveToLocal(Category entity, {String? userId}) async {
    final localId = getLocalId(entity);
    final map = toMap(entity)..['localId'] = localId;
    await driftService.records.upsert(userId: syncManager.getUserId() ?? '', 
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
  Future<void> deleteFromLocal(Category entity, {String? userId}) async {
    await driftService.records.deleteByLocalId(
      collectionName: collectionName,
      localId: getLocalId(entity),
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
  }

  @override
  Future<List<Category>> getAllForEnterprise(String enterpriseId) async {
    // This is needed for OfflineRepository abstract method
    final rows = await driftService.records.listForEnterprise(
      collectionName: collectionName,
      enterpriseId: enterpriseId,
      moduleType: moduleType,
    );
    return rows
        .map((r) => fromMap(jsonDecode(r.dataJson)))
        .where((c) => c.deletedAt == null)
        .toList();
  }

  @override
  Future<Category?> getByLocalId(String localId) async {
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

  // CategoryRepository implementation

  @override
  Future<List<Category>> fetchCategories() async {
    return await getAllForEnterprise(enterpriseId);
  }

  @override
  Future<Category?> getCategory(String id) async {
    return await getByLocalId(id);
  }

  @override
  Future<String> createCategory(Category category) async {
    final newCategory = category.copyWith(
      id: getLocalId(category),
      enterpriseId: enterpriseId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await save(newCategory);
    return newCategory.id;
  }

  @override
  Future<void> updateCategory(Category category) async {
    await save(category.copyWith(updatedAt: DateTime.now()));
  }

  @override
  Future<void> deleteCategory(String id, {required String deletedBy}) async {
    final category = await getCategory(id);
    if (category != null) {
      final updated = category.copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await save(updated);
    }
  }

  @override
  Stream<List<Category>> watchCategories() {
    return driftService.records
        .watchForEnterprise(
          collectionName: collectionName,
          enterpriseId: enterpriseId,
          moduleType: moduleType,
        )
        .map((rows) {
          return rows
            .map((r) => fromMap(jsonDecode(r.dataJson)))
            .where((c) => c.deletedAt == null)
            .toList();
        });
  }
}
