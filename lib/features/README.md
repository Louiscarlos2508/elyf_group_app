# Features

Organisation par module fonctionnel. Chaque module utilise la même structure :

- `presentation/` – écrans + widgets découpés (<200 lignes).
- `application/` – contrôleurs Riverpod (`StateNotifier`, `AsyncNotifier`).
- `domain/` – entités, value objects, use cases.
- `data/` – repositories + data sources (remote/local).

## Structure `features/` vs `modules/`

**Note importante** : Le projet utilise `lib/features/` au lieu de `lib/modules/` comme recommandé dans certaines architectures Flutter.

**Justification** :
- `features/` est une meilleure pratique moderne dans l'écosystème Flutter/Dart
- Aligné avec les recommandations de l'architecture Clean Architecture et Feature-First
- Plus cohérent avec les conventions de packages Dart modernes
- Meilleure séparation des préoccupations (chaque feature est autonome)

**Avantages** :
- Chaque feature est isolée et peut être développée/testée indépendamment
- Facilite la modularisation et la réutilisation
- Structure plus claire pour les développeurs
- Compatible avec les outils de génération de code Flutter

**Modules prévus** :

- `dashboard/`
- `eau_minerale/`
- `gaz/`
- `orange_money/`
- `immobilier/`
- `boutique/`
- `audit_trail/`
- `notifications/`

Chaque dossier contient un `README.md` décrivant les fichiers à créer après
réception des spécifications détaillées.

