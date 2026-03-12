import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/tour_notifier.dart';
import '../../data/models/recharge_entry.dart';
import '../../data/models/tour.dart';
import '../widgets/quantity_counter.dart';

class RechargeScreen extends ConsumerStatefulWidget {
  final String tourId;

  const RechargeScreen({super.key, required this.tourId});

  @override
  ConsumerState<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends ConsumerState<RechargeScreen> {
  Map<FormatBouteille, int> _adjustedPleines = {};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(tourNotifierProvider(widget.tourId)).value;
    final truck = ref.watch(truckStateProvider(widget.tourId));

    if (state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Initialisation de l'état local une seule fois
    if (!_initialized && truck.videsEnCamion.isNotEmpty) {
      _adjustedPleines = Map.from(truck.videsEnCamion);
      _initialized = true;
    }

    // Calcul du coût basé sur les quantités AJUSTÉES
    int totalCost = 0;
    _adjustedPleines.forEach((format, qty) {
      totalCost += qty * format.prixAchat;
    });

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.swap_horizontal_circle_outlined, size: 64, color: Colors.blue),
            const SizedBox(height: AppDimensions.s16),
            Text(
              'Recharge Fournisseur',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.s8),
            const Text(
              'Ajustez le nombre de pleines reçues si nécessaire',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: AppDimensions.s24),

            ...truck.videsEnCamion.entries.map((e) {
              final format = e.key;
              final totalVides = e.value;
              final currentPleines = _adjustedPleines[format] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.s12),
                child: QuantityCounter(
                  label: format.label,
                  value: currentPleines,
                  min: 0,
                  // On ne peut pas recevoir plus de pleines que de vides rendus
                  onChanged: (val) {
                    if (val <= totalVides) {
                      setState(() => _adjustedPleines[format] = val);
                    }
                  },
                ),
              );
            }),

            if (truck.videsEnCamion.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.s32),
                  child: Text('Aucune bouteille à recharger', style: TextStyle(fontStyle: FontStyle.italic)),
                ),
              ),

            const SizedBox(height: AppDimensions.s24),

            Container(
              padding: const EdgeInsets.all(AppDimensions.s16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppDimensions.r12),
              ),
              child: Column(
                children: [
                  const Text('MONTANT TOTAL À REGLER'),
                  const SizedBox(height: AppDimensions.s8),
                  Text(
                    Formatters.formatCurrency(totalCost),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.s24),
            OutlinedButton.icon(
              onPressed: () => context.pushNamed('frais', pathParameters: {'tourId': widget.tourId}),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('AJOUTER DES FRAIS (Carburant, etc.)'),
            ),
            const SizedBox(height: AppDimensions.s40),

            FilledButton(
              onPressed: truck.totalVides > 0 
                  ? () => _handleConfirm(ref, context, totalCost, truck.videsEnCamion)
                  : null,
              child: const Text('CONFIRMER LA RECHARGE'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleConfirm(WidgetRef ref, BuildContext context, int cost, dynamic vides) {
    final router = GoRouter.of(context);
    final entry = RechargeEntry(
      videsRendus: Map.from(vides),
      pleinesRecues: Map.from(_adjustedPleines), // On utilise les quantités ajustées
      coutAchat: cost,
      timestamp: DateTime.now(),
      ajustementRaison: _adjustedPleines.values.reduce((a, b) => a + b) < 
                        (vides as Map<FormatBouteille, int>).values.reduce((a, b) => a + b)
          ? "Recharge partielle"
          : null,
    );

    ref.read(tourNotifierProvider(widget.tourId).notifier).confirmRecharge(entry).then((_) {
      router.goNamed('livraison', pathParameters: {'tourId': widget.tourId});
    });
  }
}
