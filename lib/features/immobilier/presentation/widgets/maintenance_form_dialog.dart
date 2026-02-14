import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../core/offline/offline.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/tenant/tenant_provider.dart';
import '../../application/providers.dart';
import '../../domain/entities/maintenance_ticket.dart';
import '../../domain/entities/property.dart';
import 'maintenance_form_fields.dart';

class MaintenanceFormDialog extends ConsumerStatefulWidget {
  const MaintenanceFormDialog({
    super.key,
    this.ticket,
    this.initialProperty,
    this.onDelete,
  });

  final MaintenanceTicket? ticket;
  final Property? initialProperty;
  final VoidCallback? onDelete;

  @override
  ConsumerState<MaintenanceFormDialog> createState() => _MaintenanceFormDialogState();
}

class _MaintenanceFormDialogState extends ConsumerState<MaintenanceFormDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  Property? _selectedProperty;
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  MaintenancePriority _priority = MaintenancePriority.medium;
  MaintenanceStatus _status = MaintenanceStatus.open;
  List<String> _photos = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.ticket != null) {
      final t = widget.ticket!;
      _selectedProperty = null; // Will need to find property by ID if we want to pre-select, or just rely on ID match in the list
      _descriptionController.text = t.description;
      _costController.text = t.cost?.toString() ?? '';
      _priority = t.priority;
      _status = t.status;
      _photos = List.from(t.photos ?? []);
    } else if (widget.initialProperty != null) {
      _selectedProperty = widget.initialProperty;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  // Helper to find initial property object from list if editing
  void _findInitialProperty(List<Property> properties) {
    if (_selectedProperty == null && widget.ticket != null) {
      final propertyId = widget.ticket!.propertyId;
      try {
        _selectedProperty = properties.firstWhere((p) => p.id == propertyId);
      } catch (_) {
        // Property might have been deleted
      }
    }
  }

  Future<void> _save() async {
    if (_selectedProperty == null) {
      NotificationService.showWarning(context, 'Veuillez sélectionner une propriété');
      return;
    }

    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isSaving = isLoading),
      onSubmit: () async {
        final enterpriseId = ref.read(activeEnterpriseIdProvider).value ?? 'default';
        
        // Find active tenant for this property if not already set
        String? tenantId = widget.ticket?.tenantId;
        if (tenantId == null && _selectedProperty != null) {
          final activeLease = await ref.read(contractControllerProvider)
              .getActiveContractForProperty(_selectedProperty!.id);
          tenantId = activeLease?.tenantId;
        }

        final ticket = MaintenanceTicket(
          id: widget.ticket?.id ?? LocalIdGenerator.generate(),
          enterpriseId: enterpriseId,
          propertyId: _selectedProperty!.id,
          tenantId: tenantId,
          description: _descriptionController.text.trim(),
          priority: _priority,
          status: _status,
          photos: _photos,
          cost: double.tryParse(_costController.text),
          createdAt: widget.ticket?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final controller = ref.read(maintenanceControllerProvider);
        try {
          if (widget.ticket == null) {
            await controller.createTicket(ticket);
          } else {
            await controller.updateTicket(ticket);
          }

          if (mounted) {
            ref.invalidate(maintenanceTicketsProvider);
            Navigator.of(context).pop();
          }

          return widget.ticket == null
              ? 'Ticket créé avec succès'
              : 'Ticket mis à jour avec succès';
        } catch (error, stackTrace) {
           final appError = ErrorHandler.instance.handleError(error, stackTrace);
           throw appError.message;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return FormDialog(
      title: widget.ticket == null ? 'Nouveau Ticket' : 'Modifier le Ticket',
      saveLabel: 'Enregistrer',
      onSave: _isSaving ? null : _save,
      isLoading: _isSaving,
      customAction: widget.ticket != null && widget.onDelete != null
          ? IconButton(
              icon: Icon(widget.ticket!.deletedAt != null 
                  ? Icons.restore_from_trash 
                  : Icons.archive_outlined),
              onPressed: () {
                // Determine if archived or active to show correct confirmation in parent?
                // Actually the callback passed from screen already handles the confirmation dialog.
                // But wait, the screen's callback shows a dialog.
                // If I call it here, it will show a dialog on top of this dialog.
                // That's fine.
                // BUT, if I archive it, I probably want to close THIS dialog too.
                // The screen callback does NOT close this dialog (it assumes this dialog is closed or it's called from a list).
                
                // Let's look at MaintenanceScreen logic again.
                // It calls `showDialog` for MaintenanceFormDialog.
                // And passes `onDelete: () => _deleteTicket(ticket)`.
                // `_deleteTicket` shows a confirmation dialog.
                // If confirmed, it calls controller and invalidates.
                // It does NOT pop the FormDialog.
                
                // So I should pop this dialog first, then call onDelete.
                Navigator.of(context).pop();
                widget.onDelete?.call();
              },
              tooltip: widget.ticket!.deletedAt != null ? 'Restaurer' : 'Archiver',
              color: widget.ticket!.deletedAt != null ? Colors.green : Theme.of(context).colorScheme.error,
            )
          : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            propertiesAsync.when(
              data: (properties) {
                _findInitialProperty(properties);
                return MaintenanceFormFields.propertyField(
                  selectedProperty: _selectedProperty,
                  properties: properties,
                  onChanged: (value) => setState(() => _selectedProperty = value),
                  validator: (value) => value == null ? 'La propriété est requise' : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement des propriétés'),
            ),
            const SizedBox(height: 16),
            MaintenanceFormFields.priorityField(
              value: _priority,
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 16),
            MaintenanceFormFields.statusField(
              value: _status,
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 16),
            MaintenanceFormFields.descriptionField(
              controller: _descriptionController,
            ),
            const SizedBox(height: 16),
            MaintenanceFormFields.costField(
              controller: _costController,
            ),
            const SizedBox(height: 16),
            FormImagePicker(
              initialImagePath: _photos.isNotEmpty ? _photos.first : null,
              label: 'Photo du problème',
              onImageSelected: (file) {
                setState(() {
                  _photos = file != null ? [file.path] : [];
                });
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
