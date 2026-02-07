import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/enterprise.dart';
import '../../application/providers.dart';
import '../../application/tenant_providers.dart';
import '../../application/services/tenant_context_service.dart';

/// Multi-tenant dashboard showing stats and quick access to tenants
class MultiTenantDashboard extends ConsumerWidget {
  const MultiTenantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTenantAsync = ref.watch(currentTenantProvider);
    final tenantService = ref.watch(tenantContextServiceProvider);

    return currentTenantAsync.when(
      data: (currentTenant) {
        if (currentTenant == null) {
          return _buildNoTenantSelected(context);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current tenant card
              _TenantCard(
                enterprise: currentTenant,
                isCurrent: true,
              ),
              const SizedBox(height: 24),

              // Children tenants
              FutureBuilder<List<Enterprise>>(
                future: tenantService.getChildren(currentTenant.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sous-entités',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return _TenantCard(
                            enterprise: snapshot.data![index],
                            isCurrent: false,
                            onTap: () {
                              tenantService.switchTenant(snapshot.data![index].id);
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erreur: $error'),
      ),
    );
  }

  Widget _buildNoTenantSelected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.business,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun tenant sélectionné',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez un tenant pour voir les détails',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Card displaying tenant information and stats
class _TenantCard extends ConsumerWidget {
  const _TenantCard({
    required this.enterprise,
    required this.isCurrent,
    this.onTap,
  });

  final Enterprise enterprise;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final typeService = ref.read(enterpriseTypeServiceProvider);

    return Card(
      elevation: isCurrent ? 4 : 1,
      color: isCurrent
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      typeService.getTypeIcon(enterprise.type.id),
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (isCurrent)
                    Chip(
                      label: const Text('Actuel'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 11,
                      ),
                    )
                  else
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: enterprise.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                ],
              ),
              const Spacer(),

              // Name
              Text(
                enterprise.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Type
              Text(
                typeService.getTypeLabel(enterprise.type.id),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              // Stats (placeholder for now)
              if (isCurrent) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '0 utilisateurs',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
