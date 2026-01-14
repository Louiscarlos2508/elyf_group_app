import 'package:flutter/material.dart';

/// Filtre par nom des agents.
class AgentsNameFilter extends StatelessWidget {
  const AgentsNameFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210.586,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1.219),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent, width: 1.219),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: const Text(
            'Nom',
            style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF0A0A0A),
          ),
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Nom',
                style: TextStyle(fontSize: 14, color: Color(0xFF0A0A0A)),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
