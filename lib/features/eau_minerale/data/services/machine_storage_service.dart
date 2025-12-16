import '../../domain/entities/machine.dart';

/// Service de stockage local pour les machines.
/// 
/// Pour l'instant, utilise un stockage en mémoire.
/// Peut être facilement migré vers Isar/Firestore plus tard.
class MachineStorageService {
  MachineStorageService._();
  
  static final MachineStorageService instance = MachineStorageService._();
  
  final List<Machine> _machines = [];
  bool _initialized = false;
  
  /// Initialise le service avec des machines par défaut si vide.
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Si aucune machine n'est stockée, initialiser avec des machines par défaut
    if (_machines.isEmpty) {
      _machines.addAll(_getDefaultMachines());
    }
    
    _initialized = true;
  }
  
  /// Récupère toutes les machines.
  Future<List<Machine>> getAllMachines() async {
    await initialize();
    return List<Machine>.from(_machines);
  }
  
  /// Récupère une machine par son ID.
  Future<Machine?> getMachineById(String id) async {
    await initialize();
    try {
      return _machines.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Ajoute une nouvelle machine.
  Future<Machine> addMachine(Machine machine) async {
    await initialize();
    final newMachine = machine.copyWith(
      id: machine.id.isEmpty 
          ? 'machine-${DateTime.now().millisecondsSinceEpoch}'
          : machine.id,
      createdAt: machine.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _machines.add(newMachine);
    return newMachine;
  }
  
  /// Met à jour une machine existante.
  Future<Machine> updateMachine(Machine machine) async {
    await initialize();
    final index = _machines.indexWhere((m) => m.id == machine.id);
    if (index == -1) {
      throw Exception('Machine non trouvée');
    }
    final updatedMachine = machine.copyWith(updatedAt: DateTime.now());
    _machines[index] = updatedMachine;
    return updatedMachine;
  }
  
  /// Supprime une machine.
  Future<void> deleteMachine(String id) async {
    await initialize();
    _machines.removeWhere((m) => m.id == id);
  }
  
  /// Machines par défaut (utilisées uniquement lors de la première initialisation).
  List<Machine> _getDefaultMachines() {
    return [
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
  }
}
