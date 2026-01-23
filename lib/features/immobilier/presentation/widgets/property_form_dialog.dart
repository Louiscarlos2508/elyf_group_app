import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elyf_groupe_app/features/immobilier/application/providers.dart';
import '../../domain/entities/property.dart';
import '../../domain/services/property_validation_service.dart';
import 'package:elyf_groupe_app/shared.dart';

class PropertyFormDialog extends ConsumerStatefulWidget {
  const PropertyFormDialog({super.key, this.property});

  final Property? property;

  @override
  ConsumerState<PropertyFormDialog> createState() => _PropertyFormDialogState();
}

class _PropertyFormDialogState extends ConsumerState<PropertyFormDialog>
    with FormHelperMixin {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _roomsController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  PropertyType _selectedType = PropertyType.house;
  PropertyStatus _selectedStatus = PropertyStatus.available;

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      final p = widget.property!;
      _addressController.text = p.address;
      _cityController.text = p.city;
      _areaController.text = p.area.toString();
      _roomsController.text = p.rooms.toString();
      _priceController.text = p.price.toString();
      _descriptionController.text = p.description ?? '';
      _selectedType = p.propertyType;
      _selectedStatus = p.status;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _roomsController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged:
          (_) {}, // Pas besoin de gestion d'état de chargement séparée
      onSubmit: () async {
        final property = Property(
          id: widget.property?.id ?? IdGenerator.generate(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          propertyType: _selectedType,
          rooms: int.parse(_roomsController.text),
          area: int.parse(_areaController.text),
          price: int.parse(_priceController.text),
          status: _selectedStatus,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          createdAt: widget.property?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final controller = ref.read(propertyControllerProvider);
        if (widget.property == null) {
          await controller.createProperty(property);
        } else {
          await controller.updateProperty(property);
        }

        if (mounted) {
          ref.invalidate(propertiesProvider);
        }

        return widget.property == null
            ? 'Propriété créée avec succès'
            : 'Propriété mise à jour avec succès';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.property == null
          ? 'Nouvelle propriété'
          : 'Modifier la propriété',
      saveLabel: widget.property == null ? 'Créer' : 'Enregistrer',
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse *',
                hintText: '123 Rue de la Paix',
                prefixIcon: Icon(Icons.location_on),
              ),
              textCapitalization: TextCapitalization.words,
              validator: PropertyValidationService.validateAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Ville *',
                hintText: 'Ouagadougou',
                prefixIcon: Icon(Icons.location_city),
              ),
              textCapitalization: TextCapitalization.words,
              validator: PropertyValidationService.validateCity,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PropertyType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type de propriété *',
                prefixIcon: Icon(Icons.category),
              ),
              items: PropertyType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _roomsController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de pièces *',
                      prefixIcon: Icon(Icons.bed),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final rooms = value != null && value.isNotEmpty
                          ? int.tryParse(value)
                          : null;
                      return PropertyValidationService.validateRooms(rooms);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Surface (m²) *',
                      prefixIcon: Icon(Icons.square_foot),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final area = value != null && value.isNotEmpty
                          ? int.tryParse(value)
                          : null;
                      return PropertyValidationService.validateArea(area);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Loyer mensuel (FCFA) *',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final price = value != null && value.isNotEmpty
                    ? int.tryParse(value)
                    : null;
                return PropertyValidationService.validatePrice(price);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PropertyStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Statut *',
                prefixIcon: Icon(Icons.info_outline),
              ),
              items: PropertyStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusLabel(status)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedStatus = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description de la propriété...',
                prefixIcon: Icon(Icons.description),
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

  String _getTypeLabel(PropertyType type) {
    switch (type) {
      case PropertyType.house:
        return 'Maison';
      case PropertyType.apartment:
        return 'Appartement';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.commercial:
        return 'Commercial';
    }
  }

  String _getStatusLabel(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return 'Disponible';
      case PropertyStatus.rented:
        return 'Louée';
      case PropertyStatus.maintenance:
        return 'En maintenance';
      case PropertyStatus.sold:
        return 'Vendue';
    }
  }
}
