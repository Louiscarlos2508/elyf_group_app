import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/production_session_controller.dart';
import '../../application/controllers/stock_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/electricity_meter_type.dart';
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
      _indexCompteurFinalKwhController.text =
          widget.session.indexCompteurFinalKwh!.toString();
    }
    if (widget.session.heureFin != null) {
      _heureFin = widget.session.heureFin!;
    }

    // Pré-remplir avec les totaux journaliers (packs / emballages) si présents,
    // sinon retomber sur les valeurs globales de la session.
    final totalPacks = widget.session.totalPacksProduitsJournalier;
    final totalEmb = widget.session.totalEmballagesUtilisesJournalier;

    final quantiteEffective =
        totalPacks > 0 ? totalPacks : widget.session.quantiteProduite;
    final emballagesEffectifs =
        totalEmb > 0 ? totalEmb : (widget.session.emballagesUtilises ?? 0);

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
      final cleanedValue = _indexCompteurFinalKwhController.text.trim().replaceAll(',', '.');
      final doubleValue = double.tryParse(cleanedValue);
      if (doubleValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L\'index compteur final est invalide'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      final indexCompteurFinalKwh = doubleValue.round();

      // Utiliser les totaux journaliers pour la quantité produite et les emballages
      final totalPacks = widget.session.totalPacksProduitsJournalier;
      final totalEmb = widget.session.totalEmballagesUtilisesJournalier;

      if (totalPacks <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez renseigner le nombre de packs produits pour au moins un jour de production.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Calculer la consommation électrique si les index sont disponibles
      double consommationElectrique = widget.session.consommationCourant;
      if (widget.session.indexCompteurInitialKwh != null &&
          indexCompteurFinalKwh != null) {
        final meterType = await ref.read(electricityMeterTypeProvider.future);
        consommationElectrique = meterType.calculateConsumption(
          widget.session.indexCompteurInitialKwh!.toDouble(),
          indexCompteurFinalKwh.toDouble(),
        );
      }

      if (totalEmb <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez renseigner le nombre d\'emballages utilisés pour au moins un jour de production.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Mettre à jour la session avec les totaux journaliers
      final updatedSession = widget.session.copyWith(
        heureFin: _heureFin,
        indexCompteurFinalKwh: indexCompteurFinalKwh?.toInt(),
        consommationCourant: consommationElectrique,
        quantiteProduite: totalPacks,
        emballagesUtilises: totalEmb,
        status: ProductionSessionStatus.completed,
      );

      final controller = ref.read(productionSessionControllerProvider);
      
      // Vérifier si la session était déjà finalisée avant cette mise à jour
      final etaitDejaFinalisee = widget.session.effectiveStatus == ProductionSessionStatus.completed;
      
      final savedSession = await controller.updateSession(updatedSession);

      // Mise à jour automatique du stock
      // IMPORTANT: Ne mettre à jour le stock QUE si la session n'était pas déjà finalisée
      // pour éviter les duplications lors d'une re-finalisation
      if (!etaitDejaFinalisee) {
        final stockController = ref.read(stockControllerProvider);
        
        // Les bobines finies ne nécessitent plus de retrait car elles sont gérées par quantité
        // Le stock a déjà été décrémenté lors de l'installation
        // Pas besoin d'enregistrer un retrait supplémentaire

        // Ajouter les packs produits au stock de produits finis
        if (savedSession.quantiteProduite > 0) {
          try {
            await stockController.recordFinishedGoodsProduction(
              quantiteProduite: savedSession.quantiteProduite,
              productionId: savedSession.id,
              notes: 'Production finalisée - ${savedSession.quantiteProduite} ${savedSession.quantiteProduiteUnite}(s) produits',
            );
          } catch (e) {
            debugPrint('Erreur lors de la mise à jour du stock de produits finis: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Attention: Erreur lors de la mise à jour du stock de produits finis: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }

        // Enregistrer l'utilisation d'emballages si défini
        if (savedSession.emballagesUtilises != null && savedSession.emballagesUtilises! > 0) {
          try {
          // Vérifier la disponibilité du stock d'emballages
          final packagingRepository = ref.read(packagingStockRepositoryProvider);
          final stocksEmballages = await packagingRepository.fetchAll();
          
          // Chercher le stock d'emballages (type "Emballage")
          PackagingStock? stockEmballage;
          try {
            stockEmballage = await packagingRepository.fetchByType('Pack 12 sachets');
          } catch (_) {
            // Si pas trouvé par type, utiliser le premier disponible ou créer
          }
          
          if (stockEmballage == null && stocksEmballages.isNotEmpty) {
            stockEmballage = stocksEmballages.first;
          }
          
          if (stockEmballage != null) {
            // Vérifier que le stock est suffisant
            if (!stockEmballage.peutSatisfaire(savedSession.emballagesUtilises!)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Stock d\'emballages insuffisant. Disponible: ${stockEmballage.quantity}, '
                      'Demandé: ${savedSession.emballagesUtilises}',
                    ),
                    backgroundColor: Colors.orange,
                  ),
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
              debugPrint('Aucun stock d\'emballages trouvé. Création d\'un nouveau stock.');
              // Créer un stock par défaut
              final nouveauStock = await packagingRepository.save(
                PackagingStock(
                  id: 'packaging-default',
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
          debugPrint('Erreur lors de la mise à jour du stock d\'emballages: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Attention: Erreur lors de la mise à jour du stock d\'emballages: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        }
      } else {
        // La session était déjà finalisée, les mouvements de stock ont déjà été enregistrés
        debugPrint('Session déjà finalisée - les mouvements de stock ne seront pas enregistrés à nouveau');
      }

      if (mounted) {
        widget.onFinalized(savedSession);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Production finalisée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Finaliser la production'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date et heure de fin
              Text(
                'Date et heure de fin',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 24),
              _buildIndexCompteurFinalField(),
              const SizedBox(height: 24),
              // Récapitulatif des quantités (lecture seule, issues des jours)
              Text(
                'Récapitulatif des quantités (somme des jours de production)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantiteProduiteController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Total des packs produits',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emballagesUtilisesController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Total des emballages utilisés',
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
              ),
              _buildConsumptionPreview(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Finaliser'),
        ),
      ],
    );
  }

  Widget _buildIndexCompteurFinalField() {
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);
    
    return meterTypeAsync.when(
      data: (meterType) {
        return TextFormField(
          controller: _indexCompteurFinalKwhController,
          decoration: InputDecoration(
            labelText: '${meterType.finalLabel} *',
            prefixIcon: const Icon(Icons.bolt),
            helperText: widget.session.indexCompteurInitialKwh != null
                ? '${meterType.initialLabel}: ${widget.session.indexCompteurInitialKwh} ${meterType.unit}'
                : meterType.finalHelperText,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
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
    final meterTypeAsync = ref.watch(electricityMeterTypeProvider);
    
    return meterTypeAsync.when(
      data: (meterType) {
        if (widget.session.indexCompteurInitialKwh == null ||
            _indexCompteurFinalKwhController.text.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Accepter les nombres avec virgule ou point décimal
        final cleanedValue = _indexCompteurFinalKwhController.text.replaceAll(',', '.');
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consommation électrique: ${consommation.toStringAsFixed(2)} ${meterType.unit}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
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
