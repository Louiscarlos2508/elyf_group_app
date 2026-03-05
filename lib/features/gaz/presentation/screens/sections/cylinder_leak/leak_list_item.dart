import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/cylinder_leak.dart';

/// Item de liste pour une fuite.
class LeakListItem extends ConsumerStatefulWidget {
  const LeakListItem({super.key, required this.leak});

  final CylinderLeak leak;

  @override
  ConsumerState<LeakListItem> createState() => _LeakListItemState();
}

class _LeakListItemState extends ConsumerState<LeakListItem> {
  Color _getStatusColor(LeakStatus status) {
    switch (status) {
      case LeakStatus.reported:
        return Colors.orange;
      case LeakStatus.sentForExchange:
        return Colors.blue;
      case LeakStatus.exchanged:
        return Colors.green;
      case LeakStatus.convertedToEmpty:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(widget.leak.status);
    final dateStr =
        '${widget.leak.reportedDate.day}/${widget.leak.reportedDate.month}/${widget.leak.reportedDate.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bouteille ${widget.leak.weight}kg',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${widget.leak.cylinderId}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Text(
                        widget.leak.status.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF6A7282),
                ),
              ),
              if (widget.leak.exchangeDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Échangée: ${widget.leak.exchangeDate!.day}/${widget.leak.exchangeDate!.month}/${widget.leak.exchangeDate!.year}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

