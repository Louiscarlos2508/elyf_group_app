import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/shared.dart';

/// Un garde-fou pour empêcher les ventes si aucune session n'est ouverte.
class GazSessionGuard extends ConsumerWidget {
  final Widget child;

  const GazSessionGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(todayGazSessionProvider);

    return sessionAsync.when(
      data: (session) {
        if (session != null && session.isOpen) {
          return child;
        }

        return _buildNoSessionView(context);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildNoSessionView(context, error: e.toString()),
    );
  }

  Widget _buildNoSessionView(BuildContext context, {String? error}) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_clock_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Session requise',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vous devez ouvrir une session avant de pouvoir enregistrer des ventes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: 250,
              child: FilledButton.icon(
                onPressed: () {
                  // Navigation vers le dashboard (où se trouve le contrôle de session)
                  // Dans cette architecture, on peut souvent juste demander à l'utilisateur d'y aller
                  // ou utiliser un signal pour changer d'onglet si possible.
                  // Pour l'instant, on invite juste à aller au tableau de bord.
                  NotificationService.showInfo(context, 'Rendez-vous sur le Tableau de Bord pour ouvrir une session.');
                },
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text('Aller au Tableau de Bord'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
