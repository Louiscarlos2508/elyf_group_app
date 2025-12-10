import '../../domain/entities/treasury.dart';
import '../../domain/entities/treasury_movement.dart';
import '../../domain/repositories/treasury_repository.dart';

/// Controller pour gérer la trésorerie.
class TreasuryController {
  TreasuryController(this._repository);

  final TreasuryRepository _repository;

  Future<Treasury> fetchTreasury(String moduleId) async {
    return _repository.fetchTreasury(moduleId);
  }

  Future<Treasury> addMovement({
    required String moduleId,
    required TreasuryMovement movement,
  }) async {
    final treasury = await _repository.fetchTreasury(moduleId);
    final newMovements = List<TreasuryMovement>.from(treasury.mouvements)
      ..add(movement);

    int newSoldeCash = treasury.soldeCash;
    int newSoldeOrangeMoney = treasury.soldeOrangeMoney;

    // Appliquer le mouvement selon son type
    switch (movement.type) {
      case TreasuryMovementType.entree:
        if (movement.method == PaymentMethod.cash) {
          newSoldeCash += movement.amount;
        } else {
          newSoldeOrangeMoney += movement.amount;
        }
        break;
      case TreasuryMovementType.sortie:
        if (movement.method == PaymentMethod.cash) {
          newSoldeCash -= movement.amount;
        } else {
          newSoldeOrangeMoney -= movement.amount;
        }
        break;
      case TreasuryMovementType.transfert:
        // Transfert : retirer d'une méthode, ajouter à l'autre
        if (movement.method == PaymentMethod.cash) {
          // Transfert de Cash vers Orange Money
          newSoldeCash -= movement.amount;
          newSoldeOrangeMoney += movement.amount;
        } else {
          // Transfert d'Orange Money vers Cash
          newSoldeOrangeMoney -= movement.amount;
          newSoldeCash += movement.amount;
        }
        break;
    }

    final updatedTreasury = treasury.copyWith(
      soldeCash: newSoldeCash,
      soldeOrangeMoney: newSoldeOrangeMoney,
      mouvements: newMovements,
    );

    return _repository.updateTreasury(updatedTreasury);
  }

  Future<Treasury> transfer({
    required String moduleId,
    required int amount,
    required PaymentMethod fromMethod,
    required PaymentMethod toMethod,
    required String description,
  }) async {
    if (fromMethod == toMethod) {
      throw Exception('Les méthodes de paiement doivent être différentes');
    }

    final movement = TreasuryMovement(
      id: 'transfer-${DateTime.now().millisecondsSinceEpoch}',
      type: TreasuryMovementType.transfert,
      amount: amount,
      method: fromMethod, // Méthode source
      date: DateTime.now(),
      description: description,
      createdAt: DateTime.now(),
    );

    return addMovement(moduleId: moduleId, movement: movement);
  }
}

