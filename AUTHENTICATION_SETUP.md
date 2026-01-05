# Configuration de l'Authentification

## Admin par défaut

Un administrateur par défaut a été créé pour permettre l'accès à l'application :

- **Email** : `admin@elyf.com`
- **Mot de passe** : `admin123`
- **ID** : `admin_user_1`
- **Statut** : Administrateur avec accès complet

## Flux d'authentification

1. **Splash Screen** → Affiche le logo ELYF
2. **Onboarding** → Présentation des fonctionnalités (peut être passé)
3. **Login** → Connexion avec email/mot de passe
4. **Modules** → Menu des modules (protégé par AuthGuard)

## Routes protégées

Toutes les routes suivantes sont protégées par `AuthGuard` et redirigent vers `/login` si l'utilisateur n'est pas connecté :

- `/modules` - Menu des modules
- `/admin` - Administration
- `/modules/eau_sachet` - Module Eau Minérale
- `/modules/gaz` - Module Gaz
- `/modules/orange_money` - Module Orange Money
- `/modules/immobilier` - Module Immobilier
- `/modules/boutique` - Module Boutique

## Service d'authentification

Le service d'authentification (`AuthService`) est situé dans `lib/core/auth/services/auth_service.dart`.

### Fonctionnalités actuelles

- Connexion avec email/mot de passe
- Déconnexion
- Persistance de la session (SharedPreferences)
- Vérification de l'état d'authentification

### Migration vers Firebase Auth

Le service est conçu pour être facilement remplacé par Firebase Auth :

1. Remplacer `signInWithEmailAndPassword` pour utiliser `FirebaseAuth.instance.signInWithEmailAndPassword`
2. Utiliser `FirebaseAuth.instance.authStateChanges()` pour le StreamProvider
3. Supprimer le système mock et utiliser les utilisateurs Firebase

## Providers

- `authServiceProvider` - Instance du service d'authentification
- `currentUserProvider` - Utilisateur actuellement connecté (FutureProvider)
- `currentUserIdProvider` - ID de l'utilisateur actuel (Provider)
- `isAuthenticatedProvider` - État d'authentification (FutureProvider)
- `isAdminProvider` - Vérifie si l'utilisateur est admin (Provider)

## Accès au module Profile

L'administrateur a accès complet à tous les modules, y compris le module Profile pour gérer les accès et permissions.

Pour vérifier si un utilisateur est admin :

```dart
final isAdmin = ref.watch(isAdminProvider);
```

## Prochaines étapes

1. **Implémenter Firebase Auth** - Remplacer le système mock par Firebase Auth
2. **Gestion des utilisateurs** - Créer un système pour ajouter/modifier des utilisateurs
3. **Récupération de mot de passe** - Ajouter la fonctionnalité "Mot de passe oublié"
4. **Sécurité** - Implémenter des règles de sécurité plus strictes

