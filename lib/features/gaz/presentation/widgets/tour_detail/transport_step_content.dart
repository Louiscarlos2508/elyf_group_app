import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/gaz/application/providers.dart';
import '../../../domain/entities/tour.dart';
import '../../../domain/entities/gaz_settings.dart';
import 'transport/loading_unloading_fees_section.dart';
import 'transport/other_expenses_section.dart';
import 'transport/transport_step_header.dart';

/// Contenu de l'étape transport du tour.
class TransportStepContent extends ConsumerStatefulWidget {
  const TransportStepContent({
    super.key,
    required this.tour,
    required this.enterpriseId,
    this.onSaved,
  });

  final Tour tour;
  final String enterpriseId;
  final VoidCallback? onSaved;

@override
  ConsumerState<TransportStepContent> createState() => _TransportStepContentState();
}

class _TransportStepContentState extends ConsumerState<TransportStepContent> {
  late bool _applyLoadingFees;
  @override
  void initState() {
    super.initState();
    _applyLoadingFees = widget.tour.applyLoadingFees;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final settingsAsync = ref.watch(gazSettingsProvider((
      enterpriseId: widget.enterpriseId,
      moduleId: 'gaz',
    )));

    return settingsAsync.when(
      data: (settings) => _buildContent(context, theme, isDark, settings),
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Erreur settings: $e')),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isDark, GazSettings? settings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? theme.colorScheme.outline.withValues(alpha: 0.2) : theme.colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : theme.colorScheme.primary).withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TransportStepHeader(tour: widget.tour, enterpriseId: widget.enterpriseId),
          const SizedBox(height: 30),
          
          // Loading fees toggle
          SwitchListTile(
            value: _applyLoadingFees,
            onChanged: (val) => setState(() => _applyLoadingFees = val),
            title: Text('Appliquer les frais de chargement', 
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('Désactiver si le chargement est gratuit ou fait en interne',
              style: theme.textTheme.bodySmall),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: theme.colorScheme.primary,
          ),
         
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Total Calculation Summary
          Text(
            'Récapitulatif des Frais (Manutention)',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Calculé selon les réglages globaux.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          
          LoadingUnloadingFeesSection(
            tour: widget.tour.copyWith(
              applyLoadingFees: _applyLoadingFees,
            ),
          ),
          const SizedBox(height: 16),
          OtherExpensesSection(
            tour: widget.tour.copyWith(
              applyLoadingFees: _applyLoadingFees,
            ),
          ),
         
          if (widget.onSaved != null) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    // Pull current settings to snapshot them into the tour
                    final loadingFees = settings?.loadingFees ?? {};
                    final unloadingFees = settings?.unloadingFees ?? {};

                    final updatedTour = widget.tour.copyWith(
                      // We snapshot the global settings into the tour record
                      loadingFees: loadingFees,
                      unloadingFees: unloadingFees,
                      applyLoadingFees: _applyLoadingFees,
                      updatedAt: DateTime.now(),
                    );
                    await ref.read(tourControllerProvider).updateTour(updatedTour);

                    if (widget.tour.transportCompletedDate == null) {
                      await ref.read(tourControllerProvider).validateTransport(widget.tour.id);
                    }
                    widget.onSaved?.call();
                  } catch (e) {
                     if (context.mounted) {
                       NotificationService.showError(context, 'Erreur lors de la validation: $e');
                     }
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Valider Transport & Frais'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
