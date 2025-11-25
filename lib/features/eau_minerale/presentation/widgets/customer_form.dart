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
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnibController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    // Basic validation: should start with + or 0 and have at least 8 digits
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'^(\+?[0-9]{8,})$').hasMatch(cleaned);
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
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
        const SnackBar(content: Text('Client enregistré avec succès')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person),
                helperText: 'Prénom et nom du client',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                if (v.trim().length < 2) return 'Nom trop court';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone),
                helperText: 'Numéro de téléphone (ex: +237 6XX XXX XXX)',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                if (!_isValidPhone(v)) {
                  return 'Format de téléphone invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cnibController,
              decoration: const InputDecoration(
                labelText: 'CNIB (optionnel)',
                prefixIcon: Icon(Icons.badge),
                helperText: 'Numéro de carte d\'identité nationale',
              ),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
      ),
    );
  }
}
