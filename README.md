# ELYF Group App

Application mobile Flutter multi-entreprises et multi-modules pour la gestion intégrée de plusieurs activités commerciales.

## 📋 Vue d'ensemble

ELYF Group App est une solution complète de gestion d'entreprise permettant de gérer plusieurs activités depuis une seule application. L'application supporte le mode offline-first avec synchronisation automatique et offre une interface utilisateur moderne et intuitive.

### Entreprises gérées

- **Eau Minérale** – Production, mise en sachet et vente d'eau minérale
- **Gaz** – Distribution de bouteilles de gaz en détail et gros
- **Orange Money** – Opérations cash-in/cash-out pour agents agréés
- **Immobilier** – Gestion de locations de maisons
- **Boutique** – Vente physique avec gestion de stocks et caisse

### Fonctionnalités principales

- 🔐 **Authentification Firebase** – Gestion sécurisée des utilisateurs
- 🏢 **Multi-tenant** – Support de plusieurs entreprises avec switch rapide
- 📱 **Offline-first** – Fonctionnement hors ligne avec synchronisation automatique
- 🖨️ **Impression thermique** – Support des imprimantes Sunmi V3 Mix
- 📊 **Tableaux de bord** – Visualisation des KPIs par module
- 🔍 **Audit trail** – Traçabilité complète des actions critiques
- 👥 **Gestion des permissions** – Système de rôles et permissions granulaire
- 💰 **Trésorerie centralisée** – Gestion financière unifiée

## 🚀 Démarrage rapide

### Prérequis

- Flutter SDK >= 3.9.0
- Dart SDK >= 3.9.0
- Android Studio / VS Code avec extensions Flutter
- Compte Firebase configuré
- (Optionnel) Imprimante Sunmi V3 Mix pour les tests d'impression

### Installation

1. **Cloner le repository**
   ```bash
   git clone <repository-url>
   cd elyf_group_app
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Configurer Firebase**
   - Ajouter les fichiers de configuration Firebase :
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`
   - Voir [Wiki - Configuration Firebase](./wiki/02-configuration/firebase.md) pour plus de détails

4. **Lancer l'application**
   ```bash
   flutter run
   ```

## 📁 Structure du projet

```
lib/
├── app/                    # Configuration de l'application
│   ├── app.dart           # Widget racine
│   ├── bootstrap.dart     # Initialisation
│   ├── router/            # Configuration du routing
│   └── theme/             # Thème et styles globaux
├── core/                   # Services transverses
│   ├── auth/              # Authentification Firebase
│   ├── firebase/          # Wrappers Firestore, Functions, FCM
│   ├── offline/           # Drift (SQLite) et synchronisation
│   ├── printing/          # Intégration Sunmi V3
│   ├── permissions/       # Système de permissions
│   ├── tenant/            # Gestion multi-tenant
│   └── pdf/               # Génération de PDFs
├── features/               # Modules métier
│   ├── administration/    # Gestion utilisateurs et rôles
│   ├── eau_minerale/      # Module eau minérale
│   ├── gaz/               # Module gaz
│   ├── orange_money/      # Module Orange Money
│   ├── immobilier/        # Module immobilier
│   ├── boutique/          # Module boutique
│   ├── dashboard/         # Tableaux de bord
│   ├── audit_trail/       # Traçabilité
│   └── notifications/     # Notifications push
└── shared/                 # Composants partagés
    ├── presentation/       # Widgets et écrans réutilisables
    ├── providers/          # Providers Riverpod globaux
    └── utils/              # Utilitaires
```

Chaque module suit la même architecture :

- `presentation/` – Écrans et widgets UI (< 200 lignes par fichier)
- `application/` – Contrôleurs Riverpod (StateNotifier, AsyncNotifier)
- `domain/` – Entités, value objects, use cases
- `data/` – Repositories et data sources (Firestore/Drift)

## 🛠️ Technologies utilisées

### Core
- **Flutter** – Framework UI
- **Dart** – Langage de programmation
- **Riverpod** – State management
- **GoRouter** – Navigation déclarative

### Backend & Storage
- **Firebase Auth** – Authentification
- **Cloud Firestore** – Base de données NoSQL
- **Cloud Functions** – Logique serveur
- **Firebase Cloud Messaging** – Notifications push
- **Firebase Storage** – Stockage de fichiers
- **Drift (SQLite)** – Base de données locale (offline-first)

### UI & Design
- **Material Design 3** – Design system
- **Google Fonts** – Typographie
- **fl_chart** – Graphiques et visualisations

### Hardware
- **Sunmi V3 Mix** – Imprimante thermique
- **sunmi_flutter_plugin_printer** – Plugin d'impression

### Utilitaires
- **pdf** – Génération de PDFs
- **intl** – Internationalisation
- **image_picker** – Sélection d'images
- **device_info_plus** – Informations sur l'appareil

## 📚 Documentation

### Wiki

Consultez le [Wiki](./wiki/) pour une documentation détaillée :

- [Guide d'installation](./wiki/01-getting-started/installation.md)
- [Configuration Firebase](./wiki/02-configuration/firebase.md)
- [Architecture de l'application](./wiki/03-architecture/overview.md)
- [Guide de développement](./wiki/04-development/guidelines.md)
- [Guide des modules](./wiki/05-modules/overview.md)
- [Gestion des permissions](./wiki/06-permissions/overview.md)
- [Mode offline](./wiki/07-offline/synchronization.md)
- [Impression thermique](./wiki/08-printing/sunmi-integration.md)

### README par module

Chaque module contient son propre README avec des détails spécifiques :

- [Module Administration](./lib/features/administration/README.md)
- [Module Eau Minérale](./lib/features/eau_minerale/README.md)
- [Module Gaz](./lib/features/gaz/README.md)
- [Module Orange Money](./lib/features/orange_money/README.md)
- [Module Immobilier](./lib/features/immobilier/README.md)
- [Module Boutique](./lib/features/boutique/README.md)

## 🎨 Design & UX

L'application suit des principes de design professionnel :

- **Cohérence visuelle** – Palette de couleurs uniforme, styles de boutons cohérents
- **Typographie claire** – Hiérarchie visuelle bien définie
- **Navigation intuitive** – Navigation adaptative (Rail/Bar selon la taille d'écran)
- **Formulaires user-friendly** – Validation et messages d'erreur clairs
- **Listes performantes** – Filtrage, tri et recherche rapide
- **Support offline** – Indicateurs visuels de synchronisation

## 🔒 Sécurité & Permissions

- Authentification sécurisée via Firebase Auth
- Système de rôles et permissions granulaire par module
- Audit trail pour toutes les actions critiques
- Gestion multi-tenant avec isolation des données

Voir [Wiki - Permissions](./wiki/06-permissions/overview.md) pour plus de détails.

## 📱 Support des plateformes

- ✅ Android
- ✅ iOS
- ✅ Web (partiel)
- ✅ Linux (partiel)
- ✅ macOS (partiel)
- ✅ Windows (partiel)

## 🧪 Tests

```bash
# Lancer tous les tests
flutter test

# Lancer les tests avec couverture
flutter test --coverage
```

## 📦 Build

### Android
```bash
flutter build apk --release
# ou
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contribution

1. Créer une branche depuis `main`
2. Développer la fonctionnalité
3. S'assurer que les tests passent
4. Créer une pull request

### Standards de code

- Respecter les règles définies dans `analysis_options.yaml`
- Aucun fichier > 200 lignes
- Découper les écrans complexes en widgets enfants
- Documenter les APIs publiques
- Suivre les conventions Dart/Flutter

## 📄 Licence

[À définir]

## 👥 Équipe

ELYF Group Development Team

## 📞 Support

Pour toute question ou problème, consultez le [Wiki](./wiki/) ou créez une issue sur le repository.

---

**Version:** 1.0.0  
**Dernière mise à jour:** 2024
