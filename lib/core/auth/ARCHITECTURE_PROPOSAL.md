# Architecture Multi-Tenant Améliorée

## Problème Actuel

L'architecture actuelle gère les permissions par `userId + moduleId` mais **PAS par entreprise**.
Cela signifie qu'un utilisateur avec accès au module "eau_minerale" peut accéder à **toutes** les entreprises de type "eau_minerale".

## Solution Proposée

### 1. Structure de Données Firestore

```
users/{userId}
  - email: string
  - firstName: string
  - lastName: string
  - phone: string?
  - isActive: boolean
  - createdAt: timestamp
  - updatedAt: timestamp

enterprises/{enterpriseId}
  - name: string
  - type: string (eau_minerale, gaz, etc.)
  - isActive: boolean
  - ...

enterprise_users/{enterpriseUserId}
  - userId: string (reference to users)
  - enterpriseId: string (reference to enterprises)
  - moduleId: string (eau_minerale, gaz, etc.)
  - roleId: string (reference to roles)
  - customPermissions: array<string>
  - isActive: boolean
  - createdAt: timestamp
  - updatedAt: timestamp

roles/{roleId}
  - name: string
  - moduleId: string
  - permissions: array<string>
  - isSystemRole: boolean
  - createdAt: timestamp
```

### 2. Modèle de Permission Amélioré

```dart
/// Permission avec support multi-tenant
class EnterpriseModuleUser {
  final String userId;           // Firebase Auth UID
  final String enterpriseId;      // Entreprise spécifique
  final String moduleId;           // Module dans l'entreprise
  final String roleId;             // Rôle assigné
  final Set<String> customPermissions;
  final bool isActive;
}

/// Service de permissions amélioré
abstract class PermissionService {
  // Vérifie permission avec entreprise
  Future<bool> hasPermission(
    String userId,
    String enterpriseId,  // ← NOUVEAU
    String moduleId,
    String permissionId,
  );
  
  // Récupère les entreprises accessibles par un utilisateur
  Future<List<Enterprise>> getUserEnterprises(String userId);
  
  // Récupère les modules accessibles dans une entreprise
  Future<List<String>> getUserModules(String userId, String enterpriseId);
}
```

### 3. Flux d'Authentification

```
1. Login (Firebase Auth)
   ↓
2. Récupérer userId depuis Firebase Auth
   ↓
3. Charger les entreprises accessibles (enterprise_users où userId = X)
   ↓
4. Si 1 seule entreprise → Auto-sélection
   Si plusieurs → Écran de sélection
   ↓
5. Charger les modules accessibles pour l'entreprise sélectionnée
   ↓
6. Navigation vers le module
```

### 4. Sécurité Firestore Rules

```javascript
// Exemple de règles Firestore
match /enterprises/{enterpriseId} {
  // Un utilisateur peut lire seulement les entreprises où il a un accès
  allow read: if request.auth != null && 
    exists(/databases/$(database)/documents/enterprise_users/$(request.auth.uid + '_' + enterpriseId));
  
  allow write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}

match /enterprise_users/{enterpriseUserId} {
  // Un utilisateur peut lire seulement ses propres accès
  allow read: if request.auth != null && 
    resource.data.userId == request.auth.uid;
  
  allow write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```

### 5. Architecture de Code

```
lib/core/auth/
  ├── services/
  │   ├── auth_service.dart          # Firebase Auth wrapper
  │   ├── permission_service.dart     # Service amélioré avec enterpriseId
  │   └── enterprise_access_service.dart  # Gestion accès entreprises
  ├── providers/
  │   ├── auth_providers.dart         # Providers Riverpod pour auth
  │   ├── current_user_provider.dart  # Utilisateur connecté
  │   └── current_enterprise_provider.dart  # Entreprise active
  ├── repositories/
  │   ├── auth_repository.dart        # Firebase Auth operations
  │   ├── enterprise_user_repository.dart  # CRUD enterprise_users
  │   └── user_repository.dart        # CRUD users
  └── guards/
      ├── auth_guard.dart             # Protection routes auth
      └── permission_guard.dart       # Protection par permission

lib/features/administration/
  ├── presentation/
  │   └── screens/
  │       ├── admin_users_screen.dart      # Gestion utilisateurs
  │       ├── admin_enterprises_screen.dart  # Gestion entreprises
  │       └── admin_permissions_screen.dart # Gestion permissions
```

## Avantages

✅ **Isolation des données** : Chaque entreprise a ses propres données
✅ **Sécurité renforcée** : Un utilisateur ne peut accéder qu'aux entreprises autorisées
✅ **Flexibilité** : Un utilisateur peut avoir des rôles différents selon l'entreprise
✅ **Scalabilité** : Facile d'ajouter de nouvelles entreprises
✅ **Audit** : Traçabilité complète des accès

## Migration

1. **Phase 1** : Créer les nouvelles entités et repositories
2. **Phase 2** : Intégrer Firebase Auth
3. **Phase 3** : Migrer les permissions existantes vers le nouveau modèle
4. **Phase 4** : Implémenter les guards et protections
5. **Phase 5** : Créer l'interface d'administration complète

## Exemple d'Utilisation

```dart
// Dans un widget
final authService = ref.watch(authServiceProvider);
final permissionService = ref.watch(permissionServiceProvider);
final currentEnterprise = ref.watch(currentEnterpriseProvider);

// Vérifier permission
final canCreate = await permissionService.hasPermission(
  authService.currentUserId!,
  currentEnterprise.id,
  'eau_minerale',
  'create_production',
);

// Récupérer entreprises accessibles
final enterprises = await permissionService.getUserEnterprises(
  authService.currentUserId!,
);
```

