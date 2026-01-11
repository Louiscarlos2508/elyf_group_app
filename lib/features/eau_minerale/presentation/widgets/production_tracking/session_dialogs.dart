import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/production_event.dart';
import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../production_event_dialog.dart';
import '../production_finalization_dialog.dart';
import '../production_resume_dialog.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/shared/utils/notification_service.dart';
/// Dialogs pour la gestion de la session de production.
class SessionDialogs {
  /// Affiche le dialog de finalisation.
  static void showFinalizationDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => ProductionFinalizationDialog(
        session: session,
        onFinalized: (finalizedSession) {
          ref.invalidate(productionSessionDetailProvider((session.id)));
          ref.invalidate(productionSessionsStateProvider);
        },
      ),
    );
  }

  /// Affiche le dialog pour enregistrer un événement.
  static void showEventDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ProductionEventDialog(
          productionId: session.id,
          onEventRecorded: (event) async {
            final updatedEvents = List<ProductionEvent>.from(session.events)
              ..add(event);
            final updatedSession = session.copyWith(
              events: updatedEvents,
              status: ProductionSessionStatus.suspended,
            );

            final controller = ref.read(productionSessionControllerProvider);
            await controller.updateSession(updatedSession);

            if (context.mounted) {
              Navigator.of(context).pop();
              ref.invalidate(productionSessionDetailProvider((session.id)));
              NotificationService.showInfo(context, 'Événement enregistré. Production suspendue.');
            }
          },
        ),
      ),
    );
  }

  /// Affiche le dialog pour reprendre la production.
  static void showResumeDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionSession session,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => ProductionResumeDialog(
        session: session,
        onResumed: (heureReprise) async {
          final updatedEvents = session.events.map((event) {
            if (!event.estTermine) {
              return event.copyWith(heureReprise: heureReprise);
            }
            return event;
          }).toList();

          final updatedSession = session.copyWith(
            events: updatedEvents,
            status: ProductionSessionStatus.inProgress,
          );

          final controller = ref.read(productionSessionControllerProvider);
          await controller.updateSession(updatedSession);

          if (context.mounted) {
            ref.invalidate(productionSessionDetailProvider((session.id)));
            NotificationService.showInfo(context, 'Production reprise avec succès.');
          }
        },
      ),
    );
  }
}

