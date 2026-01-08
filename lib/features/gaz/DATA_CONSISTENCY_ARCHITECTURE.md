# Architecture de Cohérence des Données - Module Gaz

## Vue d'ensemble

Ce document décrit l'architecture mise en place pour assurer la cohérence des données, la robustesse des traitements et l'écoute en temps réel dans le module Gaz.

## Problèmes identifiés et solutions

### 1. Cohérence des données

**Problèmes :**
- Pas de validation croisée entre Tours, Collections, Stocks et Ventes
- Les stocks ne sont pas automatiquement mis à jour lors des ventes
- Pas de vérification de cohérence des montants et quantités

**Solutions :**
- ✅ `DataConsistencyService` : Service de validation de cohérence
- ✅ Validation avant chaque opération critique
- ✅ Vérification croisée entre entités

### 2. Transactions atomiques

**Problèmes :**
- Les opérations multi-étapes ne sont pas atomiques
- Risque d'incohérence en cas d'erreur (ex: vente créée mais stock non débité)

**Solutions :**
- ✅ `TransactionService` : Service de transactions atomiques
- ✅ Rollback automatique en cas d'erreur
- ✅ Opérations critiques : Vente, Clôture tour, Paiement collection

### 3. Écoute en temps réel

**Problèmes :**
- Pas d'écoute Firestore en temps réel
- Données statiques (mock repositories)
- Pas de synchronisation multi-appareils

**Solutions :**
- ✅ `RealtimeSyncService` : Service de synchronisation temps réel
- ⏳ À implémenter : Repositories Firestore avec Stream
- ⏳ À implémenter : Synchronisation Drift ↔ Firestore

## Architecture des services

### DataConsistencyService

Valide la cohérence des données entre modules :

```dart
// Validation vente ↔ stock
await consistencyService.validateSaleStockConsistency(
  enterpriseId: enterpriseId,
  weight: 12,
  quantity: 5,
);

// Validation tour complet
await consistencyService.validateTourConsistency(tour);

// Validation globale du module
final errors = await consistencyService.validateGlobalConsistency(
  enterpriseId: enterpriseId,
);
```

**Validations effectuées :**
- ✅ Stock disponible avant vente
- ✅ Quantités cohérentes (fuites ≤ bouteilles collectées)
- ✅ Montants cohérents (paiement ≤ montant dû)
- ✅ Dates logiques (collection → transport → retour → clôture)
- ✅ Collections appartenant au bon tour

### TransactionService

Gère les opérations atomiques :

```dart
// Vente atomique (débit stock + création vente)
final sale = await transactionService.executeSaleTransaction(
  sale: gasSale,
  enterpriseId: enterpriseId,
);

// Clôture tour atomique
final tour = await transactionService.executeTourClosureTransaction(
  tourId: tourId,
);

// Paiement collection atomique
final collection = await transactionService.executeCollectionPaymentTransaction(
  tourId: tourId,
  collectionId: collectionId,
  amount: amount,
  paymentDate: DateTime.now(),
);
```

**Garanties :**
- ✅ Tout ou rien (rollback automatique en cas d'erreur)
- ✅ Validation avant exécution
- ✅ Cohérence assurée

### RealtimeSyncService

Gère la synchronisation en temps réel :

```dart
// Écoute d'un tour en temps réel
final tourStream = syncService.watchTour(tourId);
tourStream.listen((tour) {
  // Mise à jour automatique de l'UI
});

// Écoute des ventes
final salesStream = syncService.watchSales(
  from: DateTime.now().subtract(Duration(days: 7)),
);
```

**Fonctionnalités :**
- ⏳ Stream Firestore pour chaque entité
- ⏳ Résolution de conflits (last-write-wins avec updated_at)
- ⏳ Synchronisation bidirectionnelle Drift ↔ Firestore

## Intégration Firestore (À implémenter)

### Structure Firestore

```
enterprises/{enterpriseId}/modules/{moduleId}/
├── cylinders/
│   └── {cylinderId}
├── cylinder_stocks/
│   └── {stockId}
├── tours/
│   └── {tourId}
│       └── collections/
│           └── {collectionId}
├── gas_sales/
│   └── {saleId}
├── expenses/
│   └── {expenseId}
└── points_of_sale/
    └── {posId}
```

### Exemple de Repository Firestore

```dart
class FirestoreTourRepository implements TourRepository {
  final FirebaseFirestore _firestore;
  final String enterpriseId;
  final String moduleId;

  @override
  Stream<List<Tour>> watchTours({
    String? enterpriseId,
    TourStatus? status,
  }) {
    var query = _firestore
        .collection('enterprises')
        .doc(enterpriseId ?? this.enterpriseId)
        .collection('modules')
        .doc(moduleId)
        .collection('tours');

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Tour.fromFirestore(doc);
      }).toList();
    });
  }

  @override
  Future<void> updateTour(Tour tour) async {
    final docRef = _getTourDocument(tour.id);
    
    // Transaction pour garantir la cohérence
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      final existingTour = Tour.fromFirestore(doc);
      
      // Résolution de conflit
      if (existingTour.updatedAt.isAfter(tour.updatedAt)) {
        throw Exception('Conflit: version Firestore plus récente');
      }
      
      transaction.update(docRef, {
        ...tour.toFirestore(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
}
```

### Synchronisation Drift ↔ Firestore

```dart
class SyncManager {
  final IsarDatabase isar;
  final RealtimeSyncService syncService;

  // Écouter Firestore et mettre à jour Drift
  void setupFirestoreListener() {
    syncService.watchTours().listen((tours) {
      for (final tour in tours) {
        isar.writeTxn(() {
          isar.tours.put(tour);
        });
      }
    });
  }

  // Écrire dans Drift puis synchroniser avec Firestore
  Future<void> saveTour(Tour tour) async {
    // 1. Sauvegarder localement (Drift)
    await isar.writeTxn(() {
      isar.tours.put(tour);
    });

    // 2. Synchroniser avec Firestore (en arrière-plan)
    await syncService.syncEntity(
      entity: tour,
      collectionPath: 'tours',
      updatedAt: DateTime.now(),
    );
  }
}
```

## Points d'intégration dans les controllers

### GasController

```dart
class GasController {
  final TransactionService transactionService;
  final RealtimeSyncService syncService;

  Future<void> addSale(GasSale sale) async {
    // Utiliser la transaction au lieu de l'ajout direct
    await transactionService.executeSaleTransaction(
      sale: sale,
      enterpriseId: enterpriseId,
    );
    
    // Invalider le provider pour rafraîchir
    ref.invalidate(gasSalesProvider);
  }
}
```

### TourController

```dart
class TourController {
  final TransactionService transactionService;
  final DataConsistencyService consistencyService;

  Future<void> closeTour(String tourId) async {
    // Validation avant clôture
    final tour = await repository.getTourById(tourId);
    final error = await consistencyService.validateTourConsistency(tour);
    if (error != null) throw Exception(error);

    // Transaction atomique
    await transactionService.executeTourClosureTransaction(
      tourId: tourId,
    );
  }
}
```

## Checklist d'implémentation

### Phase 1 : Services de cohérence (✅ Fait)
- [x] DataConsistencyService
- [x] TransactionService
- [x] RealtimeSyncService (structure)

### Phase 2 : Repositories Firestore (⏳ À faire)
- [ ] FirestoreTourRepository avec Stream
- [ ] FirestoreGasSaleRepository avec Stream
- [ ] FirestoreCylinderStockRepository avec Stream
- [ ] FirestoreCollectionRepository avec Stream

### Phase 3 : Synchronisation Drift (⏳ À faire)
- [ ] Tables/DAO Drift pour les entités (ou stockage générique renforcé)
- [ ] SyncManager pour synchronisation bidirectionnelle
- [ ] Gestion des conflits (updated_at)

### Phase 4 : Intégration (⏳ À faire)
- [ ] Mettre à jour les controllers pour utiliser TransactionService
- [ ] Ajouter validation dans tous les formulaires
- [ ] Implémenter écoute temps réel dans les providers
- [ ] Tests de cohérence

## Bonnes pratiques

1. **Toujours valider avant d'écrire**
   ```dart
   final error = await consistencyService.validateSaleConsistency(...);
   if (error != null) throw Exception(error);
   ```

2. **Utiliser les transactions pour opérations critiques**
   ```dart
   await transactionService.executeSaleTransaction(...);
   ```

3. **Écouter en temps réel pour l'UI**
   ```dart
   ref.watch(tourStreamProvider(tourId)).when(
     data: (tour) => TourWidget(tour: tour),
     ...
   );
   ```

4. **Gérer les conflits avec updated_at**
   ```dart
   if (firestoreUpdatedAt.isAfter(localUpdatedAt)) {
     // Utiliser Firestore
   }
   ```

## Prochaines étapes

1. Implémenter les repositories Firestore avec Stream
2. Créer les tables/DAO Drift
3. Implémenter le SyncManager
4. Migrer les controllers pour utiliser les nouveaux services
5. Ajouter des tests de cohérence

