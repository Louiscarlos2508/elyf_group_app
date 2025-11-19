import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings screen for the Eau Minérale module.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Paramètres',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _SettingsSection(
          title: 'Production',
          children: [
            _SettingsTile(
              icon: Icons.calendar_today,
              title: 'Configuration des périodes',
              subtitle: 'Définir les jours par période',
              onTap: () {
                // TODO: Navigate to period config
              },
            ),
            _SettingsTile(
              icon: Icons.factory,
              title: 'Lignes de production',
              subtitle: 'Gérer les lignes de production',
              onTap: () {
                // TODO: Navigate to production lines
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SettingsSection(
          title: 'Ventes',
          children: [
            _SettingsTile(
              icon: Icons.price_check,
              title: 'Prix des produits',
              subtitle: 'Gérer les prix unitaires',
              onTap: () {
                // TODO: Navigate to prices
              },
            ),
            _SettingsTile(
              icon: Icons.credit_card,
              title: 'Conditions de crédit',
              subtitle: 'Paramètres de crédit client',
              onTap: () {
                // TODO: Navigate to credit settings
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SettingsSection(
          title: 'Stock',
          children: [
            _SettingsTile(
              icon: Icons.inventory_2,
              title: 'Seuils d\'alerte',
              subtitle: 'Configurer les alertes de stock faible',
              onTap: () {
                // TODO: Navigate to stock thresholds
              },
            ),
            _SettingsTile(
              icon: Icons.shopping_cart,
              title: 'Fournisseurs',
              subtitle: 'Gérer les fournisseurs de matières premières',
              onTap: () {
                // TODO: Navigate to suppliers
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SettingsSection(
          title: 'Système',
          children: [
            _SettingsTile(
              icon: Icons.sync,
              title: 'Synchronisation',
              subtitle: 'Synchroniser avec le serveur',
              onTap: () {
                // TODO: Trigger sync
              },
            ),
            _SettingsTile(
              icon: Icons.print,
              title: 'Imprimante',
              subtitle: 'Configuration de l\'imprimante Sunmi',
              onTap: () {
                // TODO: Navigate to printer settings
              },
            ),
            _SettingsTile(
              icon: Icons.backup,
              title: 'Sauvegarde',
              subtitle: 'Exporter les données',
              onTap: () {
                // TODO: Navigate to backup
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SettingsSection(
          title: 'Compte',
          children: [
            _SettingsTile(
              icon: Icons.person,
              title: 'Profil utilisateur',
              subtitle: 'Modifier le profil',
              onTap: () {
                // TODO: Navigate to profile
              },
            ),
            _SettingsTile(
              icon: Icons.logout,
              title: 'Déconnexion',
              subtitle: 'Se déconnecter du module',
              onTap: () {
                // TODO: Logout
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

