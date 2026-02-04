import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/providers.dart' show currentUserIdProvider;
import '../../../../core/errors/app_exceptions.dart';
import 'package:elyf_groupe_app/shared.dart'
    show NavigationSection, ProfileScreen, AdaptiveNavigationScaffold;
import '../../application/providers.dart'
    show userControllerProvider, usersProvider, isAdminSyncingProvider;
import '../../domain/entities/user.dart' show User;
import 'sections/admin_dashboard_section.dart';
import 'sections/admin_enterprises_section.dart';
import 'sections/admin_modules_section.dart';
import 'sections/admin_users_section.dart';
import 'sections/admin_roles_section.dart';
import 'sections/admin_audit_trail_section.dart';

/// Écran principal d'administration avec navigation adaptative
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _selectedIndex = 0;

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Mon Profil')),
          body: ProfileScreen(
            // Utiliser le callback du module administration pour la mise à jour
            // Cela permet d'utiliser UserController et d'avoir l'audit trail
            onProfileUpdate:
                ({
                  required userId,
                  required firstName,
                  required lastName,
                  required username,
                  email,
                  phone,
                }) async {
                  final currentUserId = ref.read(currentUserIdProvider);
                  if (currentUserId == null || currentUserId != userId) {
                    throw AuthenticationException(
                      'Utilisateur non connecté ou ID invalide',
                      'USER_NOT_AUTHENTICATED',
                    );
                  }

                  // Récupérer l'utilisateur actuel
                  final List<User> users = await ref.read(usersProvider.future);
                  final currentUser = users.firstWhere(
                    (u) => u.id == currentUserId,
                    orElse: () => throw NotFoundException(
                      'Utilisateur non trouvé',
                      'USER_NOT_FOUND',
                    ),
                  );

                  // Créer l'utilisateur mis à jour
                  final updatedUser = currentUser.copyWith(
                    firstName: firstName,
                    lastName: lastName,
                    username: username,
                    email: email,
                    phone: phone,
                    updatedAt: DateTime.now(),
                  );

                  // Utiliser UserController pour la mise à jour (inclut audit trail)
                  await ref
                      .read(userControllerProvider)
                      .updateUser(
                        updatedUser,
                        currentUserId: currentUserId,
                        oldUser: currentUser,
                      );
                },
          ),
        ),
      ),
    );
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
      NavigationSection(
        label: 'Audit Trail',
        icon: Icons.history_outlined,
        builder: () => const AdminAuditTrailSection(),
        isPrimary: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    final isSyncing = ref.watch(isAdminSyncingProvider).asData?.value ?? false;

    return AdaptiveNavigationScaffold(
      sections: sections,
      appTitle: 'Administration • ELYF Groupe',
      selectedIndex: _selectedIndex,
      onIndexChanged: (index) {
        setState(() => _selectedIndex = index);
      },
      appBarActions: [
        if (isSyncing)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Synchronisation en cours...',
              child: Icon(
                Icons.sync,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => _navigateToProfile(context),
          tooltip: 'Mon Profil',
        ),
      ],
    );
  }
}
