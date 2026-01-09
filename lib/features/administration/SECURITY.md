# Sécurité - Module Administration

## Vue d'ensemble

Ce document détaille les mesures de sécurité, les vérifications et les bonnes pratiques pour le module Administration.

## 🔒 Sécurité de Création d'Utilisateurs

### ✅ Problème Corrigé : Utilisateurs ne sont PLUS automatiquement admin

**Avant (❌ INCORRECT)** :
```dart
// ❌ TOUS les utilisateurs créés devenaient admin
final appUser = await authService.createFirstAdmin(
  email: email,
  password: password,
);
// ❌ isAdmin: true pour tous les utilisateurs
```

**Maintenant (✅ CORRECT)** :
```dart
// ✅ Utilisateurs normaux créés (pas admin)
final firebaseUid = await authService.createUserAccount(
  email: email,
  password: password,
  displayName: displayName,
);
// ✅ L'utilisateur créé n'est PAS admin
// ✅ Il doit être assigné explicitement à une entreprise/module
```

### Flux de Sécurité Garanti

#### Étape 1 : Création du Compte Firebase Auth

```dart
// ✅ Crée un utilisateur NORMAL (pas admin)
final firebaseUid = await authService.createUserAccount(
  email: email,
  password: password,
);
// ✅ L'utilisateur peut se connecter
// ❌ Il n'a AUCUN accès (pas encore assigné)
// ❌ Il n'est PAS admin
```

#### Étape 2 : Création de l'Entité User

```dart
// ✅ User créé dans le système
final user = User(
  id: firebaseUid,
  firstName: 'Jean',
  lastName: 'Dupont',
  username: 'jdupont',
  email: email,
  isActive: true,
  // ✅ PAS de champ isAdmin dans User
  // ✅ PAS de champ enterpriseId dans User
);
// ✅ Stocké avec enterpriseId = 'global' (correct pour le stockage)
```

#### Étape 3 : Assignation (Doit être faite par un Admin)

```dart
// ⚠️ Un admin doit explicitement assigner l'utilisateur
await adminController.assignUserToEnterprise(
  EnterpriseModuleUser(
    userId: user.id,
    enterpriseId: 'entreprise_gaz_1', // ✅ Entreprise spécifique
    moduleId: 'gaz',
    roleId: 'vendeur', // ✅ Rôle non-admin
  ),
);
// ✅ Maintenant l'utilisateur a accès avec ce rôle
```

### ✅ Vérifications de Sécurité

#### User Entity

```dart
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String? email;
  final String? phone;
  final bool isActive;
  // ✅ PAS de champ isAdmin
  // ✅ PAS de champ enterpriseId
}
```

#### Firebase Auth Integration

```dart
// ✅ Utilise createUserAccount() (pas createFirstAdmin)
final firebaseUid = await authService.createUserAccount(
  email: email,
  password: password,
);
// ✅ Retourne juste l'UID (pas un AppUser avec isAdmin)
```

#### User Repository

```dart
// ✅ Stockage avec enterpriseId = 'global'
enterpriseId: 'global', 
// ✅ Correct : users sont globaux
// ✅ L'assignation se fait via EnterpriseModuleUser
```

#### Admin Repository

```dart
// ✅ Assignation avec rôle spécifique
await assignUserToEnterprise(
  EnterpriseModuleUser(
    userId: userId,
    enterpriseId: enterpriseId, // ✅ Entreprise spécifique
    moduleId: moduleId,
    roleId: roleId, // ✅ Rôle spécifique (vendeur, caissier, etc.)
  ),
);
```

## 🏢 Architecture Multi-Tenant

### Stockage des Utilisateurs (✅ CORRECT)

```dart
// ✅ Users stockés avec enterpriseId = 'global'
// C'est CORRECT car :
// - Les utilisateurs sont globaux au système
// - Ils ne sont PAS liés à une entreprise spécifique
// - Leur assignation se fait via EnterpriseModuleUser

await driftService.records.upsert(
  collectionName: 'users',
  enterpriseId: 'global', // ✅ Correct : users globaux
  // ...
);
```

### Assignation aux Entreprises (✅ CORRECT)

```dart
// ✅ L'assignation se fait via EnterpriseModuleUser
final assignment = EnterpriseModuleUser(
  userId: 'user_123',
  enterpriseId: 'entreprise_gaz_1', // ✅ Entreprise spécifique
  moduleId: 'gaz',
  roleId: 'vendeur', // ✅ Rôle spécifique (PAS admin)
  isActive: true,
);

await adminController.assignUserToEnterprise(assignment);
// ✅ Maintenant l'utilisateur a accès avec le rôle spécifié
```

### Un Utilisateur, Plusieurs Assignations

Un utilisateur peut être assigné à plusieurs entreprises/modules avec des rôles différents :

```dart
// Assignation 1 : Vendeur dans entreprise Gaz
await adminController.assignUserToEnterprise(
  EnterpriseModuleUser(
    userId: 'user_123',
    enterpriseId: 'entreprise_gaz_1',
    moduleId: 'gaz',
    roleId: 'vendeur',
  ),
);

// Assignation 2 : Caissier dans entreprise Boutique
await adminController.assignUserToEnterprise(
  EnterpriseModuleUser(
    userId: 'user_123',
    enterpriseId: 'entreprise_boutique_1',
    moduleId: 'boutique',
    roleId: 'caissier',
  ),
);
```

## 🔐 Permissions et Rôles

### Par Défaut : Aucun Accès

```dart
// ✅ Un nouvel utilisateur créé :
// - ❌ N'est PAS admin
// - ❌ N'a AUCUN accès à aucune entreprise
// - ❌ Ne peut PAS se connecter si isActive = false
// - ⏳ Doit être assigné manuellement par un admin
```

### Assignation par Admin

L'admin assigne l'utilisateur avec un rôle spécifique.

**Exemples de rôles** :
- `vendeur` : Peut vendre dans le module
- `caissier` : Peut gérer la caisse
- `manager` : Peut gérer le module
- `admin` : Accès complet (uniquement si assigné explicitement)

### Service de Validation des Permissions

Le service `PermissionValidatorService` permet de vérifier les permissions :

```dart
// Vérifier une permission
final hasPermission = await permissionValidator.hasPermission(
  userId: userId,
  moduleId: moduleId,
  permissionId: 'create_production',
);

// Vérifier si admin du module
final isAdmin = await permissionValidator.isModuleAdmin(
  userId: userId,
  moduleId: moduleId,
);

// Vérifier permissions CRUD
final canCreate = await permissionValidator.canCreate(
  userId: userId,
  moduleId: moduleId,
);

final canManageUsers = await permissionValidator.canManageUsers(
  userId: userId,
);
```

## ✅ Vérifications de Sécurité dans UserController

### Création d'Utilisateur

```dart
Future<User> createUser(User user, {String? password, String? currentUserId}) async {
  // 1. ✅ Crée Firebase Auth account (utilisateur normal)
  if (password != null) {
    final firebaseUid = await firebaseAuthIntegration!.createFirebaseUser(
      email: user.email!,
      password: password,
      displayName: '${user.firstName} ${user.lastName}',
    );
    user = user.copyWith(id: firebaseUid);
  }

  // 2. ✅ Enregistre dans Drift (enterpriseId = 'global')
  final createdUser = await _repository.createUser(user);
  
  // 3. ✅ Sync Firestore
  firestoreSync?.syncUserToFirestore(createdUser);
  
  // 4. ✅ Audit trail
  auditService?.logAction(
    action: AuditAction.create,
    entityType: 'user',
    entityId: createdUser.id,
    userId: currentUserId ?? 'system',
    description: 'User created: ${createdUser.fullName}',
  );
  
  // ✅ L'utilisateur créé :
  // - N'est PAS admin
  // - N'a PAS d'accès (doit être assigné)
  // - Peut se connecter si isActive = true
  
  return createdUser;
}
```

### Séparation des Responsabilités

- ✅ `createUserAccount()` : Crée utilisateur normal (Firebase Auth)
- ✅ `createFirstAdmin()` : Uniquement pour le premier admin système (bootstrap)
- ✅ `assignUserToEnterprise()` : Assignation avec rôle spécifique (AdminController)

## 📋 Checklist de Sécurité

### Création d'Utilisateurs

- ✅ Utilisateurs créés ne sont PAS admin
- ✅ Utilisateurs créés n'ont AUCUN accès
- ✅ Assignation doit être explicite via AdminController
- ✅ Rôles assignés sont spécifiques (vendeur, caissier, manager)
- ✅ EnterpriseId "global" est correct pour le stockage
- ✅ Assignation aux entreprises via EnterpriseModuleUser
- ✅ Architecture multi-tenant respectée

### Firebase Auth

- ✅ Création de comptes via `createUserAccount()` (pas `createFirstAdmin`)
- ✅ Suppression de comptes lors de la suppression d'utilisateur
- ✅ Mise à jour de profils lors de la modification d'utilisateur
- ✅ Envoi d'emails de réinitialisation disponible

### Firestore

- ✅ Synchronisation des données utilisateurs
- ✅ Synchronisation des assignations
- ✅ Synchronisation des rôles
- ✅ Synchronisation des audit logs
- ✅ Suppression depuis Firestore lors de la suppression locale

### Audit Trail

- ✅ Toutes les actions critiques sont auditées
- ✅ Logs enregistrés localement (Drift)
- ✅ Logs synchronisés vers Firestore
- ✅ Traçabilité complète (qui, quoi, quand, où)

## 🎯 Résumé : Sécurité Garantie

### ✅ Nouveaux Utilisateurs

- ✅ **NON admin** par défaut
- ✅ **Aucun accès** par défaut
- ✅ **Doit être assigné** explicitement par un admin
- ✅ **Rôle spécifique** lors de l'assignation (vendeur, caissier, etc.)

### ✅ Architecture Multi-Tenant

- ✅ Users stockés globalement (`enterpriseId = 'global'`)
- ✅ Assignation via `EnterpriseModuleUser` (entrepriseId spécifique)
- ✅ Un utilisateur peut être assigné à plusieurs entreprises
- ✅ Chaque assignation a son propre rôle et permissions

### ✅ Séparation des Responsabilités

- ✅ `createUserAccount()` : Crée utilisateur normal
- ✅ `createFirstAdmin()` : Uniquement pour le premier admin système
- ✅ `assignUserToEnterprise()` : Assignation avec rôle spécifique

### ✅ Audit et Traçabilité

- ✅ Toutes les actions critiques auditées
- ✅ Logs locaux + Firestore
- ✅ Traçabilité complète

## ⚠️ Recommandations Futures

### Validation des Permissions

À intégrer dans tous les controllers et actions :

```dart
// Avant chaque action
final hasPermission = await permissionValidator.canManageUsers(
  userId: currentUserId,
);
if (!hasPermission) {
  throw PermissionDeniedException('Permission refusée');
}
```

### Vérification des Rôles Système

À implémenter pour empêcher la suppression des rôles système :

```dart
// Dans AdminController.deleteRole()
if (role.isSystemRole) {
  throw SystemRoleException('Impossible de supprimer un rôle système');
}
```

### Rate Limiting

À implémenter pour limiter les tentatives de création d'utilisateurs :

```dart
// Limiter à X créations par minute
if (await rateLimiter.exceeded(userId, 'create_user')) {
  throw RateLimitException('Trop de tentatives');
}
```

### Validation des Mots de Passe

À renforcer dans `CreateUserDialog` :

```dart
// Exigences de mot de passe
- Minimum 8 caractères
- Au moins une majuscule
- Au moins une minuscule
- Au moins un chiffre
- Au moins un caractère spécial
```

