import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import 'package:elyf_groupe_app/features/eau_minerale/application/providers.dart';

/// Form for creating/editing a customer account.
class CustomerForm extends ConsumerStatefulWidget {
  const CustomerForm({super.key});

  @override
  ConsumerState<CustomerForm> createState() => CustomerFormState();
}

class CustomerFormState extends ConsumerState<CustomerForm>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnibController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnibController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (_) {},
      onSubmit: () async {
        final rawPhone = _phoneController.text.trim();
        final phone = PhoneUtils.normalizeBurkina(rawPhone) ?? rawPhone;
        await ref
            .read(clientsControllerProvider)
            .createCustomer(
              _nameController.text.trim(),
              phone,
              cnib: _cnibController.text.isEmpty
                  ? null
                  : _cnibController.text.trim(),
            );

        if (mounted) {
          Navigator.of(context).pop();
          ref.invalidate(clientsStateProvider);
        }

        return 'Client enregistré avec succès';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Informations Personnelles
            ElyfCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 24,
              backgroundColor: colors.surfaceContainerLow.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Informations Client',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: _buildInputDecoration(
                      label: 'Nom complet',
                      icon: Icons.badge_rounded,
                      hintText: 'Prénom et Nom',
                    ),
                    textCapitalization: TextCapitalization.words,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    validator: (v) => Validators.combine([
                      () => Validators.required(v),
                      () => Validators.minLength(v, 2, customMessage: 'Nom trop court'),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _buildInputDecoration(
                      label: 'Téléphone',
                      icon: Icons.phone_android_rounded,
                      hintText: '70 00 00 00',
                    ),
                    keyboardType: TextInputType.phone,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    validator: (v) => Validators.phoneBurkina(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section Administrative (Optionnel)
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
                      Icon(Icons.assignment_ind_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Détails Administratifs',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _cnibController,
                    decoration: _buildInputDecoration(
                      label: 'CNIB (Optionnel)',
                      icon: Icons.credit_card_rounded,
                      hintText: 'B1234567',
                    ),
                    keyboardType: TextInputType.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
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
        onPressed: submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'ENREGISTRER LE CLIENT',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ),
    );
  }
}
