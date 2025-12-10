import '../../domain/entities/bobine.dart';
import '../../domain/repositories/bobine_repository.dart';

class MockBobineRepository implements BobineRepository {
  final List<Bobine> _bobines = [
    Bobine(
      id: 'bobine-1',
      reference: 'BOB-001',
      poidsActuel: 45.5,
      poidsInitial: 50.0,
      dateReception: DateTime.now().subtract(const Duration(days: 10)),
      fournisseur: 'Fournisseur A',
      prixUnitaire: 2500,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Bobine(
      id: 'bobine-2',
      reference: 'BOB-002',
      poidsActuel: 48.0,
      poidsInitial: 50.0,
      dateReception: DateTime.now().subtract(const Duration(days: 5)),
      fournisseur: 'Fournisseur A',
      prixUnitaire: 2500,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Bobine(
      id: 'bobine-3',
      reference: 'BOB-003',
      poidsActuel: 50.0,
      poidsInitial: 50.0,
      dateReception: DateTime.now().subtract(const Duration(days: 2)),
      fournisseur: 'Fournisseur B',
      prixUnitaire: 2600,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Future<List<Bobine>> fetchBobines({bool? estDisponible}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var bobines = List<Bobine>.from(_bobines);

    if (estDisponible != null) {
      bobines = bobines.where((b) => b.estDisponible == estDisponible).toList();
    }

    return bobines..sort((a, b) => b.dateReception.compareTo(a.dateReception));
  }

  @override
  Future<Bobine?> fetchBobineById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _bobines.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Bobine?> fetchBobineByReference(String reference) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _bobines.firstWhere((b) => b.reference == reference);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Bobine> createBobine(Bobine bobine) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newBobine = bobine.copyWith(
      id: 'bobine-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _bobines.add(newBobine);
    return newBobine;
  }

  @override
  Future<Bobine> updateBobine(Bobine bobine) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _bobines.indexWhere((b) => b.id == bobine.id);
    if (index == -1) {
      throw Exception('Bobine non trouvée');
    }
    final updatedBobine = bobine.copyWith(updatedAt: DateTime.now());
    _bobines[index] = updatedBobine;
    return updatedBobine;
  }

  @override
  Future<void> deleteBobine(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _bobines.removeWhere((b) => b.id == id);
  }
}

