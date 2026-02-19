import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';
import '../../../../core/tenant/tenant_provider.dart';
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
      final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';

      final worker = DailyWorker(
        id:
            widget.worker?.id ??
            'worker-${DateTime.now().millisecondsSinceEpoch}',
        enterpriseId: widget.worker?.enterpriseId ?? enterpriseId,
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
    final colors = theme.colorScheme;
    final isEditing = widget.worker != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ElyfCard(
          isGlass: false,
          backgroundColor: colors.surface,
          padding: EdgeInsets.zero,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with subtle gradient
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary.withValues(alpha: 0.1), colors.surface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Modifier l\'Ouvrier' : 'Nouvel Ouvrier',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Informations du personnel journalier',
                              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: _buildInputDecoration(
                            label: 'Nom complet *',
                            hintText: 'Ex: Jean Dupont',
                            icon: Icons.person_rounded,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => value?.trim().isEmpty ?? true ? 'Le nom est obligatoire' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          decoration: _buildInputDecoration(
                            label: 'Numéro de téléphone *',
                            hintText: 'Ex: 70 00 00 00',
                            icon: Icons.phone_rounded,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le numéro est obligatoire';
                            }
                            return Validators.phoneBurkina(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _salaireController,
                          decoration: _buildInputDecoration(
                            label: 'Salaire journalier (CFA) *',
                            hintText: 'Ex: 5000',
                            icon: Icons.payments_rounded,
                            suffixText: 'CFA',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Requis';
                            final salaire = int.tryParse(value);
                            if (salaire == null || salaire <= 0) return 'Montant invalide';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Actions
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildSubmitButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    String? suffixText,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      suffixText: suffixText,
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
      fillColor: colors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSubmitButton() {
    final colors = Theme.of(context).colorScheme;
    final isEditing = widget.worker != null;
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
          : Text(
            isEditing ? 'METTRE À JOUR' : 'AJOUTER L\'OUVRIER',
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
      ),
    );
  }
}
