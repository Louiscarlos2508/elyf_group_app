import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/tenant/tenant_provider.dart';

class ModuleMenuScreen extends ConsumerStatefulWidget {
  const ModuleMenuScreen({super.key});

  @override
  ConsumerState<ModuleMenuScreen> createState() => _ModuleMenuScreenState();
}

class _ModuleMenuScreenState extends ConsumerState<ModuleMenuScreen> {
  /// Mapping des types d'entreprises vers les routes de modules
  static const _moduleRoutes = {
    'eau_minerale': '/modules/eau_sachet',
    'gaz': '/modules/gaz',
    'orange_money': '/modules/orange_money',
    'immobilier': '/modules/immobilier',
    'boutique': '/modules/boutique',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);

    // Déclencher la sélection automatique si nécessaire
    ref.watch(autoSelectEnterpriseProvider);

    // Vérifier l'entreprise active
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    final accessibleEnterprisesAsync = ref.watch(
      userAccessibleEnterprisesProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeEnterpriseAsync.when(
            data: (enterprise) => enterprise == null
                ? 'Sélectionnez une entreprise'
                : enterprise.name,
            loading: () => 'Chargement...',
            error: (_, __) => 'Sélectionnez une entreprise',
          ),
        ),
        centerTitle: true,
      ),
      body: activeEnterpriseAsync.when(
        data: (activeEnterprise) {
          // Si aucune entreprise n'est sélectionnée et que l'utilisateur a plusieurs entreprises
          if (activeEnterprise == null) {
            return accessibleEnterprisesAsync.when(
              data: (enterprises) {
                if (enterprises.length > 1) {
                  // Afficher la liste des entreprises accessibles
                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemBuilder: (context, index) {
                      final enterprise = enterprises[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.business,
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            enterprise.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(enterprise.description ?? ''),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            // Sélectionner l'entreprise active
                            final tenantNotifier = ref.read(
                              activeEnterpriseIdProvider.notifier,
                            );
                            await tenantNotifier.setActiveEnterpriseId(
                              enterprise.id,
                            );

                            // Attendre que le provider soit mis à jour
                            await ref.read(activeEnterpriseProvider.future);

                            // Rediriger directement vers le module correspondant au type de l'entreprise
                            final route = _moduleRoutes[enterprise.type];
                            if (route != null && mounted) {
                              context.go(route);
                            }
                          },
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: enterprises.length,
                  );
                }
                // Si une seule entreprise, elle sera sélectionnée automatiquement
                return const Center(child: CircularProgressIndicator());
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

          // Entreprise sélectionnée : rediriger automatiquement vers le module correspondant
          final route = _moduleRoutes[activeEnterprise.type];
          if (route != null) {
            // Utiliser WidgetsBinding pour éviter les problèmes de timing
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.go(route);
              }
            });
            return const Center(child: CircularProgressIndicator());
          }
          // Si aucun module ne correspond au type d'entreprise
          return Center(
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
                  'Aucun module disponible pour ce type d\'entreprise',
                  style: textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
}
