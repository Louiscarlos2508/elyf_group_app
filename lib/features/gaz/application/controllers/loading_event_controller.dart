import '../../domain/entities/loading_event.dart';
import '../../domain/entities/loading_expense.dart';
import '../../domain/repositories/loading_event_repository.dart';
import '../../domain/services/loading_event_service.dart';

/// Contrôleur pour la gestion des événements de chargement.
class LoadingEventController {
  LoadingEventController(
    this._repository,
    this._loadingEventService,
  );

  final LoadingEventRepository _repository;
  final LoadingEventService _loadingEventService;

  /// Récupère les événements de chargement.
  Future<List<LoadingEvent>> getLoadingEvents(
    String enterpriseId, {
    LoadingEventStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    return _repository.getLoadingEvents(
      enterpriseId,
      status: status,
      from: from,
      to: to,
    );
  }

  /// Récupère un événement par ID.
  Future<LoadingEvent?> getLoadingEventById(String id) async {
    return _repository.getLoadingEventById(id);
  }

  /// Crée un événement de chargement (préparation convoi).
  Future<String> createLoadingEvent(
    String enterpriseId,
    Map<int, int> emptyCylinders, {
    String? notes,
  }) async {
    // Valider l'inventaire
    final validationError = await _loadingEventService
        .validateEmptyCylindersInventory(enterpriseId, emptyCylinders);
    if (validationError != null) {
      throw Exception(validationError);
    }

    // Préparer le convoi (changer statuts)
    await _loadingEventService.prepareConvoy(enterpriseId, emptyCylinders);

    // Créer l'événement
    final event = LoadingEvent(
      id: '',
      enterpriseId: enterpriseId,
      eventDate: DateTime.now(),
      status: LoadingEventStatus.preparing,
      emptyCylinders: emptyCylinders,
      notes: notes,
    );

    return _repository.createLoadingEvent(event);
  }

  /// Ajoute une dépense à un événement.
  Future<void> addExpenseToEvent(
    String eventId,
    LoadingExpense expense,
  ) async {
    await _repository.addExpenseToEvent(eventId, expense);
  }

  /// Valide et complète un événement (réception chargement).
  Future<void> completeLoadingEvent(
    String eventId,
    Map<int, int> fullCylindersReceived,
  ) async {
    await _loadingEventService.completeLoadingEvent(
      eventId,
      fullCylindersReceived,
    );
  }

  /// Annule un événement.
  Future<void> cancelLoadingEvent(String eventId) async {
    await _repository.cancelLoadingEvent(eventId);
  }
}