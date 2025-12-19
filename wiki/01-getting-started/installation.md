# Installation

Guide complet pour installer et configurer ELYF Group App sur votre machine de développement.

## Prérequis

### Logiciels requis

- **Flutter SDK** >= 3.9.0
  - Télécharger depuis [flutter.dev](https://flutter.dev/docs/get-started/install)
  - Vérifier l'installation : `flutter doctor`
  
- **Dart SDK** >= 3.9.0 (inclus avec Flutter)

- **IDE** (un des deux) :
  - **Android Studio** avec plugins Flutter et Dart
  - **VS Code** avec extensions Flutter et Dart

- **Git** – Pour le contrôle de version

### Plateformes cibles

#### Android
- Android Studio avec Android SDK
- SDK Platform >= API 21 (Android 5.0)
- Android SDK Build-Tools

#### iOS (macOS uniquement)
- Xcode >= 14.0
- CocoaPods : `sudo gem install cocoapods`
- iOS Simulator ou appareil physique

## Installation pas à pas

### 1. Cloner le repository

```bash
git clone <repository-url>
cd elyf_group_app
```

### 2. Vérifier Flutter

```bash
flutter doctor
```

Résoudre tous les problèmes signalés avant de continuer.

### 3. Installer les dépendances

```bash
flutter pub get
```

### 4. Configurer Firebase

Voir [Configuration Firebase](../02-configuration/firebase.md) pour les détails complets.

**Résumé rapide :**
- Créer un projet Firebase
- Ajouter les fichiers de configuration :
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- Activer les services nécessaires (Auth, Firestore, Functions, FCM, Storage)

### 5. Lancer l'application

#### Sur émulateur/simulateur

```bash
# Lister les appareils disponibles
flutter devices

# Lancer sur un appareil spécifique
flutter run -d <device-id>
```

#### Sur appareil physique

**Android :**
1. Activer le mode développeur
2. Activer le débogage USB
3. Connecter l'appareil
4. `flutter run`

**iOS :**
1. Configurer le certificat de développement dans Xcode
2. Connecter l'appareil
3. `flutter run`

### 6. Vérifier l'installation

L'application devrait :
- Afficher l'écran de splash
- Charger l'écran d'onboarding ou de login
- Se connecter à Firebase

## Problèmes courants

### Erreur "No devices found"

**Android :**
```bash
# Vérifier que l'appareil est détecté
adb devices

# Si l'appareil n'apparaît pas, réinstaller les drivers USB
```

**iOS :**
```bash
# Vérifier les certificats
flutter doctor -v
```

### Erreur de dépendances

```bash
# Nettoyer et réinstaller
flutter clean
flutter pub get
```

### Erreur Firebase

- Vérifier que les fichiers de configuration sont présents
- Vérifier que les services Firebase sont activés
- Voir [Configuration Firebase](../02-configuration/firebase.md)

### Problèmes de build Android

```bash
# Nettoyer le build
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

## Prochaines étapes

Une fois l'installation terminée :

1. Lire [Premiers pas](./first-steps.md)
2. Configurer votre environnement : [Environnement de développement](../02-configuration/dev-environment.md)
3. Explorer l'architecture : [Vue d'ensemble de l'architecture](../03-architecture/overview.md)

## Support

En cas de problème, consulter :
- [Wiki - Dépannage](../08-printing/troubleshooting.md)
- Issues GitHub du projet
- Documentation Flutter officielle
