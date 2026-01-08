# Référence de l'API Publique

Ce document décrit les APIs publiques principales du projet Elyf Group App.

## Core Services

### Authentication

#### `AuthService`

Service d'authentification utilisant le stockage sécurisé et le hashage de mots de passe.

**Méthodes principales** :

- `initialize()` : Initialise le service et migre les données depuis SharedPreferences
- `signInWithEmailAndPassword({required String email, required String password})` : Connexion avec email et mot de passe
- `signOut()` : Déconnexion de l'utilisateur actuel
- `reloadUser()` : Recharge l'utilisateur depuis le stockage sécurisé

**Propriétés** :

- `currentUser` : L'utilisateur actuellement connecté
- `isAuthenticated` : Indique si un utilisateur est connecté

**Providers Riverpod** :

- `authServiceProvider` : Provider pour le service d'authentification
- `currentUserProvider` : Provider pour l'utilisateur actuel (FutureProvider)
- `currentUserIdProvider` : Provider pour l'ID de l'utilisateur actuel
- `isAuthenticatedProvider` : Provider pour vérifier si l'utilisateur est connecté
- `isAdminProvider` : Provider pour vérifier si l'utilisateur est admin

### Storage

#### `SecureStorageService`

Service pour stocker des données sensibles de manière sécurisée.

**Méthodes** :

- `write(String key, String? value)` : Sauvegarde une valeur
- `read(String key)` : Récupère une valeur
- `delete(String key)` : Supprime une valeur
- `deleteAll()` : Supprime toutes les valeurs
- `containsKey(String key)` : Vérifie si une clé existe
- `readAll()` : Récupère toutes les clés/valeurs

### Error Handling

#### `ErrorHandler`

Gestionnaire centralisé d'erreurs.

**Méthodes** :

- `handleError(dynamic error, [StackTrace? stackTrace])` : Convertit une exception en AppException
- `getUserMessage(AppException exception)` : Obtient un message utilisateur-friendly
- `getErrorTitle(AppException exception)` : Obtient un titre pour l'erreur

**Types d'exceptions** :

- `NetworkException` : Erreurs de réseau
- `AuthenticationException` : Erreurs d'authentification
- `AuthorizationException` : Erreurs d'autorisation
- `ValidationException` : Erreurs de validation
- `NotFoundException` : Ressources non trouvées
- `StorageException` : Erreurs de stockage
- `SyncException` : Erreurs de synchronisation
- `UnknownException` : Erreurs inconnues

#### `ErrorLogger`

Logger centralisé pour les erreurs.

**Méthodes** :

- `logError(Object error, [StackTrace? stackTrace, String? context])` : Log une erreur
- `logAppException(AppException exception, [String? context])` : Log une AppException
- `logWarning(String message, [String? context])` : Log un warning
- `logInfo(String message, [String? context])` : Log une information

#### `AppErrorWidget`

Widget pour afficher une erreur de manière uniforme.

**Paramètres** :

- `error` : L'exception à afficher
- `onRetry` : Callback optionnel pour réessayer
- `compact` : Mode compact (défaut: false)

### Offline

#### `DriftService`

Service pour gérer la base de données locale Drift (SQLite).

**Méthodes principales** :

- `initialize()` : Initialise la base SQLite via Drift
- `db` : Accès à la base Drift
- `records` : DAO générique (`OfflineRecords`) utilisé par les repositories offline

#### `ConnectivityService`

Service pour surveiller la connectivité réseau.

**Méthodes** :

- `isConnected` : Stream de la connectivité actuelle
- `checkConnectivity()` : Vérifie la connectivité actuelle

### Printing

#### `SunmiV3Service`

Service pour l'impression sur imprimante Sunmi V3.

**Méthodes** :

- `isSunmiDevice` : Vérifie si l'appareil est une imprimante Sunmi
- `isPrinterAvailable()` : Vérifie si l'imprimante est disponible
- `printReceipt(String content)` : Imprime un reçu

## Features

### Eau Minérale

#### `EauMineraleInvoiceService`

Service pour l'impression de factures eau minérale.

**Méthodes** :

- `isSunmiAvailable()` : Vérifie si l'imprimante Sunmi est disponible
- `printSaleInvoice(Sale sale)` : Imprime une facture de vente
- `printCreditPaymentReceipt(...)` : Imprime un reçu de paiement crédit
- `generateSalePdf(Sale sale)` : Génère un PDF de facture de vente
- `generateCreditPaymentPdf(...)` : Génère un PDF de reçu de paiement crédit

### Orange Money

#### Controllers

- `AgentsController` : Gestion des agents Orange Money
- `TransactionsController` : Gestion des transactions

### Gaz

#### Controllers

- `SalesController` : Gestion des ventes de gaz
- `StockController` : Gestion du stock de gaz

### Immobilier

#### Controllers

- `ContractsController` : Gestion des contrats de location
- `PropertiesController` : Gestion des propriétés
- `TenantsController` : Gestion des locataires
- `PaymentsController` : Gestion des paiements

## Helpers

### Formatage

#### `InvoicePrintHelpers`

Helpers pour le formatage des factures.

**Méthodes statiques** :

- `formatCurrency(int amount)` : Formate un montant en FCFA
- `formatDate(DateTime date)` : Formate une date
- `formatTime(DateTime date)` : Formate une heure
- `centerText(String text, [int width])` : Centre un texte
- `truncateId(String id)` : Tronque un ID

#### `ForecastReportHelpers`

Helpers pour les calculs de prévisions.

**Méthodes statiques** :

- `formatCurrency(int amount)` : Formate un montant
- `groupByWeek(List<Sale> sales, DateTime startDate)` : Groupe les ventes par semaine
- `calculateTrend(List<double> data)` : Calcule la tendance
- `projectWeeks(double average, double trend, int weeks)` : Projette les semaines futures
- `calculateVariance(List<double> data, double mean)` : Calcule la variance

## Patterns d'Utilisation

### Gestion d'Erreurs

```dart
import 'package:elyf_groupe_app/core/errors/errors.dart';

try {
  // Code qui peut échouer
} catch (e, stackTrace) {
  final appException = ErrorHandler.instance.handleError(e, stackTrace);
  ErrorLogger.instance.logError(e, stackTrace, 'Context');
  
  // Afficher l'erreur
  showDialog(
    context: context,
    builder: (_) => AppErrorWidget(
      error: appException,
      onRetry: () {
        // Réessayer
      },
    ),
  );
}
```

### Utilisation avec Riverpod

```dart
final myDataProvider = FutureProvider<List<Data>>((ref) async {
  try {
    return await repository.fetchData();
  } catch (e, stackTrace) {
    ErrorLogger.instance.logError(e, stackTrace, 'fetchData');
    rethrow;
  }
});

// Dans un widget
class MyWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(myDataProvider);
    
    return dataAsync.when(
      data: (data) => DataList(data: data),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => AsyncErrorWidget(
        error: error,
        stackTrace: stack,
        onRetry: () => ref.refresh(myDataProvider),
      ),
    );
  }
}
```

### Stockage Sécurisé

```dart
final storage = SecureStorageService();

// Écrire
await storage.write('user_token', token);

// Lire
final token = await storage.read('user_token');

// Supprimer
await storage.delete('user_token');
```

## Conventions

- Tous les services publics doivent avoir des doc comments
- Les méthodes publiques doivent documenter leurs paramètres
- Les exceptions doivent être loggées avec `ErrorLogger`
- Les erreurs doivent être affichées avec `AppErrorWidget` ou `AsyncErrorWidget`


Ce document décrit les APIs publiques principales du projet Elyf Group App.

## Core Services

### Authentication

#### `AuthService`

Service d'authentification utilisant le stockage sécurisé et le hashage de mots de passe.

**Méthodes principales** :

- `initialize()` : Initialise le service et migre les données depuis SharedPreferences
- `signInWithEmailAndPassword({required String email, required String password})` : Connexion avec email et mot de passe
- `signOut()` : Déconnexion de l'utilisateur actuel
- `reloadUser()` : Recharge l'utilisateur depuis le stockage sécurisé

**Propriétés** :

- `currentUser` : L'utilisateur actuellement connecté
- `isAuthenticated` : Indique si un utilisateur est connecté

**Providers Riverpod** :

- `authServiceProvider` : Provider pour le service d'authentification
- `currentUserProvider` : Provider pour l'utilisateur actuel (FutureProvider)
- `currentUserIdProvider` : Provider pour l'ID de l'utilisateur actuel
- `isAuthenticatedProvider` : Provider pour vérifier si l'utilisateur est connecté
- `isAdminProvider` : Provider pour vérifier si l'utilisateur est admin

### Storage

#### `SecureStorageService`

Service pour stocker des données sensibles de manière sécurisée.

**Méthodes** :

- `write(String key, String? value)` : Sauvegarde une valeur
- `read(String key)` : Récupère une valeur
- `delete(String key)` : Supprime une valeur
- `deleteAll()` : Supprime toutes les valeurs
- `containsKey(String key)` : Vérifie si une clé existe
- `readAll()` : Récupère toutes les clés/valeurs

### Error Handling

#### `ErrorHandler`

Gestionnaire centralisé d'erreurs.

**Méthodes** :

- `handleError(dynamic error, [StackTrace? stackTrace])` : Convertit une exception en AppException
- `getUserMessage(AppException exception)` : Obtient un message utilisateur-friendly
- `getErrorTitle(AppException exception)` : Obtient un titre pour l'erreur

**Types d'exceptions** :

- `NetworkException` : Erreurs de réseau
- `AuthenticationException` : Erreurs d'authentification
- `AuthorizationException` : Erreurs d'autorisation
- `ValidationException` : Erreurs de validation
- `NotFoundException` : Ressources non trouvées
- `StorageException` : Erreurs de stockage
- `SyncException` : Erreurs de synchronisation
- `UnknownException` : Erreurs inconnues

#### `ErrorLogger`

Logger centralisé pour les erreurs.

**Méthodes** :

- `logError(Object error, [StackTrace? stackTrace, String? context])` : Log une erreur
- `logAppException(AppException exception, [String? context])` : Log une AppException
- `logWarning(String message, [String? context])` : Log un warning
- `logInfo(String message, [String? context])` : Log une information

#### `AppErrorWidget`

Widget pour afficher une erreur de manière uniforme.

**Paramètres** :

- `error` : L'exception à afficher
- `onRetry` : Callback optionnel pour réessayer
- `compact` : Mode compact (défaut: false)

### Offline

#### `DriftService`

Service pour gérer la base de données locale Drift (SQLite).

**Méthodes principales** :

- `initialize()` : Initialise la base SQLite via Drift
- `db` : Accès à la base Drift
- `records` : DAO générique (`OfflineRecords`) utilisé par les repositories offline

#### `ConnectivityService`

Service pour surveiller la connectivité réseau.

**Méthodes** :

- `isConnected` : Stream de la connectivité actuelle
- `checkConnectivity()` : Vérifie la connectivité actuelle

### Printing

#### `SunmiV3Service`

Service pour l'impression sur imprimante Sunmi V3.

**Méthodes** :

- `isSunmiDevice` : Vérifie si l'appareil est une imprimante Sunmi
- `isPrinterAvailable()` : Vérifie si l'imprimante est disponible
- `printReceipt(String content)` : Imprime un reçu

## Features

### Eau Minérale

#### `EauMineraleInvoiceService`

Service pour l'impression de factures eau minérale.

**Méthodes** :

- `isSunmiAvailable()` : Vérifie si l'imprimante Sunmi est disponible
- `printSaleInvoice(Sale sale)` : Imprime une facture de vente
- `printCreditPaymentReceipt(...)` : Imprime un reçu de paiement crédit
- `generateSalePdf(Sale sale)` : Génère un PDF de facture de vente
- `generateCreditPaymentPdf(...)` : Génère un PDF de reçu de paiement crédit

### Orange Money

#### Controllers

- `AgentsController` : Gestion des agents Orange Money
- `TransactionsController` : Gestion des transactions

### Gaz

#### Controllers

- `SalesController` : Gestion des ventes de gaz
- `StockController` : Gestion du stock de gaz

### Immobilier

#### Controllers

- `ContractsController` : Gestion des contrats de location
- `PropertiesController` : Gestion des propriétés
- `TenantsController` : Gestion des locataires
- `PaymentsController` : Gestion des paiements

## Helpers

### Formatage

#### `InvoicePrintHelpers`

Helpers pour le formatage des factures.

**Méthodes statiques** :

- `formatCurrency(int amount)` : Formate un montant en FCFA
- `formatDate(DateTime date)` : Formate une date
- `formatTime(DateTime date)` : Formate une heure
- `centerText(String text, [int width])` : Centre un texte
- `truncateId(String id)` : Tronque un ID

#### `ForecastReportHelpers`

Helpers pour les calculs de prévisions.

**Méthodes statiques** :

- `formatCurrency(int amount)` : Formate un montant
- `groupByWeek(List<Sale> sales, DateTime startDate)` : Groupe les ventes par semaine
- `calculateTrend(List<double> data)` : Calcule la tendance
- `projectWeeks(double average, double trend, int weeks)` : Projette les semaines futures
- `calculateVariance(List<double> data, double mean)` : Calcule la variance

## Patterns d'Utilisation

### Gestion d'Erreurs

```dart
import 'package:elyf_groupe_app/core/errors/errors.dart';

try {
  // Code qui peut échouer
} catch (e, stackTrace) {
  final appException = ErrorHandler.instance.handleError(e, stackTrace);
  ErrorLogger.instance.logError(e, stackTrace, 'Context');
  
  // Afficher l'erreur
  showDialog(
    context: context,
    builder: (_) => AppErrorWidget(
      error: appException,
      onRetry: () {
        // Réessayer
      },
    ),
  );
}
```

### Utilisation avec Riverpod

```dart
final myDataProvider = FutureProvider<List<Data>>((ref) async {
  try {
    return await repository.fetchData();
  } catch (e, stackTrace) {
    ErrorLogger.instance.logError(e, stackTrace, 'fetchData');
    rethrow;
  }
});

// Dans un widget
class MyWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(myDataProvider);
    
    return dataAsync.when(
      data: (data) => DataList(data: data),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => AsyncErrorWidget(
        error: error,
        stackTrace: stack,
        onRetry: () => ref.refresh(myDataProvider),
      ),
    );
  }
}
```

### Stockage Sécurisé

```dart
final storage = SecureStorageService();

// Écrire
await storage.write('user_token', token);

// Lire
final token = await storage.read('user_token');

// Supprimer
await storage.delete('user_token');
```

## Conventions

- Tous les services publics doivent avoir des doc comments
- Les méthodes publiques doivent documenter leurs paramètres
- Les exceptions doivent être loggées avec `ErrorLogger`
- Les erreurs doivent être affichées avec `AppErrorWidget` ou `AsyncErrorWidget`

