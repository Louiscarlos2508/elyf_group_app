import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/presentation/widgets/enterprise_selector_widget.dart';
import '../../core/tenant/tenant_provider.dart';
import '../../features/boutique/presentation/screens/boutique_shell_screen.dart';
import '../../features/eau_minerale/presentation/screens/eau_minerale_shell_screen.dart';
import '../../features/gaz/presentation/screens/gaz_shell_screen.dart';
import '../../features/immobilier/presentation/screens/immobilier_shell_screen.dart';
import '../../features/orange_money/presentation/screens/orange_money_shell_screen.dart';

/// Widget affiché quand aucune entreprise n'est sélectionnée
class _NoEnterpriseSelectedWidget extends StatelessWidget {
  const _NoEnterpriseSelectedWidget();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélection d\'entreprise requise'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Aucune entreprise sélectionnée',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Veuillez sélectionner une entreprise pour accéder à ce module.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  // Note: On ne peut pas utiliser ref directement ici,
                  // donc on redirige vers le menu des modules
                  context.go('/modules');
                },
                icon: const Icon(Icons.business),
                label: const Text('Sélectionner une entreprise'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/modules'),
                child: const Text('Retour au menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper pour le module Eau Minérale qui utilise l'entreprise active
class EauMineraleRouteWrapper extends ConsumerWidget {
  const EauMineraleRouteWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) {
          return const _NoEnterpriseSelectedWidget();
        }
        
        return EauMineraleShellScreen(
          enterpriseId: enterprise.id,
          moduleId: 'eau_minerale',
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de l\'entreprise...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Erreur: ${error.toString()}'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper pour le module Gaz qui utilise l'entreprise active
class GazRouteWrapper extends ConsumerWidget {
  const GazRouteWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) {
          return const _NoEnterpriseSelectedWidget();
        }
        
        return GazShellScreen(
          enterpriseId: enterprise.id,
          moduleId: 'gaz',
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de l\'entreprise...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Erreur: ${error.toString()}'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper pour le module Orange Money qui utilise l'entreprise active
class OrangeMoneyRouteWrapper extends ConsumerWidget {
  const OrangeMoneyRouteWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) {
          return const _NoEnterpriseSelectedWidget();
        }
        
        return OrangeMoneyShellScreen(
          enterpriseId: enterprise.id,
          moduleId: 'orange_money',
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de l\'entreprise...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Erreur: ${error.toString()}'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper pour le module Immobilier qui utilise l'entreprise active
class ImmobilierRouteWrapper extends ConsumerWidget {
  const ImmobilierRouteWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) {
          return const _NoEnterpriseSelectedWidget();
        }
        
        return ImmobilierShellScreen(
          enterpriseId: enterprise.id,
          moduleId: 'immobilier',
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de l\'entreprise...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Erreur: ${error.toString()}'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper pour le module Boutique qui utilise l'entreprise active
class BoutiqueRouteWrapper extends ConsumerWidget {
  const BoutiqueRouteWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterpriseAsync = ref.watch(activeEnterpriseProvider);
    
    return activeEnterpriseAsync.when(
      data: (enterprise) {
        if (enterprise == null) {
          return const _NoEnterpriseSelectedWidget();
        }
        
        return BoutiqueShellScreen(
          enterpriseId: enterprise.id,
          moduleId: 'boutique',
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de l\'entreprise...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Erreur: ${error.toString()}'),
            ],
          ),
        ),
      ),
    );
  }
}

