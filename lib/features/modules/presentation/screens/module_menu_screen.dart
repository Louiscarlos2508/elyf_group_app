import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModuleMenuScreen extends StatelessWidget {
  const ModuleMenuScreen({super.key});

  static final modules = [
    _ModuleEntry(
      name: 'Eau Minérale',
      route: '/modules/eau_sachet',
      description: 'Suivi de production et des ventes de sachets d’eau.',
      icon: Icons.water_drop_outlined,
    ),
    _ModuleEntry(
      name: 'Gaz',
      route: '/modules/gaz',
      description: 'Distribution de bouteilles et réseau de dépôts.',
      icon: Icons.local_fire_department_outlined,
    ),
    _ModuleEntry(
      name: 'Orange Money',
      route: '/modules/orange_money',
      description: 'Opérations cash-in / cash-out pour agents agréés.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _ModuleEntry(
      name: 'Immobilier',
      route: '/modules/immobilier',
      description: 'Gestion des maisons et locations disponibles.',
      icon: Icons.home_work_outlined,
    ),
    _ModuleEntry(
      name: 'Boutique',
      route: '/modules/boutique',
      description: 'Vente physique, stocks, caisse et reçus.',
      icon: Icons.storefront_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionnez un module'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemBuilder: (context, index) {
          final module = modules[index];
          return Card(
            child: ListTile(
              leading: Icon(module.icon, size: 32),
              title: Text(
                module.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(module.description),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.go(module.route),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: modules.length,
      ),
    );
  }
}

class _ModuleEntry {
  const _ModuleEntry({
    required this.name,
    required this.route,
    required this.description,
    required this.icon,
  });

  final String name;
  final String route;
  final String description;
  final IconData icon;
}
