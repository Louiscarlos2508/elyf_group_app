import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget for ID issue and expiry date fields.
class IdDateFields extends StatelessWidget {
  const IdDateFields({
    super.key,
    required this.issueDate,
    required this.expiryDate,
    required this.onIssueDateTap,
    required this.onExpiryDateTap,
  });

  final DateTime? issueDate;
  final DateTime? expiryDate;
  final VoidCallback onIssueDateTap;
  final VoidCallback onExpiryDateTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Date d'émission",
                style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: onIssueDateTap,
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
                          issueDate != null
                              ? DateFormat('dd/MM/yyyy').format(issueDate!)
                              : '',
                          style: TextStyle(
                            fontSize: 14,
                            color: issueDate != null
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
                style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: onExpiryDateTap,
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
                          expiryDate != null
                              ? DateFormat('dd/MM/yyyy').format(expiryDate!)
                              : '',
                          style: TextStyle(
                            fontSize: 14,
                            color: expiryDate != null
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
    );
  }
}
