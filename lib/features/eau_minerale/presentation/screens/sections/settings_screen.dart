import 'package:flutter/material.dart';

import '../../widgets/product_catalog_card.dart';
import '../../widgets/product_info_banner.dart';
import '../../widgets/production_config_card.dart';

/// Settings screen for the Eau Minérale module.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Paramètres',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const ProductionConfigCard(),
        const SizedBox(height: 24),
        const ProductInfoBanner(),
        const SizedBox(height: 24),
        const ProductCatalogCard(),
        const SizedBox(height: 24),
      ],
    );
  }
}
