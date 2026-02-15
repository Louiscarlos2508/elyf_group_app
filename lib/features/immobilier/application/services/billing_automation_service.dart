import '../../domain/entities/contract.dart';
import '../../domain/entities/immobilier_settings.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/contract_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/immobilier_settings_repository.dart';
import '../../../audit_trail/domain/services/audit_trail_service.dart';
import '../../../../shared/domain/entities/payment_method.dart';
import '../../../../core/logging/app_logger.dart';

/// Service responsible for automated billing tasks in the Immobilier module.
class BillingAutomationService {
  BillingAutomationService(
    this._contractRepository,
    this._paymentRepository,
    this._settingsRepository,
    this._auditTrailService,
    this._enterpriseId,
    this._userId,
  );

  final ContractRepository _contractRepository;
  final PaymentRepository _paymentRepository;
  final ImmobilierSettingsRepository _settingsRepository;
  final AuditTrailService _auditTrailService;
  final String _enterpriseId;
  final String _userId;
 
  static const String _logName = 'BillingAutomationService';
  DateTime? _lastRun;

  /// Runs all automation tasks.
  Future<void> runAutomation() async {
    // Throttle: don't run more than once every 5 minutes
    if (_lastRun != null && 
        DateTime.now().difference(_lastRun!) < const Duration(minutes: 5)) {
      return;
    }
    
    AppLogger.info('Starting billing automation for enterprise: $_enterpriseId', name: _logName);
    
    _lastRun = DateTime.now();
    
    final settings = await _settingsRepository.getSettings(_enterpriseId) ?? 
                    ImmobilierSettings(enterpriseId: _enterpriseId);

    if (!settings.autoBillingEnabled) {
      AppLogger.info('Auto-billing is disabled for this enterprise.', name: _logName);
      return;
    }

    await processMonthlyBilling();
    await checkOverduePayments(settings.overdueGracePeriod);
    await applyLateFees(settings);
    
    AppLogger.info('Billing automation completed.', name: _logName);
  }

  /// Calculates and applies late fees to overdue payments.
  Future<void> applyLateFees(ImmobilierSettings settings) async {
    if (settings.penaltyRate <= 0) return;

    try {
      final now = DateTime.now();
      final payments = await _paymentRepository.getAllPayments();
      final overduePayments = payments.where((p) => p.status == PaymentStatus.overdue).toList();
      
      if (overduePayments.isEmpty) return;

      int updatedCount = 0;
      for (final payment in overduePayments) {
        int penaltyAmount = 0;

        if (settings.penaltyType == 'fixed') {
          // Fixed penalty applied once
          if (payment.penaltyAmount == 0) {
            penaltyAmount = (payment.amount * (settings.penaltyRate / 100)).round();
          }
        } else if (settings.penaltyType == 'daily') {
          // Daily penalty based on days overdue since last update
          final lastUpdate = payment.updatedAt ?? payment.paymentDate;
          final daysOverdue = now.difference(lastUpdate).inDays;
          
          if (daysOverdue > 0) {
            penaltyAmount = (payment.amount * (settings.penaltyRate / 100) * daysOverdue).round();
          }
        }

        if (penaltyAmount > 0) {
          final updatedPayment = payment.copyWith(
            penaltyAmount: payment.penaltyAmount + penaltyAmount,
            // We increase the total amount due as well? 
            // In many systems, amount is base rent, and penalty is separate but added to "total due"
            // Let's assume 'amount' is total due including existing penalties.
            amount: payment.amount + penaltyAmount,
            updatedAt: now,
          );
          
          await _paymentRepository.updatePayment(updatedPayment);
          updatedCount++;
          
          await _auditTrailService.logAction(
            enterpriseId: _enterpriseId,
            userId: _userId,
            module: 'immobilier',
            action: 'auto_late_fee_apply',
            entityId: payment.id,
            entityType: 'payment',
            metadata: {
              'paymentId': payment.id,
              'penaltyAmount': penaltyAmount,
              'newTotal': updatedPayment.amount,
            },
          );
        }
      }
      
      if (updatedCount > 0) {
        AppLogger.info('Applied late fees to $updatedCount overdue payments.', name: _logName);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error during late fee application', name: _logName, error: e, stackTrace: stackTrace);
    }
  }
  /// Ensures a pending payment exists for every active contract for the current month.
  Future<void> processMonthlyBilling() async {
    try {
      final now = DateTime.now();
      final contracts = await _contractRepository.getAllContracts();
      final activeContracts = contracts.where((c) => c.status == ContractStatus.active).toList();
      
      final payments = await _paymentRepository.getAllPayments();
      
      int createdCount = 0;
      for (final contract in activeContracts) {
        // Check if there is already a payment record for this month/year
        final hasPayment = payments.any((p) => 
          p.contractId == contract.id && 
          p.month == now.month && 
          p.year == now.year &&
          p.status != PaymentStatus.cancelled
        );

        if (!hasPayment) {
          final newPayment = Payment(
            id: '', // Repository will generate ID
            enterpriseId: _enterpriseId,
            contractId: contract.id,
            amount: contract.monthlyRent,
            paidAmount: 0,
            paymentDate: DateTime(now.year, now.month, 1),
            status: PaymentStatus.pending,
            month: now.month,
            year: now.year,
            paymentMethod: PaymentMethod.cash, // Default placeholder
            createdAt: now,
            updatedAt: now,
          );

          await _paymentRepository.createPayment(newPayment);
          createdCount++;
          
          await _auditTrailService.logAction(
            enterpriseId: _enterpriseId,
            userId: _userId,
            module: 'immobilier',
            action: 'auto_billing_create',
            entityId: contract.id,
            entityType: 'payment',
            metadata: {'contractId': contract.id, 'month': now.month, 'year': now.year},
          );
        }
      }
      
      if (createdCount > 0) {
        AppLogger.info('Created $createdCount pending payments for this month.', name: _logName);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error during monthly billing process', name: _logName, error: e, stackTrace: stackTrace);
    }
  }

  /// Updates "pending" payments to "overdue" if they pass the grace period.
  Future<void> checkOverduePayments(int gracePeriodDays) async {
    try {
      final now = DateTime.now();
      final payments = await _paymentRepository.getAllPayments();
      final pendingPayments = payments.where((p) => p.status == PaymentStatus.pending).toList();
      
      if (pendingPayments.isEmpty) return;

      final contracts = await _contractRepository.getAllContracts();
      final contractMap = {for (var c in contracts) c.id: c};
      
      int updatedCount = 0;
      for (final payment in pendingPayments) {
        final contract = contractMap[payment.contractId];
        if (contract == null) continue;

        // Base due day is the contract's payment day (default to 1st)
        final baseDueDay = contract.paymentDay ?? 1;
        
        // Calculate the actual due date (Day + Grace Period)
        // Note: If day + grace > days in month, DateTime correctly rolls over to next month
        final dueDate = DateTime(
          payment.year ?? now.year, 
          payment.month ?? now.month, 
          baseDueDay + gracePeriodDays,
        );
        
        if (now.isAfter(dueDate)) {
          final updatedPayment = payment.copyWith(
            status: PaymentStatus.overdue,
            updatedAt: now,
          );
          
          await _paymentRepository.updatePayment(updatedPayment);
          updatedCount++;
          
          await _auditTrailService.logAction(
            enterpriseId: _enterpriseId,
            userId: _userId,
            module: 'immobilier',
            action: 'auto_overdue_update',
            entityId: payment.id,
            entityType: 'payment',
            metadata: {
              'paymentId': payment.id, 
              'contractId': contract.id,
              'paymentDay': baseDueDay,
              'gracePeriod': gracePeriodDays,
            },
          );
        }
      }
      
      if (updatedCount > 0) {
        AppLogger.info('Updated $updatedCount payments to OVERDUE based on contract payment days.', name: _logName);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error during overdue check process', name: _logName, error: e, stackTrace: stackTrace);
    }
  }
}
