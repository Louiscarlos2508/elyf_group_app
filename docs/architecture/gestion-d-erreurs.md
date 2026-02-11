# Gestion d'Erreurs

## ErrorHandler

Système centralisé de gestion d'erreurs :
- `ErrorHandler` : Gestionnaire centralisé
- `AppException` : Exceptions de base
- Types d'erreurs : `NetworkException`, `ValidationException`, etc.

## Utilisation

```dart
try {
  // ...
} catch (error, stackTrace) {
  final appException = ErrorHandler.instance.handleError(error, stackTrace);
  // Afficher l'erreur à l'utilisateur
}
```
