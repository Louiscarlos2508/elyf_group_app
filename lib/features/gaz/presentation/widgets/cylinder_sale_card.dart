import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared.dart';
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

    return InkWell(
      onTap: hasStock ? onTap : null,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Visual Header
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          gradientColor,
                          gradientEndColor,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.local_fire_department,
                            size: 100,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        Center(
                          child: Text(
                            '${cylinder.weight}kg',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Info Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Gaz',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: hasStock 
                                  ? Colors.green.withValues(alpha: 0.1) 
                                  : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hasStock ? '$stock' : 'Rupture',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: hasStock ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatDouble(cylinder.sellPrice),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Mini Action
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: hasStock 
                              ? theme.colorScheme.primary.withValues(alpha: 0.05)
                              : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasStock 
                                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                : theme.colorScheme.outline.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              hasStock ? 'Vendre' : 'Indisponible',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: hasStock 
                                  ? theme.colorScheme.primary 
                                  : theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!hasStock)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.4),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.do_not_disturb_on_outlined,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
