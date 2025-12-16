import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/application/providers/treasury_providers.dart';
import '../refresh_button.dart';
import '../treasury_movement_list.dart';
import '../treasury_summary_cards.dart';
import '../treasury_transfer_dialog.dart';

/// Écran de trésorerie partagé pour tous les modules.
/// 
/// Prend en paramètres le moduleId et moduleName pour afficher
/// la trésorerie spécifique au module.
class TreasuryScreen extends ConsumerWidget {
  const TreasuryScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  final String moduleId;
  final String moduleName;

  void _showTransferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TreasuryTransferDialog(
        moduleId: moduleId,
        moduleName: moduleName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final treasuryAsync = ref.watch(treasuryProvider(moduleId));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
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
                          'Trésorerie',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gestion de la trésorerie du module',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    RefreshButton(
                      onRefresh: () => ref.invalidate(treasuryProvider(moduleId)),
                      tooltip: 'Actualiser la trésorerie',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      onPressed: () => _showTransferDialog(context),
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
                child: treasuryAsync.when(
                  data: (treasury) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TreasurySummaryCards(treasury: treasury),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Text(
                              'Historique des mouvements',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: FilledButton.icon(
                                onPressed: () => _showTransferDialog(context),
                                icon: const Icon(Icons.swap_horiz),
                                label: const Text('Transfert'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TreasuryMovementList(movements: treasury.mouvements),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => Padding(
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
              ),
            ),
          ],
        );
      },
    );
  }
}

