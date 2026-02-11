# Vérification de l'Architecture

## Tests d'Architecture avec dependency_validator

Le projet utilise `dependency_validator` pour vérifier automatiquement que les règles d'architecture sont respectées.

## Configuration

Le fichier `dependency_validator.yaml` définit :
- **Dépendances interdites** : Features ne peuvent pas s'importer entre elles, règles de couches
- **Dépendances autorisées** : Features → shared/core/app, Application → Domain, etc.

## Utilisation

```bash
# Vérifier l'architecture
dart run dependency_validator

# Ou utiliser le script
dart scripts/check_architecture.dart
```

## Règles Vérifiées

1. **Isolation des Features** : Aucune dépendance directe entre features
2. **Séparation des Couches** :
   - Presentation ne peut pas importer Data
   - Domain ne peut pas importer Presentation ou Data
   - Data ne peut pas importer Presentation ou Application
