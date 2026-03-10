import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/production_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session_status.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/machine.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/machine_material_usage.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/stock_item.dart';

void main() {
  late ProductionService productionService;

  setUp(() {
    productionService = ProductionService();
  });

  group('ProductionService - calculateStatus', () {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 1));

    test('should return draft when everything is empty', () {
      final status = productionService.calculateStatus(
        quantiteProduite: 0,
        heureFin: null,
        heureDebut: now.add(const Duration(hours: 1)),
        machinesUtilisees: [],
        machineMaterials: [],
      );
      expect(status, ProductionSessionStatus.draft);
    });

    test('should return started when start time is in the past', () {
      final status = productionService.calculateStatus(
        quantiteProduite: 0,
        heureFin: null,
        heureDebut: start,
        machinesUtilisees: [],
        machineMaterials: [],
      );
      expect(status, ProductionSessionStatus.started);
    });

    test('should return inProgress when machines are used', () {
      final status = productionService.calculateStatus(
        quantiteProduite: 0,
        heureFin: null,
        heureDebut: start,
        machinesUtilisees: ['machine1'],
        machineMaterials: [],
      );
      expect(status, ProductionSessionStatus.inProgress);
    });

    test('should return completed when quantity > 0 and end time is set', () {
      final status = productionService.calculateStatus(
        quantiteProduite: 100,
        heureFin: now,
        heureDebut: start,
        machinesUtilisees: ['machine1'],
        machineMaterials: [],
      );
      expect(status, ProductionSessionStatus.completed);
    });
  });

  group('ProductionService - Finalization logic', () {
    test('toutesMatieresFinies returns false for empty list', () {
      expect(productionService.toutesMatieresFinies([]), isFalse);
    });

    test('toutesMatieresFinies returns true if all are finished', () {
      final materials = [
        MachineMaterialUsage(
          id: '1',
          materialType: 'T1',
          machineId: 'M1',
          machineName: 'Mach 1',
          dateInstallation: DateTime.now(),
          heureInstallation: DateTime.now(),
          estFinie: true,
        ),
      ];
      expect(productionService.toutesMatieresFinies(materials), isTrue);
    });

    test('peutEtreFinalisee returns true if conditions met', () {
      final materials = [
        MachineMaterialUsage(
          id: '1',
          materialType: 'T1',
          machineId: 'M1',
          machineName: 'Mach 1',
          dateInstallation: DateTime.now(),
          heureInstallation: DateTime.now(),
          estFinie: true,
        ),
      ];
      final machines = ['M1'];
      expect(
        productionService.peutEtreFinalisee(
          machineMaterials: materials,
          machinesUtilisees: machines,
        ),
        isTrue,
      );
    });
  });

  group('ProductionService - chargerMatieresNonFinies', () {
    const machine1 = Machine(id: 'M1', name: 'M1', enterpriseId: 'test', reference: 'REF1');
    final stock1 = StockItem(
      id: 'ST1',
      name: 'Test',
      type: StockType.rawMaterial,
      quantity: 10,
      unit: 'pcs',
      enterpriseId: 'test_enterprise',
      updatedAt: DateTime.now(),
    );

    test('should return empty lists when no machines selected', () async {
      final result = await productionService.chargerMatieresNonFinies(
        machinesSelectionnees: [],
        sessionsPrecedentes: [],
        machines: [machine1],
        materialStocksDisponibles: [stock1],
      );
      expect(result.machineMaterials, isEmpty);
      expect(result.machinesAvecMatiereNonFinie, isEmpty);
    });

    test('should install new material if no unfinished one found', () async {
      final result = await productionService.chargerMatieresNonFinies(
        machinesSelectionnees: ['M1'],
        sessionsPrecedentes: [],
        machines: [machine1],
        materialStocksDisponibles: [stock1],
      );
      expect(result.machineMaterials.length, 1);
      expect(result.machineMaterials.first.estInstallee, isTrue);
      expect(result.machinesAvecMatiereNonFinie, isEmpty);
    });

    test('should reuse unfinished material from previous session', () async {
      final now = DateTime.now();
      final previousMaterial = MachineMaterialUsage(
        id: '1',
        materialType: 'T-OLD',
        machineId: 'M1',
        machineName: 'M1',
        dateInstallation: now.subtract(const Duration(days: 1)),
        heureInstallation: now.subtract(const Duration(days: 1)),
        estFinie: false,
      );
      final previousSession = ProductionSession(
        id: 'S1',
        enterpriseId: 'test-enterprise',
        date: now.subtract(const Duration(days: 1)),
        period: 1,
        heureDebut: now.subtract(const Duration(days: 1)),
        consommationCourant: 0,
        machinesUtilisees: ['M1'],
        machineMaterials: [previousMaterial],
        quantiteProduite: 0,
        quantiteProduiteUnite: 'pack',
      );

      final result = await productionService.chargerMatieresNonFinies(
        machinesSelectionnees: ['M1'],
        sessionsPrecedentes: [previousSession],
        machines: [machine1],
        materialStocksDisponibles: [stock1],
      );

      expect(result.machineMaterials.length, 1);
      expect(result.machineMaterials.first.materialType, 'T-OLD');
      expect(result.machinesAvecMatiereNonFinie.containsKey('M1'), isTrue);
      expect(result.machinesAvecMatiereNonFinie['M1']!.materialType, 'T-OLD');
    });
  });
}
