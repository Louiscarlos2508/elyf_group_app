
import '../entities/cylinder_leak.dart';
import '../repositories/cylinder_leak_repository.dart';

/// Service pour agréger les fuites et préparer les réclamations fournisseur.
class LeakReportService {
  LeakReportService({
    required this.leakRepository,
  });

  final CylinderLeakRepository leakRepository;

  /// Agrége les fuites "Reported" par poids pour un rapport de réclamation.
  Future<Map<int, List<CylinderLeak>>> getPendingLeaksSummary(String enterpriseId) async {
    final leaks = await leakRepository.getLeaks(enterpriseId, status: LeakStatus.reported);
    
    final summary = <int, List<CylinderLeak>>{};
    for (final leak in leaks) {
      summary.putIfAbsent(leak.weight, () => []).add(leak);
    }
    
    return summary;
  }

  /// Marque une liste de fuites comme "Sent for Exchange".
  Future<void> markLeaksAsSent(List<String> leakIds) async {
    for (final id in leakIds) {
      await leakRepository.markAsSentForExchange(id);
    }
  }

  /// Calcule le total des fuites par poids.
  Map<int, int> calculateTotals(Map<int, List<CylinderLeak>> summary) {
    return summary.map((weight, leaks) => MapEntry(weight, leaks.length));
  }
}
