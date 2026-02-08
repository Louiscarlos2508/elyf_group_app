import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_logout_card.dart';
import 'profile_personal_info_card.dart';
import 'profile_security_card.dart';
import 'profile_security_note_card.dart';
import 'edit_profile_dialog.dart';
import 'change_password_dialog.dart';
import '../../../../core/domain/entities/user_profile.dart';
import '../../../../core/auth/providers.dart'
    show currentUserIdProvider, currentUserProfileProvider, currentUserProvider;

/// Reusable profile screen for all modules.
///
/// Utilise les providers d'authentification partagés pour récupérer les données utilisateur.
/// Accepte un callback optionnel pour la mise à jour du profil si un module
/// veut utiliser son propre système de mise à jour (ex: module administration).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.onProfileUpdate});

  /// Callback optionnel pour la mise à jour du profil.
  /// Si fourni, sera utilisé par EditProfileDialog au lieu de la mise à jour Firestore directe.
  final OnProfileUpdateCallback? onProfileUpdate;

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(onProfileUpdate: onProfileUpdate),
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

    return Scaffold( // Wrapped in Scaffold to support ElyfAppBar
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Premium App Bar
          // Premium Sliver App Bar
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85),
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Mon Profil',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          // Header with Avatar
          SliverToBoxAdapter(
            child: profileAsync.when(
              data: (userData) {
                 final profile = _buildUserProfile(userData, currentUserAsync.value, currentUserId);
                 return _ProfileHeader(profile: profile);
              },
              loading: () => const _ProfileHeaderShimmer(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: profileAsync.when(
                data: (userData) {
                  final profile = _buildUserProfile(userData, currentUserAsync.value, currentUserId);
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
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  UserProfile _buildUserProfile(Map<String, dynamic>? userData, dynamic appUser, String? currentUserId) {
    if (userData != null && currentUserId != null) {
      final displayName = appUser?.displayName ?? '';
      final nameParts = displayName.split(' ');
      return UserProfile(
        id: currentUserId,
        firstName: userData['firstName'] as String? ?? (nameParts.isNotEmpty ? nameParts.first : 'Utilisateur'),
        lastName: userData['lastName'] as String? ?? (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ''),
        username: userData['username'] as String? ?? userData['email']?.toString().split('@').first ?? 'user',
        role: (userData['isAdmin'] as bool? ?? false) ? 'Administrateur' : (userData['isActive'] as bool? ?? true ? 'Actif' : 'Inactif'),
        email: userData['email'] as String? ?? appUser?.email,
        phone: userData['phone'] as String?,
      );
    } else if (appUser != null) {
       // Fallback
      final displayName = appUser.displayName ?? appUser.email;
      final nameParts = displayName.split(' ');
      return UserProfile(
        id: appUser.id,
        firstName: nameParts.isNotEmpty ? nameParts.first : 'Utilisateur',
        lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        username: appUser.email.split('@').first,
        role: appUser.isAdmin ? 'Administrateur' : 'Utilisateur',
        email: appUser.email,
      );
    }
    return UserProfile.defaultProfile();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = (profile.firstName.isNotEmpty ? profile.firstName[0] : '') +
        (profile.lastName.isNotEmpty ? profile.lastName[0] : '');
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${profile.firstName} ${profile.lastName}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profile.role.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderShimmer extends StatelessWidget {
  const _ProfileHeaderShimmer();

  @override
  Widget build(BuildContext context) {
    // Basic shimmer placeholder
     return const Padding(
       padding: EdgeInsets.symmetric(vertical: 24),
       child: Center(child: CircularProgressIndicator()),
     );
  }
}
