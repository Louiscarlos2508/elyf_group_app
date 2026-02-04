import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/logging/app_logger.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../../shared/utils/notification_service.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../../core/offline/providers.dart' as offline_providers;
import '../../../../core/errors/app_exceptions.dart';
import '../../domain/entities/packaging_stock.dart';

/// Formulaire pour ajouter des matières premières en stock (bobines, emballages, autres).
class StockEntryForm extends ConsumerStatefulWidget {
  const StockEntryForm({
    super.key,
    this.showSubmitButton = true,
    this.onSubmit,
  });

  /// Afficher le bouton de soumission dans le formulaire.
  /// Si false, le bouton n'est pas affiché (pour utiliser le bouton du FormDialog).
  final bool showSubmitButton;

  /// Callback optionnel pour la soumission (utilisé par FormDialog).
  final Future<bool> Function()? onSubmit;

  @override
  ConsumerState<StockEntryForm> createState() => StockEntryFormState();
}

enum _StockEntryType { bobine, emballage }

class StockEntryFormState extends ConsumerState<StockEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _supplierController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  _StockEntryType _selectedType = _StockEntryType.bobine;
  DateTime _selectedDate = DateTime.now();
  
  // Type fixe pour toutes les bobines
  static const String _bobineType = 'Bobine';

  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _supplierController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Méthode publique pour soumettre le formulaire (utilisée par FormDialog).
  Future<bool> submit() async {
    developer.log('StockEntryForm.submit() called', name: 'StockEntryForm');
    
    if (widget.onSubmit != null) {
      developer.log('Using widget.onSubmit', name: 'StockEntryForm');
      return await widget.onSubmit!();
    }
    
    if (!_formKey.currentState!.validate()) {
      developer.log('Form validation failed', name: 'StockEntryForm');
      return false;
    }

    developer.log('Starting stock entry submission', name: 'StockEntryForm');
    setState(() => _isLoading = true);
    try {
      developer.log('Reading stock controller', name: 'StockEntryForm');
      final stockController = ref.read(stockControllerProvider);
      final quantiteStr = _quantityController.text.trim();
      developer.log('Quantité saisie: "$quantiteStr"', name: 'StockEntryForm');
      
      // Valider et parser la quantité
      if (quantiteStr.isEmpty) {
        developer.log('Quantité vide - validation failed', name: 'StockEntryForm');
        throw ValidationException('La quantité est requise');
      }
      
      final quantite = int.tryParse(quantiteStr);
      if (quantite == null || quantite <= 0) {
        developer.log('Quantité invalide: $quantite', name: 'StockEntryForm');
        throw ValidationException('La quantité doit être un nombre entier positif');
      }
      
      developer.log('Quantité validée: $quantite, Type: $_selectedType', name: 'StockEntryForm');

      switch (_selectedType) {
        case _StockEntryType.bobine:
          developer.log('Recording bobine entry - calling recordBobineEntry', name: 'StockEntryForm');
          // Utiliser un type fixe pour toutes les bobines
          // Enregistrer l'entrée de bobines (ajoute à la quantité du stock)
          await stockController.recordBobineEntry(
            bobineType: _bobineType,
            quantite: quantite,
            fournisseur: _supplierController.text.isEmpty
                ? null
                : _supplierController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          break;

        case _StockEntryType.emballage:
          developer.log('Recording packaging entry - starting', name: 'StockEntryForm');
          final prixUnitaire = _priceController.text.isEmpty
              ? null
              : int.tryParse(_priceController.text);
          developer.log('Prix unitaire: $prixUnitaire', name: 'StockEntryForm');

          // Récupérer ou créer le stock d'emballages
          final packagingController = ref.read(
            packagingStockControllerProvider,
          );
          var stockEmballage = await packagingController.fetchByType(
            'Emballage',
          );

          if (stockEmballage == null) {
            // Créer un nouveau stock d'emballages en mémoire seulement
            // Utiliser un ID fixe basé sur le type pour garantir la cohérence
            // (comme pour les bobines avec 'bobine-${type}')
            final packagingId = 'packaging-emballage';
            stockEmballage = PackagingStock(
              id: packagingId,
              type: 'Emballage',
              quantity: 0, // Sera mis à jour par recordPackagingEntry
              unit: 'unité',
              fournisseur: _supplierController.text.isEmpty
                  ? null
                  : _supplierController.text,
              prixUnitaire: prixUnitaire,
              createdAt: _selectedDate,
              updatedAt: _selectedDate,
            );
            // Ne pas sauvegarder ici - recordPackagingEntry le fera avec la bonne quantité
          }

          // Enregistrer l'entrée
          await stockController.recordPackagingEntry(
            packagingId: stockEmballage.id,
            packagingType: 'Emballage',
            quantite: quantite,
            fournisseur: _supplierController.text.isEmpty
                ? null
                : _supplierController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          break;
      }

      if (!mounted) {
        developer.log('Widget not mounted after submission', name: 'StockEntryForm');
        return false;
      }
      
      developer.log('Submission successful, invalidating state', name: 'StockEntryForm');
      ref.invalidate(stockStateProvider);
      // Invalider tous les providers de mouvements pour rafraîchir l'historique
      ref.invalidate(stockMovementsProvider);
      
      final message = _selectedType == _StockEntryType.bobine
          ? '$quantite bobine(s) ajoutée(s)'
          : '$quantite emballage(s) ajouté(s)';
      developer.log('Showing success message: $message', name: 'StockEntryForm');
      NotificationService.showSuccess(context, message);
      
      developer.log('Returning true - FormDialog will close', name: 'StockEntryForm');
      // Ne pas fermer le dialog ici - le FormDialog le fera automatiquement
      // si on retourne true
      return true;
    } catch (e, stackTrace) {
      if (!mounted) return false;
      
      // Capturer l'erreur originale avant qu'elle ne soit convertie
      final originalErrorString = e.toString();
      final errorType = e.runtimeType.toString();
      
      // Logger l'erreur complète pour le débogage avec plus de détails
      final appException = ErrorHandler.instance.handleError(e, stackTrace);
      AppLogger.error(
        '=== ERROR IN STOCK ENTRY FORM === Error type: $errorType, Message: ${appException.message}',
        name: 'StockEntryForm',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Extraire le message utilisateur-friendly
      String errorMessage;
      if (e is AppException) {
        errorMessage = e.message;
        // Si c'est une UnknownException, essayer d'extraire le message original
        if (e is UnknownException) {
          // L'erreur originale a été convertie, mais on peut au moins donner un message plus utile
          // Vérifier si c'est une erreur de parsing ou autre
          if (originalErrorString.toLowerCase().contains('format') ||
              originalErrorString.toLowerCase().contains('parse')) {
            errorMessage = 'Format de données invalide. Vérifiez les valeurs saisies.';
          } else if (originalErrorString.toLowerCase().contains('null')) {
            errorMessage = 'Données manquantes. Veuillez remplir tous les champs requis.';
          } else {
            errorMessage = 'Erreur lors de l\'enregistrement. Vérifiez les données saisies et réessayez.';
          }
        }
      } else {
        // Si c'est une erreur de synchronisation mais que les données sont sauvegardées localement,
        // on affiche un message d'avertissement plutôt qu'une erreur
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('sync') || errorString.contains('synchronization')) {
          // Vérifier si la connexion est disponible
          final isOnline = ref.read(offline_providers.isOnlineProvider);
          final message = isOnline
              ? 'Données enregistrées localement. La synchronisation sera effectuée en arrière-plan.'
              : 'Données enregistrées localement. La synchronisation se fera automatiquement quand la connexion sera disponible.';
          
          NotificationService.showWarning(context, message);
          // Invalider quand même pour rafraîchir l'affichage
          ref.invalidate(stockStateProvider);
          // Ne pas fermer le dialog ici - le FormDialog le fera automatiquement
          // si on retourne true
          return true; // Considérer comme succès car données sauvegardées
        }
        
        // Extraire un message plus lisible depuis l'erreur originale
        errorMessage = originalErrorString
            .replaceAll('Exception: ', '')
            .replaceAll('Error: ', '')
            .replaceAll('Une erreur inattendue s\'est produite. Veuillez réessayer.', '')
            .trim();
        
        // Détecter des erreurs spécifiques
        final lowerError = errorMessage.toLowerCase();
        if (lowerError.contains('format') || lowerError.contains('parse')) {
          errorMessage = 'Format de données invalide. Vérifiez les valeurs saisies.';
        } else if (lowerError.contains('null') || lowerError.contains('missing')) {
          errorMessage = 'Données manquantes. Veuillez remplir tous les champs requis.';
        } else if (lowerError.contains('duplicate') || lowerError.contains('existe déjà')) {
          errorMessage = 'Cette entrée existe déjà.';
        } else if (errorMessage.isEmpty || errorMessage == '') {
          errorMessage = 'Erreur lors de l\'enregistrement. Vérifiez les données saisies et réessayez.';
        } else if (errorMessage.length > 150) {
          errorMessage = '${errorMessage.substring(0, 150)}...';
        }
      }
      
      NotificationService.showError(context, errorMessage);
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    await submit();
  }

  @override
  Widget build(BuildContext context) {
    final quantite = int.tryParse(_quantityController.text) ?? 0;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type de matière première
            SegmentedButton<_StockEntryType>(
              segments: const [
                ButtonSegment(
                  value: _StockEntryType.bobine,
                  label: Text('Bobine'),
                  icon: Icon(Icons.repeat, size: 18),
                ),
                ButtonSegment(
                  value: _StockEntryType.emballage,
                  label: Text('Emballage'),
                  icon: Icon(Icons.inventory_2, size: 18),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<_StockEntryType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Date de réception
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de réception',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quantité
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantité',
                prefixIcon: const Icon(Icons.numbers),
                suffixText: 'unité${quantite > 1 ? 's' : ''}',
                helperText: _selectedType == _StockEntryType.bobine
                    ? 'Nombre de bobines à ajouter'
                    : 'Nombre d\'emballages à ajouter',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                final qty = int.tryParse(v);
                if (qty == null || qty <= 0) return 'Quantité invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fournisseur
            TextFormField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Fournisseur (optionnel)',
                prefixIcon: Icon(Icons.local_shipping),
              ),
            ),
            const SizedBox(height: 16),

            // Prix unitaire
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Prix unitaire (FCFA, optionnel)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v != null && v.isNotEmpty) {
                  final price = int.tryParse(v);
                  if (price == null || price < 0) return 'Prix invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            // Bouton de soumission (seulement si showSubmitButton est true)
            if (widget.showSubmitButton) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ajouter au stock'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
