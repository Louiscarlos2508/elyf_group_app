import 'bobine_usage.dart';
import 'production_session_status.dart';

/// Session de production avec suivi détaillé des bobines, machines et coûts.
class ProductionSession {
  const ProductionSession({
    required this.id,
    required this.date,
    required this.period,
    required this.heureDebut,
    required this.heureFin,
    required this.indexCompteurDebut,
    required this.indexCompteurFin,
    required this.consommationCourant,
    required this.machinesUtilisees,
    required this.bobinesUtilisees,
    required this.quantiteProduite,
    required this.quantiteProduiteUnite,
    this.emballagesUtilises,
    this.coutBobines,
    this.coutElectricite,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.status = ProductionSessionStatus.draft,
  }) : assert(
          indexCompteurFin >= indexCompteurDebut,
          'L\'index final doit être supérieur ou égal à l\'index initial',
        );

  final String id;
  final DateTime date;
  final int period; // Période de production (pour compatibilité)
  final DateTime heureDebut;
  final DateTime heureFin;
  final int indexCompteurDebut; // Index du compteur d'eau au début
  final int indexCompteurFin; // Index du compteur d'eau à la fin
  final double consommationCourant; // kWh
  final List<String> machinesUtilisees; // IDs des machines
  final List<BobineUsage> bobinesUtilisees;
  final int quantiteProduite; // Quantité produite
  final String quantiteProduiteUnite; // Unité (ex: "pack", "sachet")
  final int? emballagesUtilises; // Nombre d'emballages utilisés (packs)
  final int? coutBobines; // Coût total des bobines utilisées (CFA)
  final int? coutElectricite; // Coût de l'électricité (CFA)
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ProductionSessionStatus status;

  /// Calcule la consommation d'eau (indexFin - indexDébut)
  int get consommationEau => indexCompteurFin - indexCompteurDebut;

  /// Calcule la durée de production en heures
  double get dureeHeures {
    final difference = heureFin.difference(heureDebut);
    return difference.inMinutes / 60.0;
  }

  /// Calcule le poids total des bobines utilisées (kg)
  double get poidsTotalBobinesUtilisees {
    return bobinesUtilisees.fold<double>(
      0,
      (sum, bobine) => sum + bobine.poidsUtilise,
    );
  }

  /// Calcule le coût total de la session (bobines + électricité)
  int get coutTotal {
    final coutBob = coutBobines ?? 0;
    final coutElec = coutElectricite ?? 0;
    return coutBob + coutElec;
  }

  /// Vérifie si la session est complète (toutes les données nécessaires)
  bool get estComplete {
    return bobinesUtilisees.isNotEmpty &&
        machinesUtilisees.isNotEmpty &&
        quantiteProduite > 0 &&
        consommationEau >= 0;
  }

  /// Calcule le statut de progression basé sur les données disponibles
  ProductionSessionStatus get calculatedStatus {
    if (quantiteProduite > 0 && heureFin.isAfter(heureDebut)) {
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

  /// Retourne le statut effectif (celui défini ou celui calculé)
  ProductionSessionStatus get effectiveStatus {
    return status != ProductionSessionStatus.draft
        ? status
        : calculatedStatus;
  }

  ProductionSession copyWith({
    String? id,
    DateTime? date,
    int? period,
    DateTime? heureDebut,
    DateTime? heureFin,
    int? indexCompteurDebut,
    int? indexCompteurFin,
    double? consommationCourant,
    List<String>? machinesUtilisees,
    List<BobineUsage>? bobinesUtilisees,
    int? quantiteProduite,
    String? quantiteProduiteUnite,
    int? emballagesUtilises,
    int? coutBobines,
    int? coutElectricite,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProductionSessionStatus? status,
  }) {
    return ProductionSession(
      id: id ?? this.id,
      date: date ?? this.date,
      period: period ?? this.period,
      heureDebut: heureDebut ?? this.heureDebut,
      heureFin: heureFin ?? this.heureFin,
      indexCompteurDebut: indexCompteurDebut ?? this.indexCompteurDebut,
      indexCompteurFin: indexCompteurFin ?? this.indexCompteurFin,
      consommationCourant: consommationCourant ?? this.consommationCourant,
      machinesUtilisees: machinesUtilisees ?? this.machinesUtilisees,
      bobinesUtilisees: bobinesUtilisees ?? this.bobinesUtilisees,
      quantiteProduite: quantiteProduite ?? this.quantiteProduite,
      quantiteProduiteUnite: quantiteProduiteUnite ?? this.quantiteProduiteUnite,
      emballagesUtilises: emballagesUtilises ?? this.emballagesUtilises,
      coutBobines: coutBobines ?? this.coutBobines,
      coutElectricite: coutElectricite ?? this.coutElectricite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}

