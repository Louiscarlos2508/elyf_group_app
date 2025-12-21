import '../entities/loading_event.dart';
import '../entities/loading_expense.dart';

/// Interface pour le repository des événements de chargement.
abstract class LoadingEventRepository {
  Future<List<LoadingEvent>> getLoadingEvents(
    String enterpriseId, {
    LoadingEventStatus? status,
    DateTime? from,
    DateTime? to,
  });

  Future<LoadingEvent?> getLoadingEventById(String id);

  Future<String> createLoadingEvent(LoadingEvent event);

  Future<void> updateLoadingEvent(LoadingEvent event);

  Future<void> addExpenseToEvent(String eventId, LoadingExpense expense);

  Future<void> completeLoadingEvent(
    String eventId,
    Map<int, int> receivedCylinders,
  );

  Future<void> cancelLoadingEvent(String eventId);

  Future<void> deleteLoadingEvent(String id);
}