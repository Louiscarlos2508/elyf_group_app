import 'package:uuid/uuid.dart';

import '../../domain/entities/production_session.dart';
import '../../domain/entities/production_session_status.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/machine_material_usage.dart';

/// Result of loading unfinished machine materials.
class MachineMaterialLoadingResult {
  const MachineMaterialLoadingResult({
    required this.machineMaterials,
    required this.machinesAvecMatiereNonFinie,
  });

  final List<MachineMaterialUsage> machineMaterials;
  final Map<String, MachineMaterialUsage> machinesAvecMatiereNonFinie;
}

/// Service for production business logic.
class ProductionService {
  ProductionService();

  /// Loads unfinished materials for selected machines.
  Future<MachineMaterialLoadingResult> chargerMatieresNonFinies({
    required List<String> machinesSelectionnees,
    required List<ProductionSession> sessionsPrecedentes,
    required List<Machine> machines,
    required List<dynamic> materialStocksDisponibles,
    List<MachineMaterialUsage>? materialsExistantsParam,
  }) async {
    if (machinesSelectionnees.isEmpty) {
      return const MachineMaterialLoadingResult(
        machineMaterials: [],
        machinesAvecMatiereNonFinie: {},
      );
    }

    final machinesMap = <String, Machine>{for (var m in machines) m.id: m};

    final sessionsTriees = sessionsPrecedentes.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final Map<String, MachineMaterialUsage> matieresNonFiniesParMachine = {};

    for (final machineId in machinesSelectionnees) {
      for (final session in sessionsTriees) {
        try {
          final matiereNonFinie = session.machineMaterials.firstWhere(
            (b) => b.machineId == machineId && !b.estFinie,
          );

          matieresNonFiniesParMachine[machineId] = matiereNonFinie;
          break; 
        } catch (_) {
        }
      }
    }

    final materialsExistants = materialsExistantsParam ?? [];
    final machinesAvecMatiere = materialsExistants
        .map((b) => b.machineId)
        .toSet();

    final nouvellesMatieres = <MachineMaterialUsage>[];

    for (final materialExistant in materialsExistants) {
      if (machinesSelectionnees.contains(materialExistant.machineId)) {
        nouvellesMatieres.add(materialExistant);
      }
    }

    for (final machineId in machinesSelectionnees) {
      if (machinesAvecMatiere.contains(machineId)) {
        continue;
      }

      final machine = machinesMap[machineId];
      if (machine == null) continue;

      if (matieresNonFiniesParMachine.containsKey(machineId)) {
        final matiereNonFinie = matieresNonFiniesParMachine[machineId]!;
        nouvellesMatieres.add(
          matiereNonFinie.copyWith(
            isReused: true,
          ),
        );
      } else if (materialStocksDisponibles.isNotEmpty) {
        final materialStock = materialStocksDisponibles.first;
        final maintenant = DateTime.now();
        final nouvelleMatiereUsage = MachineMaterialUsage(
          id: const Uuid().v4(),
          materialType: materialStock.type,
          machineId: machineId,
          machineName: machine.name,
          dateInstallation: maintenant,
          heureInstallation: maintenant,
          estInstallee: true,
          estFinie: false,
          isReused: false,
        );
        nouvellesMatieres.add(nouvelleMatiereUsage);
      }
    }

    return MachineMaterialLoadingResult(
      machineMaterials: nouvellesMatieres,
      machinesAvecMatiereNonFinie: matieresNonFiniesParMachine,
    );
  }

  /// Calculates production session status based on available data.
  ProductionSessionStatus calculateStatus({
    required double quantiteProduite,
    required DateTime? heureFin,
    required DateTime heureDebut,
    required List<String> machinesUtilisees,
    required List<MachineMaterialUsage> machineMaterials,
  }) {
    if (quantiteProduite > 0 &&
        heureFin != null &&
        heureFin.isAfter(heureDebut)) {
      return ProductionSessionStatus.completed;
    }
    if (machinesUtilisees.isNotEmpty || machineMaterials.isNotEmpty) {
      return ProductionSessionStatus.inProgress;
    }
    if (heureDebut.isBefore(DateTime.now())) {
      return ProductionSessionStatus.started;
    }
    return ProductionSessionStatus.draft;
  }

  /// Checks if all materials are finished.
  bool toutesMatieresFinies(List<MachineMaterialUsage> machineMaterials) {
    if (machineMaterials.isEmpty) return false;
    return machineMaterials.every((m) => m.estFinie);
  }

  /// Checks if production can be finalized.
  bool peutEtreFinalisee({
    required List<MachineMaterialUsage> machineMaterials,
    required List<String> machinesUtilisees,
  }) {
    return toutesMatieresFinies(machineMaterials) &&
        machineMaterials.isNotEmpty &&
        machinesUtilisees.length == machineMaterials.length;
  }
}
