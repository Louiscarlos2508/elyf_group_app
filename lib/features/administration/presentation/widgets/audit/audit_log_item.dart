import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/audit_log.dart';
import 'audit_log_helpers.dart';

/// Widget for displaying a single audit log entry.
class AuditLogItem extends StatelessWidget {
  const AuditLogItem({super.key, required this.log});

  final AuditLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Card(
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor:
                AuditLogHelpers.getActionColor(log.action, context)
                    .withValues(alpha: 0.2),
            child: Icon(
              AuditLogHelpers.getActionIcon(log.action),
              color: AuditLogHelpers.getActionColor(log.action, context),
            ),
          ),
          title: Text(
            AuditLogHelpers.getActionLabel(log.action),
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
                  _AuditInfoRow(
                    label: 'Utilisateur',
                    value: log.userDisplayName ?? log.userId,
                  ),
                  if (log.description != null)
                    _AuditInfoRow(label: 'Description', value: log.description!),
                  if (log.moduleId != null)
                    _AuditInfoRow(label: 'Module', value: log.moduleId!),
                  if (log.enterpriseId != null)
                    _AuditInfoRow(label: 'Entreprise', value: log.enterpriseId!),
                  if (log.oldValue != null || log.newValue != null) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    if (log.oldValue != null)
                      _AuditValueRow(
                        label: 'Ancienne valeur',
                        value: log.oldValue!,
                        isOld: true,
                      ),
                    if (log.newValue != null)
                      _AuditValueRow(
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

/// Widget for displaying an info row in audit log details.
class _AuditInfoRow extends StatelessWidget {
  const _AuditInfoRow({
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

/// Widget for displaying a value row (old/new) in audit log details.
class _AuditValueRow extends StatelessWidget {
  const _AuditValueRow({
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
