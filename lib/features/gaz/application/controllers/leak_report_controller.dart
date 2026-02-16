
import '../../domain/entities/cylinder_leak.dart';
import '../../domain/services/leak_report_service.dart';

/// Controller pour gérer la génération des réclamations fournisseur.
class LeakReportController {
  LeakReportController({
    required this.service,
  });

  final LeakReportService service;

  /// Marque les fuites sélectionnées comme envoyées.
  Future<void> submitClaim(List<String> leakIds) async {
    await service.markLeaksAsSent(leakIds);
  }

  /// Récupère le résumé des fuites en attente.
  Future<Map<int, List<CylinderLeak>>> getPendingLeaksSummary(String enterpriseId) async {
    return service.getPendingLeaksSummary(enterpriseId);
  }
}
