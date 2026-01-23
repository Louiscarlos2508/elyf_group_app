import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFBEDBFF), width: 1.219),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.person_add,
                    size: 20,
                    color: Color(0xFF0A0A0A),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Enregistrer une nouvelle personne',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Carte d'information transaction
              TransactionInfoCard(
                phoneNumber: widget.phoneNumber,
                amount: widget.amount,
                type: widget.type,
              ),
              const SizedBox(height: 16),
              // Prénom et Nom
              CustomerNameFields(
                firstNameController: _firstNameController,
                lastNameController: _lastNameController,
              ),
              const SizedBox(height: 16),
              // Type de pièce d'identité
              IdTypeField(
                idType: _idType,
                onTap: () async {
                  // ✅ TODO résolu: Show ID type selector dialog
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Numéro de pièce *',
                    style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _idNumberController,
                    decoration: InputDecoration(
                      hintText: 'Ex: CI123456789',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF717182),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF3F3F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    validator: CustomerService.validateIdNumber,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Date d'émission",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _idIssueDate != null
                                        ? DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_idIssueDate!)
                                        : '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _idIssueDate != null
                                          ? const Color(0xFF0A0A0A)
                                          : const Color(0xFF717182),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Color(0xFF717182),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Date d'expiration",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _idExpiryDate != null
                                        ? DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_idExpiryDate!)
                                        : '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _idExpiryDate != null
                                          ? const Color(0xFF0A0A0A)
                                          : const Color(0xFF717182),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Color(0xFF717182),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFE5E5E5),
                          width: 1.219,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF54900),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Enregistrer et valider',
                                  style: TextStyle(fontSize: 14),
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
      ),
    );
  }
}
