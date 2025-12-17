import 'package:flutter/material.dart';

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
  });

  final List<NavigationSection> sections;
  final String appTitle;
  final int selectedIndex;
  final ValueChanged<int>? onIndexChanged;
  final bool isLoading;
  final Widget? loadingWidget;
  final String? enterpriseId;
  final String? moduleId;

  @override
  State<AdaptiveNavigationScaffold> createState() =>
      _AdaptiveNavigationScaffoldState();
}

class _AdaptiveNavigationScaffoldState
    extends State<AdaptiveNavigationScaffold> {
  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(AdaptiveNavigationScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
  }

  void _onDestinationSelected(int index) {
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

    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    if (isWideScreen) {
      return _buildWideScreen();
    }

    return _buildMobileScreen();
  }

  Widget _buildWideScreen() {
    final isExtended = MediaQuery.of(context).size.width >= 800;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appTitle),
        centerTitle: true,
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
                        : NavigationRailLabelType.all,
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
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: widget.sections.map((s) => s.builder()).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileScreen() {
    final theme = Theme.of(context);
    final sectionsCount = widget.sections.length;
    
    // Si plus de 5 sections, utiliser un drawer, sinon NavigationBar
    if (sectionsCount > 5) {
      return _buildMobileWithDrawer(theme);
    }
    
    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _selectedIndex,
        children: widget.sections.map((s) => s.builder()).toList(),
      ),
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
      ),
      drawer: _buildDrawer(theme),
      body: IndexedStack(
        index: _selectedIndex,
        children: widget.sections.map((s) => s.builder()).toList(),
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.business,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.appTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.sections.length,
                itemBuilder: (context, index) {
                  final section = widget.sections[index];
                  final isSelected = _selectedIndex == index;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    child: Material(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _onDestinationSelected(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
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
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 6,
                                  height: 6,
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

