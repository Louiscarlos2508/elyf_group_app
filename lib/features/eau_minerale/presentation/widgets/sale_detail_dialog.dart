import 'package:flutter/material.dart';
import 'package:elyf_groupe_app/shared.dart';

import '../../domain/entities/sale.dart';
import 'invoice_print/invoice_print_button.dart';
import 'sale_detail_helpers.dart';

/// Dialog showing sale details.
class SaleDetailDialog extends StatelessWidget {
  const SaleDetailDialog({super.key, required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: ElyfCard(
          isGlass: true,
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header avec dégradé subtil
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary.withValues(alpha: 0.1), colors.surface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.receipt_long_rounded, color: colors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Détails de la Vente',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.onSurface,
                              ),
                            ),
                            Text(
                              SaleDetailHelpers.formatDate(sale.date),
                              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      EauMineralePrintButton(sale: sale, compact: true),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section Client & Produit
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInfoSection(
                              theme, 
                              'CLIENT', 
                              sale.customerName, 
                              Icons.person_pin_rounded,
                              subtitle: sale.customerPhone,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildInfoSection(
                              theme, 
                              'PRODUIT', 
                              sale.productName, 
                              Icons.inventory_2_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Section Financière (KPI-like)
                      _buildFinancialSummary(theme, colors),
                      const SizedBox(height: 32),

                      // Répartition des Paiements
                      if (sale.cashAmount > 0 || sale.orangeMoneyAmount > 0)
                        _buildPaymentBreakdown(theme, colors),
                      
                      const SizedBox(height: 32),

                      // Statut & Notes
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STATUT',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildStatusBadge(context, theme, colors),
                              ],
                            ),
                          ),
                          if (sale.remainingAmount > 0)
                            Expanded(child: _buildCreditAlert(theme, colors)),
                        ],
                      ),

                      if (sale.notes != null && 
                          sale.notes!.isNotEmpty && 
                          !sale.notes!.trim().startsWith('{')) ...[
                        const SizedBox(height: 32),
                        _buildInfoSection(
                          theme, 
                          'NOTES', 
                          sale.notes!, 
                          Icons.sticky_note_2_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, String label, String value, IconData icon, {String? subtitle}) {
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: colors.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _buildFinancialSummary(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFinanceItem(theme, colors, 'PRIX TOTAL', SaleDetailHelpers.formatCurrency(sale.totalPrice), colors.primary),
              _buildFinanceItem(theme, colors, 'MONTANT PAYÉ', SaleDetailHelpers.formatCurrency(sale.amountPaid), Colors.green),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, indent: 40, endIndent: 40),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFinanceItem(theme, colors, 'UNITAIRE', SaleDetailHelpers.formatCurrency(sale.unitPrice), colors.onSurfaceVariant, isSmall: true),
              _buildFinanceItem(theme, colors, 'QUANTITÉ', '${sale.quantity}', colors.onSurfaceVariant, isSmall: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceItem(ThemeData theme, ColorScheme colors, String label, String value, Color valueColor, {bool isSmall = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: colors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: (isSmall ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)?.copyWith(
            fontWeight: FontWeight.w900,
            color: valueColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdown(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RÉPARTITION PAIEMENT',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (sale.cashAmount > 0)
          _buildPaymentRow('Espèces', sale.cashAmount, Icons.money_rounded, colors.primary, theme),
        if (sale.orangeMoneyAmount > 0) ...[
          if (sale.cashAmount > 0) const SizedBox(height: 8),
          _buildPaymentRow('Orange Money', sale.orangeMoneyAmount, Icons.account_balance_wallet_rounded, colors.secondary, theme),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, ThemeData theme, ColorScheme colors) {
    final statusColor = SaleDetailHelpers.getStatusColor(sale.status, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        SaleDetailHelpers.getStatusLabel(sale.status).toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCreditAlert(ThemeData theme, ColorScheme colors) {
    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESTE À PAYER',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
          Text(
            SaleDetailHelpers.formatCurrency(sale.remainingAmount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    int amount,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
        Text(
          SaleDetailHelpers.formatCurrency(amount),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
