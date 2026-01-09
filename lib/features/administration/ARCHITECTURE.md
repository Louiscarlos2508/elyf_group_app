# Architecture - Module Administration

## Vue d'ensemble

Le module Administration suit une **architecture Clean Architecture** avec séparation stricte des couches : Domain, Data, Application, et Presentation.

## 🏗️ Structure des Couches

### 1. Domain (Couche Domaine)

Couche métier pure, indépendante des frameworks et technologies.

#### Entities (Entités)

- `User` - Entité utilisateur
- `Enterprise` - Entité entreprise
- `AdminModule` - Entité module
- `AuditLog` - Entité log d'audit
- `UserRole` - Entité rôle (depuis core)
- `EnterpriseModuleUser` - Entité assignation (depuis core)

#### Repositories (Interfaces)

- `UserRepository` - Interface pour la gestion des utilisateurs
- `EnterpriseRepository` - Interface pour la gestion des entreprises
- `AdminRepository` - Interface pour les opérations d'administration

#### Services (Services Métier)

**Domain Services** :
- `AuditService` - Service d'audit (interface)
- `PermissionValidatorService` - Validation des permissions
- `EnterpriseTypeService` - Mappings type/icône entreprise
- `UserFilterService` - Filtrage utilisateurs
- `RoleStatisticsService` - Statistiques rôles
- `PaginationService` - Service de pagination

### 2. Data (Couche Données)

Implémentations concrètes des repositories et services de données.

#### Repositories Offline

- `UserOfflineRepository` - Implémentation offline (Drift)
- `EnterpriseOfflineRepository` - Implémentation offline (Drift)
- `AdminOfflineRepository` - Implémentation offline (Drift)

**Caractéristiques** :
- Stockage local dans Drift/SQLite
- `enterpriseId = 'global'` pour les utilisateurs
- `enterpriseId` spécifique pour les entreprises
- Support offline-first

#### Services de Données

- `FirebaseAuthIntegrationService` - Intégration Firebase Auth
- `FirestoreSyncService` - Synchronisation Firestore
- `AuditOfflineService` - Implémentation offline du service d'audit

### 3. Application (Couche Application)

Couche de logique métier orchestrée par les controllers.

#### Controllers

**UserController** ✅
- Gestion CRUD utilisateurs
- Intégration Firebase Auth
- Sync Firestore
- Audit trail
- Validation permissions (prêt)

**EnterpriseController** ✅
- Gestion CRUD entreprises
- Filtrage par type
- ✅ Audit trail (complété : create, update, delete, activate/deactivate)
- ✅ Firestore sync (complété : syncEnterpriseToFirestore, deleteFromFirestore)
- ✅ Validation permissions (complété : canManageEnterprises)

**AdminController** ✅
- Gestion rôles
- Assignations utilisateurs-entreprises
- Gestion permissions personnalisées
- ✅ Audit trail (complété : assign, roleChange, permissionChange, createRole, updateRole, deleteRole, unassign)
- ✅ Firestore sync (complété : syncEnterpriseModuleUserToFirestore, syncRoleToFirestore, deleteFromFirestore)
- ✅ Validation permissions (complété : canManageUsers, canManageRoles)

**AuditController** ✅
- Récupération logs d'audit
- Filtrage par critères
- Enregistrement actions (utilisé par autres controllers)

#### Providers (Riverpod)

Tous les providers utilisent les controllers, jamais les repositories directement.

```dart
// ✅ CORRECT
final usersProvider = FutureProvider.autoDispose<List<User>>(
  (ref) => ref.watch(userControllerProvider).getAllUsers(),
);

// ❌ INCORRECT
final usersProvider = FutureProvider.autoDispose<List<User>>(
  (ref) => ref.watch(userRepositoryProvider).getAllUsers(), // ❌
);
```

### 4. Presentation (Couche Présentation)

Interface utilisateur Flutter.

#### Écrans Principaux

- `AdminHomeScreen` - Écran principal avec navigation par onglets

#### Sections

- `AdminDashboardSection` - Tableau de bord avec statistiques
- `AdminUsersSection` - Gestion des utilisateurs
- `AdminEnterprisesSection` - Gestion des entreprises
- `AdminModulesSection` - Gestion des modules
- `AdminRolesSection` - Gestion des rôles
- `AdminAuditTrailSection` - Consultation audit trail

#### Dialogs

- `CreateUserDialog` / `EditUserDialog` - Création/modification utilisateur
- `CreateEnterpriseDialog` / `EditEnterpriseDialog` - Création/modification entreprise
- `CreateRoleDialog` / `EditRoleDialog` - Création/modification rôle
- `AssignEnterpriseDialog` - Assignation utilisateur-entreprise
- `ManagePermissionsDialog` - Gestion permissions personnalisées
- `ModuleDetailsDialog` - Détails module avec utilisateurs

#### Widgets Réutilisables

- `UserListItem` - Item de liste utilisateur
- `UserFiltersBar` - Barre de filtres
- `UserEmptyState` - État vide
- `UserSectionHeader` - En-tête de section
- `UserActionHandlers` - Handlers d'actions
- `OptimizedUserList` - Liste optimisée avec pagination
- `OptimizedStatsGrid` - Grille de statistiques
- `LazySectionBuilder` - Builder lazy pour sections

## 🔄 Flux de Données

### Flux Général

```
UI (Widget)
    ↓
Provider (Riverpod)
    ↓
Controller (Logique métier)
    ↓
Repository (Accès données)
    ↓
Drift Service (Stockage local)
    ↓
Firestore Sync Service (Synchronisation cloud)
```

### Exemple : Création d'un Utilisateur

```dart
// 1. UI appelle le controller
await userController.createUser(user, password: password);

// 2. Controller :
//    - Crée Firebase Auth (si email/password)
//    - Appelle repository.createUser()
//    - Sync Firestore
//    - Log audit trail

// 3. Repository :
//    - Enregistre dans Drift (local)
//    - enterpriseId = 'global'

// 4. Firestore Sync :
//    - Sync vers Firestore (si en ligne)

// 5. Audit Service :
//    - Enregistre l'action dans Drift
//    - Sync vers Firestore
```

### Flux Offline-First

**Principe** : *"Write locally first, sync later"*

1. **Enregistrement Local** (Toujours, immédiat)
   ```dart
   await repository.createUser(user); // ✅ Drift/SQLite
   ```

2. **Synchronisation Firestore** (Si en ligne, asynchrone)
   ```dart
   firestoreSync?.syncUserToFirestore(user); // Si en ligne
   ```

3. **Audit Trail** (Toujours)
   ```dart
   auditService?.logAction(...); // ✅ Drift + Firestore
   ```

## 📦 Collections de Données

### Collections Drift (Local)

Toutes les collections sont stockées dans la table `offline_records` :

- `users` - Utilisateurs (enterpriseId = 'global')
- `enterprises` - Entreprises (enterpriseId spécifique)
- `roles` - Rôles (enterpriseId = 'global')
- `enterprise_module_users` - Assignations (enterpriseId spécifique)
- `audit_logs` - Logs d'audit (enterpriseId = 'global')

### Collections Firestore (Cloud)

Mêmes collections dans Firestore, synchronisées automatiquement.

## 🔌 Intégrations Externes

### Firebase Auth

**Service** : `FirebaseAuthIntegrationService`

**Fonctionnalités** :
- Création de comptes utilisateurs (`createFirebaseUser`)
- Mise à jour de profils (`updateFirebaseUserProfile`)
- Suppression de comptes (`deleteFirebaseUser`)
- Envoi d'emails de réinitialisation (`sendPasswordResetEmail`)

**Intégration** : UserController uniquement (pour l'instant)

### Firestore

**Service** : `FirestoreSyncService`

**Fonctionnalités** :
- Sync utilisateurs (`syncUserToFirestore`)
- Sync entreprises (`syncEnterpriseToFirestore`)
- Sync rôles (`syncRoleToFirestore`)
- Sync assignations (`syncEnterpriseModuleUserToFirestore`)
- Sync audit logs (`syncAuditLogToFirestore`)
- Suppression (`deleteFromFirestore`)

**Intégration** : ✅ Tous les controllers (UserController, EnterpriseController, AdminController)

### Drift (SQLite)

**Stockage** : Table `offline_records`

**Structure** :
```dart
{
  collectionName: 'users',
  localId: 'local_123...',
  remoteId: 'firebase_uid_123', // null si pas encore sync
  enterpriseId: 'global',
  moduleType: 'administration',
  dataJson: '{"id": "...", "firstName": "..."}',
  localUpdatedAt: DateTime.now(),
}
```

## 🎯 Patterns Utilisés

### Repository Pattern

Séparation entre interface (domain) et implémentation (data).

### Controller Pattern

Encapsulation de la logique métier dans les controllers.

### Provider Pattern (Riverpod)

Gestion de l'état avec providers autoDispose pour optimisation mémoire.

### Offline-First Pattern

Toutes les écritures sont d'abord locales, puis synchronisées.

## ✅ Conformité Architecture

### Respect Clean Architecture

- ✅ Domain indépendant (pas d'imports Flutter/Firebase)
- ✅ Data dépend de Domain uniquement
- ✅ Application dépend de Domain uniquement
- ✅ Presentation dépend de Application uniquement

### Séparation des Responsabilités

- ✅ Controllers : Logique métier
- ✅ Repositories : Accès données
- ✅ Services : Services métier réutilisables
- ✅ UI : Présentation uniquement

### Testabilité

- ✅ Domain testable sans dépendances
- ✅ Controllers testables avec mocks
- ✅ Repositories testables avec mocks
- ✅ Services testables indépendamment

## 📊 Diagramme de Flux

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Widgets, Dialogs, Screens)           │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│         Application Layer               │
│  (Controllers, Providers)               │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│           Domain Layer                  │
│  (Entities, Repositories, Services)     │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│            Data Layer                   │
│  (Offline Repos, Firebase, Drift)      │
└─────────────────────────────────────────┘
```

## 🎯 Points d'Attention

### Controllers ✅

- ✅ AdminController : Audit trail complété (assign, roleChange, permissionChange, createRole, updateRole, deleteRole, unassign)
- ✅ EnterpriseController : Audit trail complété (create, update, delete, activate/deactivate)
- ✅ AdminController : Firestore sync complété (syncEnterpriseModuleUserToFirestore, syncRoleToFirestore, deleteFromFirestore)
- ✅ EnterpriseController : Firestore sync complété (syncEnterpriseToFirestore, deleteFromFirestore)

### Services ✅

- ✅ PermissionValidatorService : Intégré dans tous les controllers (AdminController, EnterpriseController, UserController)
- ⚠️ AuditOfflineService : Extension aux autres entités (si nécessaire dans le futur)

### Optimisations Futures

- ✅ SyncManager complet : File d'attente pour sync hors ligne - **Complété**
- ✅ Pagination au niveau Drift : `LIMIT/OFFSET` pour performance - **Complété**
- ✅ Caching : `keepAlive` pour données critiques - **Complété**
- ✅ Virtual scrolling : Pour très grandes listes (1000+ items) - **Complété**

