import 'package:flutter/material.dart';

import '../../../../shared/presentation/widgets/profile/profile_screen.dart';

class ModuleHomeScaffold extends StatefulWidget {
  const ModuleHomeScaffold({
    super.key,
    required this.title,
    required this.enterpriseId,
  });

  final String title;
  final String enterpriseId;

  @override
  State<ModuleHomeScaffold> createState() => _ModuleHomeScaffoldState();
}

class _ModuleHomeScaffoldState extends State<ModuleHomeScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
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
