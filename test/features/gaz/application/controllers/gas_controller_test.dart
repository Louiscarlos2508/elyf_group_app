import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:elyf_groupe_app/features/gaz/application/controllers/gas_controller.dart';
import 'package:elyf_groupe_app/features/gaz/domain/repositories/gas_repository.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gas_sale.dart';
import 'package:elyf_groupe_app/core/errors/app_exceptions.dart';

import 'package:elyf_groupe_app/features/audit_trail/domain/services/audit_trail_service.dart';

class MockGasRepository extends Mock implements GasRepository {
  @override
  Future<List<Cylinder>> getCylinders() => super.noSuchMethod(
        Invocation.method(#getCylinders, []),
        returnValue: Future.value(<Cylinder>[]),
      );

  @override
  Stream<List<Cylinder>> watchCylinders() => super.noSuchMethod(
        Invocation.method(#watchCylinders, []),
        returnValue: const Stream<List<Cylinder>>.empty(),
      );

  @override
  Future<Cylinder?> getCylinderById(String? id) => super.noSuchMethod(
        Invocation.method(#getCylinderById, [id]),
        returnValue: Future.value(null),
      );

  @override
  Future<void> addSale(GasSale? sale) => super.noSuchMethod(
        Invocation.method(#addSale, [sale]),
        returnValue: Future.value(),
      );

  @override
  Future<List<GasSale>> getSales({DateTime? from, DateTime? to, List<String>? enterpriseIds}) =>
      super.noSuchMethod(
        Invocation.method(#getSales, [], {#from: from, #to: to, #enterpriseIds: enterpriseIds}),
        returnValue: Future.value(<GasSale>[]),
      );

  @override
  Stream<List<GasSale>> watchSales({DateTime? from, DateTime? to, List<String>? enterpriseIds}) =>
      super.noSuchMethod(
        Invocation.method(#watchSales, [], {#from: from, #to: to, #enterpriseIds: enterpriseIds}),
        returnValue: const Stream<List<GasSale>>.empty(),
      );
}

class MockAuditTrailService extends Mock implements AuditTrailService {
  @override
  Future<String> logAction({
    required String enterpriseId,
    required String userId,
    required String module,
    required String action,
    required String entityId,
    required String entityType,
    Map<String, dynamic>? metadata,
  }) =>
      super.noSuchMethod(
        Invocation.method(#logAction, [], {
          #enterpriseId: enterpriseId,
          #userId: userId,
          #module: module,
          #action: action,
          #entityId: entityId,
          #entityType: entityType,
          #metadata: metadata,
        }),
        returnValue: Future.value('test-log-id'),
      );
}

void main() {
  late GasController controller;
  late MockGasRepository mockRepo;
  late MockAuditTrailService mockAudit;

  setUp(() {
    mockRepo = MockGasRepository();
    mockAudit = MockAuditTrailService();
    controller = GasController(mockRepo, mockAudit);
  });

  group('GasController - addSale with stock validation', () {
    test('throws ArgumentError if cylinder is not found', () async {
      when(mockRepo.getCylinderById('c1')).thenAnswer((_) async => null);

      final sale = GasSale(
        id: 's1',
        enterpriseId: 'test-enterprise',
        cylinderId: 'c1',
        quantity: 1,
        unitPrice: 2000,
        totalAmount: 2000,
        saleDate: DateTime.now(),
        saleType: SaleType.retail,
      );

      expect(() => controller.addSale(sale), throwsA(isA<BusinessException>()));
    });

    test('throws BusinessException if stock is insufficient', () async {
      final cylinder = Cylinder(
        id: 'c1',
        weight: 12,
        buyPrice: 1500,
        sellPrice: 2000,
        enterpriseId: 'e1',
        moduleId: 'm1',
        stock: 5, // Only 5 in stock
      );

      when(mockRepo.getCylinderById('c1')).thenAnswer((_) async => cylinder);

      final sale = GasSale(
        id: 's1',
        enterpriseId: 'test-enterprise',
        cylinderId: 'c1',
        quantity: 10, // Requesting 10
        unitPrice: 2000,
        totalAmount: 20000,
        saleDate: DateTime.now(),
        saleType: SaleType.retail,
      );

      expect(
        () => controller.addSale(sale),
        throwsA(isA<BusinessException>().having(
            (e) => e.message, 'message', contains('Stock insuffisant'))),
      );
    });

    test('allows sale and calls repository if stock is sufficient', () async {
      final cylinder = Cylinder(
        id: 'c1',
        weight: 12,
        buyPrice: 1500,
        sellPrice: 2000,
        enterpriseId: 'e1',
        moduleId: 'm1',
        stock: 20,
      );

      when(mockRepo.getCylinderById('c1')).thenAnswer((_) async => cylinder);
      when(mockRepo.addSale(any)).thenAnswer((_) async => {});
      when(mockRepo.getSales(from: anyNamed('from'), to: anyNamed('to')))
          .thenAnswer((_) async => []);

      final sale = GasSale(
        id: 's1',
        enterpriseId: 'test-enterprise',
        cylinderId: 'c1',
        quantity: 5,
        unitPrice: 2000,
        totalAmount: 10000,
        saleDate: DateTime.now(),
        saleType: SaleType.retail,
      );

      await controller.addSale(sale);

      verify(mockRepo.addSale(sale)).called(1);
    });
  });
}
