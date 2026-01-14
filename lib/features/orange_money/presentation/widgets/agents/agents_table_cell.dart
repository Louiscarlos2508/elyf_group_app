import 'package:flutter/material.dart';

/// Cellule de tableau pour les agents.
class AgentsTableCell {
  /// Construit un en-tête de colonne.
  static Widget buildHeader(
    String text,
    double width, {
    bool alignRight = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(left: 8, top: 9),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF0A0A0A),
        ),
      ),
    );
  }

  /// Construit une cellule de tableau.
  static Widget buildCell(
    dynamic content,
    double width, {
    bool alignRight = false,
    Color? color,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 8),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: content is Widget
              ? content
              : Text(
                  content.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: color ?? const Color(0xFF0A0A0A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ),
    );
  }
}
