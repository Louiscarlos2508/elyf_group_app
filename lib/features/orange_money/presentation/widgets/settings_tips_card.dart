import 'package:flutter/material.dart';

/// Card widget for tips and recommendations.
class SettingsTipsCard extends StatelessWidget {
  const SettingsTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        border: Border.all(color: const Color(0xFFB9F8CF), width: 1.219),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lightbulb,
              color: Color(0xFF0D542B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Conseils d\'utilisation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0D542B),
                  ),
                ),
                const SizedBox(height: 4),
                _buildTipItem(
                  'Notifications :',
                  'Activez toutes les alertes pour ne manquer aucune information importante',
                ),
                _buildTipItem(
                  'Seuil liquidité :',
                  'Ajustez selon vos besoins quotidiens moyens (minimum recommandé : 50 000 F)',
                ),
                _buildTipItem(
                  'Échéances :',
                  'Configurez l\'alerte 3-5 jours avant pour avoir le temps de préparer les paiements',
                ),
                _buildTipItem(
                  'Sécurité :',
                  'Changez régulièrement votre mot de passe dans la section Profil',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String boldText, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF016630),
            fontWeight: FontWeight.normal,
          ),
          children: [
            TextSpan(
              text: '• $boldText ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
