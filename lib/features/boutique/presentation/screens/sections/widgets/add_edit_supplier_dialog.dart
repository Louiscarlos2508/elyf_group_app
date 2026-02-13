import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/supplier.dart';
import '../../../../application/providers.dart';
import '../../../../../../core/tenant/tenant_provider.dart' show activeEnterpriseProvider;

class AddEditSupplierDialog extends StatefulWidget {
  final Supplier? supplier;

  const AddEditSupplierDialog({super.key, this.supplier});

  @override
  State<AddEditSupplierDialog> createState() => _AddEditSupplierDialogState();
}

class _AddEditSupplierDialogState extends State<AddEditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    _emailController = TextEditingController(text: widget.supplier?.email ?? '');
    _addressController = TextEditingController(text: widget.supplier?.address ?? '');
    _categoryController = TextEditingController(text: widget.supplier?.category ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplier != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier le fournisseur' : 'Nouveau fournisseur'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du fournisseur *'),
                validator: (value) => (value == null || value.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Catégorie (ex: Boissons, Divers)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        Consumer(builder: (context, ref, _) {
          return ElevatedButton(
            onPressed: () => _submit(ref),
            child: const Text('Enregistrer'),
          );
        }),
      ],
    );
  }

  Future<void> _submit(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    final enterpriseId = ref.read(activeEnterpriseProvider).value?.id ?? 'default';
    
    final supplier = (widget.supplier ?? Supplier(
      id: '',
      enterpriseId: enterpriseId,
      name: '',
    )).copyWith(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
      category: _categoryController.text,
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.supplier == null) {
        await ref.read(supplierRepositoryProvider).createSupplier(supplier.copyWith(createdAt: DateTime.now()));
      } else {
        await ref.read(supplierRepositoryProvider).updateSupplier(supplier);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}
