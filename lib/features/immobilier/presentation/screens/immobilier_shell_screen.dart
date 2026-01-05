import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/adaptive_navigation_scaffold.dart';
import '../../../../shared/presentation/widgets/module_loading_animation.dart';
import '../../../../shared/presentation/widgets/profile/profile_screen.dart'
    as shared;
import 'sections/contracts_screen.dart';
import 'sections/dashboard_screen.dart';
import 'sections/expenses_screen.dart';
import 'sections/payments_screen.dart';
import 'sections/properties_screen.dart';
import 'sections/reports_screen.dart';
import 'sections/tenants_screen.dart';

class ImmobilierShellScreen extends ConsumerStatefulWidget {
  const ImmobilierShellScreen({
    super.key,
    required this.enterpriseId,
    required this.moduleId,
  });

  final String enterpriseId;
  final String moduleId;

  @override
  ConsumerState<ImmobilierShellScreen> createState() =>
      _ImmobilierShellScreenState();
}

class _ImmobilierShellScreenState
    extends ConsumerState<ImmobilierShellScreen> {
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

  List<NavigationSection> _buildSections() {
    // TODO: Adapter les écrans de sections pour accepter enterpriseId et moduleId
    // Pour l'instant, on passe les paramètres au widget mais les sections
    // devront être adaptées individuellement pour les utiliser
    return [
      NavigationSection(
        label: 'Tableau',
        icon: Icons.dashboard_outlined,
        builder: () => const DashboardScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Propriétés',
        icon: Icons.home_outlined,
        builder: () => const PropertiesScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Locataires',
        icon: Icons.people_outlined,
        builder: () => const TenantsScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Contrats',
        icon: Icons.description_outlined,
        builder: () => const ContractsScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Paiements',
        icon: Icons.payment_outlined,
        builder: () => const PaymentsScreen(),
        isPrimary: true,
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Dépenses',
        icon: Icons.receipt_long_outlined,
        builder: () => const ExpensesScreen(),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Rapports',
        icon: Icons.assessment_outlined,
        builder: () => const ReportsScreen(),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
      NavigationSection(
        label: 'Profil',
        icon: Icons.person_outline,
        builder: () => const shared.ProfileScreen(),
        enterpriseId: widget.enterpriseId,
        moduleId: widget.moduleId,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      sections: _buildSections(),
      appTitle: 'Immobilier • Maisons',
      selectedIndex: _selectedIndex,
      onIndexChanged: (index) {
        setState(() => _selectedIndex = index);
      },
      isLoading: _isLoading,
      loadingWidget: const ModuleLoadingAnimation(
        moduleName: 'Immobilier',
        moduleIcon: Icons.home_work_outlined,
        message: 'Chargement des données...',
      ),
      enterpriseId: widget.enterpriseId,
      moduleId: widget.moduleId,
    );
  }
}

