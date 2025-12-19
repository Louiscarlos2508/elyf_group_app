# Widgets réutilisables

Guide sur les widgets partagés disponibles dans ELYF Group App.

## Vue d'ensemble

Les widgets réutilisables sont dans `lib/shared/presentation/widgets/` et peuvent être utilisés dans tous les modules.

## Widgets disponibles

### AdaptiveNavigationScaffold

Navigation adaptative selon la taille d'écran :

```dart
AdaptiveNavigationScaffold(
  destinations: [
    NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
    NavigationDestination(icon: Icon(Icons.list), label: 'Liste'),
  ],
  child: YourContent(),
)
```

### RefreshButton

Bouton de rafraîchissement avec indicateur de chargement :

```dart
RefreshButton(
  onRefresh: () async {
    ref.invalidate(productsProvider);
  },
)
```

### FileAttachmentField

Champ pour attacher des fichiers :

```dart
FileAttachmentField(
  onFileSelected: (file) {
    // Gérer le fichier
  },
  allowedExtensions: ['pdf', 'jpg', 'png'],
)
```

### AttachedFileItem

Affichage d'un fichier attaché :

```dart
AttachedFileItem(
  file: attachedFile,
  onDelete: () {
    // Supprimer le fichier
  },
)
```

### ExpenseBalanceChart

Graphique pour balance des dépenses :

```dart
ExpenseBalanceChart(
  expenses: expenses,
  income: income,
)
```

### StockReportSummary

Résumé de rapport de stock :

```dart
StockReportSummary(
  totalProducts: 150,
  totalValue: 5000000,
  lowStockItems: 5,
)
```

### StockReportTable

Tableau de rapport de stock :

```dart
StockReportTable(
  products: products,
  onProductTap: (product) {
    // Action sur produit
  },
)
```

### ModuleLoadingAnimation

Animation de chargement pour les modules :

```dart
ModuleLoadingAnimation(
  message: 'Chargement des données...',
)
```

## Créer un widget réutilisable

### Structure

```dart
// lib/shared/presentation/widgets/mon_widget.dart
class MonWidget extends StatelessWidget {
  const MonWidget({
    super.key,
    required this.data,
    this.onTap,
  });
  
  final Data data;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Widget content
      ),
    );
  }
}
```

### Bonnes pratiques

1. **Props claires** – Paramètres explicites
2. **Documentation** – Commentaires pour usage
3. **Const constructors** – Performance
4. **Thème** – Utiliser Theme.of(context)
5. **Accessibilité** – Semantics widgets

### Exemple complet

```dart
/// Widget réutilisable pour afficher une carte de produit.
/// 
/// Affiche les informations principales d'un produit avec
/// support du thème et de l'accessibilité.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onLongPress,
  });
  
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${product.price} FCFA',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Utilisation

### Import

```dart
import 'package:elyf_groupe_app/shared/presentation/widgets/product_card.dart';
```

### Dans un écran

```dart
class ProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(
        product: products[index],
        onTap: () => navigateToDetail(products[index]),
      ),
    );
  }
}
```

## Prochaines étapes

- [Tests](./testing.md)
- [Guidelines](./guidelines.md)
