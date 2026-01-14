import '../../domain/entities/machine.dart';
import '../../domain/repositories/machine_repository.dart';
import '../../domain/services/machine_storage_service.dart';

/// Repository mock pour les machines.
/// Utilise MachineStorageService pour le stockage persistant.
class MockMachineRepository implements MachineRepository {
  final MachineStorageService _storage = MachineStorageService.instance;

  @override
  Future<List<Machine>> fetchMachines({bool? estActive}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var machines = await _storage.getAllMachines();

    if (estActive != null) {
      machines = machines.where((m) => m.estActive == estActive).toList();
    }

    return machines..sort((a, b) => a.nom.compareTo(b.nom));
  }

  @override
  Future<Machine?> fetchMachineById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return await _storage.getMachineById(id);
  }

  @override
  Future<Machine> createMachine(Machine machine) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return await _storage.addMachine(machine);
  }

  @override
  Future<Machine> updateMachine(Machine machine) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return await _storage.updateMachine(machine);
  }

  @override
  Future<void> deleteMachine(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _storage.deleteMachine(id);
  }
}
