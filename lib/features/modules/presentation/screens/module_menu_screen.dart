import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'package:go_router/go_router.dart';

import '../../../../core/auth/controllers/auth_controller.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../../../administration/domain/entities/enterprise.dart';
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

    // Auto-navigation if only one module is accessible.
    // We handle BOTH cases:
    // 1. Data already loaded at build time → use addPostFrameCallback
    // 2. Data loads later → use ref.listen
    accessibleModulesAsync.whenData((moduleIds) {
      if (moduleIds.length == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          try {
            final moduleId = moduleIds.first;
            final module = EnterpriseModule.values.firstWhere((e) => e.id == moduleId);
            developer.log('🚀 Auto-navigating (immediate) to: ${module.id}', name: 'ModuleMenuScreen');
            _navigateToModule(context, module);
          } catch (e) {
            developer.log('❌ Error during auto-navigation: $e', name: 'ModuleMenuScreen');
          }
        });
      }
    });

    // Also listen for future changes (e.g. tenant switch completes while on this screen)
    ref.listen(userAccessibleModulesForActiveEnterpriseProvider, (previous, next) {
      next.whenData((moduleIds) {
        if (moduleIds.length == 1) {
          try {
            final moduleId = moduleIds.first;
            final module = EnterpriseModule.values.firstWhere((e) => e.id == moduleId);
            developer.log('🚀 Auto-navigating (listener) to: ${module.id}', name: 'ModuleMenuScreen');
            Future.microtask(() => _navigateToModule(context, module));
          } catch (e) {
            developer.log('❌ Error during auto-navigation: $e', name: 'ModuleMenuScreen');
          }
        }
      });
    });

    return DoubleTapToExit(
      child: Scaffold(
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
                  const EnterpriseSelectorWidget(style: EnterpriseSelectorStyle.appBar),
                ]
              : [
                  IconButton(
                    onPressed: () => ref.read(authControllerProvider).signOut(),
                    icon: const Icon(Icons.logout),
                    tooltip: 'Se déconnecter',
                  ),
                  const SizedBox(width: 8),
                ],
        ),
        extendBodyBehindAppBar: true, // For glassmorphism
        body: SafeArea(
          child: activeEnterpriseAsync.when(
            data: (activeEnterprise) {
              // Case 1: No active enterprise selected -> Show Enterprise Selector
              if (activeEnterprise == null) {
                return const Center(child: CircularProgressIndicator());
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
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => ref.read(authControllerProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
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
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => ref.read(authControllerProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter et réessayer'),
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
