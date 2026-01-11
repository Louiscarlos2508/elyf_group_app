import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_logout_card.dart';
import 'profile_personal_info_card.dart';
import 'profile_security_card.dart';
import 'profile_security_note_card.dart';
import 'edit_profile_dialog.dart';
import 'change_password_dialog.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/auth/providers.dart' show currentUserIdProvider, currentUserProfileProvider, currentUserProvider;
import 'edit_profile_dialog.dart';

/// Reusable profile screen for all modules.
/// 
/// Utilise les providers d'authentification partagés pour récupérer les données utilisateur.
/// Accepte un callback optionnel pour la mise à jour du profil si un module
/// veut utiliser son propre système de mise à jour (ex: module administration).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    this.onProfileUpdate,
  });

  /// Callback optionnel pour la mise à jour du profil.
  /// Si fourni, sera utilisé par EditProfileDialog au lieu de la mise à jour Firestore directe.
  final OnProfileUpdateCallback? onProfileUpdate;

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        onProfileUpdate: onProfileUpdate,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(currentUserIdProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  isWide ? 24 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon Profil',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gérez vos informations personnelles et votre mot de passe',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: profileAsync.when(
                  data: (userData) {
                    UserProfile profile;
                    if (userData != null && currentUserId != null) {
                      final displayName = currentUserAsync.value?.displayName ?? '';
                      final nameParts = displayName.split(' ');
                      profile = UserProfile(
                        id: currentUserId,
                        firstName: userData['firstName'] as String? ?? 
                            (nameParts.isNotEmpty ? nameParts.first : 'Utilisateur'),
                        lastName: userData['lastName'] as String? ?? 
                            (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ''),
                        username: userData['username'] as String? ?? 
                            userData['email']?.toString().split('@').first ?? 'user',
                        role: (userData['isAdmin'] as bool? ?? false) 
                            ? 'Administrateur' 
                            : (userData['isActive'] as bool? ?? true ? 'Actif' : 'Inactif'),
                        email: userData['email'] as String? ?? currentUserAsync.value?.email,
                        phone: userData['phone'] as String?,
                      );
                    } else if (currentUserAsync.value != null) {
                      // Fallback vers AppUser si Firestore n'est pas disponible
                      final appUser = currentUserAsync.value!;
                      final displayName = appUser.displayName ?? appUser.email;
                      final nameParts = displayName?.split(' ') ?? [];
                      profile = UserProfile(
                        id: appUser.id,
                        firstName: nameParts.isNotEmpty ? nameParts.first : 'Utilisateur',
                        lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
                        username: appUser.email.split('@').first,
                        role: appUser.isAdmin ? 'Administrateur' : 'Utilisateur',
                        email: appUser.email,
                      );
                    } else {
                      profile = UserProfile.defaultProfile();
                    }
                    return ProfilePersonalInfoCard(
                      profile: profile,
                      onEdit: () => _showEditProfileDialog(context),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => ProfilePersonalInfoCard(
                    profile: UserProfile.defaultProfile(),
                    onEdit: () => _showEditProfileDialog(context),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: ProfileSecurityCard(
                  onChangePassword: () => _showChangePasswordDialog(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: ProfileSecurityNoteCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: const ProfileLogoutCard(),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        );
      },
    );
  }
}

