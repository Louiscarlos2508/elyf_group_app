import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/services/auth_service.dart';

/// Widget guard qui protège les routes nécessitant une authentification
///
/// Redirige vers /login si l'utilisateur n'est pas connecté.
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    if (isAuthenticated) {
      return child;
    }

    return currentUserAsync.when(
      data: (user) {
        // Si on est ici et isAuthenticated est false, l'utilisateur n'est pas connecté
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Retour au login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
