# Utilisateurs par Défaut pour le Développement

## Vue d'ensemble

Pour faciliter le développement et les tests, chaque module a automatiquement un utilisateur par défaut avec **accès complet** (toutes les permissions).

## Utilisateurs créés automatiquement

Quand `MockPermissionService` est initialisé, il crée automatiquement :

### Pour chaque module :
- **Utilisateur** : `default_user_[module_id]`
- **Rôle** : `admin_[module_id]` avec permission `*` (tous les accès)
- **Statut** : Actif

### Modules concernés :
- `eau_minerale` → `default_user_eau_minerale`
- `gaz` → `default_user_gaz`
- `orange_money` → `default_user_orange_money`
- `immobilier` → `default_user_immobilier`
- `boutique` → `default_user_boutique`

## Utilisation dans les providers

Chaque module doit utiliser son utilisateur par défaut dans `currentUserIdProvider` :

```dart
/// Provider for current user ID.
/// In development, uses default user with full access for the module.
final currentUserIdProvider = Provider<String>(
  (ref) => 'default_user_eau_minerale', // Utilisateur par défaut avec accès complet
);
```

## Avantages

✅ **Pas besoin de connexion** : L'utilisateur est automatiquement connecté  
✅ **Accès complet** : Toutes les permissions sont disponibles pour les tests  
✅ **Développement facilité** : Pas besoin de gérer l'authentification pendant le développement  
✅ **Tests simplifiés** : Tous les écrans et fonctionnalités sont accessibles  

## Migration vers la production

Quand l'authentification réelle sera implémentée :

1. Remplacer `currentUserIdProvider` pour récupérer l'ID depuis l'auth
2. Supprimer l'initialisation automatique des utilisateurs par défaut
3. Utiliser le vrai système d'authentification

## Exemple

```dart
// Dans providers.dart du module
final currentUserIdProvider = Provider<String>(
  (ref) {
    // TODO: Remplacer par l'auth réelle
    // final authService = ref.watch(authServiceProvider);
    // return authService.currentUser?.id ?? 'default_user_eau_minerale';
    return 'default_user_eau_minerale'; // Pour le développement
  },
);
```

