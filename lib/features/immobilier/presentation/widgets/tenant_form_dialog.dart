import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../domain/entities/tenant.dart';
import 'package:elyf_groupe_app/shared.dart';

class TenantFormDialog extends ConsumerStatefulWidget {
  const TenantFormDialog({super.key, this.tenant});

  final Tenant? tenant;

  @override
  ConsumerState<TenantFormDialog> createState() => _TenantFormDialogState();
}

class _TenantFormDialogState extends ConsumerState<TenantFormDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.tenant != null) {
      final t = widget.tenant!;
      _fullNameController.text = t.fullName;
      _phoneController.text = t.phone;
      _emailController.text = t.email;
      _addressController.text = t.address ?? '';
      _idNumberController.text = t.idNumber ?? '';
      _emergencyContactController.text = t.emergencyContact ?? '';
      _notesController.text = t.notes ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _idNumberController.dispose();
    _emergencyContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged:
          (_) {}, // Pas besoin de gestion d'état de chargement séparée
      onSubmit: () async {
        final rawPhone = _phoneController.text.trim();
        final phone =
            PhoneUtils.normalizeBurkina(rawPhone) ?? rawPhone;
        final rawEmergency = _emergencyContactController.text.trim();
        final emergencyContact = rawEmergency.isEmpty
            ? null
            : (PhoneUtils.normalizeBurkina(rawEmergency) ?? rawEmergency);
        final tenant = Tenant(
          id: widget.tenant?.id ?? IdGenerator.generate(),
          fullName: _fullNameController.text.trim(),
          phone: phone,
          email: _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          idNumber: _idNumberController.text.trim().isEmpty
              ? null
              : _idNumberController.text.trim(),
          emergencyContact: emergencyContact,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: widget.tenant?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final controller = ref.read(tenantControllerProvider);
        if (widget.tenant == null) {
          await controller.createTenant(tenant);
        } else {
          await controller.updateTenant(tenant);
        }

        if (mounted) {
          ref.invalidate(tenantsProvider);
        }

        return widget.tenant == null
            ? 'Locataire créé avec succès'
            : 'Locataire mis à jour avec succès';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.tenant == null
          ? 'Nouveau locataire'
          : 'Modifier le locataire',
      saveLabel: widget.tenant == null ? 'Créer' : 'Enregistrer',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                hintText: 'Jean Kaboré',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone *',
                hintText: '+226 70 12 34 56',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => Validators.phoneBurkina(v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                hintText: 'jean.kabore@example.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'email est requis';
                }
                if (!value.contains('@')) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                hintText: '123 Rue de la Paix, Ouagadougou',
                prefixIcon: Icon(Icons.location_on),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _idNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de pièce d\'identité',
                hintText: 'CI-123456',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'Contact d\'urgence',
                hintText: '+226 76 12 34 56',
                prefixIcon: Icon(Icons.emergency),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Notes supplémentaires...',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
