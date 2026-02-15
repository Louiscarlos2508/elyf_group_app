import 'dart:io';

import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_card.dart';
import '../../../../app/theme/app_colors.dart';

import '../../domain/entities/product.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({
    Key? key,
    required this.product,
    required this.onTap,
    this.onRestock,
    this.onAdjust,
    this.onDuplicate,
    this.onPriceHistory,
    this.showRestockButton = false,
    this.isEnabled = true,
  }) : super(key: key);

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onRestock;
  final VoidCallback? onAdjust;
  final VoidCallback? onDuplicate;
  final VoidCallback? onPriceHistory;
  final bool showRestockButton;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = product.stock <= product.lowStockThreshold && product.stock > 0;
    final isOutOfStock = product.stock == 0;
    final effectivelyEnabled = isEnabled && !isOutOfStock;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: ElyfCard(
        padding: EdgeInsets.zero,
        onTap: effectivelyEnabled ? onTap : null,
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: product.imageUrl != null
                        ? _buildProductImage(product.imageUrl!, theme)
                        : _buildPlaceholder(theme),
                  ),
                  // Out of stock overlay
                  if (isOutOfStock)
                    Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RUPTURE',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Category badge if any
                  if (product.categoryId != null && !isOutOfStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.categoryId!.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              CurrencyFormatter.formatFCFA(product.price),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                      children: [
                        // Stock Chip
                        _buildStockChip(theme, isOutOfStock, isLowStock),
                        const Spacer(),
                        if (onPriceHistory != null)
                          Material(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: onPriceHistory,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.show_chart_rounded,
                                  size: 16,
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ),
                        if (onDuplicate != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Material(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: onDuplicate,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.content_copy_rounded,
                                    size: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (showRestockButton)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 4),
                              if (onAdjust != null)
                                Material(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: onAdjust,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        size: 16,
                                        color: theme.colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              if (onRestock != null) ...[
                                const SizedBox(width: 4),
                                Material(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: onRestock,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                            ),
                          ],
                        ),
                  ],
                ),
                ),
                );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockChip(ThemeData theme, bool isOutOfStock, bool isLowStock) {
    Color color;
    String label;
    IconData icon;

    if (isOutOfStock) {
      color = theme.colorScheme.error;
      label = '0';
      icon = Icons.do_not_disturb_on_rounded;
    } else if (isLowStock) {
      color = const Color(0xFFF59E0B); // Amber 500
      label = '${product.stock}';
      icon = Icons.warning_amber_rounded;
    } else {
      color = AppColors.success;
      label = '${product.stock}';
      icon = Icons.inventory_2_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl, ThemeData theme) {
    // Vérifier si c'est un chemin de fichier local ou une URL
    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      try {
        return Image.file(
          File(imageUrl.replaceFirst('file://', '')),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
        );
      } catch (e) {
        return _buildPlaceholder(theme);
      }
    } else {
      // URL réseau
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
      );
    }
  }
}
