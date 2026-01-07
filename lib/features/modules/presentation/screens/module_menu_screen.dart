import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../../../administration/domain/entities/admin_module.dart';

class ModuleMenuScreen extends ConsumerWidget {
  const ModuleMenuScreen({super.key});

  /// Mapping des IDs de modules vers les routes
  static const _moduleRoutes = {
    'eau_minerale': '/modules/eau_sachet',
    'gaz': '/modules/gaz',
    'orange_money': '/modules/orange_money',
    'immobilier': '/modules/immobilier',
    'boutique': '/modules/boutique',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    
    // Déclencher la sélection automatique si nécessaire
    ref.watch(autoSelectEnterpriseProvider);
    
    // Vérifier l'entreprise active
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    final accessibleEnterprisesAsync = ref.watch(userAccessibleEnterprisesProvider);
    
    // Récupérer tous les modules depuis AdminModules
    final modules = AdminModules.all;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionnez un module'),
        centerTitle: true,
        actions: [
          // Sélecteur d'entreprise
          const EnterpriseSelectorWidget(compact: true),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Administration',
            onPressed: () => context.go('/admin'),
          ),
        ],
      ),
      body: activeEnterpriseAsync.when(
        data: (activeEnterprise) {
          // Si aucune entreprise n'est sélectionnée et que l'utilisateur a plusieurs entreprises
          if (activeEnterprise == null) {
            return accessibleEnterprisesAsync.when(
              data: (enterprises) {
                if (enterprises.length > 1) {
                  // L'utilisateur doit sélectionner une entreprise
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Sélectionnez une entreprise',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Vous avez accès à ${enterprises.length} entreprises.\n'
                            'Veuillez sélectionner une entreprise pour continuer.',
                            style: textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: () {
                              // Le sélecteur d'entreprise est dans l'AppBar
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cliquez sur l\'icône entreprise en haut à droite',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.business),
                            label: const Text('Sélectionner une entreprise'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // Si une seule entreprise, elle sera sélectionnée automatiquement
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur lors du chargement des entreprises',
                      style: textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Entreprise sélectionnée, afficher les modules
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemBuilder: (context, index) {
              final module = modules[index];
              final route = _moduleRoutes[module.id];
              
              // Si pas de route, on ne montre pas le module
              if (route == null) return const SizedBox.shrink();
              
              return Card(
                child: ListTile(
                  leading: Icon(
                    _getIcon(module.icon),
                    size: 32,
                  ),
                  title: Text(
                    module.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(module.description),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go(route),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: modules.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur lors du chargement de l\'entreprise',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'local_fire_department':
        return Icons.local_fire_department_outlined;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_outlined;
      case 'home_work':
        return Icons.home_work_outlined;
      case 'storefront':
        return Icons.storefront_outlined;
      default:
        return Icons.business_outlined;
    }
  }
}
