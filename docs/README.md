# Documentation du Projet Elyf Group App

Ce dossier contient toute la documentation du projet.

## Guides Disponibles

### [Guide des Patterns](./PATTERNS_GUIDE.md)

Guide complet des patterns et conventions utilisés dans le projet :
- Architecture des modules
- State Management avec Riverpod
- Découpage des widgets
- Gestion d'erreurs
- Stockage sécurisé
- Formatage
- Multi-tenant
- Conventions de nommage

### [Référence de l'API](./API_REFERENCE.md)

Documentation complète des APIs publiques :
- Services Core (Auth, Storage, Errors, Offline, Printing)
- Controllers des features
- Helpers de formatage
- Patterns d'utilisation
- Exemples de code

## Structure de Documentation

```
docs/
├── README.md              # Ce fichier
├── PATTERNS_GUIDE.md      # Guide des patterns
└── API_REFERENCE.md       # Référence de l'API

lib/
├── core/
│   ├── README.md          # Documentation du core
│   ├── auth/README.md     # Documentation de l'authentification
│   ├── offline/README.md  # Documentation offline-first
│   └── ...
└── features/
    ├── README.md          # Documentation des features
    └── <module>/README.md # Documentation de chaque module
```

## Principes de Documentation

1. **Doc Comments** : Toutes les classes publiques doivent avoir des doc comments
2. **Paramètres** : Toutes les méthodes publiques doivent documenter leurs paramètres
3. **Exemples** : Inclure des exemples d'utilisation quand c'est pertinent
4. **Mise à jour** : La documentation doit être mise à jour avec le code

## Contribution

Lors de l'ajout de nouvelles fonctionnalités :

1. Ajouter des doc comments aux classes et méthodes publiques
2. Mettre à jour les guides pertinents si nécessaire
3. Ajouter des exemples d'utilisation dans la référence API

## Ressources Externes

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Isar Documentation](https://isar.dev)
- [Firebase Documentation](https://firebase.google.com/docs)

