import '../entities/bobine_usage.dart';
import '../entities/production_day.dart';
import '../entities/production_session.dart';
import '../entities/production_session_status.dart';
import 'production_session_status_calculator.dart';

/// Service for building ProductionSession entities from form data.
///
/// Extracts entity construction logic from UI widgets to make it testable and reusable.
class ProductionSessionBuilder {
  /// Builds a ProductionSession from form data.
  ///
  /// All parameters are required except where noted as optional.
  static ProductionSession buildFromForm({
    required String? sessionId,
    required DateTime selectedDate,
    required DateTime heureDebut,
    DateTime? heureFin,
    int? indexCompteurInitialKwh,
    int? indexCompteurFinalKwh,
    required double consommationCourant,
    required List<String> machinesUtilisees,
    required List<BobineUsage> bobinesUtilisees,
    required int quantiteProduite,
    int? emballagesUtilises,
    String? notes,
    ProductionSessionStatus? status,
    List<ProductionDay>? productionDays,
    required int period,
  }) {
    // Calculate status if not provided
    final calculatedStatus = status ??
        ProductionSessionStatusCalculator.calculateStatus(
          quantiteProduite: quantiteProduite,
          heureFin: heureFin,
          heureDebut: heureDebut,
          machinesUtilisees: machinesUtilisees,
          bobinesUtilisees: bobinesUtilisees,
        );

    return ProductionSession(
      id: sessionId ?? '',
      date: selectedDate,
      period: period,
      heureDebut: heureDebut,
      heureFin: heureFin,
      indexCompteurInitialKwh: indexCompteurInitialKwh,
      indexCompteurFinalKwh: indexCompteurFinalKwh,
      consommationCourant: consommationCourant,
      machinesUtilisees: machinesUtilisees,
      bobinesUtilisees: bobinesUtilisees,
      quantiteProduite: quantiteProduite,
      quantiteProduiteUnite: 'pack',
      emballagesUtilises: emballagesUtilises,
      notes: notes,
      status: calculatedStatus,
      productionDays: productionDays ?? const [],
    );
  }

  /// Builds a ProductionSession with default values for optional fields.
  static ProductionSession buildWithDefaults({
    required String? sessionId,
    required DateTime selectedDate,
    required DateTime heureDebut,
    required List<String> machinesUtilisees,
    required List<BobineUsage> bobinesUtilisees,
    required int period,
    double consommationCourant = 0.0,
    int quantiteProduite = 0,
  }) {
    return buildFromForm(
      sessionId: sessionId,
      selectedDate: selectedDate,
      heureDebut: heureDebut,
      heureFin: null,
      indexCompteurInitialKwh: null,
      indexCompteurFinalKwh: null,
      consommationCourant: consommationCourant,
      machinesUtilisees: machinesUtilisees,
      bobinesUtilisees: bobinesUtilisees,
      quantiteProduite: quantiteProduite,
      emballagesUtilises: null,
      notes: null,
      status: null, // Will be calculated
      productionDays: null, // Will default to empty list
      period: period,
    );
  }
}

