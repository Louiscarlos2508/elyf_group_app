import 'package:intl/intl.dart';

/// A utility class to build thermal receipt strings with consistent formatting.
///
/// Supports 58mm (32 chars) and 80mm (48 chars) widths.
class ThermalReceiptBuilder {
  ThermalReceiptBuilder({this.width = 32});

  final int width;
  final StringBuffer _buffer = StringBuffer();

  /// Adds a plain line of text.
  void writeLine([String text = '']) {
    _buffer.writeln(text);
  }

  /// Adds a centered line of text.
  void center(String text) {
    if (text.isEmpty) {
      _buffer.writeln();
      return;
    }

    if (text.length >= width) {
      _buffer.writeln(text.substring(0, width));
      return;
    }

    final padding = (width - text.length) ~/ 2;
    _buffer.writeln(' ' * padding + text);
  }

  /// Adds a separator line (---).
  void separator([String char = '-']) {
    _buffer.writeln(char * width);
  }

  /// Adds a double separator line (===).
  void doubleSeparator() {
    separator('=');
  }

  /// Adds a dotted separator line (...).
  void dottedSeparator() {
    separator('.');
  }

  /// Adds a header section with a title.
  void header(String title, {String? subtitle}) {
    doubleSeparator();
    center(title.toUpperCase());
    if (subtitle != null) {
      center(subtitle);
    }
    doubleSeparator();
    writeLine();
  }

  /// Adds a key-value row (e.g., "Date: 12/02/2026").
  /// Results in "Key | Value" which SunmiV3Service can parse into printRow.
  void row(String key, String value) {
    _buffer.writeln('$key | $value');
  }

  /// Adds a table-like row for items.
  /// Results in "Col1 | Col2 | Col3" for SunmiV3Service.
  void itemRow(String name, String qtyAndPrice, String total) {
    _buffer.writeln('$name | $qtyAndPrice | $total');
  }

  /// Adds a section title with separators.
  void section(String title) {
    writeLine();
    separator('-');
    center(title.toUpperCase());
    separator('-');
  }

  /// Adds a total line with special formatting.
  void total(String label, String amount) {
    writeLine();
    doubleSeparator();
    // Use '|' so Sunmi service can align label left and amount right
    _buffer.writeln('${label.toUpperCase()} | $amount');
    doubleSeparator();
  }

  /// Adds a footer with a message and space for cut.
  void footer(String message) {
    writeLine();
    separator('-');
    center(message);
    separator('-');
    
    // Add 4 empty lines for paper cut
    for (int i = 0; i < 4; i++) {
      writeLine();
    }
  }

  /// Adds an empty line.
  void space([int count = 1]) {
    for (int i = 0; i < count; i++) {
      _buffer.writeln();
    }
  }

  /// Formats a currency value.
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} FCFA';
  }

  @override
  String toString() => _buffer.toString();
}
