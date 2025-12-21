import 'loading_expense.dart';

// Import CylinderStatus depuis cylinder.dart via cylinder_stock.dart
// Utilisé indirectement via les services

/// Statut d'un événement de chargement.
enum LoadingEventStatus {
  preparing('En préparation'),
  inTransit('En transit'),
  completed('Terminé'),
  cancelled('Annulé');

  const LoadingEventStatus(this.label);
  final String label;
}

/// Représente un événement de chargement (voyage vers centre d'emplissage).
class LoadingEvent {
  const LoadingEvent({
    required this.id,
    required this.enterpriseId,
    required this.eventDate,
    required this.status,
    required this.emptyCylinders,
    this.fullCylindersReceived = const {},
    this.expenses = const [],
    this.notes,
    this.completedDate,
  });

  final String id;
  final String enterpriseId;
  final DateTime eventDate;
  final LoadingEventStatus status;
  final Map<int, int> emptyCylinders; // weight -> quantity
  final Map<int, int> fullCylindersReceived; // weight -> quantity
  final List<LoadingExpense> expenses;
  final String? notes;
  final DateTime? completedDate;

  LoadingEvent copyWith({
    String? id,
    String? enterpriseId,
    DateTime? eventDate,
    LoadingEventStatus? status,
    Map<int, int>? emptyCylinders,
    Map<int, int>? fullCylindersReceived,
    List<LoadingExpense>? expenses,
    String? notes,
    DateTime? completedDate,
  }) {
    return LoadingEvent(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      eventDate: eventDate ?? this.eventDate,
      status: status ?? this.status,
      emptyCylinders: emptyCylinders ?? this.emptyCylinders,
      fullCylindersReceived:
          fullCylindersReceived ?? this.fullCylindersReceived,
      expenses: expenses ?? this.expenses,
      notes: notes ?? this.notes,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  double get totalExpenses {
    return expenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }
}