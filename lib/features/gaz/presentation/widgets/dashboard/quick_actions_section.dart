import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../expense_form_dialog.dart';
import '../leak_report_dialog.dart';

class QuickActionsSection extends ConsumerWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEnterprise = ref.watch(activeEnterpriseProvider).value;
    final isPos = activeEnterprise?.isPointOfSale ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Actions Rapides',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        if (isPos)
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  label: 'Signaler Fuite',
                  icon: Icons.water_drop_outlined,
                  color: Colors.red,
                  onTap: () => _showLeakDialog(context),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  label: 'Nouveau Tour',
                  icon: Icons.local_shipping_outlined,
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to Logistics Tab
                    ref.read(gazNavigationIndexProvider.notifier).setIndex(2);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  label: 'Ajouter Dépense',
                  icon: Icons.add_card_outlined,
                  color: Colors.orange,
                  onTap: () => _showExpenseDialog(context),
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _showLeakDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LeakReportDialog(),
    );
  }

  void _showExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GazExpenseFormDialog(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
