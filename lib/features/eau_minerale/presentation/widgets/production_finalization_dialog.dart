import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/core/logging/app_logger.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../../domain/entities/packaging_stock.dart';
import '../../domain/entities/production_session.dart';
import '../../domain/entities/production_session_status.dart';
import 'time_picker_field.dart';

/// Dialog pour finaliser une production.
class ProductionFinalizationDialog extends ConsumerStatefulWidget {
  const ProductionFinalizationDialog({
    super.key,
    required this.session,
    required this.onFinalized,
  });

  final ProductionSession session;
  final ValueChanged<ProductionSession> onFinalized;

  @override
  ConsumerState<ProductionFinalizationDialog> createState() =>
      _ProductionFinalizationDialogState();
}

class _ProductionFinalizationDialogState
    extends ConsumerState<ProductionFinalizationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _indexCompteurFinalKwhController = TextEditingController();
  final _quantiteProduiteController = TextEditingController();
  final _emballagesUtilisesController = TextEditingController();
  DateTime _heureFin = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les valeurs existantes si disponibles
    if (widget.session.indexCompteurFinalKwh != null) {
      _indexCompteurFinalKwhController.text = widget
          .session
          .indexCompteurFinalKwh!
          .toString();
    }
    if (widget.session.heureFin != null) {
      _heureFin = widget.session.heureFin!;
    }

    // Pré-remplir avec les totaux journaliers (packs / emballages) si présents,
    // sinon retomber sur les valeurs globales de la session.
    final totalPacks = widget.session.totalPacksProduitsJournalier;
    final totalEmb = widget.session.totalEmballagesUtilisesJournalier;

    final quantiteEffective = totalPacks > 0
        ? totalPacks
        : widget.session.quantiteProduite;
    final emballagesEffectifs = totalEmb > 0
        ? totalEmb
        : (widget.session.emballagesUtilises ?? 0);

    if (quantiteEffective > 0) {
      _quantiteProduiteController.text = quantiteEffective.toString();
    }
    if (emballagesEffectifs > 0) {
      _emballagesUtilisesController.text = emballagesEffectifs.toString();
    }
  }

  @override
  void dispose() {
    _indexCompteurFinalKwhController.dispose();
    _quantiteProduiteController.dispose();
    _emballagesUtilisesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Accepter les nombres avec virgule ou point décimal et arrondir
      final cleanedValue = _indexCompteurFinalKwhController.text
          .trim()
          .replaceAll(',', '.');
      final doubleValue = double.tryParse(cleanedValue);
      if (doubleValue == null) {
        NotificationService.showError(
          context,
          'L\'index compteur final est invalide',
        );
        setState(() => _isLoading = false);
        return;
      }
      final indexCompteurFinalKwh = doubleValue.round();

      // Utiliser les totaux journaliers pour la quantité produite et les emballages
      final totalPacks = widget.session.totalPacksProduitsJournalier;
      final totalEmb = widget.session.totalEmballagesUtilisesJournalier;

      if (totalPacks <= 0) {
        NotificationService.showError(
          context,
          'Veuillez renseigner le nombre de packs produits pour au moins un jour de production.',
        );
        setState(() => _isLoading = false);
        return;
      }

      // Calculer la consommation électrique si les index sont disponibles
      double consommationElectrique = widget.session.consommationCourant;
      if (widget.session.indexCompteurInitialKwh != null) {
        final meterType = await ref.read(electricityMeterTypeProvider.future);
        if (!mounted) return;
        consommationElectrique = meterType.calculateConsumption(
          widget.session.indexCompteurInitialKwh!.toDouble(),
          indexCompteurFinalKwh.toDouble(),
        );
      }

      if (totalEmb <= 0) {
        if (!mounted) return;
        NotificationService.showError(
          context,
          'Veuillez renseigner le nombre d\'emballages utilisés pour au moins un jour de production.',
        );
        setState(() => _isLoading = false);
        return;
      }

      // Mettre à jour la session avec les totaux journaliers
      final updatedSession = widget.session.copyWith(
        heureFin: _heureFin,
        indexCompteurFinalKwh: indexCompteurFinalKwh.toInt(),
        consommationCourant: consommationElectrique,
        quantiteProduite: totalPacks,
        emballagesUtilises: totalEmb,
        status: ProductionSessionStatus.completed,
      );

      final controller = ref.read(productionSessionControllerProvider);

      // Vérifier si la session était déjà finalisée avant cette mise à jour
      final etaitDejaFinalisee =
          widget.session.effectiveStatus == ProductionSessionStatus.completed;

      final savedSession = await controller.updateSession(updatedSession);

      // Mise à jour automatique du stock
      // IMPORTANT: Ne mettre à jour le stock QUE si la session n'était pas déjà finalisée
      // pour éviter les duplications lors d'une re-finalisation
      if (!etaitDejaFinalisee) {
        final stockController = ref.read(stockControllerProvider);

        // Packs et emballages déjà gérés à l'enregistrement journalier → ne pas
        // ré-enregistrer à la finalisation (évite double produit fini / double
        // décrément emballages).
        final aDejaJournalier = savedSession.productionDays
            .any((d) => d.packsProduits > 0 || d.emballagesUtilises > 0);
        if (aDejaJournalier) {
          AppLogger.info(
            'Stock pack/emballage déjà enregistré en journalier → skip '
            'finalisation (session ${savedSession.id})',
            name: 'eau_minerale.production',
          );
        }

        // Les bobines finies ne nécessitent plus de retrait car elles sont gérées par quantité
        // Le stock a déjà été décrémenté lors de l'installation
        // Pas besoin d'enregistrer un retrait supplémentaire

        // Ajouter les packs produits au stock de produits finis (sauf si déjà fait via journalier)
        if (!aDejaJournalier && savedSession.quantiteProduite > 0) {
          try {
            await stockController.recordFinishedGoodsProduction(
              quantiteProduite: savedSession.quantiteProduite,
              productionId: savedSession.id,
              notes:
                  'Production finalisée - ${savedSession.quantiteProduite} ${savedSession.quantiteProduiteUnite}(s) produits',
            );
          } catch (e) {
            AppLogger.error(
              'Erreur lors de la mise à jour du stock de produits finis: $e',
              name: 'eau_minerale.production',
              error: e,
            );
            if (mounted) {
              NotificationService.showWarning(
                context,
                'Attention: Erreur lors de la mise à jour du stock de produits finis: $e',
              );
            }
          }
        }

        // Enregistrer l'utilisation d'emballages (sauf si déjà fait via journalier)
        if (!aDejaJournalier &&
            savedSession.emballagesUtilises != null &&
            savedSession.emballagesUtilises! > 0) {
          try {
            // Vérifier la disponibilité du stock d'emballages
            final packagingController = ref.read(
              packagingStockControllerProvider,
            );
            final stocksEmballages = await packagingController.fetchAll();

            // Chercher le stock d'emballages (type "Emballage")
            PackagingStock? stockEmballage;
            try {
              stockEmballage = await packagingController.fetchByType(
                'Pack 12 packs',
              );
            } catch (_) {
              // Si pas trouvé par type, utiliser le premier disponible ou créer
            }

            if (stockEmballage == null && stocksEmballages.isNotEmpty) {
              stockEmballage = stocksEmballages.first;
            }

            if (stockEmballage != null) {
              // Vérifier que le stock est suffisant
              if (!stockEmballage.peutSatisfaire(
                savedSession.emballagesUtilises!,
              )) {
                if (mounted) {
                  NotificationService.showWarning(
                    context,
                    'Stock d\'emballages insuffisant. Disponible: ${stockEmballage.quantity}, '
                    'Demandé: ${savedSession.emballagesUtilises}',
                  );
                  setState(() => _isLoading = false);
                  return;
                }
              }

              // Enregistrer l'utilisation
              await stockController.recordPackagingUsage(
                packagingId: stockEmballage.id,
                packagingType: stockEmballage.type,
                quantite: savedSession.emballagesUtilises!,
                productionId: savedSession.id,
                notes: 'Emballages utilisés lors de la production',
              );
            } else {
              // Aucun stock d'emballages trouvé, avertir mais continuer
              if (mounted) {
                AppLogger.info(
                  'Aucun stock d\'emballages trouvé. Création d\'un nouveau stock.',
                  name: 'eau_minerale.production',
                );
                final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
                // Créer un stock par défaut
                final nouveauStock = await packagingController.save(
                  PackagingStock(
                    id: 'packaging-default',
                    enterpriseId: enterpriseId,
                    type: 'Emballage',
                    quantity: 0, // Sera mis à jour lors de la réception
                    unit: 'unité',
                  ),
                );
                await stockController.recordPackagingUsage(
                  packagingId: nouveauStock.id,
                  packagingType: nouveauStock.type,
                  quantite: savedSession.emballagesUtilises!,
                  productionId: savedSession.id,
                  notes: 'Emballages utilisés lors de la production',
                );
              }
            }
          } catch (e) {
            // Si le stock n'existe pas, on continue quand même (l'utilisateur pourra le créer plus tard)
            AppLogger.error(
              'Erreur lors de la mise à jour du stock d\'emballages: $e',
              name: 'eau_minerale.production',
              error: e,
            );
            if (mounted) {
              NotificationService.showWarning(
                context,
                'Attention: Erreur lors de la mise à jour du stock d\'emballages: $e',
              );
            }
          }
        }
      } else {
        // La session était déjà finalisée, les mouvements de stock ont déjà été enregistrés
        AppLogger.info(
          'Session déjà finalisée - les mouvements de stock ne seront pas enregistrés à nouveau',
          name: 'eau_minerale.production',
        );
      }

      if (mounted) {
        widget.onFinalized(savedSession);
        Navigator.of(context).pop();
        NotificationService.showSuccess(
          context,
          'Production finalisée avec succès',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FormDialog(
      title: 'Finaliser la production',
      saveLabel: 'Finaliser',
      isLoading: _isLoading,
      isGlass: true,
      onSave: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Temps & Énergie
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      Icon(Icons.timer_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Informations de Fin',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TimePickerField(
                    label: 'Heure de fin',
                    initialTime: TimeOfDay.fromDateTime(_heureFin),
                    onTimeSelected: (time) {
                      setState(() {
                        _heureFin = DateTime(
                          widget.session.date.year,
                          widget.session.date.month,
                          widget.session.date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildIndexCompteurFinalField(),
                  _buildConsumptionPreview(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Récapitulatif
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.primary.withValues(alpha: 0.03),
              borderColor: colors.primary.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Récapitulatif Global',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Somme calculée sur tous les jours de production',
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _quantiteProduiteController,
                    readOnly: true,
                    decoration: _buildInputDecoration(
                      label: 'Total des packs produits',
                      icon: Icons.inventory_2_rounded,
                      isReadOnly: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emballagesUtilisesController,
                    readOnly: true,
                    decoration: _buildInputDecoration(
                      label: 'Total des emballages utilisés',
                      icon: Icons.shopping_bag_rounded,
                      isReadOnly: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    bool isReadOnly = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, size: 18, color: isReadOnly ? colors.onSurfaceVariant : colors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      filled: true,
      fillColor: isReadOnly 
          ? colors.surfaceContainerHighest.withValues(alpha: 0.2)
          : colors.surfaceContainerLow.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildIndexCompteurFinalField() {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);

    return meterTypeAsync.when(
      data: (meterType) {
        return TextFormField(
          controller: _indexCompteurFinalKwhController,
          decoration: _buildInputDecoration(
            label: '${meterType.finalLabel} *',
            icon: Icons.bolt_rounded,
            helperText: widget.session.indexCompteurInitialKwh != null
                ? '${meterType.initialLabel}: ${widget.session.indexCompteurInitialKwh} ${meterType.unit}'
                : meterType.finalHelperText,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Requis';
            }
            final finalValue = double.tryParse(value);
            if (finalValue == null) {
              return 'Nombre invalide';
            }
            if (widget.session.indexCompteurInitialKwh != null) {
              if (!meterType.isValidRange(
                widget.session.indexCompteurInitialKwh!.toDouble(),
                finalValue,
              )) {
                return meterType.validationErrorMessage;
              }
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        );
      },
      loading: () => TextFormField(
        decoration: const InputDecoration(
          labelText: 'Chargement...',
          prefixIcon: Icon(Icons.bolt),
        ),
        enabled: false,
      ),
      error: (_, __) => TextFormField(
        controller: _indexCompteurFinalKwhController,
        decoration: const InputDecoration(
          labelText: 'Index compteur final *',
          prefixIcon: Icon(Icons.bolt),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  Widget _buildConsumptionPreview() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);

    return meterTypeAsync.when(
      data: (meterType) {
        if (widget.session.indexCompteurInitialKwh == null ||
            _indexCompteurFinalKwhController.text.isEmpty) {
          return const SizedBox.shrink();
        }

        // Accepter les nombres avec virgule ou point décimal
        final cleanedValue = _indexCompteurFinalKwhController.text.replaceAll(
          ',',
          '.',
        );
        final finalValue = double.tryParse(cleanedValue);
        if (finalValue == null) {
          return const SizedBox.shrink();
        }

        final consommation = meterType.calculateConsumption(
          widget.session.indexCompteurInitialKwh!.toDouble(),
          finalValue,
        );

        return Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.1),
                    colors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.electric_bolt_rounded,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONSO. ÉLECTRIQUE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${consommation.toStringAsFixed(2)} ${meterType.unit}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
