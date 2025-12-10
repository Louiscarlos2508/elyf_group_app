import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/providers/treasury_providers.dart';
import '../../../core/domain/entities/treasury.dart';
import '../../../core/domain/entities/treasury_movement.dart';
import '../widgets/treasury_movement_list.dart';
import '../widgets/treasury_summary_cards.dart';
import '../widgets/treasury_transfer_dialog.dart';

/// Écran de tableau de bord de trésorerie.
class TreasuryDashboardScreen extends ConsumerWidget {
  const TreasuryDashboardScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  final String moduleId;
  final String moduleName;

  void _showTransferDialog(BuildContext context, WidgetRef ref) {
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
    final treasuryAsync = ref.watch(treasuryProvider(moduleId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Trésorerie - $moduleName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => _showTransferDialog(context, ref),
            tooltip: 'Effectuer un transfert',
          ),
        ],
      ),
      body: treasuryAsync.when(
        data: (treasury) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TreasurySummaryCards(treasury: treasury),
                const SizedBox(height: 24),
                Text(
                  'Historique des mouvements',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                TreasuryMovementList(movements: treasury.mouvements),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

