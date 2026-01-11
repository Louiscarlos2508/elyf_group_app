# Flux d'Attribution Utilisateur-Entreprise-Module-Rôle

Ce document explique comment l'attribution d'un rôle et d'une entreprise à un utilisateur est enregistrée et gérée dans l'application.

## 📋 Vue d'ensemble

Lorsqu'un administrateur attribue un utilisateur à une entreprise avec un module et un rôle, les données sont stockées dans une entité `EnterpriseModuleUser` qui lie :
- **userId** : ID de l'utilisateur (Firebase Auth UID)
- **enterpriseId** : ID de l'entreprise
- **moduleId** : ID du module (eau_minerale, gaz, orange_money, etc.)
- **roleId** : ID du rôle assigné
- **isActive** : Statut actif/inactif
- **customPermissions** : Permissions personnalisées supplémentaires

## 🔄 Flux complet d'attribution

### 1. **Création de l'attribution** (UI)

**Fichier** : `lib/features/administration/presentation/screens/sections/dialogs/assign_enterprise_dialog.dart`

```dart
// L'admin sélectionne : entreprise, module, rôle
final enterpriseModuleUser = EnterpriseModuleUser(
  userId: widget.user.id,
  enterpriseId: _selectedEnterpriseId!,
  moduleId: _selectedModuleId!,
  roleId: _selectedRoleId!,
  isActive: _isActive,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// Appel au controller
await ref.read(adminControllerProvider).assignUserToEnterprise(enterpriseModuleUser);
```

### 2. **Traitement dans le Controller**

**Fichier** : `lib/features/administration/application/controllers/admin_controller.dart`

```dart
Future<void> assignUserToEnterprise(EnterpriseModuleUser enterpriseModuleUser) async {
  // 1. Validation des permissions
  if (currentUserId != null && permissionValidator != null) {
    final hasPermission = await permissionValidator!.canManageUsers(userId: currentUserId);
    if (!hasPermission) {
      throw Exception('Permission denied: Cannot assign users');
    }
  }
  
  // 2. Sauvegarde dans Drift (base locale - offline-first)
  await _repository.assignUserToEnterprise(enterpriseModuleUser);
  
  // 3. Synchronisation avec Firestore (si en ligne)
  firestoreSync?.syncEnterpriseModuleUserToFirestore(enterpriseModuleUser);
  
  // 4. Log audit trail
  auditService?.logAction(
    action: AuditAction.assign,
    entityType: 'enterprise_module_user',
    entityId: enterpriseModuleUser.documentId,
    // ...
  );
}
```

### 3. **Stockage dans Drift (Base locale)**

**Fichier** : `lib/features/administration/data/repositories/admin_offline_repository.dart`

```dart
Future<void> assignUserToEnterprise(EnterpriseModuleUser enterpriseModuleUser) async {
  final localId = _getLocalId(enterpriseModuleUser.documentId);
  final remoteId = _getRemoteId(enterpriseModuleUser.documentId);
  final map = _enterpriseModuleUserToMap(enterpriseModuleUser)..['localId'] = localId;
  
  // Sauvegarde dans Drift (SQLite local)
  await driftService.records.upsert(
    collectionName: 'enterprise_module_users',
    localId: localId,
    remoteId: remoteId,
    enterpriseId: 'global',  // Les accès sont globaux
    moduleType: 'administration',
    dataJson: jsonEncode(map),  // Données JSON encodées
    localUpdatedAt: DateTime.now(),
  );
}
```

**Structure de stockage Drift** :
- Collection : `enterprise_module_users`
- Document ID (Firestore) : `{userId}_{enterpriseId}_{moduleId}`
- Données : JSON encodé avec tous les champs de `EnterpriseModuleUser`

### 4. **Synchronisation avec Firestore**

**Service** : `lib/features/administration/data/services/firestore_sync_service.dart`

La synchronisation se fait automatiquement :
- **Collection Firestore** : `enterprise_module_users`
- **Document ID** : `{userId}_{enterpriseId}_{moduleId}` (ex: `user123_enterprise1_eau_minerale`)
- **Structure du document** :
  ```json
  {
    "userId": "user123",
    "enterpriseId": "enterprise1",
    "moduleId": "eau_minerale",
    "roleId": "role_123",
    "customPermissions": [],
    "isActive": true,
    "createdAt": "2024-01-01T00:00:00Z",
    "updatedAt": "2024-01-01T00:00:00Z"
  }
  ```

### 5. **Récupération et utilisation**

#### Providers disponibles :

**a) `enterpriseModuleUsersProvider`**
- Récupère **tous** les accès `EnterpriseModuleUser` de tous les utilisateurs
- Utilisé pour l'administration et les statistiques

**b) `getUserEnterpriseModuleUsers(userId)`**
- Récupère les accès d'un **utilisateur spécifique**
- Utilisé par `userAccessibleEnterprisesProvider` et `userAccessibleModulesForActiveEnterpriseProvider`

**c) `userAccessibleEnterprisesProvider`**
- Filtre les entreprises accessibles à l'utilisateur connecté
- Utilisé par `EnterpriseSelectorWidget` pour afficher les entreprises disponibles

**d) `userAccessibleModulesForActiveEnterpriseProvider`**
- Filtre les modules accessibles à l'utilisateur pour l'entreprise active
- Utilisé par `ModuleMenuScreen` pour afficher uniquement les modules accessibles

### 6. **Utilisation dans l'interface**

**ModuleMenuScreen** (`lib/features/modules/presentation/screens/module_menu_screen.dart`) :
```dart
// Récupère les modules accessibles pour l'entreprise active
final accessibleModulesAsync = ref.watch(userAccessibleModulesForActiveEnterpriseProvider);

// Filtre les modules selon les accès
final accessibleModules = AdminModules.all
    .where((module) => accessibleModuleIds.contains(module.id))
    .toList();

// Affiche uniquement les modules auxquels l'utilisateur a accès
```

**EnterpriseSelectorWidget** (`lib/shared/presentation/widgets/enterprise_selector_widget.dart`) :
```dart
// Récupère les entreprises accessibles
final accessibleEnterprisesAsync = ref.watch(userAccessibleEnterprisesProvider);

// Affiche uniquement les entreprises auxquelles l'utilisateur a accès
```

## 🔑 Points importants

1. **Offline-first** : Les données sont d'abord sauvegardées dans Drift (local), puis synchronisées avec Firestore

2. **Document ID unique** : Format `{userId}_{enterpriseId}_{moduleId}` garantit l'unicité d'un accès

3. **Filtrage actif** : Seuls les accès avec `isActive: true` sont considérés pour l'affichage

4. **Multi-tenant** : Un utilisateur peut avoir plusieurs accès (plusieurs entreprises/modules/rôles)

5. **Audit trail** : Toutes les attributions sont loggées pour traçabilité

6. **Synchronisation automatique** : La sync Firestore se fait en arrière-plan via `FirestoreSyncService`

## 📊 Exemple de données

```dart
EnterpriseModuleUser(
  userId: "user123",
  enterpriseId: "eau_sachet_1",
  moduleId: "eau_minerale",
  roleId: "gestionnaire_eau_minerale",
  customPermissions: {},
  isActive: true,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
)
```

**Document ID** : `user123_eau_sachet_1_eau_minerale`

## 🔍 Vérification

Pour vérifier qu'une attribution a bien été enregistrée :

1. **Drift (local)** : Vérifier dans la table `records` avec `collectionName = 'enterprise_module_users'`
2. **Firestore** : Vérifier dans la collection `enterprise_module_users` avec le document ID
3. **UI** : L'utilisateur devrait voir l'entreprise et le module dans les sélecteurs

