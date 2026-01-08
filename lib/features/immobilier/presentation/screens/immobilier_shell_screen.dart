import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart' as shared;
import 'package:elyf_groupe_app/shared/presentation/widgets/base_module_shell_screen.dart';
import 'package:elyf_groupe_app/shared/presentation/widgets/module_loading_animation.dart';
import 'sections/contracts_screen.dart';
import 'sections/dashboard_screen.dart';
import 'sections/expenses_screen.dart';
import 'sections/payments_screen.dart';
import 'sections/properties_screen.dart';
import 'sections/reports_screen.dart';
import 'sections/tenants_screen.dart';

class ImmobilierShellScreen extends BaseModuleShellScreen {
  const ImmobilierShellScreen({
    super.key,
    required super.enterpriseId,
    required super.moduleId,
  });

  @override
  BaseModuleShellScreenState<ImmobilierShellScreen> createState() =>
      _ImmobilierShellScreenState();
}

class _ImmobilierShellScreenState
    extends BaseModuleShellScreenState<ImmobilierShellScreen> {
  @override
  String get moduleName => 'Immobilier';

  @override
  IconData get moduleIcon => Icons.home_work_outlined;

  @override
  String get appTitle => 'Immobilier • Maisons';

  @override
  Widget buildLoading() {
    return const ModuleLoadingAnimation(
      moduleName: 'Immobilier',
      moduleIcon: Icons.home_work_outlined,
      message: 'Chargement des données...',
    );
  }

  @override
  List<NavigationSection> buildSections() {
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
}

