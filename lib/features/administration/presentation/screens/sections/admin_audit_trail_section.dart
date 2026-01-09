import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/audit_log.dart';
import '../../widgets/audit/audit_export_dialog.dart';
import '../../widgets/audit/audit_log_item.dart';

/// Provider pour récupérer les logs d'audit récents.
///
/// Utilise le controller pour respecter l'architecture.
final recentAuditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>(
  (ref) => ref.watch(auditControllerProvider).getRecentLogs(limit: 100),
);

/// Provider pour récupérer les logs d'audit pour une entité.
///
/// Utilise le controller pour respecter l'architecture.
final auditLogsForEntityProvider = FutureProvider.autoDispose
    .family<List<AuditLog>, ({String type, String id})>(
  (ref, params) => ref.watch(auditControllerProvider).getLogsForEntity(
        entityType: params.type,
        entityId: params.id,
      ),
);

/// Section pour visualiser l'audit trail.
class AdminAuditTrailSection extends ConsumerWidget {
  const AdminAuditTrailSection({super.key});

  void _showExportDialog(BuildContext context, List<AuditLog> logs) {
    showDialog(
      context: context,
      builder: (context) => AuditExportDialog(logs: logs),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(recentAuditLogsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
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
                // Export button
                logsAsync.when(
                  data: (logs) => logs.isNotEmpty
                      ? OutlinedButton.icon(
                          onPressed: () => _showExportDialog(context, logs),
                          icon: const Icon(Icons.download),
                          label: const Text('Exporter'),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        logsAsync.when(
          data: (logs) => _buildLogsList(context, logs),
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => _buildErrorState(context, error),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildLogsList(BuildContext context, List<AuditLog> logs) {
    final theme = Theme.of(context);

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
          return AuditLogItem(log: log);
        },
        childCount: logs.length,
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);

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
