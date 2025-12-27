import 'package:flutter/material.dart';

import '../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/cylinder.dart';

/// Card displaying a cylinder for sale - matches Figma design.
class CylinderSaleCard extends StatelessWidget {
  const CylinderSaleCard({
    super.key,
    required this.cylinder,
    required this.stock,
    required this.onTap,
  });

  final Cylinder cylinder;
  final int stock;
  final VoidCallback onTap;

  Color _getGradientColor(int weight) {
    switch (weight) {
      case 6:
        return const Color(0xFF00C950); // Green
      case 12:
        return const Color(0xFF2B7FFF); // Blue
      case 38:
        return const Color(0xFFFF6900); // Orange
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Color _getGradientEndColor(int weight) {
    switch (weight) {
      case 6:
        return const Color(0xFF00A63E);
      case 12:
        return const Color(0xFF155DFC);
      case 38:
        return const Color(0xFFF54900);
      default:
        return const Color(0xFF2563EB);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasStock = stock > 0;
    final gradientColor = _getGradientColor(cylinder.weight);
    final gradientEndColor = _getGradientEndColor(cylinder.weight);

    return Container(
      width: 325,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with weight and stock badge
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${cylinder.weight}kg',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEEF2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.transparent,
                      width: 1.3,
                    ),
                  ),
                  child: Text(
                    '$stock en stock',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF030213),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder with gradient
                Container(
                  height: 192,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [gradientColor, gradientEndColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Icon placeholder in center
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_fire_department,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      // Overlay if no stock
                      if (!hasStock)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.block,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Price section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Prix unitaire',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF4A5565),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatDouble(cylinder.sellPrice)
                            .replaceAll(' FCFA', ''),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF155DFC),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'FCFA',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF6A7282),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Action button
                GestureDetector(
                  onTap: hasStock ? onTap : null,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: hasStock
                          ? const Color(0xFF030213)
                          : const Color(0xFFECEEF2).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        hasStock ? 'Vendre' : 'Rupture de stock',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: hasStock
                              ? Colors.white
                              : const Color(0xFF030213).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

