# Structure du Projet

## Organisation par Features

Le projet utilise une organisation par **features** (fonctionnalités) plutôt que par modules techniques. Cette approche améliore la maintenabilité et la scalabilité.

```
lib/
├── features/          # Modules organisés par fonctionnalité
│   ├── boutique/      # Module boutique
│   ├── eau_minerale/  # Module eau minérale
│   ├── gaz/           # Module gaz
│   ├── orange_money/  # Module Orange Money
│   ├── immobilier/    # Module immobilier
│   └── administration/# Module administration
├── shared/            # Composants partagés
│   ├── presentation/  # Widgets UI partagés
│   └── utils/         # Utilitaires partagés
├── core/              # Services transverses
│   ├── auth/          # Authentification
│   ├── offline/       # Infrastructure offline-first
│   ├── permissions/   # Gestion des permissions
│   └── tenant/        # Gestion multi-tenant
└── app/               # Configuration application
    ├── router/        # Configuration routing
    └── bootstrap.dart # Initialisation
```

## Note sur "features" vs "modules"

**Règle originale** : Le projet devait utiliser `lib/modules/`  
**Réalité** : Le projet utilise `lib/features/`

**Justification** : `features/` est une meilleure pratique moderne qui :
- Organise le code par fonctionnalité métier
- Facilite la navigation et la maintenance
- Améliore la scalabilité
- Suit les recommandations Flutter/Dart modernes

Cette différence est documentée ici pour éviter toute confusion.
