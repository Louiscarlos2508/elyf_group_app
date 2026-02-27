import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import 'package:elyf_groupe_app/features/orange_money/domain/entities/agent.dart' as entity;
import 'package:elyf_groupe_app/features/administration/domain/entities/enterprise.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/add_agent_modal.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agent_recharge_dialog.dart';
import 'package:elyf_groupe_app/features/orange_money/presentation/widgets/agents/agents_format_helpers.dart';

/// Dialogs pour la gestion des agents (Entreprises Mobile Money).
class AgentsDialogs {
  /// Affiche le dialog de formulaire d'agent.
  static void showAgentDialog(
    BuildContext context,
    WidgetRef ref,
    Enterprise? agent,
    String? enterpriseId,
    String searchQuery,
    void Function() onSuccess,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAgentModal(agency: agent),
        fullscreenDialog: true,
      ),
    ).then((result) {
      if (result == true) {
        final agentsKey =
            '${enterpriseId ?? ''}||$searchQuery';
        ref.invalidate(agentAccountsProvider((agentsKey)));
        onSuccess();
      }
    });
  }

  /// Affiche le dialog de recharge/retrait.
  static void showRechargeDialog(
    BuildContext context,
    WidgetRef ref,
    String? enterpriseId,
    String searchQuery,
    void Function() onSuccess,
  ) {
    final scopeId = enterpriseId ?? '';
    final agentsAsync = ref.read(agentAccountsProvider('$scopeId||'));
    final agenciesAsync = ref.read(agentAgenciesProvider('$scopeId||'));

    showDialog(
      context: context,
      builder: (dialogContext) => AgentRechargeDialog(
        agents: agentsAsync.value ?? [],
        agencies: agenciesAsync.value ?? [],
        onConfirm: (target, type, amount, notes) async {
          final controller = ref.read(agentsControllerProvider);
          final name = target is Enterprise ? target.name : (target as entity.Agent).name;
          
          if (target is Enterprise) {
            await controller.updateAgencyLiquidity(
              agency: target,
              amount: amount,
              isRecharge: type == AgentTransactionType.recharge,
            );
          } else if (target is entity.Agent) {
            await controller.updateAgentLiquidity(
              agent: target,
              amount: amount,
              isRecharge: type == AgentTransactionType.recharge,
            );
          }

          if (context.mounted) {
            ref.invalidate(agentAccountsProvider);
            ref.invalidate(agentAgenciesProvider);
            ref.invalidate(agentsDailyStatisticsProvider(scopeId));
            onSuccess();

            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(
                    type == AgentTransactionType.recharge
                        ? 'Recharge de ${AgentsFormatHelpers.formatCurrency(amount)} effectuée pour $name'
                        : 'Retrait de ${AgentsFormatHelpers.formatCurrency(amount)} effectué pour $name',
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// Affiche le dialog de confirmation de suppression.
  static Future<bool?> showDeleteDialog(BuildContext context, String name) {
    final theme = Theme.of(context);
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer l\'entité',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontFamily: 'Outfit',
          ),
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer $name ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Annuler',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialog d'ajout/modification d'un compte agent (SIM).
  static void showAgentAccountDialog(
    BuildContext context,
    WidgetRef ref,
    entity.Agent? agent,
    String? enterpriseId,
    void Function() onSuccess,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAgentModal(agentAccount: agent),
        fullscreenDialog: true,
      ),
    ).then((result) {
      if (result == true) {
        final scopeId = enterpriseId ?? '';
        ref.invalidate(agentAccountsProvider('$scopeId||'));
        onSuccess();
      }
    });
  }
}
