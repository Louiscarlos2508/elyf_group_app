import 'package:flutter/material.dart';

import '../../../../core/domain/entities/user_profile.dart';

/// Personal information card for profile screen.
class ProfilePersonalInfoCard extends StatelessWidget {
  const ProfilePersonalInfoCard({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.blue.shade300, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations personnelles',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vos informations de base et votre rôle dans l\'application',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: _ProfileTextField(
                            label: 'Prénom',
                            value: profile.firstName,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ProfileTextField(
                            label: 'Nom',
                            value: profile.lastName,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _ProfileTextField(
                          label: 'Prénom',
                          value: profile.firstName,
                        ),
                        const SizedBox(height: 16),
                        _ProfileTextField(
                          label: 'Nom',
                          value: profile.lastName,
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: _ProfileTextField(
                            label: 'Nom d\'utilisateur',
                            value: profile.username,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ProfileTextField(
                            label: 'Rôle',
                            value: profile.role,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _ProfileTextField(
                          label: 'Nom d\'utilisateur',
                          value: profile.username,
                        ),
                        const SizedBox(height: 16),
                        _ProfileTextField(label: 'Rôle', value: profile.role),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onEdit,
              child: const Text('Modifier mes informations'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
