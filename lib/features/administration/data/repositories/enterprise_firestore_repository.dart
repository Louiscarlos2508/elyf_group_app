import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/auth/services/auth_service.dart';
import '../../domain/entities/enterprise.dart';
import '../../domain/repositories/enterprise_repository.dart';

/// Repository Firestore pour Enterprise (web uniquement)
class EnterpriseFirestoreRepository implements EnterpriseRepository {
  EnterpriseFirestoreRepository({
    required this.firestore,
    required this.authService,
  });

  final FirebaseFirestore firestore;
  final AuthService authService;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection('enterprises');

  CollectionReference<Map<String, dynamic>> _getSubCollection(String parentId, String subCollection) =>
      firestore.collection('enterprises').doc(parentId).collection(subCollection);

  DocumentReference<Map<String, dynamic>> _docFor(Enterprise e) {
    if (e.isPointOfSale && e.parentEnterpriseId != null) {
      return _getSubCollection(e.parentEnterpriseId!, e.subCollectionName).doc(e.id);
    }
    return _collection.doc(e.id);
  }

  List<String> _getAllowedEnterpriseIds() {
    final user = authService.currentUser;
    if (user == null) return [];
    if (user.isAdmin || user.email == 'admin@elyf-group.com' || user.email == 'admin@elyf.com') return ['*']; // Admin can see all
    return user.enterpriseIds;
  }

  @override
  Stream<List<Enterprise>> watchAllEnterprises() {
    return authService.userStream.switchMap<List<Enterprise>>((user) {
      if (user == null) return Stream.value([]);
      
      final isAdmin = (user.isAdmin || user.email == 'admin@elyf-group.com' || user.email == 'admin@elyf.com');
      final allowedIds = isAdmin ? ['*'] : user.enterpriseIds;
          
      if (allowedIds.isEmpty) return Stream.value([]);

      // 1. Stream pour les entreprises racines
      Query<Map<String, dynamic>> rootQuery = _collection;
      if (!allowedIds.contains('*')) {
        rootQuery = _collection.where(FieldPath.documentId, whereIn: allowedIds.take(10).toList());
      }
      
      final Stream<List<Enterprise>> rootsStream = rootQuery.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => Enterprise.fromMap({...doc.data(), 'id': doc.id}))
          .toList());

      if (isAdmin) {
        // Pour les admins, on écoute TOUT en temps réel via collectionGroup
        final Stream<List<Enterprise>> possStream = firestore
            .collectionGroup('pointsOfSale')
            .snapshots()
            .map((snapshot) => snapshot.docs.map((doc) {
                  final parentId = doc.reference.parent.parent?.id;
                  return Enterprise.fromMap({...doc.data(), 'id': doc.id, 'parentEnterpriseId': parentId});
                }).toList());

        final Stream<List<Enterprise>> agencesStream = firestore
            .collectionGroup('agences')
            .snapshots()
            .map((snapshot) => snapshot.docs.map((doc) {
                  final parentId = doc.reference.parent.parent?.id;
                  return Enterprise.fromMap({...doc.data(), 'id': doc.id, 'parentEnterpriseId': parentId});
                }).toList());

        return CombineLatestStream.combine3<List<Enterprise>, List<Enterprise>, List<Enterprise>, List<Enterprise>>(
          rootsStream,
          possStream,
          agencesStream,
          (roots, poss, agences) {
            final all = <Enterprise>[...roots, ...poss, ...agences];
            final unique = <String, Enterprise>{};
            for (final e in all) {
              unique[e.id] = e;
            }
            return unique.values.toList();
          },
        );
      } else {
        // Pour les non-admins, on garde l'approche par racine (plus restrictive)
        return rootsStream.asyncMap((roots) async {
          final all = <Enterprise>[...roots];
          
          for (final root in roots) {
            for (final subName in ['pointsOfSale', 'agences']) {
              try {
                final posSnapshot = await _getSubCollection(root.id, subName).get();
                all.addAll(posSnapshot.docs.map((doc) => 
                  Enterprise.fromMap({...doc.data(), 'id': doc.id, 'parentEnterpriseId': root.id})
                ));
              } catch (e) {
                // Suppress permission errors on specific sub-collections
              }
            }
          }
          
          return all;
        });
      }
    }).onErrorReturn(<Enterprise>[]);
  }

  @override
  Future<List<Enterprise>> getAllEnterprises() async {
    final allowedIds = _getAllowedEnterpriseIds();
    if (allowedIds.isEmpty) return [];

    try {
      Query<Map<String, dynamic>> query = _collection;
      if (!allowedIds.contains('*')) {
        query = _collection.where(FieldPath.documentId, whereIn: allowedIds.take(10).toList());
      }

      final snapshot = await query.get();
      final roots = snapshot.docs
          .map((doc) => Enterprise.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      final all = <Enterprise>[...roots];
      for (final root in roots) {
        for (final subName in ['pointsOfSale', 'agences']) {
          try {
            final posSnapshot = await _getSubCollection(root.id, subName).get();
            all.addAll(posSnapshot.docs.map((doc) => 
              Enterprise.fromMap({...doc.data(), 'id': doc.id, 'parentEnterpriseId': root.id})
            ));
          } catch (e) {
            // Suppress error
          }
        }
      }
      return all;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<({List<Enterprise> enterprises, int totalCount})> getEnterprisesPaginated({
    int page = 0,
    int limit = 50,
  }) async {
    final all = await getAllEnterprises();
    final totalCount = all.length;
    final startIndex = page * limit;
    final paginated = all.skip(startIndex).take(limit).toList();
    
    return (enterprises: paginated, totalCount: totalCount);
  }

  @override
  Future<List<Enterprise>> getEnterprisesByType(String type) async {
    final all = await getAllEnterprises();
    return all.where((e) => e.type.id == type).toList();
  }

  @override
  Future<Enterprise?> getEnterpriseById(String enterpriseId) async {
    // Essayer racine
    final doc = await _collection.doc(enterpriseId).get();
    if (doc.exists) return Enterprise.fromMap({...doc.data()!, 'id': doc.id});

    // Chercher dans les sous-collections (nécessiterait plus de logique si on ne connaît pas le parent)
    // Pour l'instant on se limite à la racine ou on attend que le controller fournisse les bonnes infos
    return null; 
  }

  @override
  Future<void> createEnterprise(Enterprise enterprise) async {
    await _docFor(enterprise).set(enterprise.toMap());
  }

  @override
  Future<void> updateEnterprise(Enterprise enterprise) async {
    await _docFor(enterprise).set(enterprise.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteEnterprise(String enterpriseId) async {
    // Nécessite de savoir si c'est un POS
    await _collection.doc(enterpriseId).delete();
    // TODO: Gérer suppression de POS si ID fourni
  }

  @override
  Future<void> toggleEnterpriseStatus(String enterpriseId, bool isActive) async {
    // Simplifié : on essaye uniquement à la racine
    await _collection.doc(enterpriseId).update({
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}

