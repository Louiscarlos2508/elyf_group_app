import 'package:rxdart/rxdart.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/contract.dart';
import '../../domain/repositories/contract_repository.dart';

class MockContractRepository implements ContractRepository {
  final _contracts = <String, Contract>{};
  final _subject = BehaviorSubject<List<Contract>>();

  MockContractRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    final contracts = [
      Contract(
        id: 'contract-1',
        propertyId: 'prop-2',
        tenantId: 'tenant-1',
        startDate: now.subtract(const Duration(days: 90)),
        endDate: now.add(const Duration(days: 275)),
        monthlyRent: 100000,
        deposit: 200000,
        status: ContractStatus.active,
        paymentDay: 5,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
    ];

    for (final contract in contracts) {
      _contracts[contract.id] = contract;
    }
    _subject.add(_contracts.values.toList());
  }

  @override
  Future<List<Contract>> getAllContracts() async {
    return _contracts.values.toList();
  }

  @override
  Future<Contract?> getContractById(String id) async {
    return _contracts[id];
  }

  @override
  Future<List<Contract>> getActiveContracts() async {
    return _contracts.values
        .where((c) => c.status == ContractStatus.active && c.isActive)
        .toList();
  }

  @override
  Future<List<Contract>> getContractsByProperty(String propertyId) async {
    return _contracts.values.where((c) => c.propertyId == propertyId).toList();
  }

  @override
  Future<List<Contract>> getContractsByTenant(String tenantId) async {
    return _contracts.values.where((c) => c.tenantId == tenantId).toList();
  }

  @override
  Stream<List<Contract>> watchContracts() => _subject.stream;

  @override
  Future<Contract> createContract(Contract contract) async {
    final now = DateTime.now();
    final newContract = Contract(
      id: contract.id,
      propertyId: contract.propertyId,
      tenantId: contract.tenantId,
      startDate: contract.startDate,
      endDate: contract.endDate,
      monthlyRent: contract.monthlyRent,
      deposit: contract.deposit,
      status: contract.status,
      property: contract.property,
      tenant: contract.tenant,
      paymentDay: contract.paymentDay,
      notes: contract.notes,
      createdAt: now,
      updatedAt: now,
    );
    _contracts[contract.id] = newContract;
    _subject.add(_contracts.values.toList());
    return newContract;
  }

  @override
  Future<Contract> updateContract(Contract contract) async {
    final existing = _contracts[contract.id];
    if (existing == null) {
      throw NotFoundException(
        'Contract not found',
        'CONTRACT_NOT_FOUND',
      );
    }
    final updated = Contract(
      id: contract.id,
      propertyId: contract.propertyId,
      tenantId: contract.tenantId,
      startDate: contract.startDate,
      endDate: contract.endDate,
      monthlyRent: contract.monthlyRent,
      deposit: contract.deposit,
      status: contract.status,
      property: contract.property,
      tenant: contract.tenant,
      paymentDay: contract.paymentDay,
      notes: contract.notes,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _contracts[contract.id] = updated;
    _subject.add(_contracts.values.toList());
    return updated;
  }

  @override
  Future<void> deleteContract(String id) async {
    _contracts.remove(id);
    _subject.add(_contracts.values.toList());
  }
}
