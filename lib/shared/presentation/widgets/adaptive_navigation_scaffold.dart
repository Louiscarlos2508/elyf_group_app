import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tenant/tenant_switch_manager.dart';

import '../../utils/responsive_helper.dart';
import 'elyf_ui/organisms/elyf_app_bar.dart';
import 'elyf_ui/organisms/elyf_drawer.dart';
import 'elyf_ui/organisms/elyf_navigation.dart';

/// Configuration pour une section de navigation
class NavigationSection {
  const NavigationSection({
    required this.label,
    required this.icon,
    required this.builder,
    this.isPrimary = false,
    this.enterpriseId,
    this.moduleId,
  });

  final String label;
  final IconData icon;
  final Widget Function() builder;
  final bool isPrimary;
  final String? enterpriseId;
  final String? moduleId;
}

/// Scaffold avec navigation adaptative pour mobile et desktop
///
/// Sur mobile :
/// - Drawer avec toutes les sections (navigation unique)
///
/// Sur desktop :
/// - NavigationRail avec toutes les sections
///
/// Support multi-tenant :
/// - Passe enterpriseId et moduleId aux sections pour filtrer les données
class AdaptiveNavigationScaffold extends ConsumerStatefulWidget {
  const AdaptiveNavigationScaffold({
    super.key,
    required this.sections,
    required this.appTitle,
    this.selectedIndex = 0,
    this.onIndexChanged,
    this.isLoading = false,
    this.loadingWidget,
    this.enterpriseId,
    this.moduleId,
    this.appBarActions,
  });

  final List<NavigationSection> sections;
  final String appTitle;
  final int selectedIndex;
  final ValueChanged<int>? onIndexChanged;
  final bool isLoading;
  final Widget? loadingWidget;
  final String? enterpriseId;
  final String? moduleId;
  final List<Widget>? appBarActions;

  @override
  ConsumerState<AdaptiveNavigationScaffold> createState() =>
      _AdaptiveNavigationScaffoldState();
}

class _AdaptiveNavigationScaffoldState
    extends ConsumerState<AdaptiveNavigationScaffold> {
  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<int, Widget> _cachedWidgets = {};

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    // Construire uniquement le widget initial
    _cachedWidgets[_selectedIndex] = widget.sections[_selectedIndex].builder();
  }

  @override
  void didUpdateWidget(AdaptiveNavigationScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
      // Construire le widget si pas encore en cache
      if (!_cachedWidgets.containsKey(_selectedIndex)) {
        _cachedWidgets[_selectedIndex] = widget.sections[_selectedIndex]
            .builder();
      }
    }
  }

  Widget _getWidgetForIndex(int index) {
    if (!_cachedWidgets.containsKey(index)) {
      _cachedWidgets[index] = widget.sections[index].builder();
    }
    return _cachedWidgets[index]!;
  }

  void _onDestinationSelected(int index) {
    // Construire le widget si pas encore en cache
    if (!_cachedWidgets.containsKey(index)) {
      _cachedWidgets[index] = widget.sections[index].builder();
    }
    setState(() {
      _selectedIndex = index;
    });
    widget.onIndexChanged?.call(index);
    // Fermer le drawer si ouvert
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    final isSwitching = ref.watch(tenantSwitchManagerProvider).isLoading;

    Widget content;
    // Utiliser le helper pour déterminer le type d'écran
    if (ResponsiveHelper.isMobile(context)) {
      content = _buildMobileScreen();
    } else if (ResponsiveHelper.isTablet(context)) {
      content = _buildTabletScreen();
    } else {
      content = _buildDesktopScreen();
    }

    if (!isSwitching) return content;

    return Stack(
      children: [
        content,
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Changement d\'espace...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Synchronisation en cours',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletScreen() {
    // Sur tablette, utiliser NavigationRail compact (80px) avec labels
    return Scaffold(
      appBar: ElyfAppBar(
        title: widget.appTitle,
        centerTitle: true,
        actions: widget.appBarActions,
        elevation: 1, // Subtle elevation for tablet
        moduleId: widget.moduleId,
      ),
      resizeToAvoidBottomInset: false,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElyfNavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            extended: false,
            moduleId: widget.moduleId,
            destinations: widget.sections
                .map(
                  (section) => ElyfNavigationDestination(
                    icon: section.icon,
                    label: section.label,
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _getWidgetForIndex(_selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildDesktopScreen() {
    final isExtended = ResponsiveHelper.isExtendedScreen(context);

    return Scaffold(
      appBar: ElyfAppBar(
        title: widget.appTitle,
        centerTitle: true,
        actions: widget.appBarActions,
        elevation: 1,
        moduleId: widget.moduleId,
      ),
      resizeToAvoidBottomInset: false,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElyfNavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            extended: isExtended,
            moduleId: widget.moduleId,
            destinations: widget.sections
                .map(
                  (section) => ElyfNavigationDestination(
                    icon: section.icon,
                    label: section.label,
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _getWidgetForIndex(_selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildMobileScreen() {
    final theme = Theme.of(context);
    final sectionsCount = widget.sections.length;

    // Augmenté de 5 à 8 : l'utilisateur préfère la Bottom Nav même avec beaucoup de sections.
    // ElyfBottomNavigationBar supporte le défilement horizontal.
    if (sectionsCount > 8) {
      return _buildMobileWithDrawer(theme);
    }

    // Pour 4 sections ou moins, utiliser la barre de navigation premium flottante
    return Scaffold(
      key: _scaffoldKey,
      extendBody: false, // Désactivé pour une clarté maximale
      appBar: ElyfAppBar(
        title: widget.appTitle,
        centerTitle: true,
        leading: Navigator.of(context).canPop() 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Retour',
              )
            : null,
        actions: widget.appBarActions,
        useGlassmorphism: false,
        elevation: 0,
        moduleId: widget.moduleId,
      ),
      body: _getWidgetForIndex(_selectedIndex),
      bottomNavigationBar: ElyfBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        moduleId: widget.moduleId,
        destinations: widget.sections.map((section) {
          return ElyfNavigationDestination(
            icon: section.icon,
            label: section.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileWithDrawer(ThemeData theme) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: false, // Plus simple sans superposition
      appBar: ElyfAppBar(
        title: widget.appTitle,
        centerTitle: true,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (Navigator.of(context).canPop())
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Retour',
              ),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Menu',
            ),
          ],
        ),
        actions: widget.appBarActions,
        elevation: 0,
        moduleId: widget.moduleId,
      ),
      drawer: ElyfDrawer(
        sections: widget.sections,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        appTitle: widget.appTitle,
        moduleId: widget.moduleId,
      ),
      body: _getWidgetForIndex(_selectedIndex),
    );
  }
}
