import '../repositories/tour_repository.dart';
import '../repositories/pos_remittance_repository.dart';
import '../repositories/cylinder_leak_repository.dart';
import '../repositories/gaz_settings_repository.dart';
import '../repositories/gas_repository.dart';
import '../../../administration/domain/repositories/enterprise_repository.dart';
import '../entities/site_logistics_record.dart';
import '../entities/pos_remittance.dart';
import '../entities/cylinder_leak.dart';

class GazReconciliationService {
  final TourRepository tourRepository;
  final GazPOSRemittanceRepository remittanceRepository;
  final CylinderLeakRepository leakRepository;
  final GazSettingsRepository settingsRepository;
  final EnterpriseRepository enterpriseRepository;
  final GasRepository gasRepository;

  const GazReconciliationService({
    required this.tourRepository,
    required this.remittanceRepository,
    required this.leakRepository,
    required this.settingsRepository,
    required this.enterpriseRepository,
    required this.gasRepository,
  });

  /// Calcule le record logistique complet pour une entreprise mère.
  /// Retourne une liste de records (un par POS enfant).
  Stream<List<GazSiteLogisticsRecord>> watchReconciliationRecords(String parentEnterpriseId) {
    // 1. Surveiller toutes les entreprises enfants (POS)
    return enterpriseRepository.watchAllEnterprises().asyncMap((allEnterprises) async {
      final posList = allEnterprises.where((e) => 
        (e.parentEnterpriseId == parentEnterpriseId || e.ancestorIds.contains(parentEnterpriseId)) &&
        e.isPointOfSale
      ).toList();

      if (posList.isEmpty) return [];

      // 2. Récupérer les données globales nécessaires
      final tours = await tourRepository.getTours(parentEnterpriseId);
      final remittances = await remittanceRepository.getRemittances(parentEnterpriseId, status: RemittanceStatus.validated);
      final parentSettings = await settingsRepository.getSettings(
        enterpriseId: parentEnterpriseId, 
        moduleId: 'gaz'
      );

      final List<GazSiteLogisticsRecord> records = [];

      for (final pos in posList) {
        // A. Récupérer les paramètres spécifiques du POS
        final posSettings = await settingsRepository.getSettings(
          enterpriseId: pos.id, 
          moduleId: 'gaz'
        );
        
        // Déterminer si le POS est en mode Gros (Wholesale)
        // Règle : Si des prix de gros sont définis, on considère qu'on suit les ventes réelles
        final isWholesaleEnabled = posSettings?.wholesalePrices.isNotEmpty ?? false;

        double totalConsignedValue = 0.0;
        double siteCollectedCash = 0.0;
        
        if (isWholesaleEnabled) {
          // MODE GROS : Dette = Somme des ventes enregistrées par le POS
          final sales = await gasRepository.getSales(enterpriseIds: [pos.id]);
          totalConsignedValue = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
        } else {
          // MODE DETAIL : Dette = Bouteilles confiées (livrées) × Prix de vente detail du POS
          for (final tour in tours) {
            for (final interaction in tour.siteInteractions) {
              if (interaction.siteId == pos.id) {
                for (final entry in interaction.fullBottlesDelivered.entries) {
                  final price = posSettings?.retailPrices[entry.key] ?? parentSettings?.retailPrices[entry.key] ?? 0.0;
                  totalConsignedValue += entry.value * price;
                }
              }
            }
          }
        }

        // B. Calculer le Cash collecté sur site durant les tournées (Remittance)
        for (final tour in tours) {
          for (final interaction in tour.siteInteractions) {
            if (interaction.siteId == pos.id) {
              siteCollectedCash += interaction.cashCollected;
            }
          }
        }

        // C. Sommes déjà versées (Remittances validées + Cash collecté sur site)
        final posRemittances = remittances.where((r) => r.posId == pos.id);
        final totalRemittedValue = posRemittances.fold<double>(0, (sum, r) => sum + r.amount) + siteCollectedCash;

        // D. Valeur des fuites (Utilise le prix d'achat du Parent - Au prix de revient)
        // On ne compte que les fuites qui représentent une perte sèche (non encore échangées)
        final posLeaks = await leakRepository.getLeaks(pos.id);
        double totalLeakValue = 0.0;
        for (final leak in posLeaks) {
          if (leak.status == LeakStatus.exchanged) continue;
          
          final price = parentSettings?.purchasePrices[leak.weight] ?? 0.0;
          totalLeakValue += price;
        }

        records.add(GazSiteLogisticsRecord(
          id: 'rec_${pos.id}',
          enterpriseId: parentEnterpriseId,
          siteId: pos.id,
          totalConsignedValue: totalConsignedValue,
          totalRemittedValue: totalRemittedValue,
          totalLeakValue: totalLeakValue,
          updatedAt: DateTime.now(),
        ));
      }

      return records;
    });
  }
}
