import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart' as entity;
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/app/theme/app_radius.dart';

/// A premium, modern card for representing agents or agencies in the network.
class AgentNetworkCard extends StatelessWidget {
  const AgentNetworkCard({
    super.key,
    this.agent,
    this.agency,
    this.onView,
    this.onEdit,
    this.onDelete,
    this.onRecharge,
    this.stats,
  });

  final entity.Agent? agent;
  final Enterprise? agency;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRecharge;
  final AsyncValue<Map<String, dynamic>>? stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAgent = agent != null;
    
    final name = isAgent ? agent!.name : agency!.name;
    final subTitle = isAgent 
        ? '${agent!.phoneNumber} • ${agent!.simNumber}'
        : (agency!.type == EnterpriseType.pointOfSale ? 'Point de Vente' : 'Agence');
    
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    
    // Status
    final isActive = isAgent ? agent!.isActive : true;
    final statusColor = isActive ? AppColors.success : theme.colorScheme.error;

    return ElyfCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Avatar & Menu
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Outfit',
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _buildStatusDot(statusColor, theme),
                          ],
                        ),
                        Text(
                          subTitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Menu
                  _buildPopupMenu(context),
                ],
              ),
            ),
            
            // Middle Section (Flux/Performance Today)
            if (isAgent) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: stats?.when(
                  data: (s) => Column(
                    children: [
                      _buildFluxRow(
                        context,
                        label: 'Dépôts',
                        amount: s['totalCashIn'] as int? ?? 0,
                        count: s['transactionCount'] as int? ?? 0, // Simplified count for today
                        icon: Icons.arrow_downward_rounded,
                        color: const Color(0xFFFF6B00),
                      ),
                      const SizedBox(height: 8),
                      _buildFluxRow(
                        context,
                        label: 'Retraits',
                        amount: s['totalCashOut'] as int? ?? 0,
                        count: 0, // Placeholder if count per type not available
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                  loading: () => const LoadingIndicator(height: 40),
                  error: (_, __) => const Text('Flux non disponible'),
                ) ?? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Performance du Jour',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Chargement...', style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ] else ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        agency!.address ?? 'Aucune adresse',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const Spacer(),
            
            // Bottom Actions
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
                border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.05))),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    if (isAgent) ...[
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onRecharge,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, 
                                       size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Recharger',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ],
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onView,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_forward_rounded, 
                                     size: 16, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Détails',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(Color color, ThemeData theme) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }


  Widget _buildFluxRow(
    BuildContext context, {
    required String label,
    required int amount,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          CurrencyFormatter.formatFCFA(amount),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontFamily: 'Outfit',
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      elevation: 4,
      onSelected: (value) {
        if (value == 'edit') {
          onEdit?.call();
        } else if (value == 'delete') {
          onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              const Text('Modifier'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
              SizedBox(width: AppSpacing.sm),
              Text('Supprimer', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
    );
  }
}
