import 'bobine_usage.dart';
import 'production_day.dart';
import 'production_event.dart';
import 'production_session_status.dart';

/// Session de production avec suivi détaillé des bobines, machines et coûts.
class ProductionSession {
  const ProductionSession({
    required this.id,
    required this.date,
    required this.period,
    required this.heureDebut,
    this.heureFin,
    this.indexCompteurInitialKwh,
    this.indexCompteurFinalKwh,
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
    this.cancelReason,
    this.events = const [],
    this.productionDays = const [],
  });

  final String id;
  final DateTime date;
  final int period; // Période de production (pour compatibilité)
  final DateTime heureDebut;
  final DateTime? heureFin; // null jusqu'à la finalisation de la production
  final int?
  indexCompteurInitialKwh; // Index compteur électrique initial (kWh) au démarrage
  final int?
  indexCompteurFinalKwh; // Index compteur électrique final (kWh) à la fin
  final double
  consommationCourant; // kWh (calculé si indexCompteurInitialKwh et indexCompteurFinalKwh sont définis)
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
  final List<ProductionEvent> events; // Événements (pannes, coupures, arrêts)
  final List<ProductionDay>
  productionDays; // Jours de production avec personnel
  final String? cancelReason;

  /// Calcule la durée de production en heures
  double get dureeHeures {
    if (heureFin == null) {
      // Si pas encore finalisée, calculer depuis le début jusqu'à maintenant
      final difference = DateTime.now().difference(heureDebut);
      return difference.inMinutes / 60.0;
    }
    final difference = heureFin!.difference(heureDebut);
    return difference.inMinutes / 60.0;
  }

  /// Calcule le coût total de la session (bobines + électricité + personnel)
  int get coutTotal {
    final coutBob = coutBobines ?? 0;
    final coutElec = coutElectricite ?? 0;
    final coutPers = coutTotalPersonnel;
    return coutBob + coutElec + coutPers;
  }

  /// Vérifie si la session est complète (toutes les données nécessaires)
  bool get estComplete {
    return bobinesUtilisees.isNotEmpty &&
        machinesUtilisees.isNotEmpty &&
        (quantiteProduite > 0 || totalPacksProduitsJournalier > 0);
  }

  /// Calcule le statut de progression basé sur les données disponibles
  ProductionSessionStatus get calculatedStatus {
    if (quantiteProduite > 0 &&
        heureFin != null &&
        heureFin!.isAfter(heureDebut)) {
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

  /// Retourne le statut effectif (toujours utiliser le statut enregistré, sauf s'il est draft)
  ///
  /// Le statut enregistré doit toujours être utilisé pour éviter les conflits.
  /// Si le statut est draft, on peut calculer le statut à partir des données.
  ProductionSessionStatus get effectiveStatus {
    // Si annulée, on reste annulée
    if (status == ProductionSessionStatus.cancelled) {
      return ProductionSessionStatus.cancelled;
    }
    // Utiliser le statut enregistré s'il existe et n'est pas draft
    // Cela garantit que le statut explicitement défini (notamment "completed") est toujours respecté
    if (status != ProductionSessionStatus.draft) {
      return status;
    }
    // Si le statut est draft, calculer le statut à partir des données disponibles
    return calculatedStatus;
  }

  /// Vérifie si toutes les bobines sont complètement finies.
  /// Une production ne peut se terminer que si toutes les bobines sont finies.
  bool get toutesBobinesFinies {
    if (bobinesUtilisees.isEmpty) return false;
    return bobinesUtilisees.every((bobine) => bobine.estFinie);
  }

  /// Vérifie si la production peut être finalisée.
  /// Conditions : toutes les boubines doivent être finies.
  bool get peutEtreFinalisee {
    return toutesBobinesFinies &&
        bobinesUtilisees.isNotEmpty &&
        machinesUtilisees.length == bobinesUtilisees.length;
  }

  /// Total des packs produits sur l'ensemble des jours de production.
  int get totalPacksProduitsJournalier {
    return productionDays.fold<int>(0, (sum, day) => sum + day.packsProduits);
  }

  /// Total des emballages utilisés sur l'ensemble des jours de production.
  int get totalEmballagesUtilisesJournalier {
    return productionDays.fold<int>(
      0,
      (sum, day) => sum + day.emballagesUtilises,
    );
  }

  /// Calcule le coût total du personnel pour tous les jours de production.
  int get coutTotalPersonnel {
    return productionDays.fold<int>(
      0,
      (sum, day) => sum + day.coutTotalPersonnel,
    );
  }

  /// Vérifie s'il y a des événements en cours (non terminés).
  bool get aEvenementsEnCours {
    return events.any((event) => !event.estTermine);
  }

  /// Récupère les événements d'un type donné.
  List<ProductionEvent> evenementsParType(ProductionEventType type) {
    return events.where((event) => event.type == type).toList();
  }

  ProductionSession copyWith({
    String? id,
    DateTime? date,
    int? period,
    DateTime? heureDebut,
    DateTime? heureFin,
    int? indexCompteurInitialKwh,
    int? indexCompteurFinalKwh,
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
    String? cancelReason,
    List<ProductionEvent>? events,
    List<ProductionDay>? productionDays,
  }) {
    return ProductionSession(
      id: id ?? this.id,
      date: date ?? this.date,
      period: period ?? this.period,
      heureDebut: heureDebut ?? this.heureDebut,
      heureFin: heureFin ?? this.heureFin,
      indexCompteurInitialKwh:
          indexCompteurInitialKwh ?? this.indexCompteurInitialKwh,
      indexCompteurFinalKwh:
          indexCompteurFinalKwh ?? this.indexCompteurFinalKwh,
      consommationCourant: consommationCourant ?? this.consommationCourant,
      machinesUtilisees: machinesUtilisees ?? this.machinesUtilisees,
      bobinesUtilisees: bobinesUtilisees ?? this.bobinesUtilisees,
      quantiteProduite: quantiteProduite ?? this.quantiteProduite,
      quantiteProduiteUnite:
          quantiteProduiteUnite ?? this.quantiteProduiteUnite,
      emballagesUtilises: emballagesUtilises ?? this.emballagesUtilises,
      coutBobines: coutBobines ?? this.coutBobines,
      coutElectricite: coutElectricite ?? this.coutElectricite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      events: events ?? this.events,
      productionDays: productionDays ?? this.productionDays,
    );
  }
}
