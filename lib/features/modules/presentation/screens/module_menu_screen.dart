import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'package:go_router/go_router.dart';

import '../../../../core/tenant/tenant_provider.dart';
import '../../../administration/domain/entities/enterprise.dart';
import '../../../../shared/presentation/widgets/elyf_ui/organisms/elyf_app_bar.dart';
import '../../../../shared/presentation/widgets/widgets.dart';

class ModuleMenuScreen extends ConsumerStatefulWidget {
  const ModuleMenuScreen({super.key});

  @override
  ConsumerState<ModuleMenuScreen> createState() => _ModuleMenuScreenState();
}

class _ModuleMenuScreenState extends ConsumerState<ModuleMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    final hierarchicalEnterprisesAsync = ref.watch(hierarchicalEnterprisesProvider);
    final accessibleModulesAsync = ref.watch(
      userAccessibleModulesForActiveEnterpriseProvider,
    );
    // Activer la sélection automatique si une seule entreprise est disponible
    ref.watch(autoSelectEnterpriseProvider);

    return DoubleTapToExit(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: ElyfAppBar(
          title: activeEnterpriseAsync.when(
            data: (enterprise) => enterprise == null
                ? 'Sélection Organisation'
                : enterprise.name,
            loading: () => 'Chargement...',
            error: (_, __) => 'Sélection Organisation',
          ),
          centerTitle: true,
          useGlassmorphism: true,
          elevation: 0,
          actions: activeEnterpriseAsync.asData?.value != null
              ? [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    tooltip: 'Changer d\'organisation',
                    onPressed: () {
                      ref.read(activeEnterpriseIdProvider.notifier).clearActiveEnterprise();
                    },
                  ),
                ]
              : null,
        ),
        extendBodyBehindAppBar: true, // For glassmorphism
        body: SafeArea(
          child: activeEnterpriseAsync.when(
            data: (activeEnterprise) {
              // Case 1: No active enterprise selected -> Show Enterprise Selector
              if (activeEnterprise == null) {
                return hierarchicalEnterprisesAsync.when(
                  data: (modulesMap) {
                    developer.log(
                      '🔍 ModuleMenuScreen: modulesMap has ${modulesMap.length} modules',
                      name: 'ModuleMenuScreen',
                    );
                    
                    if (modulesMap.isEmpty) {
                      developer.log(
                        '⚠️ ModuleMenuScreen: modulesMap is empty, trying fallback to accessible enterprises',
                        name: 'ModuleMenuScreen',
                      );
                      
                      // Fallback: afficher les entreprises accessibles sans hiérarchie
                      final accessibleEnterprisesAsync = ref.watch(userAccessibleEnterprisesProvider);
                      return accessibleEnterprisesAsync.when(
                        data: (enterprises) {
                          developer.log(
                            '🔍 ModuleMenuScreen FALLBACK: ${enterprises.length} accessible enterprises',
                            name: 'ModuleMenuScreen',
                          );
                          
                          if (enterprises.isEmpty) {
                            return _buildEmptyState(theme);
                          }
                          
                          // Afficher une liste simple groupée par module
                          final grouped = <EnterpriseModule, List<Enterprise>>{};
                          for (final e in enterprises) {
                            grouped.putIfAbsent(e.type.module, () => []).add(e);
                          }
                          
                          final sortedModules = grouped.keys.toList()
                            ..sort((a, b) {
                              if (a == EnterpriseModule.group) return -1;
                              if (b == EnterpriseModule.group) return 1;
                              return a.label.compareTo(b.label);
                            });
                          
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            itemCount: sortedModules.length,
                            itemBuilder: (context, index) {
                              final module = sortedModules[index];
                              final moduleEnterprises = grouped[module]!;
                              return _buildSimpleModuleSection(context, module, moduleEnterprises);
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => _buildErrorView(theme, e),
                      );
                    }

                    // Trier les modules : mettre 'group' en premier si présent
                    final sortedModules = modulesMap.keys.toList()
                      ..sort((a, b) {
                        if (a == EnterpriseModule.group) return -1;
                        if (b == EnterpriseModule.group) return 1;
                        return a.label.compareTo(b.label);
                      });

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      itemCount: sortedModules.length,
                      itemBuilder: (context, index) {
                        final module = sortedModules[index];
                        final nodes = modulesMap[module]!;
                        return _buildModuleSection(context, module, nodes);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) {
                    return _buildErrorView(theme, error);
                  },
                );
              }

              // Case 2: Enterprise selected -> Show Available Modules Grid
              return accessibleModulesAsync.when(
                data: (moduleIds) {
                  if (moduleIds.isEmpty) {
                    return _buildNoModulesState(theme);
                  }

                  // Map string IDs to EnterpriseModule enums
                  final modules = moduleIds
                      .map((id) {
                        try {
                          return EnterpriseModule.values
                              .firstWhere((e) => e.id == id);
                        } catch (_) {
                          return null;
                        }
                      })
                      .whereType<EnterpriseModule>()
                      .toList();
                  
                   // Sort modules manually if needed
                  modules.sort((a, b) => a.label.compareTo(b.label));

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Text(
                              'Modules Accessibles',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sélectionnez un module pour continuer',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: modules.length,
                          itemBuilder: (context, index) {
                            return _ModuleMenuCard(
                              module: modules[index],
                              onTap: () => _navigateToModule(context, modules[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorView(theme, error),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorView(theme, error),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleModuleSection(
    BuildContext context,
    EnterpriseModule module,
    List<Enterprise> enterprises,
  ) {
    final theme = Theme.of(context);
    final isGroup = module == EnterpriseModule.group;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de section
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: module.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: module.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(module.icon, size: 18, color: module.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isGroup ? 'Administration & Groupe' : module.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: module.color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: module.color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                     BoxShadow(
                       color: module.color.withValues(alpha: 0.3),
                       blurRadius: 4,
                       offset: const Offset(0, 2),
                     ),
                  ],
                ),
                child: Text(
                  '${enterprises.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Liste simple des entreprises
        ...enterprises.map((enterprise) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _selectEnterprise(enterprise),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                           colors: [
                              module.color.withValues(alpha: 0.1),
                              module.color.withValues(alpha: 0.2),
                           ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        enterprise.type.icon,
                        color: module.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            enterprise.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (enterprise.description != null || enterprise.type.label.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              enterprise.description ?? enterprise.type.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildModuleSection(
    BuildContext context,
    EnterpriseModule module,
    List<EnterpriseHierarchyNode> nodes,
  ) {
    final theme = Theme.of(context);
    final isGroup = module == EnterpriseModule.group;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de section avec badge
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: module.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(module.icon, size: 22, color: module.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isGroup ? 'Administration & Groupe' : module.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: module.color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: module.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${nodes.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: module.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Liste des entreprises
        ...nodes.map((node) => _buildHierarchyNode(context, node, module, 0)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHierarchyNode(
    BuildContext context,
    EnterpriseHierarchyNode node,
    EnterpriseModule module,
    int depth,
  ) {
    final theme = Theme.of(context);
    final enterprise = node.enterprise;
    final hasChildren = node.children.isNotEmpty;

    if (hasChildren) {
      // Société principale avec sous-entités
      return Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: depth * 16.0,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: module.color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: module.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                enterprise.type.icon,
                color: module.color,
                size: 24,
              ),
            ),
            title: Text(
              enterprise.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    enterprise.type.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: module.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${node.children.length} ${node.children.length > 1 ? 'sites' : 'site'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: module.color,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              // Option pour accéder au module principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Material(
                  color: module.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _selectEnterprise(enterprise),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.dashboard, size: 20, color: module.color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vue globale ${enterprise.name}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: module.color,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward, size: 18, color: module.color),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Sous-entités
              ...node.children.map((child) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildChildNode(context, child, module),
              )),
            ],
          ),
        ),
      );
    }

    // Entreprise sans enfants (ou enfant dans la hiérarchie)
    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: depth * 16.0,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectEnterprise(enterprise),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: module.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    enterprise.type.icon,
                    color: module.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enterprise.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        enterprise.description ?? enterprise.type.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildNode(
    BuildContext context,
    EnterpriseHierarchyNode node,
    EnterpriseModule module,
  ) {
    final theme = Theme.of(context);
    final enterprise = node.enterprise;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _selectEnterprise(enterprise),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  enterprise.type.icon,
                  color: module.color.withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enterprise.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (enterprise.address != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                enterprise.address!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectEnterprise(Enterprise enterprise) async {
    final tenantNotifier = ref.read(activeEnterpriseIdProvider.notifier);
    await tenantNotifier.setActiveEnterpriseId(enterprise.id);
  }

  void _navigateToModule(BuildContext context, EnterpriseModule module) {
    if (module.id == 'group') {
      context.go('/admin');
      return;
    }

    String? route;
    switch (module) {
      case EnterpriseModule.gaz:
        route = '/modules/gaz';
        break;
      case EnterpriseModule.eau:
        route = '/modules/eau_sachet';
        break;
      case EnterpriseModule.mobileMoney:
        route = '/modules/orange_money';
        break;
      case EnterpriseModule.immobilier:
        route = '/modules/immobilier';
        break;
      case EnterpriseModule.boutique:
        route = '/modules/boutique';
        break;
      default:
        route = null;
    }

    if (route != null) {
      context.go(route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Module ${module.label} bientôt disponible')),
      );
    }
  }

  Widget _buildNoModulesState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dashboard_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun module accessible',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Vous n\'avez accès à aucun module pour cette organisation.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(activeEnterpriseIdProvider.notifier).clearActiveEnterprise();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Changer d\'organisation'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune organisation accessible',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contactez votre administrateur pour obtenir un accès',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleMenuCard extends StatefulWidget {
  const _ModuleMenuCard({
    required this.module,
    required this.onTap,
  });

  final EnterpriseModule module;
  final VoidCallback onTap;

  @override
  State<_ModuleMenuCard> createState() => _ModuleMenuCardState();
}

class _ModuleMenuCardState extends State<_ModuleMenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.module.color;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            if (_isHovered)
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _controller.forward().then((_) {
                _controller.reverse();
                widget.onTap();
              });
            },
            onHover: (value) {
              setState(() => _isHovered = value);
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.1),
                          color.withValues(alpha: 0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      widget.module.icon,
                      size: 36,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.module.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.module.supportsHierarchy) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                         color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                         borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Multi-sites',
                        style: theme.textTheme.labelSmall?.copyWith( 
                           fontSize: 10,
                           color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
