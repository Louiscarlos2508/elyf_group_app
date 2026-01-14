/// Represents a module in the administration system.
class AdminModule {
  const AdminModule({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
  });

  final String id;
  final String name;
  final String description;
  final String? icon;
}

/// Available modules for administration
class AdminModules {
  static const eauMinerale = AdminModule(
    id: 'eau_minerale',
    name: 'Eau Minérale',
    description: 'Gestion de la production et vente d\'eau en sachet',
    icon: 'water_drop',
  );

  static const gaz = AdminModule(
    id: 'gaz',
    name: 'Gaz',
    description: 'Distribution de bouteilles de gaz',
    icon: 'local_fire_department',
  );

  static const orangeMoney = AdminModule(
    id: 'orange_money',
    name: 'Orange Money',
    description: 'Opérations cash-in / cash-out',
    icon: 'account_balance_wallet',
  );

  static const immobilier = AdminModule(
    id: 'immobilier',
    name: 'Immobilier',
    description: 'Gestion des maisons et locations',
    icon: 'home_work',
  );

  static const boutique = AdminModule(
    id: 'boutique',
    name: 'Boutique',
    description: 'Vente physique, stocks et caisse',
    icon: 'storefront',
  );

  static const all = [eauMinerale, gaz, orangeMoney, immobilier, boutique];
}
