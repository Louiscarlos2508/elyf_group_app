# Features

Organisation par module fonctionnel. Chaque module utilise la même structure :

- `presentation/` – écrans + widgets découpés (<200 lignes).
- `application/` – contrôleurs Riverpod (`StateNotifier`, `AsyncNotifier`).
- `domain/` – entités, value objects, use cases.
- `data/` – repositories + data sources (remote/local).

Modules prévus :

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

