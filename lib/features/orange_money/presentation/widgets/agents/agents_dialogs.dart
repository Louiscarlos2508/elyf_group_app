import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';
import '../../../domain/entities/agent.dart';
import '../agent_form_dialog.dart';
import '../agent_recharge_dialog.dart' show AgentRechargeDialog, AgentTransactionType;
import 'agents_format_helpers.dart';

/// Dialogs pour la gestion des agents.
class AgentsDialogs {
  /// Affiche le dialog de formulaire d'agent.
  static void showAgentDialog(
    BuildContext context,
    WidgetRef ref,
    Agent? agent,
    String? enterpriseId,
    String searchQuery,
    AgentStatus? statusFilter,
    void Function() onSuccess,
  ) {
    showDialog(
      context: context,
      builder: (context) => AgentFormDialog(
        agent: agent,
        onSave: (Agent savedAgent) async {
          final controller = ref.read(agentsControllerProvider);
          if (agent == null) {
            await controller.createAgent(savedAgent);
          } else {
            await controller.updateAgent(savedAgent);
          }
          if (context.mounted) {
            final agentsKey = '$enterpriseId|${statusFilter?.name ?? ''}|$searchQuery';
            ref.invalidate(agentsProvider((agentsKey)));
            onSuccess();
          }
        },
      ),
    );
  }

  /// Affiche le dialog de recharge/retrait.
  static void showRechargeDialog(
    BuildContext context,
    WidgetRef ref,
    String? enterpriseId,
    String searchQuery,
    AgentStatus? statusFilter,
    void Function() onSuccess,
  ) {
    final agentsKey = '$enterpriseId||';
    final agentsAsync = ref.read(agentsProvider((agentsKey)));

    agentsAsync.whenData((agents) {
      if (agents.isEmpty) {
        NotificationService.showInfo(context, 'Aucun agent disponible');
        return;
      }

      showDialog(
        context: context,
        builder: (dialogContext) => AgentRechargeDialog(
          agents: agents,
          onConfirm: (agent, type, amount, notes) async {
            final controller = ref.read(agentsControllerProvider);
            await controller.updateAgentLiquidity(
              agent: agent,
              amount: amount,
              isRecharge: type == AgentTransactionType.recharge,
            );
            if (context.mounted) {
              final currentAgentsKey = '$enterpriseId|${statusFilter?.name ?? ''}|$searchQuery';
              ref.invalidate(agentsProvider((currentAgentsKey)));
              ref.invalidate(agentsDailyStatisticsProvider((enterpriseId ?? '')));
              onSuccess();

              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      type == AgentTransactionType.recharge
                          ? 'Recharge de ${AgentsFormatHelpers.formatCurrency(amount)} effectuée pour ${agent.name}'
                          : 'Retrait de ${AgentsFormatHelpers.formatCurrency(amount)} effectué pour ${agent.name}',
                    ),
                  ),
                );
              }
            }
          },
        ),
      );
    });
  }

  /// Affiche le dialog de confirmation de suppression.
  static Future<bool?> showDeleteDialog(
    BuildContext context,
    Agent agent,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'agent'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${agent.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

