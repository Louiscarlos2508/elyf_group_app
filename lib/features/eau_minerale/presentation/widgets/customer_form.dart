import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';

/// Form for creating/editing a customer account.
class CustomerForm extends ConsumerStatefulWidget {
  const CustomerForm({super.key});

  @override
  ConsumerState<CustomerForm> createState() => CustomerFormState();
}

class CustomerFormState extends ConsumerState<CustomerForm> {
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
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(clientsControllerProvider).createCustomer(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        cnib: _cnibController.text.isEmpty ? null : _cnibController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(clientsStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client enregistré')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cnibController,
            decoration: const InputDecoration(
              labelText: 'CNIB (optionnel)',
              prefixIcon: Icon(Icons.badge),
            ),
          ),
        ],
      ),
    );
  }
}
