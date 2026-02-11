# Séparation des Responsabilités

## Règle : Pas de Logique Métier dans l'UI

**❌ Mauvais** :
```dart
Widget build(BuildContext context) {
  final total = sales.fold(0, (sum, s) => sum + s.totalPrice);
  // ...
}
```

**✅ Bon** :
```dart
// Dans un service
class DashboardCalculationService {
  int calculateTotalRevenue(List<Sale> sales) {
    return sales.fold(0, (sum, s) => sum + s.totalPrice);
  }
}

// Dans le widget
Widget build(BuildContext context) {
  final total = ref.watch(dashboardCalculationServiceProvider)
      .calculateTotalRevenue(sales);
  // ...
}
```

## Services de Calcul

Services créés pour extraire la logique métier :
- `DashboardCalculationService` : Calculs de dashboard
- `ReportCalculationService` : Calculs de rapports
- `SaleService` : Logique de vente
- `ProductionService` : Logique de production
- `ProductCalculationService` : Calculs de produits
