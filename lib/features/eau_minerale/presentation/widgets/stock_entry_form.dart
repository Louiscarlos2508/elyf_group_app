import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/offline/providers.dart' as offline_providers;
import '../../../../core/logging/app_logger.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
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
  final _unitsPerLotController = TextEditingController(text: '1000'); // Valeur par défaut indicative

  _StockEntryType _selectedType = _StockEntryType.bobine;
  DateTime _selectedDate = DateTime.now();
  bool _useLots = false; // Toggle pour saisir en lots au lieu d'unités
  
  // Type fixe pour toutes les bobines
  static const String _bobineType = 'Bobine';

  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _supplierController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _unitsPerLotController.dispose();
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
        throw const ValidationException('La quantité est requise', 'MISSING_QUANTITY');
      }
      
      final quantite = int.tryParse(quantiteStr);
      if (quantite == null || quantite <= 0) {
        developer.log('Quantité invalide: $quantite', name: 'StockEntryForm');
        throw const ValidationException('La quantité doit être un nombre entier positif', 'INVALID_QUANTITY');
      }
      
      developer.log('Quantité validée: $quantite, Type: $_selectedType', name: 'StockEntryForm');

      switch (_selectedType) {
        case _StockEntryType.bobine:
          developer.log('Recording bobine entry - calling recordBobineEntry', name: 'StockEntryForm');
          await stockController.recordBobineEntry(
            bobineType: _bobineType,
            quantite: quantite,
            prixUnitaire: _priceController.text.isEmpty
                ? null
                : int.tryParse(_priceController.text),
            fournisseur: _supplierController.text.isEmpty
                ? null
                : _supplierController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );
          break;

        case _StockEntryType.emballage:
          developer.log('Recording packaging entry - starting', name: 'StockEntryForm');
          
          // Récupérer ou créer le stock d'emballages
          final packagingController = ref.read(
            packagingStockControllerProvider,
          );
          var stockEmballage = await packagingController.fetchByType(
            'Emballage',
          );

          if (stockEmballage == null) {
            // Créer un nouveau stock d'emballages avec le facteur de conversion renseigné
            final unitsPerLot = int.tryParse(_unitsPerLotController.text) ?? 1;
            final packagingId = 'packaging-emballage';
            stockEmballage = PackagingStock(
              id: packagingId,
              type: 'Emballage',
              quantity: 0, 
              unit: 'unité',
              unitsPerLot: unitsPerLot,
              fournisseur: _supplierController.text.isEmpty
                  ? null
                  : _supplierController.text,
              prixUnitaire: _priceController.text.isEmpty
                  ? null
                  : int.tryParse(_priceController.text),
              createdAt: _selectedDate,
              updatedAt: _selectedDate,
            );
            
            // On sauvegarde le stock avec sa configuration d'unité d'abord
            await packagingController.save(stockEmballage);
          } else if (_useLots) {
             // Si on utilise des lots, on met à jour la configuration si elle a changé
             // Cela permet de gérer les changements de conditionnement (ex: passage de 1000 à 500)
             final newUnitsPerLot = int.tryParse(_unitsPerLotController.text) ?? 1;
             if (newUnitsPerLot > 0 && stockEmballage.unitsPerLot != newUnitsPerLot) {
               developer.log('Updating unitsPerLot from ${stockEmballage.unitsPerLot} to $newUnitsPerLot', name: 'StockEntryForm');
               await packagingController.save(stockEmballage.copyWith(unitsPerLot: newUnitsPerLot));
             }
          }

          // Calculer le prix à l'unité si on saisit par lots
          int? prixFinalUnitaire;
          final prixSaisiStr = _priceController.text.trim();
          if (prixSaisiStr.isNotEmpty) {
            final prixSaisi = int.tryParse(prixSaisiStr) ?? 0;
            if (_useLots) {
              final unitsPerLot = int.tryParse(_unitsPerLotController.text) ?? 1;
              prixFinalUnitaire = (prixSaisi / unitsPerLot).round();
            } else {
              prixFinalUnitaire = prixSaisi;
            }
          }

          // Enregistrer l'entrée
          final unitsPerLot = _useLots ? (int.tryParse(_unitsPerLotController.text) ?? 1) : null;
          
          await stockController.recordPackagingEntry(
            packagingId: stockEmballage.id,
            packagingType: 'Emballage',
            quantite: quantite,
            prixUnitaire: prixFinalUnitaire,
            isInLots: _useLots,
            unitsPerLot: unitsPerLot,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final quantite = int.tryParse(_quantityController.text) ?? 0;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Type d'Entrée
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Type d\'Entrée Stock',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        _buildTypeSegment(
                          type: _StockEntryType.bobine,
                          label: 'Bobine',
                          icon: Icons.album_rounded,
                          isSelected: _selectedType == _StockEntryType.bobine,
                        ),
                        const SizedBox(width: 4),
                        _buildTypeSegment(
                          type: _StockEntryType.emballage,
                          label: 'Emballage',
                          icon: Icons.layers_rounded,
                          isSelected: _selectedType == _StockEntryType.emballage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Date & Quantité
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      Icon(Icons.edit_calendar_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Informations de Réception',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Date Picker Premium
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: theme.copyWith(
                            colorScheme: colors.copyWith(primary: colors.primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: colors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date de réception',
                                  style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                                ),
                                Text(
                                  DateFormatter.formatLongDate(_selectedDate),
                                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_selectedType == _StockEntryType.emballage) ...[
                    // Toggle Lot vs Unité
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildUnitToggleSegment(
                              isSelected: !_useLots,
                              label: 'Unités',
                              onTap: () => setState(() => _useLots = false),
                            ),
                          ),
                          Expanded(
                            child: _buildUnitToggleSegment(
                              isSelected: _useLots,
                              label: 'Lots',
                              onTap: () => setState(() => _useLots = true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_useLots) ...[
                      TextFormField(
                        controller: _unitsPerLotController,
                        decoration: _buildInputDecoration(
                          label: 'Unités par Lot',
                          icon: Icons.scale_rounded,
                          hintText: 'Ex: 1000',
                          suffixText: 'unités/lot',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => _useLots && (v?.isEmpty ?? true) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  TextFormField(
                    controller: _quantityController,
                    decoration: _buildInputDecoration(
                      label: 'Quantité',
                      icon: Icons.numbers_rounded,
                      hintText: _useLots ? 'Nombre de lots' : 'Nombre d\'unités',
                      suffixText: _useLots 
                          ? 'lot${quantite > 1 ? 's' : ''}'
                          : 'unité${quantite > 1 ? 's' : ''}',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Détails Supplémentaires
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
                      Icon(Icons.add_business_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Détails Supplémentaires',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _supplierController,
                    decoration: _buildInputDecoration(
                      label: 'Fournisseur (Optionnel)',
                      icon: Icons.local_shipping_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: _buildInputDecoration(
                      label: (_selectedType == _StockEntryType.emballage && _useLots)
                          ? 'Prix du lot total (FCFA, Optionnel)'
                          : 'Prix unitaire (FCFA, Optionnel)',
                      icon: Icons.payments_rounded,
                      helperText: (_selectedType == _StockEntryType.emballage && _useLots)
                          ? 'Le système calculera automatiquement le prix à l\'unité'
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: _buildInputDecoration(
                      label: 'Notes (Optionnel)',
                      icon: Icons.note_alt_rounded,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            if (widget.showSubmitButton) ...[
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    String? suffixText,
    String? helperText,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixText: suffixText,
      helperText: helperText,
      prefixIcon: Icon(icon, size: 20, color: colors.primary),
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
      fillColor: colors.surfaceContainerLow.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSubmitButton() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
            'AJOUTER AU STOCK',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
      ),
    );
  }

  Widget _buildTypeSegment({
    required _StockEntryType type,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigo.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.indigo.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildUnitToggleSegment({
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
