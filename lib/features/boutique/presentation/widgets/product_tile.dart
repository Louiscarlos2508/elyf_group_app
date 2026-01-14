import 'dart:io';

import 'package:flutter/material.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';

import '../../domain/entities/product.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
    this.onRestock,
    this.showRestockButton = false,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onRestock;
  final bool showRestockButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = product.stock <= 10;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: product.stock > 0 ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: product.imageUrl != null
                    ? _buildProductImage(product.imageUrl!, theme)
                    : _buildPlaceholder(theme),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatFCFA(product.price),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 14,
                        color: isLowStock
                            ? Colors.orange
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Stock: ${product.stock}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isLowStock
                                ? Colors.orange
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isLowStock
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (showRestockButton && onRestock != null)
                        InkWell(
                          onTap: onRestock,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.add_shopping_cart,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
