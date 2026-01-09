import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/audit_log.dart';

/// Provider pour récupérer les logs d'audit récents.
/// 
/// Utilise le controller pour respecter l'architecture.
final recentAuditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>(
  (ref) => ref.watch(auditControllerProvider).getRecentLogs(limit: 100),
);

/// Provider pour récupérer les logs d'audit pour une entité.
/// 
/// Utilise le controller pour respecter l'architecture.
final auditLogsForEntityProvider =
    FutureProvider.autoDispose.family<List<AuditLog>, ({String type, String id})>(
  (ref, params) => ref.watch(auditControllerProvider).getLogsForEntity(
        entityType: params.type,
        entityId: params.id,
      ),
);

/// Section pour visualiser l'audit trail.
class AdminAuditTrailSection extends ConsumerWidget {
  const AdminAuditTrailSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(recentAuditLogsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journal d\'Audit',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Historique de toutes les actions administratives',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        logsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun log d\'audit',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Les actions administratives seront enregistrées ici',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final log = logs[index];
                  return _AuditLogItem(log: log);
                },
                childCount: logs.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => SliverToBoxAdapter(
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
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

/// Widget pour afficher un log d'audit.
class _AuditLogItem extends StatelessWidget {
  const _AuditLogItem({required this.log});

  final AuditLog log;

  String _getActionLabel(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return 'Création';
      case AuditAction.update:
        return 'Modification';
      case AuditAction.delete:
        return 'Suppression';
      case AuditAction.assign:
        return 'Assignation';
      case AuditAction.unassign:
        return 'Désassignation';
      case AuditAction.activate:
        return 'Activation';
      case AuditAction.deactivate:
        return 'Désactivation';
      case AuditAction.permissionChange:
        return 'Changement de permissions';
      case AuditAction.roleChange:
        return 'Changement de rôle';
      case AuditAction.unknown:
        return 'Action inconnue';
    }
  }

  IconData _getActionIcon(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return Icons.add_circle_outline;
      case AuditAction.update:
        return Icons.edit_outlined;
      case AuditAction.delete:
        return Icons.delete_outline;
      case AuditAction.assign:
        return Icons.person_add_outlined;
      case AuditAction.unassign:
        return Icons.person_remove_outlined;
      case AuditAction.activate:
        return Icons.check_circle_outline;
      case AuditAction.deactivate:
        return Icons.block_outlined;
      case AuditAction.permissionChange:
        return Icons.shield_outlined;
      case AuditAction.roleChange:
        return Icons.swap_horiz_outlined;
      case AuditAction.unknown:
        return Icons.help_outline;
    }
  }

  Color _getActionColor(AuditAction action, BuildContext context) {
    final theme = Theme.of(context);
    switch (action) {
      case AuditAction.create:
        return theme.colorScheme.primary;
      case AuditAction.update:
        return theme.colorScheme.secondary;
      case AuditAction.delete:
        return theme.colorScheme.error;
      case AuditAction.activate:
        return Colors.green;
      case AuditAction.deactivate:
        return Colors.orange;
      default:
        return theme.colorScheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Card(
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: _getActionColor(log.action, context).withValues(alpha: 0.2),
            child: Icon(
              _getActionIcon(log.action),
              color: _getActionColor(log.action, context),
            ),
          ),
          title: Text(
            _getActionLabel(log.action),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('${log.entityType}: ${log.entityId}'),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(log.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Utilisateur', value: log.userId),
                  if (log.description != null)
                    _InfoRow(label: 'Description', value: log.description!),
                  if (log.moduleId != null)
                    _InfoRow(label: 'Module', value: log.moduleId!),
                  if (log.enterpriseId != null)
                    _InfoRow(label: 'Entreprise', value: log.enterpriseId!),
                  if (log.oldValue != null || log.newValue != null) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    if (log.oldValue != null)
                      _ValueRow(
                        label: 'Ancienne valeur',
                        value: log.oldValue!,
                        isOld: true,
                      ),
                    if (log.newValue != null)
                      _ValueRow(
                        label: 'Nouvelle valeur',
                        value: log.newValue!,
                        isOld: false,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher une ligne d'information.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher une valeur (ancienne/nouvelle).
class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    required this.isOld,
  });

  final String label;
  final Map<String, dynamic> value;
  final bool isOld;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isOld ? Colors.orange : Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

