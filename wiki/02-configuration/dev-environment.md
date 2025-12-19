# Environnement de développement

Configuration de l'environnement de développement pour ELYF Group App.

## Configuration de l'IDE

### VS Code

#### Extensions recommandées

1. **Flutter** – Support Flutter et Dart
2. **Dart** – Support du langage Dart
3. **Error Lens** – Affichage des erreurs en ligne
4. **GitLens** – Amélioration de Git
5. **Pubspec Assist** – Aide pour pubspec.yaml

#### Configuration

Créer `.vscode/settings.json` :

```json
{
  "dart.flutterSdkPath": null,
  "dart.lineLength": 80,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "files.exclude": {
    "**/.dart_tool": true,
    "**/.flutter-plugins": true,
    "**/.flutter-plugins-dependencies": true,
    "**/.packages": true,
    "**/.pub-cache": true,
    "**/.pub": true,
    "**/build": true
  }
}
```

### Android Studio

#### Plugins

1. **Flutter** – Support Flutter
2. **Dart** – Support Dart
3. **Flutter Intl** – Internationalisation

#### Configuration

- **File** > **Settings** > **Editor** > **Code Style** > **Dart**
  - Line length: 80
  - Enable format on save

## Outils de développement

### Flutter DevTools

```bash
# Lancer DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

DevTools permet de :
- Inspecter le widget tree
- Analyser les performances
- Déboguer les problèmes de mémoire
- Voir les logs

### Hot Reload / Hot Restart

- **Hot Reload** : `r` dans le terminal ou bouton dans l'IDE
- **Hot Restart** : `R` dans le terminal
- **Full Restart** : Arrêter et relancer l'application

### Analyse statique

```bash
# Analyser le code
flutter analyze

# Formater le code
dart format lib/

# Corriger automatiquement
dart fix --apply
```

## Configuration Git

### .gitignore

Vérifier que `.gitignore` contient :

```
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
*.iml
*.ipr
*.iws
.idea/

# Firebase
**/google-services.json
**/GoogleService-Info.plist

# Environnement
.env
.env.local
```

### Hooks Git (optionnel)

Créer `.git/hooks/pre-commit` :

```bash
#!/bin/sh
flutter analyze
dart format --set-exit-if-changed lib/
```

## Variables d'environnement

### Configuration par environnement

Créer des fichiers de configuration :

- `.env.development`
- `.env.staging`
- `.env.production`

Utiliser `flutter_dotenv` pour charger les variables :

```dart
await dotenv.load(fileName: ".env.development");
```

### Secrets

Ne jamais commiter :
- Clés API
- Tokens d'authentification
- Certificats
- Fichiers Firebase

Utiliser des variables d'environnement ou un gestionnaire de secrets.

## Scripts utiles

### Scripts de build

Créer `scripts/build.sh` :

```bash
#!/bin/bash
flutter clean
flutter pub get
flutter build apk --release
```

### Scripts de test

Créer `scripts/test.sh` :

```bash
#!/bin/bash
flutter test
flutter test --coverage
```

## Debugging

### Logs

Utiliser `developer.log` au lieu de `print` :

```dart
import 'dart:developer' as developer;

developer.log('Message', name: 'myapp.feature');
```

### Breakpoints

- Placer des breakpoints dans l'IDE
- Utiliser `debugger()` dans le code
- Inspecter les variables dans le debugger

### Network debugging

Pour déboguer les appels réseau :
- Utiliser Firebase Console pour voir les requêtes Firestore
- Utiliser DevTools Network tab
- Logger les requêtes dans le code

## Performance

### Profiling

```bash
# Profiler l'application
flutter run --profile
```

### Memory leaks

Utiliser DevTools Memory tab pour détecter les fuites mémoire.

### Build size

```bash
# Analyser la taille du build
flutter build apk --analyze-size
```

## Tests

### Lancer les tests

```bash
# Tous les tests
flutter test

# Tests spécifiques
flutter test test/features/boutique/

# Avec couverture
flutter test --coverage
```

### Tests d'intégration

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

## Prochaines étapes

- Lire les [Guidelines de développement](../04-development/guidelines.md)
- Comprendre l'[Architecture](../03-architecture/overview.md)
