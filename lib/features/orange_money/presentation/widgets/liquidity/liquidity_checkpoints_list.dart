import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared/utils/currency_formatter.dart';
import '../../../domain/entities/liquidity_checkpoint.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/orange_money/application/providers.dart';

/// Widget affichant la liste des pointages de liquidité.
class LiquidityCheckpointsList extends StatelessWidget {
  const LiquidityCheckpointsList({super.key, required this.checkpoints});

  final List<LiquidityCheckpoint> checkpoints;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Column(
      children: checkpoints.map((checkpoint) {
        final hasMorning = checkpoint.hasMorningCheckpoint;
        final hasEvening = checkpoint.hasEveningCheckpoint;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.1),
              width: 1.219,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        dateFormat.format(checkpoint.date),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF101828),
                        ),
                      ),
                      // Display enterprise name if in network view
                      Consumer(
                        builder: (context, ref, _) {
                          final enterprisesMap = ref.watch(networkEnterprisesProvider).value ?? {};
                          final enterpriseName = enterprisesMap[checkpoint.enterpriseId];
                          
                          if (enterpriseName != null) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  enterpriseName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasMorning)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDD4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.transparent,
                              width: 1.219,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wb_sunny,
                                size: 12,
                                color: Color(0xFF9F2D00),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Matin',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9F2D00),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasEvening)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.transparent,
                              width: 1.219,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.nightlight_round,
                                size: 12,
                                color: Color(0xFF6B21A8),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Soir',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B21A8),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (hasMorning || hasEvening) ...[
                const SizedBox(height: 12),
                if (hasMorning &&
                    (checkpoint.morningCashAmount != null ||
                        checkpoint.morningSimAmount != null))
                  _PeriodCard(
                    title: '🌅 MATIN',
                    backgroundColor: const Color(0xFFFFF7ED),
                    titleColor: const Color(0xFFCA3500),
                    cashAmount: checkpoint.morningCashAmount ?? 0,
                    simAmount: checkpoint.morningSimAmount ?? 0,
                  ),
                if (hasMorning && hasEvening) const SizedBox(height: 12),
                if (hasEvening &&
                    (checkpoint.eveningCashAmount != null ||
                        checkpoint.eveningSimAmount != null))
                  _PeriodCard(
                    title: '🌙 SOIR',
                    backgroundColor: const Color(0xFFF5F3FF),
                    titleColor: const Color(0xFF7C3AED),
                    cashAmount: checkpoint.eveningCashAmount ?? 0,
                    simAmount: checkpoint.eveningSimAmount ?? 0,
                    theoreticalCash: checkpoint.theoreticalCash,
                    theoreticalSim: checkpoint.theoreticalSim,
                    requiresJustification: checkpoint.requiresJustification,
                    discrepancyPercentage: checkpoint.discrepancyPercentage,
                  ),
                if (hasMorning && hasEvening) ...[
                  const SizedBox(height: 12),
                  _buildVariancesCard(checkpoint),
                ],
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVariancesCard(LiquidityCheckpoint checkpoint) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.219),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 ÉCARTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cash:',
                style: TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
              ),
              Builder(
                builder: (context) {
                  final morningCash = checkpoint.morningCashAmount ?? 0;
                  final eveningCash = checkpoint.eveningCashAmount ?? 0;
                  final diff = eveningCash - morningCash;
                  final isPositive = diff >= 0;
                  return Text(
                    '${isPositive ? '+' : ''}${CurrencyFormatter.formatShort(diff.abs())}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isPositive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SIM:',
                style: TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
              ),
              Builder(
                builder: (context) {
                  final morningSim = checkpoint.morningSimAmount ?? 0;
                  final eveningSim = checkpoint.eveningSimAmount ?? 0;
                  final diff = eveningSim - morningSim;
                  final isPositive = diff >= 0;
                  return Text(
                    '${isPositive ? '+' : ''}${CurrencyFormatter.formatShort(diff.abs())}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isPositive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1.219, color: Color(0xFFE5E5E5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E40AF),
                ),
              ),
              Builder(
                builder: (context) {
                  final morningTotal =
                      (checkpoint.morningCashAmount ?? 0) +
                      (checkpoint.morningSimAmount ?? 0);
                  final eveningTotal =
                      (checkpoint.eveningCashAmount ?? 0) +
                      (checkpoint.eveningSimAmount ?? 0);
                  final diff = eveningTotal - morningTotal;
                  final isPositive = diff >= 0;
                  return Text(
                    '${isPositive ? '+' : '-'}${CurrencyFormatter.formatShort(diff.abs())}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPositive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.title,
    required this.backgroundColor,
    required this.titleColor,
    required this.cashAmount,
    required this.simAmount,
    this.theoreticalCash,
    this.theoreticalSim,
    this.requiresJustification = false,
    this.discrepancyPercentage,
  });

  final String title;
  final Color backgroundColor;
  final Color titleColor;
  final int cashAmount;
  final int simAmount;
  final int? theoreticalCash;
  final int? theoreticalSim;
  final bool requiresJustification;
  final double? discrepancyPercentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: requiresJustification ? Border.all(color: const Color(0xFFFCA5A5), width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
              ),
              if (requiresJustification)
                const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
            ],
          ),
          if (cashAmount > 0 || simAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (cashAmount > 0 || theoreticalCash != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💵 Cash',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4A5565),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatShort(cashAmount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        if (theoreticalCash != null)
                          Text(
                            'Théo: ${CurrencyFormatter.formatShort(theoreticalCash!)}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                      ],
                    ),
                  ),
                ],
                if (simAmount > 0 || theoreticalSim != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📱 SIM',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4A5565),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatShort(simAmount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        if (theoreticalSim != null)
                          Text(
                            'Théo: ${CurrencyFormatter.formatShort(theoreticalSim!)}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (requiresJustification && discrepancyPercentage != null) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ Écart détecté: ${discrepancyPercentage!.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
            ),
          ],
        ],
      ),
    );
  }
}
