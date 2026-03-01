import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

class ModuleHomeScaffold extends ConsumerStatefulWidget {
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
  ConsumerState<ModuleHomeScaffold> createState() => _ModuleHomeScaffoldState();
}

class _ModuleHomeScaffoldState extends ConsumerState<ModuleHomeScaffold> {
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
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _selectedIndex == 1
          ? null
          : ElyfAppBar(
              title: activeEnterprise?.name ?? widget.title.split(' • ').last,
              subtitle: widget.title.split(' • ').first.toUpperCase(),
              module: activeEnterprise?.type.module,
              actions: [
                EnterpriseSelectorWidget(style: EnterpriseSelectorStyle.appBar),
              ],
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
      bottomNavigationBar: ElyfBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          ElyfNavigationDestination(
            icon: Icons.dashboard_outlined,
            label: 'Accueil',
          ),
          ElyfNavigationDestination(
            icon: Icons.person_outline,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
