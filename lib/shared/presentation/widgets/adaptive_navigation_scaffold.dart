import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

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
class AdaptiveNavigationScaffold extends StatefulWidget {
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
  State<AdaptiveNavigationScaffold> createState() =>
      _AdaptiveNavigationScaffoldState();
}

class _AdaptiveNavigationScaffoldState
    extends State<AdaptiveNavigationScaffold> {
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

    // Utiliser le helper pour déterminer le type d'écran
    if (ResponsiveHelper.isMobile(context)) {
      return _buildMobileScreen();
    } else if (ResponsiveHelper.isTablet(context)) {
      return _buildTabletScreen();
    } else {
      return _buildDesktopScreen();
    }
  }

  Widget _buildTabletScreen() {
    // Sur tablette, utiliser NavigationRail compact (80px) avec labels
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appTitle),
        centerTitle: true,
        actions: widget.appBarActions,
      ),
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRect(
                child: SizedBox(
                  width: 80,
                  height: maxHeight,
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onDestinationSelected,
                    labelType: NavigationRailLabelType.selected,
                    extended: false,
                    minWidth: 80,
                    destinations: widget.sections
                        .map(
                          (section) => NavigationRailDestination(
                            icon: Icon(section.icon),
                            selectedIcon: Icon(section.icon),
                            label: Text(section.label),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: _getWidgetForIndex(_selectedIndex)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopScreen() {
    final isExtended = ResponsiveHelper.isExtendedScreen(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appTitle),
        centerTitle: true,
        actions: widget.appBarActions,
      ),
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRect(
                child: SizedBox(
                  width: isExtended ? 200 : 80,
                  height: maxHeight,
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onDestinationSelected,
                    labelType: isExtended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.selected,
                    extended: isExtended,
                    minExtendedWidth: 200,
                    minWidth: 80,
                    destinations: widget.sections
                        .map(
                          (section) => NavigationRailDestination(
                            icon: Icon(section.icon),
                            selectedIcon: Icon(section.icon),
                            label: Text(section.label),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: _getWidgetForIndex(_selectedIndex)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileScreen() {
    final theme = Theme.of(context);
    final sectionsCount = widget.sections.length;

    // Si plus de 4 sections, utiliser un drawer pour une meilleure ergonomie
    // Le drawer offre plus d'espace et une meilleure lisibilité sur petits écrans
    if (sectionsCount > 4) {
      return _buildMobileWithDrawer(theme);
    }

    // Pour 4 sections ou moins, utiliser NavigationBar en bas
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.appTitle),
        centerTitle: true,
        actions: widget.appBarActions,
      ),
      body: _getWidgetForIndex(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 72,
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          indicatorColor: theme.colorScheme.primaryContainer,
          destinations: widget.sections.map((section) {
            return NavigationDestination(
              icon: Icon(section.icon),
              selectedIcon: Icon(
                section.icon,
                color: theme.colorScheme.primary,
              ),
              label: section.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileWithDrawer(ThemeData theme) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.appTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Menu',
        ),
        actions: widget.appBarActions,
      ),
      drawer: _buildDrawer(theme),
      body: _getWidgetForIndex(_selectedIndex),
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.business,
                      size: 28,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.appTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Système de Gestion Intégré',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.sections.length,
                itemBuilder: (context, index) {
                  final section = widget.sections[index];
                  final isSelected = _selectedIndex == index;
 
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _onDestinationSelected(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                section.icon,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  section.label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
