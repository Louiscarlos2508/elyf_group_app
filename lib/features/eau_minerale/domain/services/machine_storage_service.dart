import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/machine.dart';

/// Service de stockage pour les machines.
///
/// Utilise un stockage en mémoire pour le moment.
/// Note: Drift est utilisé exclusivement pour le stockage offline (pas ObjectBox).
class MachineStorageService {
  MachineStorageService._();

  static final MachineStorageService instance = MachineStorageService._();

  final Map<String, Machine> _machines = {};

  /// Récupère toutes les machines.
  Future<List<Machine>> getAllMachines() async {
    return _machines.values.toList();
  }

  /// Récupère une machine par son ID.
  Future<Machine?> getMachineById(String id) async {
    return _machines[id];
  }

  /// Ajoute une nouvelle machine.
  Future<Machine> addMachine(Machine machine) async {
    final newMachine = machine.copyWith(
      id: machine.id.isEmpty ? IdGenerator.generate() : machine.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _machines[newMachine.id] = newMachine;
    return newMachine;
  }

  /// Met à jour une machine existante.
  Future<Machine> updateMachine(Machine machine) async {
    final updatedMachine = machine.copyWith(updatedAt: DateTime.now());
    _machines[machine.id] = updatedMachine;
    return updatedMachine;
  }

  /// Supprime une machine.
  Future<void> deleteMachine(String id) async {
    _machines.remove(id);
  }

  /// Efface toutes les machines (pour les tests).
  Future<void> clear() async {
    _machines.clear();
  }
}
