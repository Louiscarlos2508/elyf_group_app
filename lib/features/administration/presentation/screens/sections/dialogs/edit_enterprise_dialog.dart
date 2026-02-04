import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../../../domain/entities/enterprise.dart';

/// Dialogue pour modifier une entreprise existante.
class EditEnterpriseDialog extends StatefulWidget {
  const EditEnterpriseDialog({super.key, required this.enterprise});

  final Enterprise enterprise;

  @override
  State<EditEnterpriseDialog> createState() => _EditEnterpriseDialogState();
}

class _EditEnterpriseDialogState extends State<EditEnterpriseDialog>
    with FormHelperMixin {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  late String _selectedType;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController(text: widget.enterprise.name);
    _descriptionController = TextEditingController(
      text: widget.enterprise.description ?? '',
    );
    _addressController = TextEditingController(
      text: widget.enterprise.address ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.enterprise.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.enterprise.email ?? '',
    );
    _selectedType = widget.enterprise.type;
    _isActive = widget.enterprise.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    await handleFormSubmit(
      context: context,
      formKey: _formKey,
      onLoadingChanged: (isLoading) => setState(() => _isLoading = isLoading),
      onSubmit: () async {
        final updatedEnterprise = widget.enterprise.copyWith(
          name: _nameController.text.trim(),
          type: _selectedType,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : (PhoneUtils.normalizeBurkina(_phoneController.text.trim()) ??
                  _phoneController.text.trim()),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          isActive: _isActive,
          updatedAt: DateTime.now(),
        );

        if (mounted) {
          Navigator.of(context).pop(updatedEnterprise);
        }

        return 'Entreprise modifiée avec succès';
      },
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return Validators.phoneBurkina(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight =
        screenHeight - keyboardHeight - (isMobile ? 60 : 100);
    final maxWidth = isMobile
        ? screenWidth * 0.95
        : (screenWidth * 0.9).clamp(320.0, 600.0);

    return Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: availableHeight.clamp(300.0, screenHeight * 0.9),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modifier l\'Entreprise',
                      style:
                          (isMobile
                                  ? theme.textTheme.titleLarge
                                  : theme.textTheme.headlineSmall)
                              ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.enterprise.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          hintText: 'Nom de l\'entreprise',
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
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(labelText: 'Type *'),
                        items: EnterpriseType.values.map((type) {
                          return DropdownMenuItem(
                            value: type.id,
                            child: Text(type.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Description de l\'entreprise',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse',
                          hintText: 'Adresse complète',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          hintText: '+226 70 00 00 00',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d\s\+]'),
                          ),
                        ],
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'contact@entreprise.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Entreprise active'),
                        subtitle: const Text(
                          'Les entreprises inactives ne sont pas accessibles',
                        ),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: isMobile
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Enregistrer'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Annuler'),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 16),
                          IntrinsicWidth(
                            child: FilledButton(
                              onPressed: _isLoading ? null : _handleSubmit,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Enregistrer'),
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
