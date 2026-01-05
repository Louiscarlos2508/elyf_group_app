import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/bottle_price_table.dart';
import '../../widgets/cylinder_form_dialog.dart';
import '../../widgets/point_of_sale_form_dialog.dart';
import '../../widgets/point_of_sale_table.dart';

/// Écran de paramètres pour le module Gaz selon le design Figma.
class GazSettingsScreen extends ConsumerWidget {
  const GazSettingsScreen({
    super.key,
    this.enterpriseId,
    this.moduleId,
  });

  final String? enterpriseId;
  final String? moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveEnterpriseId = enterpriseId ?? 'gaz_1';
    final effectiveModuleId = moduleId ?? 'gaz';
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      color: const Color(0xFFF9FAFB),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(23.98),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section Configuration des prix
                _buildPriceConfigurationSection(
                  context: context,
                  theme: theme,
                  enterpriseId: effectiveEnterpriseId,
                  moduleId: effectiveModuleId,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 23.98),
                // Section Gestion des points de vente
                _buildPointOfSaleSection(
                  context: context,
                  theme: theme,
                  enterpriseId: effectiveEnterpriseId,
                  moduleId: effectiveModuleId,
                  isMobile: isMobile,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la section de configuration des prix.
  Widget _buildPriceConfigurationSection({
    required BuildContext context,
    required ThemeData theme,
    required String enterpriseId,
    required String moduleId,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec titre et bouton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuration des prix',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérez les types de bouteilles et leurs tarifs',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF6A7282),
                  ),
                ),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF030213),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11.99,
                  vertical: 9.99,
                ),
                minimumSize: const Size(136.947, 36),
              ),
              onPressed: () {
                // TODO: Ouvrir le formulaire d'ajout de type
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Nouveau type',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 23.98),
        // Carte avec tableau des tarifs
        BottlePriceTable(
          enterpriseId: enterpriseId,
          moduleId: moduleId,
        ),
      ],
    );
  }

  /// Construit la section de gestion des points de vente.
  Widget _buildPointOfSaleSection({
    required BuildContext context,
    required ThemeData theme,
    required String enterpriseId,
    required String moduleId,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec titre et bouton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des points de vente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Créez et gérez les différents points de vente',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: const Color(0xFF6A7282),
                  ),
                ),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF030213),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11.99,
                  vertical: 9.99,
                ),
                minimumSize: const Size(201.057, 36),
              ),
              onPressed: () {
                // TODO: Ouvrir le formulaire d'ajout de point de vente
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'Nouveau point de vente',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 23.98),
        // Carte avec tableau des points de vente
        PointOfSaleTable(
          enterpriseId: enterpriseId,
          moduleId: moduleId,
        ),
      ],
    );
  }
}
