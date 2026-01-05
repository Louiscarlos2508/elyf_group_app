import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/settings.dart';

/// Card widget for threshold settings.
class SettingsThresholdsCard extends StatefulWidget {
  const SettingsThresholdsCard({
    super.key,
    required this.thresholds,
    required this.onThresholdsChanged,
  });

  final ThresholdSettings thresholds;
  final ValueChanged<ThresholdSettings> onThresholdsChanged;

  @override
  State<SettingsThresholdsCard> createState() => _SettingsThresholdsCardState();
}

class _SettingsThresholdsCardState extends State<SettingsThresholdsCard> {
  late TextEditingController _liquidityController;
  late TextEditingController _daysController;

  @override
  void initState() {
    super.initState();
    _liquidityController = TextEditingController(
      text: widget.thresholds.criticalLiquidityThreshold.toString(),
    );
    _daysController = TextEditingController(
      text: widget.thresholds.paymentDueDaysBefore.toString(),
    );
  }

  @override
  void didUpdateWidget(SettingsThresholdsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thresholds != widget.thresholds) {
      _liquidityController.text = widget.thresholds.criticalLiquidityThreshold.toString();
      _daysController.text = widget.thresholds.paymentDueDaysBefore.toString();
    }
  }

  @override
  void dispose() {
    _liquidityController.dispose();
    _daysController.dispose();
    super.dispose();
  }

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
                  Icons.tune,
                  size: 20,
                  color: Color(0xFF0A0A0A),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Seuils et limites',
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
                  child: _buildNumberField(
                    label: 'Seuil de liquidité critique (FCFA)',
                    controller: _liquidityController,
                    hint: '50000',
                    description:
                        'Vous serez alerté si la liquidité descend en dessous de ce montant',
                    onChanged: (value) {
                      final intValue = int.tryParse(value) ?? widget.thresholds.criticalLiquidityThreshold;
                      widget.onThresholdsChanged(
                        widget.thresholds.copyWith(criticalLiquidityThreshold: intValue),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberField(
                    label: 'Jours avant échéance pour alerte',
                    controller: _daysController,
                    hint: '3',
                    description:
                        'Nombre de jours avant l\'échéance pour recevoir une alerte',
                    onChanged: (value) {
                      final intValue = int.tryParse(value) ?? widget.thresholds.paymentDueDaysBefore;
                      widget.onThresholdsChanged(
                        widget.thresholds.copyWith(paymentDueDaysBefore: intValue),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecommendationsBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String description,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0A0A0A),
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent, width: 1.219),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0A0A0A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF717182),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF4A5565),
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsBox() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(
          color: const Color(0xFFFEE685),
          width: 1.219,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Color(0xFF7B3306),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Recommandations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7B3306),
                  ),
                ),
                const SizedBox(height: 4),
                _buildRecommendationItem(
                  'Seuil liquidité recommandé : 50 000 - 100 000 F',
                ),
                _buildRecommendationItem(
                  'Alerte échéance recommandée : 3-5 jours avant',
                ),
                _buildRecommendationItem(
                  'Activez toutes les notifications pour une gestion optimale',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '• $text',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF973C00),
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}

