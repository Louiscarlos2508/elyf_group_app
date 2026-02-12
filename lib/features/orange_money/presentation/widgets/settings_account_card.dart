import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Card widget for account information.
class SettingsAccountCard extends StatelessWidget {
  const SettingsAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ElyfCard(
      padding: const EdgeInsets.all(24),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_rounded, size: 22, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Text(
                'Mon Compte',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildAccountDetail(
                  context,
                  label: 'Utilisateur Connecté',
                  value: 'Mobile Money Admin',
                  icon: Icons.badge_outlined,
                ),
              ),
              Expanded(
                child: _buildAccountDetail(
                  context,
                  label: 'Rôle',
                  value: 'Administrateur',
                  icon: Icons.admin_panel_settings_outlined,
                  isBadge: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildAccountDetail(
                  context,
                  label: 'Identifiant',
                  value: '@admin_mm',
                  icon: Icons.alternate_email_rounded,
                ),
              ),
              Expanded(
                child: _buildAccountDetail(
                  context,
                  label: 'Téléphone',
                  value: '0701234567',
                  icon: Icons.phone_android_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetail(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isBadge = false,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.w700,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w900,
                fontFamily: 'Outfit',
              ),
            ),
          )
        else
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
      ],
    );
  }
}
