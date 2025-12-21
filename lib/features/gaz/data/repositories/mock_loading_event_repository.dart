import 'dart:math';
import '../../domain/entities/loading_event.dart';
import '../../domain/entities/loading_expense.dart';
import '../../domain/repositories/loading_event_repository.dart';

/// Implémentation mock du repository des événements de chargement.
class MockLoadingEventRepository implements LoadingEventRepository {
  final List<LoadingEvent> _events = [];
  final Random _random = Random();

  @override
  Future<List<LoadingEvent>> getLoadingEvents(
    String enterpriseId, {
    LoadingEventStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    return _events.where((e) {
      if (e.enterpriseId != enterpriseId) return false;
      if (status != null && e.status != status) return false;
      if (from != null && e.eventDate.isBefore(from)) return false;
      if (to != null && e.eventDate.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<LoadingEvent?> getLoadingEventById(String id) async {
    return _events.where((e) => e.id == id).firstOrNull;
  }

  @override
  Future<String> createLoadingEvent(LoadingEvent event) async {
    final id = event.id.isEmpty
        ? 'loading_event_${_random.nextInt(1000000)}'
        : event.id;
    final newEvent = event.copyWith(id: id);
    _events.add(newEvent);
    return id;
  }

  @override
  Future<void> updateLoadingEvent(LoadingEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
    }
  }

  @override
  Future<void> addExpenseToEvent(
    String eventId,
    LoadingExpense expense,
  ) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = _events[index];
      final updatedExpenses = [...event.expenses, expense];
      _events[index] = event.copyWith(expenses: updatedExpenses);
    }
  }

  @override
  Future<void> completeLoadingEvent(
    String eventId,
    Map<int, int> receivedCylinders,
  ) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(
        status: LoadingEventStatus.completed,
        fullCylindersReceived: receivedCylinders,
        completedDate: DateTime.now(),
      );
    }
  }

  @override
  Future<void> cancelLoadingEvent(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(
        status: LoadingEventStatus.cancelled,
      );
    }
  }

  @override
  Future<void> deleteLoadingEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
  }
}