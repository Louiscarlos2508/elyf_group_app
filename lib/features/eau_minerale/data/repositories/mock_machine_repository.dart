import '../../domain/entities/machine.dart';
import '../../domain/repositories/machine_repository.dart';

class MockMachineRepository implements MachineRepository {
  final List<Machine> _machines = [
    Machine(
      id: 'machine-1',
      nom: 'Machine de remplissage A',
      reference: 'MACH-001',
      description: 'Machine principale de production',
      estActive: true,
      puissanceKw: 5.5,
      dateInstallation: DateTime.now().subtract(const Duration(days: 365)),
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    ),
    Machine(
      id: 'machine-2',
      nom: 'Machine de remplissage B',
      reference: 'MACH-002',
      description: 'Machine secondaire de production',
      estActive: true,
      puissanceKw: 5.5,
      dateInstallation: DateTime.now().subtract(const Duration(days: 200)),
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
    ),
    Machine(
      id: 'machine-3',
      nom: 'Machine de scellage',
      reference: 'MACH-003',
      description: 'Machine de scellage des sachets',
      estActive: true,
      puissanceKw: 2.0,
      dateInstallation: DateTime.now().subtract(const Duration(days: 150)),
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
    ),
  ];

  @override
  Future<List<Machine>> fetchMachines({bool? estActive}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var machines = List<Machine>.from(_machines);

    if (estActive != null) {
      machines = machines.where((m) => m.estActive == estActive).toList();
    }

    return machines..sort((a, b) => a.nom.compareTo(b.nom));
  }

  @override
  Future<Machine?> fetchMachineById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _machines.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Machine> createMachine(Machine machine) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newMachine = machine.copyWith(
      id: 'machine-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _machines.add(newMachine);
    return newMachine;
  }

  @override
  Future<Machine> updateMachine(Machine machine) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _machines.indexWhere((m) => m.id == machine.id);
    if (index == -1) {
      throw Exception('Machine non trouvée');
    }
    final updatedMachine = machine.copyWith(updatedAt: DateTime.now());
    _machines[index] = updatedMachine;
    return updatedMachine;
  }

  @override
  Future<void> deleteMachine(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _machines.removeWhere((m) => m.id == id);
  }
}

