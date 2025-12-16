import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bouton d'actualisation réutilisable pour rafraîchir les providers.
class RefreshButton extends ConsumerWidget {
  const RefreshButton({
    super.key,
    required this.onRefresh,
    this.tooltip = 'Actualiser',
    this.icon = Icons.refresh,
  });

  /// Callback appelé lors du rafraîchissement.
  final VoidCallback onRefresh;

  /// Tooltip à afficher.
  final String tooltip;

  /// Icône à afficher.
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onRefresh,
      tooltip: tooltip,
    );
  }
}

