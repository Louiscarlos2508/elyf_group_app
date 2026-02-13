import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/boutique_header.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/widgets/integrity_verification_dialog.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/sections/category_management_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/settings/printer_settings_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/settings/receipt_settings_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/settings/alert_settings_screen.dart';
import 'package:elyf_groupe_app/features/boutique/presentation/screens/settings/payment_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        const BoutiqueHeader(
          title: "PARAMÈTRES",
          subtitle: "Configuration du Module Boutique",
          gradientColors: [
            Color(0xFF475569), // Slate 600
            Color(0xFF334155), // Slate 700
          ],
          shadowColor: Color(0xFF475569),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionTitle("Matériel & Impression"),
              _buildSettingTile(
                icon: Icons.print_outlined,
                title: "Imprimante Thermique",
                subtitle: "Gérer la connexion Sunmi ou System",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                ),
              ),
              _buildSettingTile(
                icon: Icons.receipt_long_outlined,
                title: "Format du Reçu",
                subtitle: "Largeur (58mm/80mm), Logo, Message de pied",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReceiptSettingsScreen()),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Configuration Commerciale"),
              _buildSettingTile(
                icon: Icons.notifications_active_outlined,
                title: "Alertes de Stock",
                subtitle: "Seuils globaux et notifications push",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertSettingsScreen()),
                ),
              ),
              _buildSettingTile(
                icon: Icons.money_outlined,
                title: "Méthodes de Paiement",
                subtitle: "Activer/Désactiver Cash, Orange Money, etc.",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentSettingsScreen()),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Administration"),
              _buildSettingTile(
                icon: Icons.sync,
                title: "Synchronisation Forcee",
                subtitle: "Forcer la remontée des transactions vers le cloud",
                onTap: () {},
                color: Colors.blue,
              ),
              _buildSettingTile(
                icon: Icons.delete_outline,
                title: "Réinitialiser les données locales",
                subtitle: "Action irréversible - Vide la base Drift locale",
                onTap: () {},
                color: Colors.red,
              ),
              _buildSettingTile(
                icon: Icons.category_outlined,
                title: "Gestion des catégories",
                subtitle: "Gérer les types de produits",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Sécurité & Intégrité"),
              _buildSettingTile(
                icon: Icons.verified_user_outlined,
                title: "Vérifier l'intégrité du registre",
                subtitle: "Analyser la validité mathématique des signatures",
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const IntegrityVerificationDialog(),
                  );
                },
                color: Colors.teal,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.black87),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
