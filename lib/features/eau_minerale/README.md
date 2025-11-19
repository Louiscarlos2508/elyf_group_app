# Feature › Eau Minérale

Structure modulaire pour la gestion de la production d’eau en sachet :

- `presentation/` — écrans et widgets (shell + sous-modules).
- `application/` — providers Riverpod, contrôleurs et navigation interne.
- `domain/` — entités, value objects et interfaces de repository.
- `data/` — implémentations mock (Isar/Firestore seront branchés plus tard).

Chaque fichier reste <200 lignes et est prêt à être complété avec la logique
métier (production, ventes, stock, clients, finances, activité).
# Feature › Eau Minérale

À implémenter lorsque le métier sera détaillé :

- `presentation/screens/packaging_screen.dart`
- `presentation/screens/orders_screen.dart`
- `widgets/order_list.dart`
- `widgets/stock_summary.dart`
- `application/order_controller.dart`
- `domain/entities/water_order.dart`
- `data/order_repository.dart`
- `data/local/order_local_ds.dart`
- `data/remote/order_remote_ds.dart`
- `printing/templates/water_ticket.dart`

