
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:open_file/open_file.dart';
import '../../domain/entities/closing.dart';
import '../../application/providers.dart';
import '../../../../core/pdf/boutique_report_pdf_service.dart';
import 'package:elyf_groupe_app/app/theme/app_colors.dart';

class DailyClosingDialog extends ConsumerStatefulWidget {
  const DailyClosingDialog({super.key});

  @override
  ConsumerState<DailyClosingDialog> createState() => _DailyClosingDialogState();
}

class _DailyClosingDialogState extends ConsumerState<DailyClosingDialog> {
  int _currentStep = 0;
  final _cashController = TextEditingController();
  final _mmController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;
  bool _isSuccess = false;
  Closing? _closedClosing;

  @override
  void dispose() {
    _cashController.dispose();
    _mmController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleClosing({
    required Closing activeSession,
    required int totalRevenue,
    required int cashRevenue,
    required int mmRevenue,
    required int cardRevenue,
    required int totalExpenses,
  }) async {
    final physicalCash = int.tryParse(_cashController.text) ?? 0;
    final physicalMM = int.tryParse(_mmController.text) ?? 0;
    
    // Theoretical net (revenue - expenses)
    final digitalNet = totalRevenue - totalExpenses;
    
    // Cash Reconciliation
    final expectedCash = activeSession.openingCashAmount + (cashRevenue - totalExpenses);
    final cashDiscrepancy = physicalCash - expectedCash;
    
    // MM Reconciliation
    final expectedMM = activeSession.openingMobileMoneyAmount + mmRevenue;
    final mmDiscrepancy = physicalMM - expectedMM;

    final totalDiscrepancy = cashDiscrepancy + mmDiscrepancy;

    setState(() => _isSaving = true);

    try {
      final closing = activeSession.copyWith(
        date: DateTime.now(),
        digitalRevenue: totalRevenue,
        digitalExpenses: totalExpenses,
        digitalNet: digitalNet,
        physicalCashAmount: physicalCash,
        physicalMobileMoneyAmount: physicalMM,
        discrepancy: totalDiscrepancy,
        digitalCashRevenue: cashRevenue,
        digitalMobileMoneyRevenue: mmRevenue,
        digitalCardRevenue: cardRevenue,
        mobileMoneyDiscrepancy: mmDiscrepancy,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await ref.read(storeControllerProvider).performClosing(closing);
      
      if (mounted) {
        setState(() {
          _isSuccess = true;
          _closedClosing = closing;
        });
        NotificationService.showSuccess(context, 'Clôture et réconciliation effectuées.');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de la clôture: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(recentSalesProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final activeSessionAsync = ref.watch(activeSessionProvider);

    return activeSessionAsync.when(
      data: (activeSession) {
        if (activeSession == null) {
          return const Center(child: Text('Aucune caisse ouverte.'));
        }

        return salesAsync.when(
          data: (sales) => expensesAsync.when(
            data: (expenses) {
              final calculationService = ref.read(boutiqueCalculationServiceProvider);
              final metrics = calculationService.calculateTodayMetrics(sales);
              
              // Only expenses since opening
              final sessionExpenses = expenses.where((e) {
                return e.date.isAfter(activeSession.openingDate!);
              }).fold(0, (sum, e) => sum + e.amountCfa);

              final digitalNet = metrics.revenue - sessionExpenses;

              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(activeSession),
                      const Divider(height: 32),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      if (_isSuccess)
                        _buildSuccess(_closedClosing!)
                      else ...[
                        if (_currentStep == 0) _buildSummaryStep(activeSession, metrics, sessionExpenses),
                        if (_currentStep == 1) _buildCashInputStep((activeSession.openingCashAmount + (metrics.cashRevenue - sessionExpenses)).toInt()),
                        if (_currentStep == 2) _buildMMInputStep((activeSession.openingMobileMoneyAmount + metrics.mobileMoneyRevenue).toInt()),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (!_isSuccess) _buildActions(activeSession, metrics, sessionExpenses),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e'),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erreur: $e'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erreur Session: $e'),
    );
  }

  Widget _buildHeader(Closing activeSession) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.account_balance_wallet, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clôture & Réconciliation',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${activeSession.number ?? "Session"} • Espèces + Mobile Money',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildActions(Closing activeSession, dynamic metrics, int todayExpenses) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: () => setState(() => _currentStep--),
            child: const Text('Retour'),
          ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isSaving
              ? null
              : () {
                  if (_currentStep < 2) {
                    setState(() => _currentStep++);
                    } else {
                    _handleClosing(
                      activeSession: activeSession,
                      totalRevenue: metrics.revenue,
                      cashRevenue: metrics.cashRevenue,
                      mmRevenue: metrics.mobileMoneyRevenue,
                      cardRevenue: metrics.cardRevenue,
                      totalExpenses: todayExpenses,
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_currentStep < 2 ? 'Suivant' : 'Confirmer la Clôture'),
        ),
      ],
    );
  }

  Widget _buildSuccess(Closing closing) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Session Clôturée',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'La session ${closing.number ?? ''} a été enregistrée avec succès.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final file = await BoutiqueReportPdfService.instance
                      .generateZReport(closing: closing);
                  await OpenFile.open(file.path);
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Rapport PDF'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrintZReportButton(closing: closing),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Fermer'),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStep(Closing session, dynamic metrics, int expenses) {
    final netFlow = metrics.revenue - expenses;
    return Column(
      children: [
        _buildStatItem('Fonds de caisse (Espèces)', session.openingCashAmount, Colors.grey),
        _buildStatItem('Fonds initiaux (MM)', session.openingMobileMoneyAmount, Colors.grey),
        const Divider(),
        _buildStatItem('Ventes Espèces (Session)', metrics.cashRevenue, Colors.green),
        _buildStatItem('Ventes MM (Session)', metrics.mobileMoneyRevenue, Colors.blue),
        _buildStatItem('Ventes Carte (Session)', metrics.cardRevenue, Colors.orange),
        _buildStatItem('Dépenses (Session)', -expenses, Colors.red),
        const Divider(height: 24),
        _buildStatItem('Total Attendu (Espèces)', (session.openingCashAmount + (metrics.cashRevenue - expenses)).toInt(), Colors.green, isTotal: true),
        _buildStatItem('Total Attendu (MM)', (session.openingMobileMoneyAmount + metrics.mobileMoneyRevenue).toInt(), Colors.blue, isTotal: true),
        _buildStatItem('Total Attendu (Carte)', metrics.cardRevenue.toInt(), Colors.orange, isTotal: true),
      ],
    );
  }

  Widget _buildCashInputStep(int digitalNet) {
    return _buildReconciliationInput(
      title: 'Combien de liquide avez-vous physiquement ?',
      label: 'Espèces Physiques (CFA)',
      controller: _cashController,
      digitalNet: digitalNet,
      icon: Icons.money,
    );
  }

  Widget _buildMMInputStep(int digitalNet) {
    return _buildReconciliationInput(
      title: 'Vérifiez votre solde Mobile Money (compte agent)',
      label: 'Solde MM actuel (CFA)',
      controller: _mmController,
      digitalNet: digitalNet,
      icon: Icons.phone_android,
    );
  }

  Widget _buildReconciliationInput({
    required String title,
    required String label,
    required TextEditingController controller,
    required int digitalNet,
    required IconData icon,
  }) {
    final physical = int.tryParse(controller.text) ?? 0;
    final discrepancy = physical - digitalNet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 24),
        _buildDiscrepancyCard(discrepancy),
        if (discrepancy != 0 && _currentStep == 2) ...[
          const SizedBox(height: 24),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Justification globale des écarts',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'Expliquez la raison de la différence...',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiscrepancyCard(int discrepancy) {
    final color = discrepancy == 0
        ? Colors.green
        : (discrepancy.abs() < 100 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(discrepancy == 0 ? Icons.check_circle : Icons.warning, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              discrepancy == 0
                  ? 'Parfait ! Le physique correspond au digital.'
                  : 'Écart de ${CurrencyFormatter.formatFCFA(discrepancy)} détecté.',
              style: TextStyle(fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            CurrencyFormatter.formatFCFA(value),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 20 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
