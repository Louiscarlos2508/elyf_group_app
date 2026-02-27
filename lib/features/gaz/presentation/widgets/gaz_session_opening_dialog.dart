import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/cylinder.dart';
import 'package:elyf_groupe_app/features/gaz/domain/entities/gaz_session.dart';
import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import 'package:elyf_groupe_app/core/tenant/tenant_provider.dart';

class GazSessionOpeningDialog extends ConsumerStatefulWidget {
  const GazSessionOpeningDialog({super.key});

  @override
  ConsumerState<GazSessionOpeningDialog> createState() => _GazSessionOpeningDialogState();
}

class _GazSessionOpeningDialogState extends ConsumerState<GazSessionOpeningDialog> {
  final _cashController = TextEditingController(text: '0');
  final _mmController = TextEditingController(text: '0');
  final Map<int, TextEditingController> _fullStockControllers = {};
  final Map<int, TextEditingController> _emptyStockControllers = {};
  bool _isLoading = false;
  bool _showStockAdjustments = false;
  bool _autoFilled = false;
  String? _autoFillSource; // description de la source auto-remplie

  @override
  void dispose() {
    _cashController.dispose();
    _mmController.dispose();
    for (final controller in _fullStockControllers.values) {
      controller.dispose();
    }
    for (final controller in _emptyStockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Tente de pré-remplir les montants depuis la dernière session clôturée.
  /// Si aucune session, utilise le solde courant de la trésorerie.
  void _tryAutoFill(List<GazSession> sessions, Map<String, int>? balances) {
    if (_autoFilled) return;

    // Priorité 1 : Dernière session clôturée
    final closedSessions = sessions
        .where((s) => s.isClosed && s.closedAt != null)
        .toList()
      ..sort((a, b) => b.closedAt!.compareTo(a.closedAt!));

    if (closedSessions.isNotEmpty) {
      final last = closedSessions.first;
      setState(() {
        _cashController.text = last.physicalCash.toStringAsFixed(0);
        _mmController.text = last.physicalMobileMoney.toStringAsFixed(0);
        _autoFilled = true;
        _autoFillSource =
            'Clôture du ${_formatDate(last.closedAt ?? last.openedAt)}';
      });
      return;
    }

    // Priorité 2 : Solde trésorerie actuel
    if (balances != null) {
      final cash = (balances['cash'] ?? 0).toDouble();
      final mm = (balances['mobileMoney'] ?? 0).toDouble();
      if (cash > 0 || mm > 0) {
        setState(() {
          _cashController.text = cash.toStringAsFixed(0);
          _mmController.text = mm.toStringAsFixed(0);
          _autoFilled = true;
          _autoFillSource = 'Solde actuel de la trésorerie';
        });
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cylindersAsync = ref.watch(cylindersProvider);
    final stocksAsync = ref.watch(gazStocksProvider);
    final sessionsAsync = ref.watch(gazSessionsProvider);
    final enterpriseId = ref.watch(activeEnterpriseProvider).value?.id ?? '';
    final balanceAsync = ref.watch(gazTreasuryBalanceProvider(enterpriseId));

    // Auto-fill dès que les données sont disponibles
    if (sessionsAsync.hasValue) {
      final balances = balanceAsync.value;
      _tryAutoFill(sessionsAsync.value!, balances);
    }

    // Pré-remplir les stocks depuis la DB
    ref.listen(gazStocksProvider, (previous, next) {
      if (next.hasValue && (previous == null || !previous.hasValue)) {
        final stocks = next.value!;
        for (final stock in stocks) {
          if (stock.status == CylinderStatus.full) {
            _fullStockControllers[stock.weight]?.text = stock.quantity.toString();
          } else if (stock.status == CylinderStatus.emptyAtStore) {
            _emptyStockControllers[stock.weight]?.text = stock.quantity.toString();
          }
        }
      }
    });

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_open_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Ouverture de Session'),
        ],
      ),
      content: cylindersAsync.when(
        data: (cylinders) {
          final weights = cylinders.map((c) => c.weight).toSet().toList()..sort();

          for (final weight in weights) {
            _fullStockControllers.putIfAbsent(weight, () => TextEditingController(text: '0'));
            _emptyStockControllers.putIfAbsent(weight, () => TextEditingController(text: '0'));
          }

          if (stocksAsync.hasValue) {
            final stocks = stocksAsync.value!;
            for (final stock in stocks) {
              if (stock.status == CylinderStatus.full) {
                final controller = _fullStockControllers[stock.weight];
                if (controller != null && controller.text == '0') {
                  controller.text = stock.quantity.toString();
                }
              } else if (stock.status == CylinderStatus.emptyAtStore) {
                final controller = _emptyStockControllers[stock.weight];
                if (controller != null && controller.text == '0') {
                  controller.text = stock.quantity.toString();
                }
              }
            }
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Déclarez vos fonds initiaux pour démarrer la session.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // Bandeau auto-rempli
                if (_autoFillSource != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pré-rempli depuis : $_autoFillSource',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _cashController.text = '0';
                            _mmController.text = '0';
                            _autoFillSource = null;
                          }),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          child: Text(
                            'Réinitialiser',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Cash Initial
                TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fond de caisse (Espèces)',
                    prefixIcon: Icon(Icons.money),
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Mobile Money Initial
                TextField(
                  controller: _mmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Solde Orange Money',
                    prefixIcon: Icon(Icons.phonelink_ring),
                    suffixText: 'FCFA',
                    border: OutlineInputBorder(),
                  ),
                ),

                // Résumé total
                const SizedBox(height: 10),
                Builder(builder: (context) {
                  final cash = double.tryParse(_cashController.text) ?? 0;
                  final mm = double.tryParse(_mmController.text) ?? 0;
                  if (cash == 0 && mm == 0) return const SizedBox.shrink();
                  return Text(
                    'Total : ${CurrencyFormatter.formatDouble(cash + mm)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Toggle Stock Adjustments
                InkWell(
                  onTap: () => setState(() => _showStockAdjustments = !_showStockAdjustments),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _showStockAdjustments ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ajuster le stock initial (optionnel)',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showStockAdjustments) ...[
                  const SizedBox(height: 12),
                  ...weights.map((weight) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${weight}k',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _fullStockControllers[weight],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pleines',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _emptyStockControllers[weight],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Vides',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _handleOpen,
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmer l\'ouverture'),
        ),
      ],
    );
  }

  Future<void> _handleOpen() async {
    setState(() => _isLoading = true);

    final openingCash = double.tryParse(_cashController.text) ?? 0.0;
    final openingMM = double.tryParse(_mmController.text) ?? 0.0;
    final openingFullStock = _fullStockControllers.map((k, v) => MapEntry(k, int.tryParse(v.text) ?? 0));
    final openingEmptyStock = _emptyStockControllers.map((k, v) => MapEntry(k, int.tryParse(v.text) ?? 0));

    final userId = ref.read(currentUserIdProvider);

    try {
      await ref.read(gazSessionControllerProvider).openSession(
        userId: userId,
        openingCash: openingCash,
        openingMobileMoney: openingMM,
        openingFullStock: openingFullStock,
        openingEmptyStock: openingEmptyStock,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur lors de l\'ouverture: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
