import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets.dart';
import 'elyf_ui/organisms/elyf_app_bar.dart';
import '../../../core/tenant/tenant_provider.dart';

// Re-export NavigationSection so subclasses can use it
export 'adaptive_navigation_scaffold.dart' show NavigationSection;

/// Classe de base pour les shell screens de modules.
///
/// Gère la logique commune :
/// - Gestion de l'index sélectionné
/// - Gestion des erreurs de chargement
/// - Affichage du loading
/// - Gestion du cas "aucune section"
///
/// Les classes enfants doivent implémenter :
/// - `buildSections()` : retourne la liste des sections
/// - `moduleName` : nom du module
/// - `moduleIcon` : icône du module
abstract class BaseModuleShellScreen extends ConsumerStatefulWidget {
  const BaseModuleShellScreen({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;
}

abstract class BaseModuleShellScreenState<T extends BaseModuleShellScreen>
    extends ConsumerState<T> {
  int _selectedIndex = 0;

  /// Nom du module (pour l'affichage).
  String get moduleName;

  /// Icône du module (pour l'affichage).
  IconData get moduleIcon;

  /// Titre de l'application.
  String get appTitle => '$moduleName • Module';

  /// Construit les actions de l'AppBar (sélecteur d'entreprise si plusieurs entreprises accessibles).
  List<Widget> _buildAppBarActions() {
    final accessibleEnterprisesAsync = ref.watch(userAccessibleEnterprisesProvider);
    
    return accessibleEnterprisesAsync.when(
      data: (enterprises) {
        // Afficher le sélecteur uniquement si l'utilisateur a accès à plus d'une entreprise
        if (enterprises.length > 1) {
          return const [EnterpriseSelectorWidget(compact: true)];
        }
        return const [];
      },
      loading: () => const [],
      error: (_, __) => const [],
    );
  }

  /// Construit la liste des sections de navigation.
  List<NavigationSection> buildSections();

  /// Retourne le provider async des sections si disponible, null sinon.
  /// Permet aux classes enfants de retourner un provider async pour les sections.
  AsyncValue<List<NavigationSection>>? getSectionsAsync() {
    return null; // Par défaut, pas de provider async
  }

  /// Widget affiché pendant le chargement.
  Widget buildLoading() {
    return ModuleLoadingAnimation(
      moduleName: moduleName,
      moduleIcon: moduleIcon,
      message: 'Chargement des modules...',
    );
  }

  /// Widget affiché en cas d'erreur.
  Widget buildError(Object error, StackTrace? stackTrace) {
    return Scaffold(
      appBar: ElyfAppBar(
        title: appTitle,
        actions: _buildAppBarActions(),
      ),
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
    );
  }

  /// Widget affiché quand aucune section n'est accessible.
  Widget buildNoAccess() {
    return Scaffold(
      appBar: ElyfAppBar(
        title: appTitle,
        actions: _buildAppBarActions(),
      ),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    final sections = buildSections();

    // Si les sections sont asynchrones, utiliser getSectionsAsync()
    final sectionsAsync = getSectionsAsync();
    if (sectionsAsync != null) {
      return sectionsAsync.when(
        data: (loadedSections) {
          // Utiliser les sections chargées
          return _buildWithSections(loadedSections);
        },
        loading: () => buildLoading(),
        error: (error, stackTrace) => buildError(error, stackTrace),
      );
    }

    // Utiliser les sections synchrones
    return _buildWithSections(sections);
  }

  Widget _buildWithSections(List<NavigationSection> sections) {
    // Ajuster l'index si nécessaire
    if (_selectedIndex >= sections.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedIndex = 0);
        }
      });
    }

    final currentIndex = _selectedIndex < sections.length ? _selectedIndex : 0;

    // Aucune section accessible
    if (sections.isEmpty) {
      return buildNoAccess();
    }

    // Une seule section : pas de navigation
    if (sections.length < 2) {
      return Scaffold(
        appBar: ElyfAppBar(
          title: appTitle,
          actions: _buildAppBarActions(),
        ),
        body: IndexedStack(
          index: currentIndex,
          children: sections.map((s) => s.builder()).toList(),
        ),
      );
    }

    // Navigation complète
    return DoubleTapToExit(
      child: AdaptiveNavigationScaffold(
        sections: sections,
        appTitle: appTitle,
        selectedIndex: currentIndex,
        onIndexChanged: (index) {
          if (index < sections.length) {
            setState(() => _selectedIndex = index);
          }
        },
        isLoading: false,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
        appBarActions: _buildAppBarActions(),
      ),
    );
  }

  /// Change l'index de navigation programmatiquement.
  void navigateToIndex(int index) {
    if (mounted) {
      setState(() => _selectedIndex = index);
    }
  }
}
