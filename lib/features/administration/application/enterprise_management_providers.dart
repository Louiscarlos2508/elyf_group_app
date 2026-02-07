import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';


/// Provider pour les statistiques de vente d'une entreprise donnée.
/// Note: En production, cela appellerait les services des différents modules.
final enterpriseSalesStatsProvider = FutureProvider.autoDispose.family<Map<String, double>, String>((ref, enterpriseId) async {
  // Simulation de données de vente
  await Future.delayed(const Duration(milliseconds: 500));
  return {
    'total_sales': 1250000.0,
    'monthly_growth': 12.5,
    'average_transaction': 15000.0,
  };
});

/// Provider pour les employés rattachés à une entreprise.
final enterpriseEmployeesProvider = Provider.autoDispose.family<AsyncValue<List<dynamic>>, String>((ref, enterpriseId) {
  final assignmentsAsync = ref.watch(enterpriseModuleUsersProvider);
  
  return assignmentsAsync.whenData((assignments) {
    return assignments.where((a) => a.enterpriseId == enterpriseId).toList();
  });
});
