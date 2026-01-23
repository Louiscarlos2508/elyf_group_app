# Améliorations de Fiabilité pour la Synchronisation

## ✅ Points Déjà Bien Gérés

1. **Validation des IDs** - `DataSanitizer.isValidId()` utilisé
2. **Retry Logic** - Exponential backoff avec jitter
3. **Timeouts** - Configurés (30s par défaut)
4. **Gestion des erreurs réseau** - Détection et retry
5. **Déconnexion** - Arrêt des syncs lors du logout
6. **Conflits bidirectionnels** - Gestion avec ConflictResolver
7. **Soft delete** - Synchronisés dans les deux sens

## ⚠️ Points à Améliorer pour Plus de Fiabilité

### 1. **Sanitization des Données Avant Sync** (CRITIQUE)
**Problème** : `DataSanitizer` existe mais n'est pas utilisé dans `FirebaseSyncHandler` avant d'envoyer les données à Firestore.

**Impact** : Risque d'injection, données corrompues, dépassement de taille.

**Solution** :
```dart
// Dans FirebaseSyncHandler._handleCreate et _handleUpdate
final sanitizedData = DataSanitizer.sanitizeMap(data);
final safeJson = DataSanitizer.toSafeJson(sanitizedData);
```

### 2. **Gestion Spécifique des Erreurs Firestore** (IMPORTANT)
**Problème** : Les erreurs Firestore (permission-denied, resource-exhausted, etc.) ne sont pas gérées spécifiquement.

**Impact** : Retry inutile pour les erreurs non-récupérables, pas de messages d'erreur clairs.

**Solution** :
```dart
// Dans FirebaseSyncHandler
try {
  await docRef.add(data);
} on FirebaseException catch (e) {
  switch (e.code) {
    case 'permission-denied':
      throw SyncException('Permission refusée: ${e.message}');
    case 'resource-exhausted':
      // Quota dépassé - retry avec backoff plus long
      throw SyncException('Quota Firestore dépassé');
    case 'unauthenticated':
      throw SyncException('Non authentifié - reconnectez-vous');
    case 'not-found':
      // Document supprimé entre temps
      return; // Ignorer silencieusement
    default:
      rethrow;
  }
}
```

### 3. **Validation de la Taille des Payloads** (IMPORTANT)
**Problème** : Pas de validation de la taille avant de queue une opération.

**Impact** : Opérations échouant systématiquement si trop grandes, gaspillage de retries.

**Solution** :
```dart
// Dans SyncManager.queueCreate/queueUpdate
final jsonPayload = jsonEncode(data);
try {
  DataSanitizer.validateJsonSize(jsonPayload);
} on DataSizeException catch (e) {
  throw SyncException('Données trop volumineuses: ${e.message}');
}
```

### 4. **Gestion des Données Corrompues dans Drift** (IMPORTANT)
**Problème** : Si `dataJson` dans Drift est corrompu, `jsonDecode` peut échouer silencieusement.

**Impact** : Perte de données, crashs silencieux.

**Solution** :
```dart
// Dans ModuleRealtimeSyncService et autres
try {
  final localData = jsonDecode(localRecord.dataJson) as Map<String, dynamic>;
} catch (e) {
  developer.log('Corrupted JSON in Drift, skipping: $e');
  // Option 1: Supprimer l'enregistrement corrompu
  await driftService.records.deleteByLocalId(...);
  // Option 2: Réessayer de récupérer depuis Firestore
  return;
}
```

### 5. **Gestion de la Déconnexion Pendant une Sync Active** (MOYEN)
**Problème** : Si l'utilisateur se déconnecte pendant une sync, les opérations peuvent continuer.

**Impact** : Sync vers Firestore avec un utilisateur non authentifié, erreurs.

**Solution** :
```dart
// Dans SyncManager.syncPendingOperations
// Vérifier l'authentification avant chaque opération
if (!_isAuthenticated) {
  developer.log('User logged out, stopping sync');
  _isSyncing = false;
  return SyncResult(success: false, message: 'User logged out');
}
```

### 6. **Limite sur le Nombre d'Opérations en Attente** (MOYEN)
**Problème** : Pas de limite, peut grandir indéfiniment.

**Impact** : Consommation mémoire excessive, sync très lente.

**Solution** :
```dart
// Dans SyncManager.queueCreate/queueUpdate/queueDelete
final pendingCount = await getPendingCount();
if (pendingCount > config.maxPendingOperations) {
  throw SyncException('Trop d\'opérations en attente ($pendingCount). '
    'Veuillez attendre que la synchronisation se termine.');
}
```

### 7. **Validation des Données Avant Sauvegarde Locale** (MOYEN)
**Problème** : Pas de validation avant de sauvegarder dans Drift.

**Impact** : Données invalides stockées localement, erreurs lors de la sync.

**Solution** :
```dart
// Dans OfflineRepository.save
final sanitizedData = DataSanitizer.sanitizeMap(data);
final validatedJson = DataSanitizer.toSafeJson(sanitizedData);
// Utiliser validatedJson au lieu de data
```

### 8. **Gestion des Erreurs de Schéma** (FAIBLE)
**Problème** : Si le schéma Firestore change, les données peuvent être incompatibles.

**Impact** : Erreurs de parsing, données perdues.

**Solution** :
```dart
// Validation basique des champs requis
final requiredFields = ['id', 'enterpriseId', 'updatedAt'];
for (final field in requiredFields) {
  if (!data.containsKey(field)) {
    throw SyncException('Champ requis manquant: $field');
  }
}
```

### 9. **Monitoring et Alerting** (FAIBLE)
**Problème** : Pas de système pour détecter les problèmes récurrents.

**Impact** : Problèmes non détectés jusqu'à ce qu'ils deviennent critiques.

**Solution** :
```dart
// Compteur d'erreurs par type
final errorCounts = <String, int>{};
// Si trop d'erreurs du même type, alerter
if (errorCounts['permission-denied'] > 10) {
  // Envoyer une alerte ou notification
}
```

### 10. **Gestion des Timeouts de Connexion** (FAIBLE)
**Problème** : Timeout global mais pas de timeout spécifique pour la connexion initiale.

**Impact** : Sync peut rester bloquée si la connexion est lente.

**Solution** : Déjà géré avec `operationTimeoutMs`, mais pourrait être amélioré avec un timeout de connexion séparé.

## Priorités d'Implémentation

### 🔴 CRITIQUE (À faire immédiatement)
1. Sanitization des données avant sync
2. Gestion spécifique des erreurs Firestore
3. Validation de la taille des payloads

### 🟡 IMPORTANT (À faire bientôt)
4. Gestion des données corrompues dans Drift
5. Validation des données avant sauvegarde locale

### 🟢 MOYEN (Améliorations)
6. Gestion de la déconnexion pendant sync
7. Limite sur les opérations en attente
8. Monitoring et alerting

### ⚪ FAIBLE (Nice to have)
9. Gestion des erreurs de schéma
10. Timeouts de connexion améliorés

## Recommandations Supplémentaires

### Tests de Charge
- Tester avec 1000+ opérations en attente
- Tester avec des payloads de 1MB
- Tester avec des connexions instables

### Monitoring en Production
- Logger le nombre d'opérations en attente
- Logger les erreurs par type
- Logger les temps de sync
- Alertes si > 100 opérations en attente pendant > 1h

### Documentation
- Documenter les limites (taille max, nombre max d'opérations)
- Documenter les codes d'erreur possibles
- Guide de dépannage pour les erreurs courantes
