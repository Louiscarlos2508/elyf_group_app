import 'package:flutter/material.dart';

/// Security note card for profile screen.
class ProfileSecurityNoteCard extends StatelessWidget {
  const ProfileSecurityNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pour votre sécurité, changez régulièrement votre mot de passe et ne le partagez jamais.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

