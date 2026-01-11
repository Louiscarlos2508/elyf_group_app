# Dépannage - Erreur "NotInitializedError" lors de la connexion

## Problème

Lors de la tentative de connexion, vous recevez l'erreur : **"Erreur de connexion: instance of NotInitializedError"**

## Causes possibles

### 1. Firebase n'est pas complètement initialisé

Firebase doit être initialisé dans `main()` via `bootstrap()` avant que l'application ne démarre.

**Vérification** :
- Vérifiez que `main()` appelle `await bootstrap()` avant `runApp()`
- Vérifiez les logs au démarrage pour voir si "Firebase initialized successfully" apparaît

### 2. Firebase Options manquantes ou incorrectes

Le fichier `firebase_options.dart` doit être généré correctement.

**Solution** :
```bash
flutterfire configure
```

Ou vérifiez que le fichier `lib/firebase_options.dart` existe et contient les bonnes options.

### 3. Problème avec SecureStorage (Android)

Sur Android, `flutter_secure_storage` peut nécessiter une configuration spéciale.

**Vérification** :
- Vérifiez que `android/app/build.gradle` contient `minSdkVersion >= 18`
- Sur certains appareils, SecureStorage peut échouer silencieusement

### 4. Provider non initialisé

Si un provider Riverpod essaie d'accéder à un service non initialisé, cela peut causer cette erreur.

**Solution** :
- Vérifiez que `authServiceProvider` est bien défini
- Vérifiez que `currentUserProvider` gère correctement les états de chargement

## Solutions

### Solution 1 : Redémarrer l'application complètement

1. Arrêter complètement l'application (pas juste la mettre en arrière-plan)
2. Redémarrer l'application
3. Attendre quelques secondes que le bootstrap se termine
4. Essayer de se connecter

### Solution 2 : Vérifier les logs au démarrage

Dans les logs de l'application, cherchez :
```
[bootstrap] Firebase initialized successfully
[bootstrap] Permissions initialized
```

Si ces messages n'apparaissent pas, Firebase n'est pas initialisé correctement.

### Solution 3 : Vérifier la configuration Firebase

1. Vérifiez que `google-services.json` (Android) existe dans `android/app/`
2. Vérifiez que `GoogleService-Info.plist` (iOS) existe dans `ios/Runner/`
3. Vérifiez que le fichier `firebase_options.dart` est à jour

### Solution 4 : Nettoyer et reconstruire

```bash
flutter clean
flutter pub get
flutter run
```

### Solution 5 : Vérifier les dépendances

Vérifiez que toutes les dépendances Firebase sont installées :

```bash
flutter pub deps | grep firebase
```

Vous devriez voir :
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`

## Debugging

Pour obtenir plus d'informations sur l'erreur :

1. **Activer les logs détaillés** :
   - Les logs sont maintenant automatiquement enregistrés dans `developer.log`
   - Cherchez dans les logs "Error during auth service initialization"

2. **Vérifier l'état de Firebase** :
   ```dart
   // Dans le login screen, avant la connexion
   try {
     final apps = Firebase.apps;
     print('Firebase apps: $apps');
   } catch (e) {
     print('Firebase not initialized: $e');
   }
   ```

3. **Vérifier l'état de l'auth service** :
   - Les erreurs d'initialisation sont maintenant loggées avec le stack trace complet
   - Consultez les logs pour voir exactement où l'erreur se produit

## Messages d'erreur améliorés

Les messages d'erreur ont été améliorés pour être plus explicites :

- ✅ **"Firebase n'est pas initialisé"** : Redémarrer l'application
- ✅ **"Problème de connexion réseau"** : Vérifier la connexion internet
- ✅ **"Aucun compte trouvé"** : Vérifier que l'utilisateur existe dans Firebase Console
- ✅ **"Mot de passe incorrect"** : Vérifier le mot de passe

## Si le problème persiste

1. **Collecter les logs complets** :
   - Notez tous les messages de log avant et pendant la connexion
   - Cherchez les erreurs qui commencent par `[auth]` ou `[bootstrap]`

2. **Vérifier la configuration Firebase** :
   - Firebase Console → Authentication → Vérifier que l'utilisateur existe
   - Firebase Console → Firestore → Vérifier que la base de données existe

3. **Tester avec un utilisateur simple** :
   - Créer un nouvel utilisateur dans Firebase Console
   - Essayer de se connecter avec cet utilisateur

## Améliorations apportées

✅ **Gestion d'erreur améliorée** dans `AuthService.initialize()`
- Try-catch autour de toutes les opérations Firebase
- Messages d'erreur clairs et en français
- Logs détaillés pour le debugging

✅ **Gestion d'erreur améliorée** dans `AuthController.signIn()`
- Détection spécifique des erreurs d'initialisation
- Messages d'erreur explicites

✅ **Gestion d'erreur améliorée** dans `LoginScreen._submit()`
- Logs détaillés avec stack trace
- Messages d'erreur spécifiques selon le type d'erreur

