import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/widgets/adaptive_navigation_scaffold.dart';
import '../../../core/application/providers/treasury_providers.dart';
import '../widgets/treasury_movement_list.dart';
import '../widgets/treasury_summary_cards.dart';
import '../widgets/treasury_transfer_dialog.dart';
import 'treasury_module_selection_screen.dart';

/// Écran shell pour la trésorerie avec navigation.
class TreasuryShellScreen extends ConsumerStatefulWidget {
  const TreasuryShellScreen({
    super.key,
    this.moduleId,
  });

  final String? moduleId;

  @override
  ConsumerState<TreasuryShellScreen> createState() =>
      _TreasuryShellScreenState();
}

class _TreasuryShellScreenState extends ConsumerState<TreasuryShellScreen> {
  int _selectedIndex = 0;

  void _showTransferDialog(BuildContext context, WidgetRef ref) {
    if (widget.moduleId == null) return;
    
    showDialog(
      context: context,
      builder: (context) => TreasuryTransferDialog(
        moduleId: widget.moduleId!,
        moduleName: _getModuleName(widget.moduleId!),
      ),
    );
  }

  String _getModuleName(String moduleId) {
    switch (moduleId) {
      case 'eau_minerale':
        return 'Eau Minérale';
      case 'boutique':
        return 'Boutique';
      case 'immobilier':
        return 'Immobilier';
      case 'gaz':
        return 'Gaz';
      case 'orange_money':
        return 'Orange Money';
      default:
        return moduleId;
    }
  }

  List<NavigationSection> _buildSections() {
    final sections = <NavigationSection>[
      NavigationSection(
        label: 'Sélection',
        icon: Icons.apps_outlined,
        builder: () => const TreasuryModuleSelectionScreen(),
        isPrimary: true,
      ),
    ];

    // Si un module est sélectionné, ajouter son écran de trésorerie
    if (widget.moduleId != null) {
      sections.add(
        NavigationSection(
          label: _getModuleName(widget.moduleId!),
          icon: Icons.account_balance,
          builder: () => _TreasuryDashboardContent(
            moduleId: widget.moduleId!,
            moduleName: _getModuleName(widget.moduleId!),
            onTransferTap: () => _showTransferDialog(context, ref),
          ),
          isPrimary: true,
        ),
      );
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();

    if (sections.length < 2) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trésorerie'),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: sections.map((s) => s.builder()).toList(),
        ),
      );
    }

    return AdaptiveNavigationScaffold(
      sections: sections,
      appTitle: 'Trésorerie',
      selectedIndex: _selectedIndex,
      onIndexChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      isLoading: false,
    );
  }
}

/// Widget pour afficher le contenu du tableau de bord de trésorerie.
class _TreasuryDashboardContent extends ConsumerWidget {
  const _TreasuryDashboardContent({
    required this.moduleId,
    required this.moduleName,
    required this.onTransferTap,
  });

  final String moduleId;
  final String moduleName;
  final VoidCallback onTransferTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final treasuryAsync = ref.watch(treasuryProvider(moduleId));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return treasuryAsync.when(
          data: (treasury) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      isWide ? 24 : 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trésorerie - $moduleName',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gestion centralisée de la trésorerie',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          onPressed: onTransferTap,
                          tooltip: 'Effectuer un transfert',
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TreasurySummaryCards(treasury: treasury),
                        const SizedBox(height: 32),
                        Text(
                          'Historique des mouvements',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TreasuryMovementList(movements: treasury.mouvements),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const CustomScrollView(
            slivers: [
              SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (error, stack) => CustomScrollView(
            slivers: [
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur lors du chargement',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

