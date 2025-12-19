# Configuration Firebase

Guide complet pour configurer Firebase dans ELYF Group App.

## Vue d'ensemble

ELYF Group App utilise Firebase pour :
- **Authentication** – Gestion des utilisateurs
- **Cloud Firestore** – Base de données principale
- **Cloud Functions** – Logique serveur
- **Firebase Cloud Messaging (FCM)** – Notifications push
- **Firebase Storage** – Stockage de fichiers

## Création du projet Firebase

### 1. Créer un projet

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquer sur "Ajouter un projet"
3. Entrer le nom du projet (ex: "elyf-group-app")
4. Activer/désactiver Google Analytics selon vos besoins
5. Créer le projet

### 2. Ajouter les applications

#### Android

1. Dans Firebase Console, cliquer sur l'icône Android
2. Entrer le package name (ex: `com.elyfgroup.app`)
3. Télécharger `google-services.json`
4. Placer le fichier dans `android/app/google-services.json`
5. Vérifier que `android/build.gradle` contient :
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
6. Vérifier que `android/app/build.gradle` contient :
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

#### iOS

1. Dans Firebase Console, cliquer sur l'icône iOS
2. Entrer le bundle ID (ex: `com.elyfgroup.app`)
3. Télécharger `GoogleService-Info.plist`
4. Ouvrir Xcode
5. Glisser-déposer le fichier dans `ios/Runner/`
6. Cocher "Copy items if needed"

## Configuration des services

### Authentication

1. Dans Firebase Console : **Authentication** > **Get started**
2. Activer **Email/Password**
3. (Optionnel) Activer d'autres méthodes (Google, Apple, etc.)

### Cloud Firestore

1. **Firestore Database** > **Create database**
2. Choisir le mode :
   - **Production mode** (recommandé) – Règles strictes
   - **Test mode** – Accès libre pendant 30 jours
3. Choisir la région (ex: `europe-west1`)
4. Configurer les règles de sécurité (voir ci-dessous)

### Cloud Functions

1. **Functions** > **Get started**
2. Installer Firebase CLI :
   ```bash
   npm install -g firebase-tools
   ```
3. Initialiser Functions :
   ```bash
   firebase init functions
   ```

### Firebase Cloud Messaging

1. **Cloud Messaging** > **Get started**
2. Pour Android : Configurer le serveur de clés (optionnel)
3. Pour iOS : Uploader le certificat APNs

### Firebase Storage

1. **Storage** > **Get started**
2. Choisir le mode de sécurité
3. Choisir la région

## Règles de sécurité Firestore

Exemple de règles de base (à adapter selon vos besoins) :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Règles pour les entreprises (tenants)
    match /enterprises/{enterpriseId} {
      // Seuls les utilisateurs authentifiés peuvent lire
      allow read: if request.auth != null;
      // Seuls les admins peuvent écrire
      allow write: if request.auth != null 
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      
      // Règles pour les collections sous une entreprise
      match /{collection}/{document=**} {
        allow read: if request.auth != null 
          && request.auth.uid in resource.data.authorizedUsers;
        allow write: if request.auth != null 
          && request.auth.uid in resource.data.authorizedUsers;
      }
    }
    
    // Règles pour les utilisateurs
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Configuration dans le code

### Initialisation Firebase

L'application initialise Firebase dans `lib/app/bootstrap.dart` :

```dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialiser Isar (base de données locale)
  // ...
}
```

### Variables d'environnement

Pour différents environnements (dev, staging, prod), utilisez :
- `flutterfire_cli` pour générer les configurations
- Variables d'environnement pour les clés API
- Fichiers de configuration séparés par environnement

## Vérification

### Tester l'authentification

1. Lancer l'application
2. Aller sur l'écran de login
3. Créer un compte ou se connecter
4. Vérifier dans Firebase Console > Authentication que l'utilisateur apparaît

### Tester Firestore

1. Créer une entrée dans l'application
2. Vérifier dans Firebase Console > Firestore que les données sont créées
3. Vérifier la structure des collections

### Tester FCM

1. Envoyer une notification de test depuis Firebase Console
2. Vérifier que la notification arrive sur l'appareil

## Dépannage

### Erreur "MissingPluginException"

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Erreur de configuration Android

Vérifier que `google-services.json` est bien dans `android/app/`

### Erreur de configuration iOS

Vérifier que `GoogleService-Info.plist` est bien dans `ios/Runner/` et ajouté au projet Xcode

### Erreur de permissions Firestore

Vérifier les règles de sécurité dans Firebase Console

## Prochaines étapes

- Configurer l'environnement de développement : [Environnement de développement](./dev-environment.md)
- Comprendre l'architecture : [Vue d'ensemble de l'architecture](../03-architecture/overview.md)
