import '../entities/bobine_usage.dart';
import '../entities/production_session_status.dart';

/// Service for calculating production session status.
///
/// Extracts status calculation logic from UI widgets to make it testable and reusable.
class ProductionSessionStatusCalculator {
  /// Calculates the status of a production session based on available data.
  ///
  /// Status determination logic:
  /// - completed: quantity > 0 AND endTime is set AND endTime > startTime
  /// - inProgress: machines or bobines are set
  /// - started: startTime is before now
  /// - draft: default
  static ProductionSessionStatus calculateStatus({
    required int quantiteProduite,
    required DateTime? heureFin,
    required DateTime heureDebut,
    required List<String> machinesUtilisees,
    required List<BobineUsage> bobinesUtilisees,
  }) {
    // Completed: quantity produced and end time set
    if (quantiteProduite > 0 &&
        heureFin != null &&
        heureFin.isAfter(heureDebut)) {
      return ProductionSessionStatus.completed;
    }

    // In progress: machines or bobines assigned
    if (machinesUtilisees.isNotEmpty || bobinesUtilisees.isNotEmpty) {
      return ProductionSessionStatus.inProgress;
    }

    // Started: start time is before now
    if (heureDebut.isBefore(DateTime.now())) {
      return ProductionSessionStatus.started;
    }

    // Default: draft
    return ProductionSessionStatus.draft;
  }

  /// Determines if a session can be completed.
  static bool canComplete({
    required int quantiteProduite,
    required DateTime? heureFin,
    required DateTime heureDebut,
  }) {
    return quantiteProduite > 0 &&
        heureFin != null &&
        heureFin.isAfter(heureDebut);
  }

  /// Determines if a session is in progress.
  static bool isInProgress({
    required List<String> machinesUtilisees,
    required List<BobineUsage> bobinesUtilisees,
  }) {
    return machinesUtilisees.isNotEmpty || bobinesUtilisees.isNotEmpty;
  }

  /// Determines if a session has started.
  static bool hasStarted(DateTime heureDebut) {
    return heureDebut.isBefore(DateTime.now());
  }
}
