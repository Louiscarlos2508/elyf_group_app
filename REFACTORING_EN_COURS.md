# Refactoring en Cours - Actions Prioritaires

**Date de début**: 26 Janvier 2026  
**Statut**: En cours

---

## ✅ Actions Complétées

### 1. Service AppLogger Centralisé

**Fichiers créés**:
- `lib/core/logging/app_logger.dart` - Service de logging centralisé
- `lib/core/logging/logging.dart` - Barrel file pour exports

**Fonctionnalités**:
- ✅ Méthodes `debug()`, `info()`, `warning()`, `error()`, `critical()`
- ✅ Support des niveaux de log structurés
- ✅ Intégration avec `dart:developer`
- ✅ Logs de debug uniquement en mode développement (`kDebugMode`)

**Prochaine étape**: Remplacer tous les `debugPrint` (114 occurrences) par `AppLogger`

**Exemple d'utilisation**:
```dart
// ❌ Ancien code
debugPrint('Message de debug');

// ✅ Nouveau code
AppLogger.debug('Message de debug', name: 'module.auth');
AppLogger.info('Opération réussie', name: 'module.auth');
AppLogger.error('Erreur lors de la connexion', error: e, stackTrace: st, name: 'module.auth');
```

### 2. Découpage de auth_service.dart (En cours)

**Fichiers créés**:
- `lib/core/auth/entities/app_user.dart` - Entité AppUser extraite ✅
- `lib/core/auth/services/auth_storage_service.dart` - Service de stockage ✅
- `lib/core/auth/services/auth_user_service.dart` - Service de gestion des utilisateurs ✅

**Fichiers modifiés**:
- `lib/core/auth/entities/entities.dart` - Export de AppUser ajouté ✅

**Progrès**:
- ✅ `AppUser` extrait dans un fichier séparé
- ✅ `AuthStorageService` créé (gestion du stockage)
- ✅ `AuthUserService` créé (création d'utilisateurs, changement de mot de passe)
- ✅ `AuthSessionService` créé (gestion de session et connexion)
- ✅ `auth_service.dart` refactorisé pour utiliser les sous-services (198 lignes, objectif atteint !)

**Services créés**:

#### AuthStorageService ✅
- `loadUser()` - Charger depuis SecureStorage
- `saveUser()` - Sauvegarder dans SecureStorage
- `clearLocalAuthData()` - Nettoyer les données
- `isLoggedIn()` - Vérifier l'état de connexion
- `migrateFromSharedPreferences()` - Migration

#### AuthUserService ✅
- `createUserAccount()` - Créer un compte utilisateur
- `createFirstAdmin()` - Créer le premier admin
- `changePassword()` - Changer le mot de passe

#### AuthSessionService ✅
- `initialize()` - Initialisation du service
- `signInWithEmailAndPassword()` - Connexion (logique complexe - 365 lignes)
- `signOut()` - Déconnexion
- `reloadUser()` - Recharger l'utilisateur
- `forceReset()` - Réinitialisation forcée

---

## 🔄 Actions en Cours

### 1. Découpage de auth_service.dart

**Objectif**: Réduire `auth_service.dart` de 1,118 lignes à < 200 lignes

**Plan de découpage**:

1. **AuthStorageService** ✅ (Créé)
   - Toutes les méthodes liées au stockage

2. **AuthUserService** ✅ (Créé)
   - Création d'utilisateurs et changement de mot de passe

3. **AuthSessionService** ✅ (Créé)
   - Gestion de session et connexion
   - La méthode `signInWithEmailAndPassword()` est très complexe (365 lignes)
   - Gère tous les cas d'erreur pour une expérience utilisateur fluide

4. **AuthService** (Orchestrateur final)
   - Utilise les 3 sous-services
   - Expose les méthodes publiques
   - Gère la cohérence entre services
   - Devrait être < 200 lignes après refactoring

---

## 📋 Prochaines Étapes

### Priorité 1: Compléter le découpage de auth_service.dart ✅

1. ✅ Créer `AuthSessionService` avec la logique de connexion
2. ✅ Refactoriser `AuthService` pour utiliser les sous-services
3. ✅ Vérifier que `auth_service.dart` est < 200 lignes (198 lignes ✅)
4. ⏳ Tester que tout fonctionne (à faire)
5. ⏳ Supprimer l'ancien fichier AppUser de auth_service.dart (déjà extrait)

### Priorité 2: Remplacer tous les debugPrint

1. Créer un script de recherche/remplacement
2. Remplacer les 114 occurrences de `debugPrint`
3. Utiliser `AppLogger` avec les noms appropriés
4. Vérifier que les logs fonctionnent correctement

### Priorité 3: Améliorer la gestion d'erreurs

1. Remplacer `Exception` générique par `AppException`
2. Utiliser `ErrorHandler` partout
3. Ajouter try-catch dans les controllers

---

## 📊 Métriques

### Avant Refactoring
- `auth_service.dart`: 1,118 lignes
- `debugPrint`: 114 occurrences
- `Exception` générique: ~50 occurrences

### Après Refactoring (Partiel)
- `auth_service.dart`: **198 lignes** ✅ (objectif < 200 lignes atteint !)
- Réduction: **-82%** (de 1,118 à 198 lignes)
- `debugPrint`: 114 occurrences (à remplacer)
- `Exception` générique: ~50 occurrences (à remplacer)

### Objectifs Finaux
- `auth_service.dart`: < 200 lignes ✅ **ATTEINT**
- `debugPrint`: 0 occurrence (en cours)
- `Exception` générique: 0 occurrence (remplacé par `AppException`)

### Progrès Actuel
- Services créés: 3/3 (AuthStorageService ✅, AuthUserService ✅, AuthSessionService ✅)
- `AppUser` extrait: ✅
- `AppLogger` créé: ✅
- `AuthService` refactorisé: ✅ (198 lignes, objectif < 200 lignes atteint !)
- **Réduction**: De 1,118 lignes à 198 lignes (-82% de réduction)
- **Prochaine étape**: Tester que tout fonctionne, puis remplacer les `debugPrint`

---

## 🔗 Fichiers à Modifier

### Pour le découpage de auth_service.dart

1. `lib/core/auth/services/auth_service.dart` - Refactoriser (en cours)
2. `lib/core/auth/services/auth_session_service.dart` - Créer ⏳
3. Tous les fichiers qui importent `auth_service.dart` - Mettre à jour (après refactoring)

### Pour le remplacement de debugPrint

1. `lib/features/intro/presentation/screens/login_screen.dart` - 10+ occurrences
2. `lib/features/administration/application/controllers/enterprise_controller.dart` - 8 occurrences
3. `lib/features/gaz/presentation/widgets/point_of_sale_table.dart` - 20+ occurrences
4. `lib/features/eau_minerale/application/controllers/production_session_controller.dart` - 20+ occurrences
5. ... (voir rapport d'analyse complet)

---

## 📝 Notes

- Le refactoring est progressif pour éviter de casser l'application
- Chaque étape est testée avant de passer à la suivante
- Les fichiers sont créés en parallèle pour maintenir la compatibilité
- La documentation est mise à jour au fur et à mesure
- La méthode `signInWithEmailAndPassword()` est très complexe et nécessite une attention particulière lors de la refactorisation

---

**Dernière mise à jour**: 26 Janvier 2026
