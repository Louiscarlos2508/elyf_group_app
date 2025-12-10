import '../../domain/entities/treasury.dart';
import '../../domain/entities/treasury_movement.dart';
import '../../domain/repositories/treasury_repository.dart';

class MockTreasuryRepository implements TreasuryRepository {
  final Map<String, Treasury> _treasuries = {};

  MockTreasuryRepository() {
    // Initialiser avec des données de test
    _treasuries['eau_minerale'] = Treasury(
      id: 'treasury-eau',
      moduleId: 'eau_minerale',
      soldeCash: 500000,
      soldeOrangeMoney: 250000,
      mouvements: [
        TreasuryMovement(
          id: 'mov-1',
          type: TreasuryMovementType.entree,
          amount: 100000,
          method: PaymentMethod.cash,
          date: DateTime.now().subtract(const Duration(days: 1)),
          description: 'Vente sachets',
        ),
        TreasuryMovement(
          id: 'mov-2',
          type: TreasuryMovementType.transfert,
          amount: 50000,
          method: PaymentMethod.cash,
          date: DateTime.now().subtract(const Duration(hours: 12)),
          description: 'Transfert Cash → Orange Money',
        ),
      ],
      updatedAt: DateTime.now(),
    );

    _treasuries['boutique'] = Treasury(
      id: 'treasury-boutique',
      moduleId: 'boutique',
      soldeCash: 300000,
      soldeOrangeMoney: 150000,
      mouvements: [],
      updatedAt: DateTime.now(),
    );

    _treasuries['immobilier'] = Treasury(
      id: 'treasury-immobilier',
      moduleId: 'immobilier',
      soldeCash: 2000000,
      soldeOrangeMoney: 500000,
      mouvements: [],
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Treasury> fetchTreasury(String moduleId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _treasuries[moduleId] ??
        Treasury(
          id: 'treasury-$moduleId',
          moduleId: moduleId,
          soldeCash: 0,
          soldeOrangeMoney: 0,
          mouvements: [],
        );
  }

  @override
  Future<Treasury> updateTreasury(Treasury treasury) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _treasuries[treasury.moduleId] = treasury.copyWith(
      updatedAt: DateTime.now(),
    );
    return _treasuries[treasury.moduleId]!;
  }

  @override
  Future<Treasury> createTreasury(Treasury treasury) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _treasuries[treasury.moduleId] = treasury.copyWith(
      updatedAt: DateTime.now(),
    );
    return _treasuries[treasury.moduleId]!;
  }
}

