import 'package:flutter/material.dart';

import '../../../../domain/entities/production_session.dart';

/// Widget affichant les informations de base de la session de production.
class ProductionTrackingSessionInfo extends StatelessWidget {
  const ProductionTrackingSessionInfo({
    super.key,
    required this.session,
  });

  final ProductionSession session;

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Informations de session',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Date',
              _formatDate(session.date),
            ),
            if (session.heureDebut != null)
              _buildInfoRow(
                context,
                Icons.access_time,
                'Heure de début',
                _formatDateTime(session.heureDebut!),
              ),
            if (session.heureFin != null)
              _buildInfoRow(
                context,
                Icons.check_circle_outline,
                'Heure de fin',
                _formatDateTime(session.heureFin!),
              ),
            _buildInfoRow(
              context,
              Icons.precision_manufacturing,
              'Machines utilisées',
              '${session.machinesUtilisees.length}',
            ),
            _buildInfoRow(
              context,
              Icons.inventory_2,
              'Bobines utilisées',
              '${session.bobinesUtilisees.length}',
            ),
            if (session.quantiteProduite > 0)
              _buildInfoRow(
                context,
                Icons.water_drop,
                'Quantité produite',
                '${session.quantiteProduite} L',
              ),
            if (session.emballagesUtilises != null &&
                session.emballagesUtilises! > 0)
              _buildInfoRow(
                context,
                Icons.inventory,
                'Emballages utilisés',
                '${session.emballagesUtilises}',
              ),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                session.notes!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

