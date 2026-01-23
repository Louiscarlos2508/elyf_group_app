import 'payment_status.dart';

/// Représente un jour de production avec le personnel et la production journalière.
class ProductionDay {
  const ProductionDay({
    required this.id,
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
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentId,
    this.datePaiement,
  });

  /// Identifiant unique du jour de production.
  final String id;

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

  /// Statut de paiement de ce jour de production.
  final PaymentStatus paymentStatus;

  /// ID du paiement associé (si payé).
  final String? paymentId;

  /// Date à laquelle le paiement a été effectué.
  final DateTime? datePaiement;

  /// Coût total du personnel pour ce jour.
  /// Utilise [coutTotalPersonnelStored] si présent, sinon nombrePersonnes × salaireJournalierParPersonne.
  int get coutTotalPersonnel =>
      coutTotalPersonnelStored ??
      (nombrePersonnes * salaireJournalierParPersonne);

  /// Indique si au moins une personne est enregistrée pour ce jour.
  bool get aPersonnel => nombrePersonnes > 0 && personnelIds.isNotEmpty;

  /// Indique si une production a été saisie pour ce jour.
  bool get aProduction => packsProduits > 0 || emballagesUtilises > 0;

  ProductionDay copyWith({
    String? id,
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
    PaymentStatus? paymentStatus,
    String? paymentId,
    DateTime? datePaiement,
  }) {
    return ProductionDay(
      id: id ?? this.id,
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
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      datePaiement: datePaiement ?? this.datePaiement,
    );
  }
}
