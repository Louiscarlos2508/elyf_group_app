import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/widgets/adaptive_navigation_scaffold.dart';
import 'sections/admin_dashboard_section.dart';
import 'sections/admin_enterprises_section.dart';
import 'sections/admin_modules_section.dart';
import 'sections/admin_users_section.dart';
import 'sections/admin_roles_section.dart';

/// Écran principal d'administration avec navigation adaptative
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _selectedIndex = 0;

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      // Rafraîchir les providers
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentUserIdProvider);
      context.go('/login');
    }
  }

  List<NavigationSection> _buildSections() {
    return [
      NavigationSection(
        label: 'Tableau de bord',
        icon: Icons.dashboard_outlined,
        builder: () => const AdminDashboardSection(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Entreprises',
        icon: Icons.business_outlined,
        builder: () => const AdminEnterprisesSection(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Modules',
        icon: Icons.apps_outlined,
        builder: () => const AdminModulesSection(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Utilisateurs',
        icon: Icons.people_outlined,
        builder: () => const AdminUsersSection(),
        isPrimary: true,
      ),
      NavigationSection(
        label: 'Rôles',
        icon: Icons.shield_outlined,
        builder: () => const AdminRolesSection(),
        isPrimary: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration • ELYF Groupe'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Se déconnecter'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildSections().map((s) => s.builder()).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _buildSections()
            .map(
              (section) => NavigationDestination(
                icon: Icon(section.icon),
                selectedIcon: Icon(section.icon),
                label: section.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

