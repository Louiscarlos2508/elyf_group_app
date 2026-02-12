import '../../domain/entities/production_session.dart';
import '../../domain/entities/production_session_status.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/bobine_stock.dart';
import '../../domain/entities/bobine_usage.dart';

/// Result of loading unfinished bobbins for machines.
class BobineLoadingResult {
  const BobineLoadingResult({
    required this.bobinesUtilisees,
    required this.machinesAvecBobineNonFinie,
  });

  final List<BobineUsage> bobinesUtilisees;
  final Map<String, BobineUsage> machinesAvecBobineNonFinie;
}

/// Service for production business logic.
///
/// Extracts complex business logic from UI widgets, particularly
/// the _chargerBobinesNonFinies method.
class ProductionService {
  ProductionService();

  /// Loads unfinished bobbins for selected machines.
  ///
  /// For each selected machine:
  /// - If machine has an unfinished bobine from a previous session → reuse (no decrement)
  /// - If machine has no unfinished bobine → install new bobine (decrement needed)
  ///
  /// This is the extracted version of _chargerBobinesNonFinies from production_session_form_steps.dart
  Future<BobineLoadingResult> chargerBobinesNonFinies({
    required List<String> machinesSelectionnees,
    required List<ProductionSession> sessionsPrecedentes,
    required List<Machine> machines,
    required List<BobineStock> bobineStocksDisponibles,
    List<BobineUsage>? bobinesExistantesParam,
  }) async {
    if (machinesSelectionnees.isEmpty) {
      return const BobineLoadingResult(
        bobinesUtilisees: [],
        machinesAvecBobineNonFinie: {},
      );
    }

    // Create machines map for quick lookup
    final machinesMap = <String, Machine>{for (var m in machines) m.id: m};

    // Sort sessions from most recent to oldest
    final sessionsTriees = sessionsPrecedentes.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Map to store unfinished bobbins found per machine
    final Map<String, BobineUsage> bobinesNonFiniesParMachine = {};

    // For each selected machine, check if it has an unfinished bobine
    for (final machineId in machinesSelectionnees) {
      // Search in all sessions if this machine has an unfinished bobine
      for (final session in sessionsTriees) {
        try {
          final bobineNonFinie = session.bobinesUtilisees.firstWhere(
            (b) => b.machineId == machineId && !b.estFinie,
          );

          // If we find an unfinished bobine for this machine, store it and stop
          bobinesNonFiniesParMachine[machineId] = bobineNonFinie;
          break; // A machine can only have one bobine at a time
        } catch (_) {
          // No unfinished bobine found in this session, continue
        }
      }
    }

    // Identify machines that already have a bobine in the current list
    final bobinesExistantes = bobinesExistantesParam ?? [];
    final machinesAvecBobine = bobinesExistantes
        .map((b) => b.machineId)
        .toSet();

    // Build new list of bobbins used
    final nouvellesBobines = <BobineUsage>[];

    // Keep existing bobbins that are still on selected machines
    for (final bobineExistante in bobinesExistantes) {
      if (machinesSelectionnees.contains(bobineExistante.machineId)) {
        nouvellesBobines.add(bobineExistante);
      }
    }

    // For each selected machine, determine which bobine to use
    for (final machineId in machinesSelectionnees) {
      // If this machine already has a bobine in the current list, keep it
      if (machinesAvecBobine.contains(machineId)) {
        continue;
      }

      final machine = machinesMap[machineId];
      if (machine == null) continue;

      // Check machine state: does it have an unfinished bobine?
      if (bobinesNonFiniesParMachine.containsKey(machineId)) {
        // Machine with unfinished bobine: reuse (no decrement)
        final bobineNonFinie = bobinesNonFiniesParMachine[machineId]!;
        final maintenant = DateTime.now();
        nouvellesBobines.add(
          bobineNonFinie.copyWith(
            dateInstallation: maintenant,
            heureInstallation: maintenant,
          ),
        );
      } else if (bobineStocksDisponibles.isNotEmpty) {
        // Machine without unfinished bobine: install new bobine (decrement needed)
        final bobineStock = bobineStocksDisponibles.first;
        final maintenant = DateTime.now();
        final nouvelleBobineUsage = BobineUsage(
          bobineType: bobineStock.type,
          machineId: machineId,
          machineName: machine.name,
          dateInstallation: maintenant,
          heureInstallation: maintenant,
          estInstallee: true,
          estFinie: false,
        );
        nouvellesBobines.add(nouvelleBobineUsage);
      }
    }

    return BobineLoadingResult(
      bobinesUtilisees: nouvellesBobines,
      machinesAvecBobineNonFinie: bobinesNonFiniesParMachine,
    );
  }

  /// Calculates production session status based on available data.
  ProductionSessionStatus calculateStatus({
    required int quantiteProduite,
    required DateTime? heureFin,
    required DateTime heureDebut,
    required List<String> machinesUtilisees,
    required List<BobineUsage> bobinesUtilisees,
  }) {
    if (quantiteProduite > 0 &&
        heureFin != null &&
        heureFin.isAfter(heureDebut)) {
      return ProductionSessionStatus.completed;
    }
    if (machinesUtilisees.isNotEmpty || bobinesUtilisees.isNotEmpty) {
      return ProductionSessionStatus.inProgress;
    }
    if (heureDebut.isBefore(DateTime.now())) {
      return ProductionSessionStatus.started;
    }
    return ProductionSessionStatus.draft;
  }

  /// Checks if all bobbins are finished.
  bool toutesBobinesFinies(List<BobineUsage> bobinesUtilisees) {
    if (bobinesUtilisees.isEmpty) return false;
    return bobinesUtilisees.every((bobine) => bobine.estFinie);
  }

  /// Checks if production can be finalized.
  bool peutEtreFinalisee({
    required List<BobineUsage> bobinesUtilisees,
    required List<String> machinesUtilisees,
  }) {
    return toutesBobinesFinies(bobinesUtilisees) &&
        bobinesUtilisees.isNotEmpty &&
        machinesUtilisees.length == bobinesUtilisees.length;
  }
}
