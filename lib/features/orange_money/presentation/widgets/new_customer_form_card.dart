import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:elyf_groupe_app/shared.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/services/customer_service.dart';
import 'new_customer_form/transaction_info_card.dart';
import 'new_customer_form/customer_name_fields.dart';
import 'new_customer_form/id_type_field.dart';

/// Widget pour afficher le formulaire d'enregistrement d'une nouvelle personne.
/// Affiche une carte avec les informations de transaction et un formulaire d'enregistrement.
class NewCustomerFormCard extends StatefulWidget {
  const NewCustomerFormCard({
    super.key,
    required this.phoneNumber,
    required this.amount,
    required this.type,
    this.existingCustomerName,
    this.onCancel,
    required this.onSave,
  });

  final String phoneNumber;
  final int amount;
  final TransactionType type;
  final String? existingCustomerName; // Si le client existe déjà
  final VoidCallback? onCancel;
  final Future<void> Function({
    required String firstName,
    required String lastName,
    required String idType,
    required String idNumber,
    DateTime? idIssueDate,
    DateTime? idExpiryDate,
  })
  onSave;

  @override
  State<NewCustomerFormCard> createState() => _NewCustomerFormCardState();
}

class _NewCustomerFormCardState extends State<NewCustomerFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();

  String _idType = "Carte Nationale d'Identité"; // Type de pièce sélectionné
  DateTime? _idIssueDate;
  DateTime? _idExpiryDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir le nom si le client existe déjà
    if (widget.existingCustomerName != null) {
      final parts = widget.existingCustomerName!.split(' ');
      if (parts.isNotEmpty) {
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        idType: _idType,
        idNumber: _idNumberController.text.trim(),
        idIssueDate: _idIssueDate,
        idExpiryDate: _idExpiryDate,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _idIssueDate = picked;
        } else {
          _idExpiryDate = picked;
        }
      });
    }
  }

  /// Affiche un dialog pour sélectionner le type de pièce d'identité.
  Future<String?> _showIdTypeDialog(BuildContext context) async {
    final idTypes = [
      "Carte Nationale d'Identité",
      "Passeport",
      "Permis de Conduire",
      "Carte de Séjour",
      "Carte Consulaire",
    ];

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Type de pièce d\'identité',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: idTypes.length,
            itemBuilder: (context, index) {
              final type = idTypes[index];
              final isSelected = type == _idType;
              
              return ListTile(
                title: Text(
                  type,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected 
                        ? const Color(0xFFF54900) 
                        : const Color(0xFF0A0A0A),
                    fontWeight: isSelected 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected 
                      ? const Color(0xFFF54900) 
                      : const Color(0xFF717182),
                  size: 20,
                ),
                onTap: () => Navigator.of(context).pop(type),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isKeyboardOpen ? 12 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.person_add_rounded,
                  size: isKeyboardOpen ? 18 : 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Enregistrement Client',
                  style: (isKeyboardOpen ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (!isKeyboardOpen) const SizedBox(height: 24),
            
            // Carte d'information transaction (masquée si clavier ouvert pour plus de place)
            if (!isKeyboardOpen) ...[
              TransactionInfoCard(
                phoneNumber: widget.phoneNumber,
                amount: widget.amount,
                type: widget.type,
              ),
              const SizedBox(height: 16),
            ] else 
              const SizedBox(height: 12),

            // Prénom et Nom
            Row(
              children: [
                Expanded(
                  child: ElyfField(
                    label: 'Prénom',
                    controller: _firstNameController,
                    hint: 'ex: Jean',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElyfField(
                    label: 'Nom',
                    controller: _lastNameController,
                    hint: 'ex: Dupont',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: isKeyboardOpen ? 16 : 24),
            _buildSectionHeader('Pièce d\'identité'),
            SizedBox(height: isKeyboardOpen ? 12 : 16),
            // Type de pièce d'identité
            IdTypeField(
              idType: _idType,
              onTap: () async {
                final selectedType = await _showIdTypeDialog(context);
                if (selectedType != null) {
                  setState(() {
                    _idType = selectedType;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Numéro de pièce
            ElyfField(
              label: 'Numéro de pièce',
              controller: _idNumberController,
              hint: 'Ex: CI123456789',
              prefixIcon: Icons.numbers_rounded,
              validator: CustomerService.validateIdNumber,
            ),
            const SizedBox(height: 16),
            // Dates
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: isKeyboardOpen ? 10 : 14
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date d\'émission', style: theme.textTheme.labelSmall),
                                Text(
                                  _idIssueDate != null ? DateFormat('dd/MM/yyyy').format(_idIssueDate!) : 'Sélectionner',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: _idIssueDate != null ? FontWeight.bold : FontWeight.normal,
                                    fontSize: isKeyboardOpen ? 12 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: isKeyboardOpen ? 10 : 14
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_busy, size: 18, color: theme.colorScheme.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date d\'expiration', style: theme.textTheme.labelSmall),
                                Text(
                                  _idExpiryDate != null ? DateFormat('dd/MM/yyyy').format(_idExpiryDate!) : 'Sélectionner',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: _idExpiryDate != null ? FontWeight.bold : FontWeight.normal,
                                    fontSize: isKeyboardOpen ? 12 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isKeyboardOpen ? 24 : 32),
            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: isKeyboardOpen ? 12 : 16),
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.symmetric(vertical: isKeyboardOpen ? 12 : 16),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: isKeyboardOpen ? 16 : 20),
                              const SizedBox(width: 8),
                              Text(
                                'Confirmer',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isKeyboardOpen ? 13 : 14
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
