import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../widgets/quantity_counter.dart';
import '../../application/tour_notifier.dart';
import '../../data/models/tour.dart';
import '../../data/models/livraison_entry.dart';
import '../../../../core/services/sunmi_print_service.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';

class LivraisonGrossisteScreen extends ConsumerStatefulWidget {
  final String tourId;
  final String siteId;
  final String siteName;

  const LivraisonGrossisteScreen({super.key, required this.tourId, required this.siteId, required this.siteName});

  @override
  ConsumerState<LivraisonGrossisteScreen> createState() => _LivraisonGrossisteScreenState();
}

class _LivraisonGrossisteScreenState extends ConsumerState<LivraisonGrossisteScreen> {
  final Map<FormatBouteille, int> _counts = {};
  bool _initialized = false;
  bool _isPaid = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formats = ref.watch(formatsActifsProvider);
    final state = ref.watch(tourNotifierProvider(widget.tourId)).value;

    if (!_initialized && state != null && formats.isNotEmpty) {
      // Auto-pre-remplissage : On livre ce qu'on a collecté au départ (1 pour 1)
      final collection = state.collectes.where((c) => c.siteId == widget.siteId).firstOrNull;
      if (collection != null) {
        _counts.addAll(collection.quantitesVides);
      } else {
        for (var f in formats) {
          _counts[f] = 0;
        }
      }
      _initialized = true;
    }

    int totalAmount = 0;
    _counts.forEach((f, q) => totalAmount += q * f.prixGros);

    return Scaffold(
      appBar: AppBar(title: const Text('Livraison Grossiste')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.s16),
              itemCount: formats.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.s16),
              itemBuilder: (context, index) {
                final format = formats[index];
                return QuantityCounter(
                  label: format.label,
                  value: _counts[format] ?? 0,
                  onChanged: (val) => setState(() => _counts[format] = val),
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(AppDimensions.s16),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total à encaisser :', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(Formatters.formatCurrency(totalAmount), style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: AppDimensions.s12),
                CheckboxListTile(
                  title: const Text('Paiement reçu / Somme OK'),
                  value: _isPaid,
                  onChanged: (val) => setState(() => _isPaid = val!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.s16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _hasData ? _printReceipt : null,
                      icon: const Icon(Icons.print),
                      label: const Text('FACTURE'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.s12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (_hasData && _isPaid) ? _handleSave : null,
                      child: const Text('VALIDER'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasData => _counts.values.any((v) => v > 0);

  Future<void> _printReceipt() async {
    final entry = _createEntry();
    final wholesalers = ref.read(wholesalersProvider).value ?? [];
    final site = wholesalers.where((w) => w.id == widget.siteId).firstOrNull;
    
    await SunmiPrintService.instance.printDeliveryReceipt(
      enterpriseName: "ELYF GROUP GAZ", 
      siteName: site?.name ?? "Grossiste", 
      entry: entry,
    );
  }

  LivraisonEntry _createEntry() {
    return LivraisonEntry(
      siteId: widget.siteId,
      siteName: widget.siteName,
      typeSite: TypeSite.grossiste,
      lignes: _counts.entries
          .where((e) => e.value > 0)
          .map((e) => LivraisonLigne(
                format: e.key,
                quantiteLivree: e.value,
                prixUnitaire: e.key.prixGros,
              ))
          .toList(),
      montantEncaisse: _counts.entries.fold(0, (s, e) => s + (e.value * e.key.prixGros)),
      timestamp: DateTime.now(),
    );
  }

  void _handleSave() {
    final entry = _createEntry();
    ref.read(tourNotifierProvider(widget.tourId).notifier).addLivraison(entry);
    context.pop();
  }
}
