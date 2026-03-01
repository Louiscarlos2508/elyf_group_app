import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/production_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session_status.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/machine.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/bobine_usage.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/bobine_stock.dart';

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
        bobinesUtilisees: [],
      );
      expect(status, ProductionSessionStatus.draft);
    });

    test('should return started when start time is in the past', () {
      final status = productionService.calculateStatus(
        quantiteProduite: 0,
        heureFin: null,
        heureDebut: start,
        machinesUtilisees: [],
        bobinesUtilisees: [],
      );
      expect(status, ProductionSessionStatus.started);
    });

    test('should return inProgress when machines are used', () {
      final status = productionService.calculateStatus(
        quantiteProduite: 0,
        heureFin: null,
        heureDebut: start,
        machinesUtilisees: ['machine1'],
        bobinesUtilisees: [],
      );
      expect(status, ProductionSessionStatus.inProgress);
    });

    test('should return completed when quantity > 0 and end time is set', () {
      final status = productionService.calculateStatus(
        quantiteProduite: 100,
        heureFin: now,
        heureDebut: start,
        machinesUtilisees: ['machine1'],
        bobinesUtilisees: [],
      );
      expect(status, ProductionSessionStatus.completed);
    });
  });

  group('ProductionService - Finalization logic', () {
    test('toutesBobinesFinies returns false for empty list', () {
      expect(productionService.toutesBobinesFinies([]), isFalse);
    });

    test('toutesBobinesFinies returns true if all are finished', () {
      final bobines = [
        BobineUsage(
          bobineType: 'T1',
          machineId: 'M1',
          machineName: 'Mach 1',
          dateInstallation: DateTime.now(),
          heureInstallation: DateTime.now(),
          estFinie: true,
        ),
      ];
      expect(productionService.toutesBobinesFinies(bobines), isTrue);
    });

    test('peutEtreFinalisee returns true if conditions met', () {
      final bobines = [
        BobineUsage(
          bobineType: 'T1',
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
          bobinesUtilisees: bobines,
          machinesUtilisees: machines,
        ),
        isTrue,
      );
    });
  });

  group('ProductionService - chargerBobinesNonFinies', () {
    final machine1 = Machine(id: 'M1', name: 'M1', enterpriseId: 'test', reference: 'REF1');
    final stock1 = BobineStock(
      id: 'ST1',
      enterpriseId: 'test',
      type: 'T1',
      quantity: 10,
      unit: 'pcs',
      seuilAlerte: 2,
    );

    test('should return empty lists when no machines selected', () async {
      final result = await productionService.chargerBobinesNonFinies(
        machinesSelectionnees: [],
        sessionsPrecedentes: [],
        machines: [machine1],
        bobineStocksDisponibles: [stock1],
      );
      expect(result.bobinesUtilisees, isEmpty);
      expect(result.machinesAvecBobineNonFinie, isEmpty);
    });

    test('should install new bobine if no unfinished one found', () async {
      final result = await productionService.chargerBobinesNonFinies(
        machinesSelectionnees: ['M1'],
        sessionsPrecedentes: [],
        machines: [machine1],
        bobineStocksDisponibles: [stock1],
      );
      expect(result.bobinesUtilisees.length, 1);
      expect(result.bobinesUtilisees.first.bobineType, 'T1');
      expect(result.bobinesUtilisees.first.estInstallee, isTrue);
      expect(result.machinesAvecBobineNonFinie, isEmpty);
    });

    test('should reuse unfinished bobine from previous session', () async {
      final now = DateTime.now();
      final previousBobine = BobineUsage(
        bobineType: 'T-OLD',
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
        bobinesUtilisees: [previousBobine],
        quantiteProduite: 0,
        quantiteProduiteUnite: 'pack',
      );

      final result = await productionService.chargerBobinesNonFinies(
        machinesSelectionnees: ['M1'],
        sessionsPrecedentes: [previousSession],
        machines: [machine1],
        bobineStocksDisponibles: [stock1],
      );

      expect(result.bobinesUtilisees.length, 1);
      expect(result.bobinesUtilisees.first.bobineType, 'T-OLD');
      expect(result.machinesAvecBobineNonFinie.containsKey('M1'), isTrue);
      expect(result.machinesAvecBobineNonFinie['M1']!.bobineType, 'T-OLD');
    });
  });
}
