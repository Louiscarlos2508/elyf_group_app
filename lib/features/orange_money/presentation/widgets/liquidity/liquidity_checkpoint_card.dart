import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

/// Card widget displaying a single liquidity checkpoint (morning or evening).
class LiquidityCheckpointCard extends StatelessWidget {
  const LiquidityCheckpointCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.hasCheckpoint,
    this.cashAmount,
    this.simAmount,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool hasCheckpoint;
  final int? cashAmount;
  final int? simAmount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.219,
        ),
      ),
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(), const SizedBox(height: 12), _buildContent()],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Color(0xFF101828),
          ),
        ),
        if (hasCheckpoint) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent, width: 1.219),
            ),
            child: const Text(
              '✓ Fait',
              style: TextStyle(fontSize: 12, color: Color(0xFF016630)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent() {
    if (hasCheckpoint && (cashAmount != null || simAmount != null)) {
      return _buildCheckpointDetails();
    }
    return _buildEmptyState();
  }

  Widget _buildCheckpointDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cashAmount != null) ...[
          const Text(
            '💵 Cash disponible',
            style: TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatFCFA(cashAmount!),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.normal,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (simAmount != null) ...[
          const Text(
            '📱 Solde SIM',
            style: TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatFCFA(simAmount!),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.normal,
              color: Color(0xFF155DFC),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const Text(
          'Aucun pointage effectué',
          style: TextStyle(fontSize: 14, color: Color(0xFF6A7282)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: title.contains('Matin')
                  ? const Color(0xFFF54900)
                  : const Color(0xFF4F39F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 16),
                SizedBox(width: 4),
                Text('Faire le pointage', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
