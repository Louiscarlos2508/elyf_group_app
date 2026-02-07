import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/enterprise.dart';
import '../../domain/repositories/enterprise_repository.dart';

/// Repository Firestore pour Enterprise (web uniquement)
class EnterpriseFirestoreRepository implements EnterpriseRepository {
  EnterpriseFirestoreRepository({
    required this.firestore,
  });

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('enterprises');

  @override
  Stream<List<Enterprise>> watchAllEnterprises() {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Enterprise.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  @override
  Future<List<Enterprise>> getAllEnterprises() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => Enterprise.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<({List<Enterprise> enterprises, int totalCount})> getEnterprisesPaginated({
    int page = 0,
    int limit = 50,
  }) async {
    // Get total count
    final allSnapshot = await _collection.get();
    final totalCount = allSnapshot.docs.length;
    
    // Get paginated results (simple approach for web)
    
    // Skip to the right page manually (Firestore web doesn't have offset)
    final startIndex = page * limit;
    final docs = allSnapshot.docs;
    
    final paginatedDocs = docs.skip(startIndex).take(limit).toList();
    
    final enterprises = paginatedDocs
        .map((doc) => Enterprise.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
    
    return (enterprises: enterprises, totalCount: totalCount);
  }

  @override
  Future<List<Enterprise>> getEnterprisesByType(String type) async {
    final snapshot = await _collection.where('type', isEqualTo: type).get();
    return snapshot.docs
        .map((doc) => Enterprise.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<Enterprise?> getEnterpriseById(String enterpriseId) async {
    final doc = await _collection.doc(enterpriseId).get();
    if (!doc.exists) return null;
    return Enterprise.fromMap({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<void> createEnterprise(Enterprise enterprise) async {
    await _collection.doc(enterprise.id).set(enterprise.toMap());
  }

  @override
  Future<void> updateEnterprise(Enterprise enterprise) async {
    await _collection.doc(enterprise.id).update(enterprise.toMap());
  }

  @override
  Future<void> deleteEnterprise(String enterpriseId) async {
    await _collection.doc(enterpriseId).delete();
  }

  @override
  Future<void> toggleEnterpriseStatus(String enterpriseId, bool isActive) async {
    await _collection.doc(enterpriseId).update({
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}

