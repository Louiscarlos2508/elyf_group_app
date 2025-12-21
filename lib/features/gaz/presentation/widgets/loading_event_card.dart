import 'package:flutter/material.dart';

import '../../domain/entities/loading_event.dart';

/// Carte affichant un événement de chargement avec statut, dates, quantités.
class LoadingEventCard extends StatelessWidget {
  const LoadingEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onAddExpense,
    this.onComplete,
  });

  final LoadingEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onAddExpense;
  final VoidCallback? onComplete;

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        ) +
        ' FCFA';
  }

  Color _getStatusColor(LoadingEventStatus status) {
    switch (status) {
      case LoadingEventStatus.preparing:
        return Colors.orange;
      case LoadingEventStatus.inTransit:
        return Colors.blue;
      case LoadingEventStatus.completed:
        return Colors.green;
      case LoadingEventStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(event.status);
    final dateStr = '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year} ${event.eventDate.hour}:${event.eventDate.minute.toString().padLeft(2, '0')}';

    return Card(
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
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      event.status.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Bouteilles vides envoyées:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: event.emptyCylinders.entries.map((entry) {
                  return Chip(
                    label: Text('${entry.value} × ${entry.key}kg'),
                    labelStyle: theme.textTheme.bodySmall,
                  );
                }).toList(),
              ),
              if (event.fullCylindersReceived.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Bouteilles pleines reçues:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: event.fullCylindersReceived.entries.map((entry) {
                    return Chip(
                      label: Text('${entry.value} × ${entry.key}kg'),
                      labelStyle: theme.textTheme.bodySmall,
                    );
                  }).toList(),
                ),
              ],
              if (event.expenses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Frais totaux: ${_formatCurrency(event.totalExpenses)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              if (event.status != LoadingEventStatus.completed &&
                  event.status != LoadingEventStatus.cancelled) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onAddExpense != null)
                      TextButton.icon(
                        onPressed: onAddExpense,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ajouter frais'),
                      ),
                    if (event.status == LoadingEventStatus.preparing &&
                        onComplete != null) ...[
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Compléter'),
                      ),
                    ],
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