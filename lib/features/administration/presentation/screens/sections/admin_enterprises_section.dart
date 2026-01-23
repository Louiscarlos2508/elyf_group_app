import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elyf_groupe_app/features/administration/application/providers.dart';
import '../../../../../shared/utils/responsive_helper.dart';
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
    final combinedAsync = ref.watch(enterprisesWithPointsOfSaleProvider);
    
    // Log pour déboguer
    combinedAsync.whenData((combined) {
      final posCount = combined.where((item) => item.isPointOfSale).length;
      developer.log(
        '🔵 AdminEnterprisesSection: ${combined.length} éléments au total ($posCount points de vente)',
        name: 'AdminEnterprisesSection',
      );
    });

    return CustomScrollView(
      slivers: [
        _buildHeader(context, theme),
        _buildCreateButton(context, ref),
        SliverToBoxAdapter(
          child: SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 24),
        ),
        combinedAsync.when(
          data: (combined) {
            final posCount = combined.where((item) => item.isPointOfSale).length;
            developer.log(
              '🔵 AdminEnterprisesSection: Affichage de ${combined.length} éléments ($posCount points de vente)',
              name: 'AdminEnterprisesSection',
            );
            return _buildEnterprisesList(context, ref, combined);
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) {
            developer.log(
              '❌ AdminEnterprisesSection: Erreur: $error',
              name: 'AdminEnterprisesSection',
              error: error,
              stackTrace: stack,
            );
            return _buildErrorState(context, theme, error);
          },
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 24),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: ResponsiveHelper.adaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion des Entreprises',
              style: ResponsiveHelper.isMobile(context)
                  ? theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : theme.textTheme.headlineMedium?.copyWith(
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
    final isMobile = ResponsiveHelper.isMobile(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: ResponsiveHelper.adaptiveHorizontalPadding(context),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => EnterpriseActions.create(context, ref),
            icon: const Icon(Icons.add_business),
            label: Text(
              isMobile ? 'Nouvelle Entreprise' : 'Nouvelle Entreprise',
            ),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 12 : 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnterprisesList(
    BuildContext context,
    WidgetRef ref,
    List<({Enterprise enterprise, bool isPointOfSale})> combined,
  ) {
    if (combined.isEmpty) {
      return const SliverToBoxAdapter(child: EnterpriseEmptyState());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = combined[index];
        return EnterpriseListItem(
          enterprise: item.enterprise,
          isPointOfSale: item.isPointOfSale,
          onEdit: () => EnterpriseActions.edit(context, ref, item.enterprise),
          onToggleStatus: () =>
              EnterpriseActions.toggleStatus(context, ref, item.enterprise),
          onDelete: () => EnterpriseActions.delete(context, ref, item.enterprise),
          onNavigate: () {
            if (item.isPointOfSale) {
              // Pour les points de vente, naviguer vers l'entreprise mère
              // On doit extraire le parentEnterpriseId depuis l'ID du point de vente
              // Format: pos_{parentEnterpriseId}_{timestamp}
              final posId = item.enterprise.id;
              if (posId.startsWith('pos_')) {
                final parts = posId.split('_');
                if (parts.length >= 2) {
                  final parentEnterpriseId = parts[1];
                  context.go('/modules/${item.enterprise.type}/$parentEnterpriseId');
                } else {
                  context.go('/modules/${item.enterprise.type}');
                }
              } else {
                context.go('/modules/${item.enterprise.type}');
              }
            } else {
              context.go('/modules/${item.enterprise.type}/${item.enterprise.id}');
            }
          },
        );
      }, childCount: combined.length),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, Object error) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: ResponsiveHelper.adaptivePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: ResponsiveHelper.isMobile(context) ? 48 : 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Erreur de chargement', style: theme.textTheme.titleLarge),
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
