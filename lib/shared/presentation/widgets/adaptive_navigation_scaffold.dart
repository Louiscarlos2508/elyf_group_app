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
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: widget.sections.map((s) => s.builder()).toList(),
      ),
    );
  }

  Widget _buildDrawer() {
    final theme = Theme.of(context);
    
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu,
                    size: 48,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.appTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...widget.sections.asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final section = entry.value;
                      final isSelected = _selectedIndex == index;
                      return ListTile(
                        leading: Icon(
                          section.icon,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        title: Text(section.label),
                        selected: isSelected,
                        onTap: () => _onDestinationSelected(index),
                        selectedTileColor:
                            theme.colorScheme.primaryContainer,
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

