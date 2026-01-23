import 'package:flutter/material.dart';

/// Widget réutilisable pour les états de chargement.
///
/// Assure une cohérence visuelle pour tous les loading states.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.height = 120,
    this.message,
  });

  final double height;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
