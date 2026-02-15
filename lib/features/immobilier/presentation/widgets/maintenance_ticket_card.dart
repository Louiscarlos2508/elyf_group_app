import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../administration/application/providers.dart';
import '../../../administration/domain/entities/user.dart';
import '../../domain/entities/maintenance_ticket.dart';
import '../../domain/entities/property.dart';

class MaintenanceTicketCard extends ConsumerWidget {
  const MaintenanceTicketCard({
    super.key,
    required this.ticket,
    this.property,
    this.onTap,
  });

  final MaintenanceTicket ticket;
  final Property? property;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _getPriorityColor(ticket.priority);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _getPriorityLabel(ticket.priority).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _StatusBadge(status: ticket.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.description,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (property != null)
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property!.address,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (ticket.cost != null && ticket.cost! > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Coût estimé: ${ticket.cost} FCFA',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                   if (ticket.assignedUserId != null)
                    Expanded(
                      child: ref.watch(searchUsersProvider('')).when(
                        data: (users) {
                          final user = users.cast<User?>().firstWhere(
                            (u) => u?.id == ticket.assignedUserId,
                            orElse: () => null
                          );
                          return Row(
                            children: [
                              Icon(Icons.person, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                user?.fullName ?? 'Utilisateur inconnu',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return Colors.green;
      case MaintenancePriority.medium:
        return Colors.orange;
      case MaintenancePriority.high:
        return Colors.red;
      case MaintenancePriority.critical:
        return Colors.purple;
    }
  }

  String _getPriorityLabel(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return 'Basse';
      case MaintenancePriority.medium:
        return 'Moyenne';
      case MaintenancePriority.high:
        return 'Haute';
      case MaintenancePriority.critical:
        return 'Critique';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final MaintenanceStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color, icon) = _getData(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _getData(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.open:
        return ('Ouvert', Colors.blue, Icons.info_outline);
      case MaintenanceStatus.inProgress:
        return ('En cours', Colors.orange, Icons.pending_actions);
      case MaintenanceStatus.resolved:
        return ('Résolu', Colors.green, Icons.check_circle_outline);
      case MaintenanceStatus.closed:
        return ('Fermé', Colors.grey, Icons.lock_outline);
    }
  }
}
