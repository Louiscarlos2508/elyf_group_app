import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/controller_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers/state_providers.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/entities/closing.dart';
import 'package:elyf_groupe_app/features/eau_minerale/domain/services/dashboard_calculation_service.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

class ZReportDialog extends ConsumerStatefulWidget {
  const ZReportDialog({super.key});

  @override
  ConsumerState<ZReportDialog> createState() => _ZReportDialogState();
}

class _ZReportDialogState extends ConsumerState<ZReportDialog> {
  final _cashController = TextEditingController();
  final _mmController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cashController.dispose();
    _mmController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(Closing currentSession, DailyDashboardMetrics metrics) async {
    final physicalCash = int.tryParse(_cashController.text);
    final physicalMM = int.tryParse(_mmController.text) ?? 0;
    
    if (physicalCash == null) {
      NotificationService.showWarning(context, 'Entrez le montant de caisse physique');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final closing = currentSession.copyWith(
        status: ClosingStatus.closed,
        date: DateTime.now(),
        digitalRevenue: metrics.collections,
        digitalExpenses: metrics.expenses,
        cashRevenue: metrics.cashCollections,
        mmRevenue: metrics.mobileMoneyCollections,
        cashExpenses: metrics.cashExpenses,
        mmExpenses: metrics.mobileMoneyExpenses,
        physicalCashAmount: physicalCash,
        physicalMmAmount: physicalMM,
        notes: _notesController.text,
      );

      await ref.read(closingControllerProvider).closeSession(closing);
      if (mounted) {
        NotificationService.showSuccess(context, 'Session clôturée avec succès');
        Navigator.pop(context);
      }
    } catch (e) {
      NotificationService.showError(context, 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionAsync = ref.watch(currentClosingSessionProvider);
    final metricsAsync = ref.watch(dailyDashboardSummaryProvider);

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const _OpenSessionView();
        }
        return metricsAsync.when(
          data: (metrics) => _buildClosingView(session, metrics, theme),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Erreur metrics: $e")),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Erreur session: $e")),
    );
  }

  Widget _buildClosingView(Closing session, DailyDashboardMetrics metrics, ThemeData theme) {
    final expectedCash = session.openingCashAmount + metrics.cashCollections - metrics.cashExpenses;
    final expectedMM = metrics.mobileMoneyCollections - metrics.mobileMoneyExpenses;
    final totalTheoretical = expectedCash + expectedMM;

    return AlertDialog(
      title: const Text("Clôture de Journée (Z-Report)"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _SummaryTile(label: "Fonds de caisse", value: "${session.openingCashAmount} CFA"),
            const Divider(),
            _SectionSubHeader(title: " ESPÈCES (CASH)"),
            _SummaryTile(label: "Recettes Cash", value: "${metrics.cashCollections} CFA", color: Colors.green),
            _SummaryTile(label: "Dépenses Cash", value: "-${metrics.cashExpenses} CFA", color: Colors.red),
            _SummaryTile(label: "Solde Cash Théorique", value: "$expectedCash CFA", bold: true),
            const SizedBox(height: 12),
            _SectionSubHeader(title: " MOBILE MONEY (OM)"),
            _SummaryTile(label: "Recettes OM", value: "${metrics.mobileMoneyCollections} CFA", color: Colors.green),
            _SummaryTile(label: "Dépenses OM", value: "-${metrics.mobileMoneyExpenses} CFA", color: Colors.red),
            _SummaryTile(label: "Solde OM Théorique", value: "$expectedMM CFA", bold: true),
            const Divider(),
            if (metrics.apports > 0 || metrics.retraits > 0) ...[
              _SectionSubHeader(title: " TRÉSORERIE MANUELLE"),
              if (metrics.apports > 0) 
                 _SummaryTile(label: "Total Apports (+)", value: "${metrics.apports} CFA", color: Colors.green),
              if (metrics.retraits > 0)
                 _SummaryTile(label: "Total Retraits (-)", value: "-${metrics.retraits} CFA", color: Colors.red),
              const Divider(),
            ],
            _SummaryTile(label: "SOLDE TOTAL THÉORIQUE", value: "$totalTheoretical CFA", bold: true, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: "Notes / Justification",
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cashController,
                      decoration: const InputDecoration(
                        labelText: "Espèces Physiques (CFA)",
                        prefixIcon: Icon(Icons.payments),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _mmController,
                      decoration: const InputDecoration(
                        labelText: "Solde Mobile Money (CFA)",
                        prefixIcon: Icon(Icons.smartphone),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
        FilledButton(onPressed: _isLoading ? null : () => _submit(session, metrics), child: const Text("CLÔTURER")),
      ],
    );
  }
}

class _OpenSessionView extends ConsumerStatefulWidget {
  const _OpenSessionView();
  @override
  ConsumerState<_OpenSessionView> createState() => _OpenSessionViewState();
}

class _OpenSessionViewState extends ConsumerState<_OpenSessionView> {
  final _openingController = TextEditingController();
  bool _isLoading = false;

  Future<void> _open() async {
    final amount = int.tryParse(_openingController.text) ?? 0;
    setState(() => _isLoading = true);
    try {
      final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? 'default';
      final session = Closing(
        id: '',
        enterpriseId: enterpriseId,
        userId: 'system',
        date: DateTime.now(),
        openingDate: DateTime.now(),
        digitalRevenue: 0,
        digitalExpenses: 0,
        openingCashAmount: amount,
        physicalCashAmount: 0,
        status: ClosingStatus.open,
      );
      await ref.read(closingControllerProvider).openSession(session);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      NotificationService.showError(context, 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Ouvrir une session"),
      content: TextFormField(
        controller: _openingController,
        decoration: const InputDecoration(
          labelText: "Fonds de caisse (Aube)",
          prefixIcon: Icon(Icons.wb_sunny_outlined),
        ),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
        FilledButton(onPressed: _isLoading ? null : _open, child: const Text("OUVRIR")),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, this.color, this.bold = false});
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}

class _SectionSubHeader extends StatelessWidget {
  const _SectionSubHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
