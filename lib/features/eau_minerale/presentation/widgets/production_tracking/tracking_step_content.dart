import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/production_session.dart';
import '../../../domain/entities/production_session_status.dart';
import 'draft_step.dart';
import 'started_step.dart';
import 'in_progress_step.dart';
import 'suspended_step.dart';
import 'completed_step.dart';

/// Widget qui affiche le contenu approprié selon le statut de la session.
class TrackingStepContent extends ConsumerWidget {
  const TrackingStepContent({
    super.key,
    required this.session,
    required this.status,
  });

  final ProductionSession session;
  final ProductionSessionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (status) {
      case ProductionSessionStatus.draft:
        return DraftStep(session: session);
      case ProductionSessionStatus.started:
        return StartedStep(session: session);
      case ProductionSessionStatus.inProgress:
        return InProgressStep(session: session);
      case ProductionSessionStatus.suspended:
        return SuspendedStep(session: session);
      case ProductionSessionStatus.completed:
        return CompletedStep(session: session);
    }
  }
}
