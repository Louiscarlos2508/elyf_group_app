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
    final isAuthenticatedAsync = ref.watch(isAuthenticatedProvider);

    return isAuthenticatedAsync.when(
      data: (isAuthenticated) {
        if (!isAuthenticated) {
          // Rediriger vers le login si non connecté
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/login');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return child;
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
