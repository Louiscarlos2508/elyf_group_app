import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_logout_card.dart';
import 'profile_personal_info_card.dart';
import 'profile_security_card.dart';
import 'profile_security_note_card.dart';
import '../../../../core/entities/user_profile.dart';

/// Reusable profile screen for all modules.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context) {
    // TODO: Implement edit profile dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modifier mes informations - À implémenter')),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    // TODO: Implement change password dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changer mon mot de passe - À implémenter')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = UserProfile.defaultProfile();
    final theme = Theme.of(context);
    
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
                child: ProfilePersonalInfoCard(
                  profile: profile,
                  onEdit: () => _showEditProfileDialog(context),
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

