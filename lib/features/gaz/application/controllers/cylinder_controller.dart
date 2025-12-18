import '../../domain/entities/cylinder.dart';
import '../../domain/repositories/gas_repository.dart';

/// Contrôleur pour la gestion des bouteilles de gaz.
class CylinderController {
  CylinderController(this._repository);

  final GasRepository _repository;

  /// Récupère toutes les bouteilles.
  Future<List<Cylinder>> getCylinders() async {
    return _repository.getCylinders();
  }

  /// Récupère une bouteille par son ID.
  Future<Cylinder?> getCylinderById(String id) async {
    return _repository.getCylinderById(id);
  }

  /// Ajoute une nouvelle bouteille.
  Future<void> addCylinder(Cylinder cylinder) async {
    await _repository.addCylinder(cylinder);
  }

  /// Met à jour une bouteille existante.
  Future<void> updateCylinder(Cylinder cylinder) async {
    await _repository.updateCylinder(cylinder);
  }

  /// Supprime une bouteille.
  Future<void> deleteCylinder(String id) async {
    await _repository.deleteCylinder(id);
  }

  /// Met à jour le stock d'une bouteille.
  Future<void> updateStock(String cylinderId, int newStock) async {
    final cylinder = await _repository.getCylinderById(cylinderId);
    if (cylinder != null) {
      await _repository.updateCylinder(
        cylinder.copyWith(stock: newStock),
      );
    }
  }

  /// Ajuste le stock d'une bouteille (ajoute ou retire).
  Future<void> adjustStock(String cylinderId, int adjustment) async {
    final cylinder = await _repository.getCylinderById(cylinderId);
    if (cylinder != null) {
      final newStock = cylinder.stock + adjustment;
      await _repository.updateCylinder(
        cylinder.copyWith(stock: newStock >= 0 ? newStock : 0),
      );
    }
  }
}
