# Guide de Correction des Duplications dans les Repositories

## Problème Identifié

Lors de la mise à jour d'entités, certains repositories génèrent un nouveau `localId` au lieu de rechercher et réutiliser le `localId` existant, ce qui crée des duplications dans la base de données.

## Solution Implémentée

Une méthode utilitaire `findExistingLocalId` a été ajoutée dans la classe de base `OfflineRepository` pour rechercher l'entité existante avant de générer un nouveau `localId`.

## Repositories Corrigés

### Module Gaz ✅
- ✅ `tour_offline_repository.dart` - Utilise `findExistingLocalId`
- ✅ `gas_offline_repository.dart` - `updateCylinder` corrigé
- ✅ `gas_sale_offline_repository.dart` - Utilise `findExistingLocalId`
- ✅ `expense_offline_repository.dart` - Utilise `findExistingLocalId`
- ✅ `financial_report_offline_repository.dart` - Utilise `findExistingLocalId`
- ✅ `cylinder_stock_offline_repository.dart` - Utilise `findExistingLocalId`
- ✅ `cylinder_leak_offline_repository.dart` - Utilise `findExistingLocalId`
- ✅ `point_of_sale_offline_repository.dart` - Utilise `findExistingLocalId`
- ⚠️ `gaz_settings_offline_repository.dart` - Pas de problème (ID déterministe)

## Pattern de Correction

Pour chaque repository, remplacer :

```dart
@override
Future<void> saveToLocal(T entity) async {
  final localId = getLocalId(entity);  // ❌ Génère toujours un nouveau localId
  final remoteId = getRemoteId(entity);
  final map = toMap(entity)..['localId'] = localId;
  await driftService.records.upsert(...);
}
```

Par :

```dart
@override
Future<void> saveToLocal(T entity) async {
  // Utiliser la méthode utilitaire pour trouver le localId existant
  final existingLocalId = await findExistingLocalId(entity, moduleType: moduleType);
  final localId = existingLocalId ?? getLocalId(entity);
  final remoteId = getRemoteId(entity);
  final map = toMap(entity)..['localId'] = localId..['id'] = localId;
  await driftService.records.upsert(...);
}
```

## Repositories à Corriger

### Module Eau Minérale
- [ ] `finance_offline_repository.dart`
- [ ] `sale_offline_repository.dart`
- [ ] `product_offline_repository.dart`
- [ ] `inventory_offline_repository.dart`
- [ ] `machine_offline_repository.dart`
- [ ] `bobine_stock_offline_repository.dart`
- [ ] `stock_offline_repository.dart`
- [ ] `packaging_stock_offline_repository.dart`
- [ ] `salary_offline_repository.dart`
- [ ] `daily_worker_offline_repository.dart`
- [ ] `production_session_offline_repository.dart`
- [ ] `credit_offline_repository.dart`
- [ ] `customer_offline_repository.dart`
- [ ] `bobine_stock_quantity_offline_repository.dart`
- [ ] `activity_offline_repository.dart`

### Module Boutique
- [ ] `purchase_offline_repository.dart`
- [ ] `product_offline_repository.dart`
- [ ] `expense_offline_repository.dart`
- [ ] `sale_offline_repository.dart`
- [ ] `stock_offline_repository.dart`
- [ ] `report_offline_repository.dart`

### Module Immobilier
- [ ] `property_expense_offline_repository.dart`
- [ ] `property_offline_repository.dart`
- [ ] `tenant_offline_repository.dart`
- [ ] `contract_offline_repository.dart`
- [ ] `payment_offline_repository.dart`

### Module Orange Money
- [ ] `liquidity_offline_repository.dart`
- [ ] `transaction_offline_repository.dart`
- [ ] `commission_offline_repository.dart`
- [ ] `settings_offline_repository.dart`
- [ ] `agent_offline_repository.dart`

### Module Administration
- [ ] `user_offline_repository.dart`
- [ ] `enterprise_offline_repository.dart`
- [ ] `admin_offline_repository.dart`

## Notes Importantes

1. **ModuleType requis** : La méthode `findExistingLocalId` nécessite le `moduleType` en paramètre. Assurez-vous que chaque repository a accès à son `moduleType`.

2. **ID déterministe** : Certains repositories (comme `gaz_settings`) utilisent un ID déterministe basé sur des champs de l'entité. Ces repositories n'ont pas besoin de correction.

3. **Mise à jour de l'ID dans le JSON** : N'oubliez pas d'ajouter `..['id'] = localId` dans le map pour s'assurer que l'ID dans le JSON correspond au localId.

4. **Logs** : Les logs sont automatiquement ajoutés par `findExistingLocalId` pour faciliter le débogage.

## Vérification

Après correction, vérifiez que :
- ✅ Les entités sont mises à jour au lieu d'être dupliquées
- ✅ Les logs montrent "Entité existante trouvée" lors des mises à jour
- ✅ Aucune duplication n'apparaît dans les listes
