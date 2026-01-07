import 'package:flutter/material.dart';

/// Tab selector widget for liquidity screen navigation.
class LiquidityTabs extends StatelessWidget {
  const LiquidityTabs({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFECECF0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildTab(
            index: 0,
            label: 'Historique récent',
          ),
          _buildTab(
            index: 1,
            label: 'Tous les pointages',
          ),
        ],
      ),
    );
  }

  Widget _buildTab({required int index, required String label}) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2.99),
          height: 29.428,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(color: Colors.transparent, width: 1.219)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0A0A0A),
            ),
          ),
        ),
      ),
    );
  }
}

