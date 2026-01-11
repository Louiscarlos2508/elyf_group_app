import 'package:flutter_test/flutter_test.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/production_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/production_session_status.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/bobine_usage.dart';

void main() {
  group('ProductionService', () {
    late ProductionService service;

    setUp(() {
      service = ProductionService();
    });

    group('calculateStatus', () {
      test('should return completed when all conditions met', () {
        final result = service.calculateStatus(
          quantiteProduite: 1000,
          heureFin: DateTime(2024, 1, 1, 16),
          heureDebut: DateTime(2024, 1, 1, 8),
          machinesUtilisees: ['m1'],
          bobinesUtilisees: [
            BobineUsage(
              bobineType: 'type1',
              machineId: 'm1',
              machineName: 'Machine 1',
              dateInstallation: DateTime(2024, 1, 1, 8),
              heureInstallation: DateTime(2024, 1, 1, 8),
              estInstallee: true,
              estFinie: true,
            ),
          ],
        );

        expect(result, equals(ProductionSessionStatus.completed));
      });

      test('should return inProgress when machines or bobbins used', () {
        final result = service.calculateStatus(
          quantiteProduite: 0,
          heureFin: null,
          heureDebut: DateTime(2024, 1, 1, 8),
          machinesUtilisees: ['m1'],
          bobinesUtilisees: [
            BobineUsage(
              bobineType: 'type1',
              machineId: 'm1',
              machineName: 'Machine 1',
              dateInstallation: DateTime(2024, 1, 1, 8),
              heureInstallation: DateTime(2024, 1, 1, 8),
              estInstallee: true,
              estFinie: false,
            ),
          ],
        );

        expect(result, equals(ProductionSessionStatus.inProgress));
      });

      test('should return started when heureDebut is in past', () {
        final result = service.calculateStatus(
          quantiteProduite: 0,
          heureFin: null,
          heureDebut: DateTime(2024, 1, 1, 8),
          machinesUtilisees: [],
          bobinesUtilisees: [],
        );

        expect(result, equals(ProductionSessionStatus.started));
      });

      test('should return draft when no activity', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final result = service.calculateStatus(
          quantiteProduite: 0,
          heureFin: null,
          heureDebut: futureDate,
          machinesUtilisees: [],
          bobinesUtilisees: [],
        );

        expect(result, equals(ProductionSessionStatus.draft));
      });
    });

    group('toutesBobinesFinies', () {
      test('should return false for empty list', () {
        final result = service.toutesBobinesFinies([]);
        expect(result, isFalse);
      });

      test('should return true when all bobbins finished', () {
        final bobines = [
          BobineUsage(
            bobineType: 'type1',
            machineId: 'm1',
            machineName: 'Machine 1',
            dateInstallation: DateTime.now(),
            heureInstallation: DateTime.now(),
            estInstallee: true,
            estFinie: true,
          ),
          BobineUsage(
            bobineType: 'type2',
            machineId: 'm2',
            machineName: 'Machine 2',
            dateInstallation: DateTime.now(),
            heureInstallation: DateTime.now(),
            estInstallee: true,
            estFinie: true,
          ),
        ];

        final result = service.toutesBobinesFinies(bobines);
        expect(result, isTrue);
      });

      test('should return false when some bobbins not finished', () {
        final bobines = [
          BobineUsage(
            bobineType: 'type1',
            machineId: 'm1',
            machineName: 'Machine 1',
            dateInstallation: DateTime.now(),
            heureInstallation: DateTime.now(),
            estInstallee: true,
            estFinie: true,
          ),
          BobineUsage(
            bobineType: 'type2',
            machineId: 'm2',
            machineName: 'Machine 2',
            dateInstallation: DateTime.now(),
            heureInstallation: DateTime.now(),
            estInstallee: true,
            estFinie: false,
          ),
        ];

        final result = service.toutesBobinesFinies(bobines);
        expect(result, isFalse);
      });
    });

    group('peutEtreFinalisee', () {
      test('should return true when all conditions met', () {
        final result = service.peutEtreFinalisee(
          bobinesUtilisees: [
            BobineUsage(
              bobineType: 'type1',
              machineId: 'm1',
              machineName: 'Machine 1',
              dateInstallation: DateTime.now(),
              heureInstallation: DateTime.now(),
              estInstallee: true,
              estFinie: true,
            ),
          ],
          machinesUtilisees: ['m1'],
        );

        expect(result, isTrue);
      });

      test('should return false when bobbins not finished', () {
        final result = service.peutEtreFinalisee(
          bobinesUtilisees: [
            BobineUsage(
              bobineType: 'type1',
              machineId: 'm1',
              machineName: 'Machine 1',
              dateInstallation: DateTime.now(),
              heureInstallation: DateTime.now(),
              estInstallee: true,
              estFinie: false,
            ),
          ],
          machinesUtilisees: ['m1'],
        );

        expect(result, isFalse);
      });

      test('should return false when machine count mismatch', () {
        final result = service.peutEtreFinalisee(
          bobinesUtilisees: [
            BobineUsage(
              bobineType: 'type1',
              machineId: 'm1',
              machineName: 'Machine 1',
              dateInstallation: DateTime.now(),
              heureInstallation: DateTime.now(),
              estInstallee: true,
              estFinie: true,
            ),
          ],
          machinesUtilisees: ['m1', 'm2'],
        );

        expect(result, isFalse);
      });
    });
  });
}

