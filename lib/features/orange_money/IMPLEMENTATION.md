# Guide d'Implémentation - Module Orange Money

## Vue d'ensemble

Ce guide explique comment implémenter de nouvelles fonctionnalités dans le module Orange Money.

## 🏗️ Patterns d'Implémentation

### 1. Créer un OfflineRepository

Suivre le même pattern que les autres modules. Voir `IMPLEMENTATION.md` du module eau_minerale pour le template complet.

### 2. Créer un Controller

```dart
class XController {
  XController(this._repository);

  final XRepository _repository;

  Future<List<X>> fetchAll() async {
    return await _repository.fetchAll();
  }
}
```

### 3. Créer un Provider

```dart
final xRepositoryProvider = Provider<XRepository>(
  (ref) {
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? 'default';
    final driftService = DriftService.instance;
    final syncManager = ref.watch(syncManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    
    return XOfflineRepository(
      driftService: driftService,
      syncManager: syncManager,
      connectivityService: connectivityService,
      enterpriseId: enterpriseId,
    );
  },
);
```

## ✅ Repositories Migrés

- ✅ `TransactionOfflineRepository`
- ✅ `AgentOfflineRepository`
- ✅ `CommissionOfflineRepository`
- ✅ `LiquidityOfflineRepository`
- ✅ `SettingsOfflineRepository`

## 📝 Best Practices

1. Toujours utiliser les Controllers depuis l'UI
2. Gérer les erreurs avec ErrorHandler
3. Utiliser enterpriseId depuis activeEnterpriseProvider
4. Logger les actions importantes avec developer.log

