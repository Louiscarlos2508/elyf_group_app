import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart' as entity;
import 'package:elyf_groupe_app/app/theme/app_colors.dart';
import 'package:elyf_groupe_app/app/theme/app_spacing.dart';
import 'package:elyf_groupe_app/app/theme/app_radius.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_dialogs.dart';

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
  });

  final entity.Agent? agent;
  final Enterprise? agency;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRecharge;

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
              padding: EdgeInsets.all(AppSpacing.md),
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
                  SizedBox(width: AppSpacing.md),
                  
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
            
            // Middle Section (Liquidity/Indicator)
            if (isAgent) ...[
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Solde SIM',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatFCFA(agent!.liquidity),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _buildLiquidityProgress(agent!.liquidity, theme),
                  ],
                ),
              ),
            ] else ...[
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.primary),
                    SizedBox(width: AppSpacing.xs),
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
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, 
                                       size: 16, color: theme.colorScheme.primary),
                                  SizedBox(width: AppSpacing.xs),
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
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_forward_rounded, 
                                     size: 16, color: theme.colorScheme.onSurfaceVariant),
                                SizedBox(width: AppSpacing.xs),
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

  Widget _buildLiquidityProgress(int current, ThemeData theme) {
    // Thresholds for color coding
    const lowThreshold = 100000;
    const warningThreshold = 300000;
    const targetMax = 1000000; // Reference for progress bar

    final progress = (current / targetMax).clamp(0.0, 1.0);
    final color = current < lowThreshold 
        ? AppColors.danger 
        : (current < warningThreshold ? AppColors.warning : AppColors.success);
    
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          '${(progress * 100).toInt()}%',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
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
              SizedBox(width: AppSpacing.sm),
              const Text('Modifier'),
            ],
          ),
        ),
        PopupMenuItem(
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
