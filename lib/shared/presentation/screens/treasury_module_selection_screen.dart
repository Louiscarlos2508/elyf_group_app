import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Écran de sélection de module pour la trésorerie.
/// Affiche tous les modules disponibles et permet de naviguer vers la trésorerie de chaque module.
class TreasuryModuleSelectionScreen extends StatelessWidget {
  const TreasuryModuleSelectionScreen({super.key});

  static const List<_ModuleInfo> _modules = [
    _ModuleInfo(
      id: 'eau_minerale',
      name: 'Eau Minérale',
      icon: Icons.water_drop_outlined,
      color: Colors.blue,
    ),
    _ModuleInfo(
      id: 'boutique',
      name: 'Boutique',
      icon: Icons.store_outlined,
      color: Colors.orange,
    ),
    _ModuleInfo(
      id: 'immobilier',
      name: 'Immobilier',
      icon: Icons.home_outlined,
      color: Colors.green,
    ),
    _ModuleInfo(
      id: 'gaz',
      name: 'Gaz',
      icon: Icons.local_gas_station_outlined,
      color: Colors.red,
    ),
    _ModuleInfo(
      id: 'orange_money',
      name: 'Orange Money',
      icon: Icons.account_balance_wallet_outlined,
      color: Colors.deepOrange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trésorerie'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sélectionner un module',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choisissez le module pour accéder à sa trésorerie',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final module = _modules[index];
                  return _ModuleCard(
                    module: module,
                    onTap: () {
                      context.push('/treasury/${module.id}');
                    },
                  );
                },
                childCount: _modules.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}

class _ModuleInfo {
  const _ModuleInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.onTap,
  });

  final _ModuleInfo module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  module.icon,
                  size: 32,
                  color: module.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                module.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

