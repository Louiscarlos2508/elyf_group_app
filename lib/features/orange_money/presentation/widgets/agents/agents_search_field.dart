import 'package:flutter/material.dart';

/// Champ de recherche pour les agents.
class AgentsSearchField extends StatelessWidget {
  const AgentsSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210.586,
      height: 36,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher (nom, tél, SIM)...',
          hintStyle: const TextStyle(color: Color(0xFF717182), fontSize: 14),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.search, size: 16, color: Color(0xFF717182)),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 16,
            minHeight: 16,
          ),
          filled: true,
          fillColor: const Color(0xFFF3F3F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}
