import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../domain/entities/daily_worker.dart';

/// Dialog pour ajouter ou modifier un ouvrier journalier.
class DailyWorkerFormDialog extends ConsumerStatefulWidget {
  const DailyWorkerFormDialog({super.key, this.worker});

  final DailyWorker? worker;

  @override
  ConsumerState<DailyWorkerFormDialog> createState() =>
      _DailyWorkerFormDialogState();
}

class _DailyWorkerFormDialogState extends ConsumerState<DailyWorkerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaireController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      _nameController.text = widget.worker!.name;
      _phoneController.text = widget.worker!.phone;
      _salaireController.text = widget.worker!.salaireJournalier.toString();
    } else {
      // Valeur par défaut pour le salaire journalier
      _salaireController.text = '5000';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaireController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phoneRaw = _phoneController.text.trim();
    final phone = PhoneUtils.normalizeBurkina(phoneRaw) ?? phoneRaw;
    final salaire = int.tryParse(_salaireController.text);

    if (salaire == null || salaire <= 0) {
      NotificationService.showWarning(context, 'Salaire journalier invalide');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(dailyWorkerRepositoryProvider);

      final worker = DailyWorker(
        id:
            widget.worker?.id ??
            'worker-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phone: phone,
        salaireJournalier: salaire,
        joursTravailles: widget.worker?.joursTravailles ?? const [],
        createdAt: widget.worker?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.worker == null) {
        await repository.createWorker(worker);
        if (mounted) {
          NotificationService.showSuccess(
            context,
            'Ouvrier ajouté avec succès',
          );
        }
      } else {
        await repository.updateWorker(worker);
        if (mounted) {
          NotificationService.showSuccess(
            context,
            'Ouvrier mis à jour avec succès',
          );
        }
      }

      // Invalider le provider pour rafraîchir la liste
      ref.invalidate(allDailyWorkersProvider);

      if (mounted) {
        Navigator.of(context).pop(worker);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, e.toString());
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
    final isEditing = widget.worker != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? 'Modifier l\'ouvrier' : 'Nouvel ouvrier',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Formulaire
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nom
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom complet *',
                          hintText: 'Ex: Jean Dupont',
                          prefixIcon: Icon(Icons.person),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Téléphone
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone *',
                          hintText: '+226 70 00 00 00',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le numéro de téléphone est obligatoire';
                          }
                          return Validators.phoneBurkina(value);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Salaire journalier
                      TextFormField(
                        controller: _salaireController,
                        decoration: const InputDecoration(
                          labelText: 'Salaire journalier (CFA) *',
                          hintText: 'Ex: 5000',
                          prefixIcon: Icon(Icons.attach_money),
                          helperText: 'Montant en francs CFA par jour',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le salaire journalier est obligatoire';
                          }
                          final salaire = int.tryParse(value);
                          if (salaire == null || salaire <= 0) {
                            return 'Montant invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Boutons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isEditing ? 'Modifier' : 'Ajouter'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
