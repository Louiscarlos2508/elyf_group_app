import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/elyf_ui/organisms/elyf_app_bar.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

class EauMineraleShellScreen extends ConsumerStatefulWidget {
  const EauMineraleShellScreen({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  ConsumerState<EauMineraleShellScreen> createState() =>
      _EauMineraleShellScreenState();
}

class _EauMineraleShellScreenState
    extends ConsumerState<EauMineraleShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(accessibleSectionsProvider);
    final navigationSections = ref.watch(
      navigationSectionsProvider((
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      )),
    );

    return sectionsAsync.when(
      data: (accessibleSections) {
        // Adjust index if current section is not accessible
        if (_index >= accessibleSections.length && accessibleSections.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _index = 0);
            }
          });
        }

        final currentIndex = _index < accessibleSections.length ? _index : 0;

        // Show message if no sections accessible
        if (accessibleSections.isEmpty) {
          return Scaffold(
            appBar: ElyfAppBar(title: 'Eau Minérale • Module'),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun accès',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Vous n\'avez pas accès à ce module.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show navigation only if 2+ sections
        if (navigationSections.length < 2) {
          return Scaffold(
            appBar: ElyfAppBar(title: 'Eau Minérale • Module'),
            body: IndexedStack(
              index: currentIndex,
              children: navigationSections.map((s) => s.builder()).toList(),
            ),
          );
        }

        return DoubleTapToExit(
          child: AdaptiveNavigationScaffold(
            sections: navigationSections,
            appTitle: 'Eau Minérale • Module',
            selectedIndex: currentIndex,
            onIndexChanged: (i) {
              if (i < accessibleSections.length) {
                setState(() => _index = i);
              }
            },
            isLoading: false,
            enterpriseId: widget.enterpriseId,
            moduleId: widget.moduleId,
          ),
        );
      },
      loading: () => const ModuleLoadingAnimation(
        moduleName: 'Eau Minérale',
        moduleIcon: Icons.water_drop_outlined,
        message: 'Chargement des modules...',
      ),
      error: (error, stack) => Scaffold(
        appBar: ElyfAppBar(title: 'Eau Minérale • Module'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
