import 'package:flutter/material.dart';

/// Card widget for system information.
class SettingsSystemInfoCard extends StatelessWidget {
  const SettingsSystemInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Color(0xFF0A0A0A),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Informations système',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Version', '1.0.0'),
                ),
                Expanded(
                  child: _buildInfoItem('Dernière mise à jour', '16 Nov 2024'),
                ),
                Expanded(
                  child: _buildInfoItem('Entreprise', 'Groupe ELYF'),
                ),
                Expanded(
                  child: _buildInfoItem('Application', 'Mobile Money'),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.settings,
                  size: 20,
                  color: Color(0xFF0A0A0A),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ELYF Mobile Money',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Application de gestion des transactions Mobile Money, liquidité et commissions pour le Groupe ELYF. Optimisée pour tablette avec système multi-utilisateurs et sécurité renforcée.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4A5565),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Color(0xFF4A5565),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF101828),
          ),
        ),
      ],
    );
  }
}

