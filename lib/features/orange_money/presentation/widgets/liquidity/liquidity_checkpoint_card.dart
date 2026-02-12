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
    this.requiresJustification = false,
    this.discrepancyPercentage,
    required this.onPressed,
    this.onJustifyPressed,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool hasCheckpoint;
  final int? cashAmount;
  final int? simAmount;
  final bool requiresJustification;
  final double? discrepancyPercentage;
  final VoidCallback onPressed;
  final VoidCallback? onJustifyPressed;

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
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF101828),
            ),
            overflow: TextOverflow.ellipsis,
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.formatFCFA(cashAmount!),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: Color(0xFF101828),
              ),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.formatFCFA(simAmount!),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: Color(0xFF155DFC),
              ),
            ),
          ),
        ],
        if (requiresJustification) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB91C1C)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Écart détecté: ${discrepancyPercentage?.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: onJustifyPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Justifier', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
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
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16),
                  SizedBox(width: 4),
                  Text('Faire le pointage', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
