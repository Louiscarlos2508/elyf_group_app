# Module Administration

Module centralisé pour gérer les utilisateurs, rôles, entreprises et permissions dans tous les modules de l'application multi-entreprises.

## 📋 Vue d'ensemble

Le module Administration permet de :
- Gérer les utilisateurs du système (création, modification, suppression)
- Assigner les utilisateurs aux entreprises et modules avec des rôles spécifiques
- Gérer les rôles et permissions par module
- Gérer les entreprises et leurs types
- Auditer toutes les actions administratives
- Synchroniser avec Firebase Auth et Firestore

## 🏗️ Architecture

Le module suit une **architecture Clean Architecture** avec :

- **Offline-first** : Toutes les données sont stockées localement (Drift/SQLite) en premier
- **Synchronisation** : Sync automatique avec Firestore quand en ligne
- **Firebase Auth** : Intégration pour la création de comptes utilisateurs
- **Audit Trail** : Enregistrement de toutes les actions critiques
- **Permissions** : Système de validation des permissions

### Structure des dossiers

```
administration/
├── domain/                    # Couche domaine (entities, repositories, services)
│   ├── entities/             # Entités métier
│   ├── repositories/         # Interfaces des repositories
│   └── services/             # Services métier (audit, validation, filtrage)
├── data/                     # Couche données (implémentations)
│   ├── repositories/         # Repositories offline (Drift)
│   └── services/             # Services de données (Firebase, Firestore)
├── application/              # Couche application (controllers, providers)
│   ├── controllers/          # Controllers (logique métier)
│   └── providers.dart        # Providers Riverpod
└── presentation/             # Couche présentation (UI)
    └── screens/
        ├── admin_home_screen.dart
        └── sections/         # Sections de l'écran admin
```

## 🎯 Fonctionnalités

### 1. Gestion des Utilisateurs

- ✅ Création d'utilisateurs avec compte Firebase Auth
- ✅ Modification d'utilisateurs
- ✅ Suppression d'utilisateurs (avec suppression Firebase Auth)
- ✅ Activation/désactivation d'utilisateurs
- ✅ Recherche et filtrage d'utilisateurs
- ✅ Audit trail complet

**Controller** : `UserController`

### 2. Gestion des Entreprises

- ✅ Création d'entreprises
- ✅ Modification d'entreprises
- ✅ Suppression d'entreprises
- ✅ Activation/désactivation d'entreprises
- ✅ Filtrage par type d'entreprise

**Controller** : `EnterpriseController`

### 3. Gestion des Rôles et Permissions

- ✅ Création de rôles par module
- ✅ Modification de rôles
- ✅ Suppression de rôles (sauf système)
- ✅ Assignation de rôles aux utilisateurs
- ✅ Gestion des permissions personnalisées

**Controller** : `AdminController`

### 4. Assignation Utilisateurs-Entreprises

- ✅ Assigner un utilisateur à une entreprise/module avec un rôle
- ✅ Modifier le rôle d'un utilisateur
- ✅ Retirer un utilisateur d'une entreprise/module
- ✅ Gérer les permissions personnalisées par assignation

**Controller** : `AdminController`

### 5. Audit Trail

- ✅ Enregistrement automatique de toutes les actions
- ✅ Consultation des logs par entité, utilisateur, module, entreprise
- ✅ Interface utilisateur pour visualiser l'audit trail
- ✅ Synchronisation avec Firestore

**Controller** : `AuditController`

### 6. Modules Disponibles

Le module Administration gère les accès pour :
- 🧊 Eau Minérale
- 🔥 Gaz
- 💰 Orange Money
- 🏠 Immobilier
- 🏪 Boutique

## 🔄 Flux de Synchronisation

### Enregistrement Local (Priorité)

Toutes les données sont **TOUJOURS** enregistrées localement en premier dans Drift/SQLite, même hors ligne.

```dart
// Dans un controller
final createdUser = await _repository.createUser(user); // ✅ Enregistré localement
```

### Synchronisation Firestore (Asynchrone)

Après l'enregistrement local, si en ligne, la synchronisation avec Firestore se fait automatiquement.

```dart
// Sync Firestore (non bloquant)
firestoreSync?.syncUserToFirestore(createdUser);
```

### Flux complet

```
1. Action utilisateur (création, modification, suppression)
   ↓
2. Controller (logique métier)
   ↓
3. Firebase Auth (si création utilisateur)
   ↓
4. Repository → Enregistrement local (Drift) ✅ IMMÉDIAT
   ↓
5. Firestore Sync Service → Sync Firestore (si en ligne)
   ↓
6. Audit Service → Enregistrement audit trail
   ↓
7. Retour à l'utilisateur
```

**Principe clé** : *"Write locally first, sync later"*

## 🔐 Sécurité

### Création d'utilisateurs

- ✅ Les nouveaux utilisateurs ne sont **PAS admin** par défaut
- ✅ Les nouveaux utilisateurs n'ont **AUCUN accès** par défaut
- ✅ L'assignation doit être faite explicitement par un admin
- ✅ Les rôles sont assignés lors de l'assignation (vendeur, caissier, manager, etc.)

### Architecture Multi-Tenant

- ✅ Utilisateurs stockés globalement (`enterpriseId = 'global'`)
- ✅ Assignation via `EnterpriseModuleUser` (entrepriseId spécifique)
- ✅ Un utilisateur peut être assigné à plusieurs entreprises/modules
- ✅ Chaque assignation a son propre rôle et permissions

### Validation des Permissions

Le service `PermissionValidatorService` permet de vérifier :
- `hasPermission()` - Vérifier une permission
- `hasAnyPermission()` - Vérifier si l'utilisateur a une des permissions
- `hasAllPermissions()` - Vérifier si l'utilisateur a toutes les permissions
- `isModuleAdmin()` - Vérifier si l'utilisateur est admin du module
- `canCreate/canUpdate/canDelete/canView()` - Vérifications CRUD
- `canManageUsers/canManageRoles/canManageEnterprises()` - Permissions admin

## 📊 Controllers

Tous les accès aux données passent par des **controllers** qui encapsulent la logique métier.

### UserController ✅

**Intégrations complètes** :
- ✅ Firebase Auth (création de comptes)
- ✅ Firestore Sync
- ✅ Audit Trail (toutes les actions)
- ✅ Permission Validation (prêt)

**Provider** : `userControllerProvider`

### EnterpriseController ✅

**Intégrations complètes** :
- ✅ CRUD entreprises
- ✅ Audit trail (create, update, delete, activate/deactivate)
- ✅ Firestore sync (syncEnterpriseToFirestore, deleteFromFirestore)
- ✅ Permission Validation (canManageEnterprises)

**Provider** : `enterpriseControllerProvider`

### AdminController ✅

**Intégrations complètes** :
- ✅ Gestion rôles et assignations
- ✅ Audit trail (assign, roleChange, permissionChange, createRole, updateRole, deleteRole, unassign)
- ✅ Firestore sync (syncEnterpriseModuleUserToFirestore, syncRoleToFirestore, deleteFromFirestore)
- ✅ Permission Validation (canManageUsers, canManageRoles)

**Provider** : `adminControllerProvider`

### AuditController ✅

**Intégrations** :
- ✅ Récupération des logs d'audit
- ✅ Filtrage par entité, utilisateur, module, entreprise

**Provider** : `auditControllerProvider`

## 🔌 Intégration

### 1. Ajouter le module au router

```dart
GoRoute(
  path: '/admin',
  name: AppRoute.admin.name,
  builder: (context, state) => const AdminHomeScreen(),
),
```

### 2. Utiliser les controllers dans un widget

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utiliser un provider (pour les données)
    final usersAsync = ref.watch(usersProvider);
    
    // Utiliser le controller (pour les actions)
    final userController = ref.read(userControllerProvider);
    
    return usersAsync.when(
      data: (users) => ListView(...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### 3. Créer un utilisateur

```dart
final userController = ref.read(userControllerProvider);

await userController.createUser(
  User(
    firstName: 'Jean',
    lastName: 'Dupont',
    username: 'jdupont',
    email: 'jean.dupont@example.com',
    isActive: true,
  ),
  password: 'secure_password',
  currentUserId: currentUserId, // Pour l'audit trail
);
```

### 4. Enregistrer les permissions d'un module

Dans le module (ex: eau_minerale), lors de l'initialisation :

```dart
final permissions = [
  ActionPermission(
    id: 'view_dashboard',
    name: 'Voir le tableau de bord',
    module: 'eau_minerale',
    description: 'Permet de voir le tableau de bord',
  ),
  // ... autres permissions
];

PermissionRegistry.instance.registerModulePermissions(
  'eau_minerale',
  permissions,
);
```

## 📚 Documentation Complémentaire

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Détails de l'architecture, flux de données, structure
- [IMPLEMENTATION.md](./IMPLEMENTATION.md) - Statut d'implémentation détaillé, fonctionnalités
- [SECURITY.md](./SECURITY.md) - Sécurité, permissions, vérifications de sécurité
- [DEVELOPMENT.md](./DEVELOPMENT.md) - Optimisations, conformité, guide de développement

## ✅ État Actuel

### Complété ✅

- ✅ Architecture Clean Architecture
- ✅ Controllers pour tous les domaines
- ✅ Intégration Firebase Auth (UserController)
- ✅ Intégration Firestore Sync (UserController)
- ✅ Audit Trail complet (UserController)
- ✅ Service de validation des permissions
- ✅ Interface utilisateur pour l'audit trail
- ✅ Offline-first avec Drift
- ✅ Optimisations de performance

### À Étendre ⚠️

- ✅ Audit trail dans AdminController et EnterpriseController - **Complété**
- ✅ Firestore sync dans AdminController et EnterpriseController - **Complété**
- ✅ Intégration validation des permissions dans tous les controllers - **Complété**
- ✅ SyncManager complet avec file d'attente et retry - **Complété**
- ⚠️ Export des logs d'audit (CSV, PDF) - À implémenter

## 🎯 Principes de Développement

### Architecture

- ✅ **Offline-first** : Toutes les données d'abord locales
- ✅ **0 logique métier dans l'UI** : Toute la logique dans les controllers
- ✅ **Clean Architecture** : Respect strict de la séparation des couches
- ✅ **Testable** : Logique métier isolée et testable

### Code Quality

- ✅ **Aucun fichier > 200 lignes** : Découpage en widgets/services
- ✅ **AutoDispose providers** : Optimisation mémoire
- ✅ **Lazy loading** : Sections chargées à la demande
- ✅ **Pagination** : Listes paginées pour performance

### Sécurité

- ✅ **Utilisateurs non-admin par défaut** : Sécurité par défaut
- ✅ **Assignation explicite** : Pas d'accès par défaut
- ✅ **Audit trail complet** : Traçabilité de toutes les actions
