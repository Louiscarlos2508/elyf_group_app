import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Card widget for tips and recommendations.
class SettingsTipsCard extends StatelessWidget {
  const SettingsTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ElyfCard(
      padding: const EdgeInsets.all(24),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C897).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, size: 22, color: Color(0xFF00C897)),
              ),
              const SizedBox(width: 16),
              Text(
                'Conseils d\'Utilisation',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildTipItem(
            context,
            'Optimisation Alertes',
            'Maintenez toutes les notifications actives pour une réactivité maximale sur la liquidité.',
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            context,
            'Gestion Liquidité',
            'Le seuil de 50.000 F est un minimum conseillé pour assurer la continuité de service.',
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            context,
            'Sécurité SIM',
            'Assurez-vous que le numéro configuré correspond exactement à la SIM de service.',
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            context,
            'Pointages RIGOUREUX',
            'Un double pointage quotidien garantit l\'exactitude de vos commissions en fin de mois.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String title, String description) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Icon(Icons.stars_rounded, size: 16, color: Color(0xFF00C897)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF00C897),
                  letterSpacing: 0.8,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
