import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../../../domain/entities/enterprise.dart';
import '../../widgets/enterprises/enterprise_actions.dart';
import '../../widgets/enterprises/enterprise_list_item.dart';
import '../../widgets/enterprises/enterprise_empty_state.dart';

/// Section pour gérer les entreprises
class AdminEnterprisesSection extends ConsumerWidget {
  const AdminEnterprisesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enterprisesAsync = ref.watch(enterprisesProvider);

    return CustomScrollView(
      slivers: [
        _buildHeader(theme),
        _buildCreateButton(context, ref),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        enterprisesAsync.when(
          data: (enterprises) => _buildEnterprisesList(
            context,
            ref,
            enterprises,
          ),
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => _buildErrorState(theme, error),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion des Entreprises',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gérez les entreprises du groupe ELYF',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: FilledButton.icon(
          onPressed: () => EnterpriseActions.create(context, ref),
          icon: const Icon(Icons.add_business),
          label: const Text('Nouvelle Entreprise'),
        ),
      ),
    );
  }

  Widget _buildEnterprisesList(
    BuildContext context,
    WidgetRef ref,
    List<Enterprise> enterprises,
  ) {
    if (enterprises.isEmpty) {
      return const SliverToBoxAdapter(child: EnterpriseEmptyState());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final enterprise = enterprises[index];
          return EnterpriseListItem(
            enterprise: enterprise,
            onEdit: () => EnterpriseActions.edit(context, ref, enterprise),
            onToggleStatus: () =>
                EnterpriseActions.toggleStatus(context, ref, enterprise),
            onDelete: () => EnterpriseActions.delete(context, ref, enterprise),
            onNavigate: () {
              context.go('/modules/${enterprise.type}/${enterprise.id}');
            },
          );
        },
        childCount: enterprises.length,
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
