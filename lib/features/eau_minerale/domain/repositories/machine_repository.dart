import '../entities/machine.dart';

/// Repository pour gérer les machines.
abstract class MachineRepository {
  /// Récupère toutes les machines.
  Future<List<Machine>> fetchMachines({bool? estActive});

  /// Récupère une machine par son ID.
  Future<Machine?> fetchMachineById(String id);

  /// Crée une nouvelle machine.
  Future<Machine> createMachine(Machine machine);

  /// Met à jour une machine.
  Future<Machine> updateMachine(Machine machine);

  /// Supprime une machine.
  Future<void> deleteMachine(String id);
}
