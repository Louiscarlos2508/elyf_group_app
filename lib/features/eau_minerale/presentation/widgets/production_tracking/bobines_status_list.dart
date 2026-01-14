import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/production_session.dart';
import 'tracking_dialogs.dart';

/// Widget pour afficher la liste des bobines avec leur statut.
class BobinesStatusList extends ConsumerWidget {
  const BobinesStatusList({super.key, required this.session});

  final ProductionSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (session.bobinesUtilisees.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État des bobines',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...session.bobinesUtilisees.map((bobine) {
          final aBobineActiveSurMachine = session.bobinesUtilisees.any(
            (b) => b.machineId == bobine.machineId && !b.estFinie,
          );
          final peutInstallerNouvelle =
              bobine.estFinie && !aBobineActiveSurMachine;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: bobine.estFinie
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.surface,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: bobine.estFinie
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.secondaryContainer,
                child: Icon(
                  bobine.estFinie ? Icons.check : Icons.sync,
                  size: 20,
                  color: bobine.estFinie
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(bobine.bobineType),
              subtitle: Text('Machine: ${bobine.machineName}'),
              trailing: bobine.estFinie
                  ? (peutInstallerNouvelle
                        ? IntrinsicWidth(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  TrackingDialogs.showInstallNewBobineDialog(
                                    context,
                                    ref,
                                    session,
                                    bobine,
                                  ),
                              icon: const Icon(Icons.add_circle, size: 18),
                              label: const Text('Nouvelle'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Bobine active',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.build,
                            color: Colors.orange,
                            size: 20,
                          ),
                          tooltip: 'Signaler panne',
                          onPressed: () =>
                              TrackingDialogs.showMachineBreakdownDialog(
                                context,
                                ref,
                                session,
                                bobine,
                              ),
                        ),
                        SizedBox(
                          width: 100,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                TrackingDialogs.showBobineFinishDialog(
                                  context,
                                  ref,
                                  session,
                                  bobine,
                                ),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Finie'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        }),
      ],
    );
  }
}
