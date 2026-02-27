import 'payment_status.dart';
import 'material_consumption.dart';

/// Représente un jour de production avec le personnel et la production journalière.
class ProductionDay {
  const ProductionDay({
    required this.id,
    required this.enterpriseId,
    required this.productionId,
    required this.date,
    required this.personnelIds,
    required this.nombrePersonnes,
    required this.salaireJournalierParPersonne,
    this.coutTotalPersonnelStored,
    this.packsProduits = 0,
    this.emballagesUtilises = 0,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deletedBy,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentId,
    this.datePaiement,
    this.consumptions = const [],
    this.producedItems = const [],
  });

  /// Identifiant unique du jour de production.
  final String id;

  /// Identifiant de l'entreprise.
  final String enterpriseId;

  /// Identifiant de la session de production associée.
  final String productionId;

  /// Date du jour de production.
  final DateTime date;

  /// Identifiants des personnes (ouvriers) présentes ce jour‑là.
  final List<String> personnelIds;

  /// Nombre total de personnes présentes.
  final int nombrePersonnes;

  /// Salaire journalier par personne (moyenne ou taux unique, en CFA).
  final int salaireJournalierParPersonne;

  /// Coût total réel (somme des salaires des ouvriers) lorsqu’enregistré.
  /// Évite les écarts dus aux arrondis de la moyenne.
  final int? coutTotalPersonnelStored;

  /// Nombre de packs produits pendant ce jour.
  final int packsProduits;

  /// Nombre d'emballages (packs) utilisés pendant ce jour.
  final int emballagesUtilises;

  /// Commentaires éventuels sur la journée.
  final String? notes;

  /// Date de création de l'enregistrement.
  final DateTime? createdAt;

  /// Dernière mise à jour.
  final DateTime? updatedAt;

  /// Date de suppression.
  final DateTime? deletedAt;

  /// Utilisateur ayant supprimé.
  final String? deletedBy;

  /// Statut de paiement de ce jour de production.
  final PaymentStatus paymentStatus;

  /// ID du paiement associé (si payé).
  final String? paymentId;

  /// Date à laquelle le paiement a été effectué.
  final DateTime? datePaiement;

  /// Liste des matières consommées ce jour‑là (emballages, etc. hors bobines).
  final List<MaterialConsumption> consumptions;

  /// Liste des produits finis produits ce jour‑là.
  final List<MaterialConsumption> producedItems;

  /// Coût total du personnel pour ce jour.
  /// Utilise [coutTotalPersonnelStored] si présent, sinon nombrePersonnes × salaireJournalierParPersonne.
  int get coutTotalPersonnel =>
      coutTotalPersonnelStored ??
      (nombrePersonnes * salaireJournalierParPersonne);

  /// Indique si au moins une personne est enregistrée pour ce jour.
  bool get aPersonnel => nombrePersonnes > 0 && personnelIds.isNotEmpty;

  /// Indique si une production a été saisie pour ce jour.
  bool get aProduction => producedItems.isNotEmpty || packsProduits > 0 || consumptions.isNotEmpty || emballagesUtilises > 0;
  bool get isDeleted => deletedAt != null;

  ProductionDay copyWith({
    String? id,
    String? enterpriseId,
    String? productionId,
    DateTime? date,
    List<String>? personnelIds,
    int? nombrePersonnes,
    int? salaireJournalierParPersonne,
    int? coutTotalPersonnelStored,
    int? packsProduits,
    int? emballagesUtilises,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletedBy,
    PaymentStatus? paymentStatus,
    String? paymentId,
    DateTime? datePaiement,
    List<MaterialConsumption>? consumptions,
    List<MaterialConsumption>? producedItems,
  }) {
    return ProductionDay(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      productionId: productionId ?? this.productionId,
      date: date ?? this.date,
      personnelIds: personnelIds ?? this.personnelIds,
      nombrePersonnes: nombrePersonnes ?? this.nombrePersonnes,
      salaireJournalierParPersonne:
          salaireJournalierParPersonne ?? this.salaireJournalierParPersonne,
      coutTotalPersonnelStored:
          coutTotalPersonnelStored ?? this.coutTotalPersonnelStored,
      packsProduits: packsProduits ?? this.packsProduits,
      emballagesUtilises: emballagesUtilises ?? this.emballagesUtilises,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      datePaiement: datePaiement ?? this.datePaiement,
      consumptions: consumptions ?? this.consumptions,
      producedItems: producedItems ?? this.producedItems,
    );
  }

  factory ProductionDay.fromMap(
    Map<String, dynamic> map,
    String defaultEnterpriseId,
  ) {
    return ProductionDay(
      id: (map['localId'] as String?)?.trim().isNotEmpty == true 
          ? map['localId'] as String 
          : (map['id'] as String? ?? ''),
      enterpriseId: map['enterpriseId'] as String? ?? defaultEnterpriseId,
      productionId: map['productionId'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      personnelIds: List<String>.from(map['personnelIds'] as List? ?? []),
      nombrePersonnes: (map['nombrePersonnes'] as num?)?.toInt() ?? 0,
      salaireJournalierParPersonne:
          (map['salaireJournalierParPersonne'] as num?)?.toInt() ?? 0,
      coutTotalPersonnelStored:
          (map['coutTotalPersonnelStored'] as num?)?.toInt(),
      packsProduits: (map['packsProduits'] as num?)?.toInt() ?? 0,
      emballagesUtilises: (map['emballagesUtilises'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'] as String)
          : null,
      deletedBy: map['deletedBy'] as String?,
      paymentStatus: PaymentStatus.values.byName(
        map['paymentStatus'] as String? ?? 'unpaid',
      ),
      paymentId: map['paymentId'] as String?,
      datePaiement: map['datePaiement'] != null
          ? DateTime.parse(map['datePaiement'] as String)
          : null,
      consumptions: (map['consumptions'] as List? ?? [])
          .map((e) => MaterialConsumption.fromMap(e as Map<String, dynamic>))
          .toList(),
      producedItems: (map['producedItems'] as List? ?? [])
          .map((e) => MaterialConsumption.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'productionId': productionId,
      'date': date.toIso8601String(),
      'personnelIds': personnelIds,
      'nombrePersonnes': nombrePersonnes,
      'salaireJournalierParPersonne': salaireJournalierParPersonne,
      'coutTotalPersonnelStored': coutTotalPersonnelStored,
      'packsProduits': packsProduits,
      'emballagesUtilises': emballagesUtilises,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'paymentStatus': paymentStatus.name,
      'paymentId': paymentId,
      'datePaiement': datePaiement?.toIso8601String(),
      'consumptions': consumptions.map((e) => e.toMap()).toList(),
      'producedItems': producedItems.map((e) => e.toMap()).toList(),
    };
  }
}
