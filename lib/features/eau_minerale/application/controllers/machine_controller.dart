import '../../domain/entities/machine.dart';
import '../../domain/repositories/machine_repository.dart';

/// Controller pour gérer les machines.
class MachineController {
  MachineController(this._repository);

  final MachineRepository _repository;

  /// Récupère toutes les machines, optionnellement filtrées par statut actif.
  Future<List<Machine>> fetchMachines({bool? estActive}) async {
    return await _repository.fetchMachines(estActive: estActive);
  }

  /// Récupère une machine par son ID.
  Future<Machine?> fetchMachineById(String id) async {
    return await _repository.fetchMachineById(id);
  }

  /// Crée une nouvelle machine.
  Future<Machine> createMachine(Machine machine) async {
    return await _repository.createMachine(machine);
  }

  /// Met à jour une machine existante.
  Future<Machine> updateMachine(Machine machine) async {
    return await _repository.updateMachine(machine);
  }

  /// Supprime une machine.
  Future<void> deleteMachine(String id) async {
    return await _repository.deleteMachine(id);
  }
}
