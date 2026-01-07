import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared.dart';

class ModuleHomeScaffold extends StatefulWidget {
  const ModuleHomeScaffold({
    super.key,
    required this.title,
    required this.enterpriseId,
    this.moduleIcon,
  });

  final String title;
  final String enterpriseId;
  final IconData? moduleIcon;

  @override
  State<ModuleHomeScaffold> createState() => _ModuleHomeScaffoldState();
}

class _ModuleHomeScaffoldState extends State<ModuleHomeScaffold> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate module initialization
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  IconData _getModuleIcon() {
    if (widget.moduleIcon != null) return widget.moduleIcon!;
    switch (widget.enterpriseId) {
      case 'gaz':
        return Icons.local_fire_department_outlined;
      case 'orange_money':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.business;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ModuleLoadingAnimation(
        moduleName: widget.title.split(' • ').first,
        moduleIcon: _getModuleIcon(),
        message: 'Initialisation du module...',
      );
    }
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home/Dashboard placeholder
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.enterpriseId,
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Profile screen
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
