# Structure de la Documentation - ELYF Group App

**Dernière mise à jour** : Janvier 2026

## 📚 Organisation de la Documentation

La documentation du projet est organisée en plusieurs niveaux :

### 1. Documentation Racine

- **README.md** - Vue d'ensemble du projet, installation, structure
- **PROJECT_AUDIT_REPORT.md** - Audit technique complet du projet (mise à jour régulière)
- **ENV_SETUP.md** - Configuration de l'environnement
- **AUTHENTICATION_SETUP.md** - Configuration de l'authentification

### 2. Documentation Wiki (`wiki/`)

Documentation structurée par catégories :

- **01-getting-started/** - Installation et premiers pas
- **02-configuration/** - Configuration Firebase et environnement
- **03-architecture/** - Architecture générale, state management, navigation, multi-tenant
- **04-development/** - Guidelines, structure des modules, widgets, tests
- **05-modules/** - Documentation spécifique de chaque module
- **06-permissions/** - Système de permissions
- **07-offline/** - Mode offline-first, Drift, synchronisation
- **08-printing/** - Intégration Sunmi, templates, dépannage

### 3. Documentation Technique (`docs/`)

- **README.md** - Index de la documentation technique
- **ARCHITECTURE.md** - Architecture détaillée avec diagrammes
- **PATTERNS_GUIDE.md** - Guide des patterns et conventions
- **API_REFERENCE.md** - Référence complète des APIs
- **OFFLINE_REPOSITORY_MIGRATION.md** - Guide de migration offline-first
- **FIREBASE_ACTION_PLAN.md** - Plan d'action Firebase
- **adr/** - Architecture Decision Records (ADR)

### 4. Documentation par Module (`lib/features/*/`)

Chaque module contient sa propre documentation :

- **README.md** - Vue d'ensemble du module
- **ARCHITECTURE.md** - Architecture spécifique au module
- **IMPLEMENTATION.md** - Statut d'implémentation
- **DEVELOPMENT.md** - Guide de développement (si applicable)
- **SECURITY.md** - Sécurité et permissions (si applicable)
- **AUDIT_REPORT.md** - Audit spécifique au module (si applicable)

### 5. Documentation Core (`lib/core/*/`)

Documentation des services transverses :

- **README.md** - Documentation du service
- **INTEGRATION_GUIDE.md** - Guide d'intégration (si applicable)
- **SUNMI_SDK_INTEGRATION.md** - Documentation Sunmi (printing)

### 6. Documentation Shared (`lib/shared/*/`)

Documentation des composants partagés :

- **README.md** - Documentation du composant
- **README_ACCESSIBILITY.md** - Accessibilité (utils)

## 🔄 Maintenance de la Documentation

### Dates et Versions

- Toutes les dates doivent être mises à jour régulièrement
- Format de date : "Janvier 2026" ou "9 Janvier 2026" selon le contexte
- Version du projet : `1.0.0+1` (définie dans `pubspec.yaml`)

### Fichiers Obsolètes

Les fichiers suivants sont considérés comme historiques/obsolètes :

- `lib/core/auth/COMPARISON_AND_RECOMMENDATION.md` - Architecture implémentée
- `lib/core/auth/ARCHITECTURE_PROPOSAL.md` - Architecture implémentée

Ces fichiers peuvent être conservés pour référence historique mais ne doivent plus être mis à jour.

### Doublons et Redondances

- **docs/ARCHITECTURE.md** vs **wiki/03-architecture/overview.md** :
  - `docs/ARCHITECTURE.md` : Documentation technique détaillée avec diagrammes
  - `wiki/03-architecture/overview.md` : Guide concis pour développeurs
  - Les deux sont complémentaires et doivent être maintenus

- **PROJECT_AUDIT_REPORT.md** vs **lib/features/administration/AUDIT_REPORT.md** :
  - `PROJECT_AUDIT_REPORT.md` : Audit global du projet
  - `lib/features/administration/AUDIT_REPORT.md` : Audit spécifique au module administration
  - Les deux sont complémentaires

## 📝 Principes de Documentation

1. **Doc Comments** : Toutes les classes publiques doivent avoir des doc comments
2. **Paramètres** : Toutes les méthodes publiques doivent documenter leurs paramètres
3. **Exemples** : Inclure des exemples d'utilisation quand c'est pertinent
4. **Mise à jour** : La documentation doit être mise à jour avec le code
5. **Cohérence** : Utiliser un format cohérent pour les dates et versions

## 🔗 Références Croisées

Les fichiers de documentation doivent référencer les autres documents pertinents :

- README.md principal → Wiki, docs/, modules
- Wiki → README.md, docs/ pour détails techniques
- Modules → Wiki pour architecture générale
- Core → Wiki pour patterns partagés

## ✅ Checklist de Maintenance

Lors de la mise à jour de la documentation :

- [ ] Mettre à jour les dates
- [ ] Vérifier les références croisées
- [ ] Supprimer les informations obsolètes
- [ ] Ajouter les nouvelles fonctionnalités
- [ ] Vérifier la cohérence avec le code
- [ ] Mettre à jour les exemples de code si nécessaire

