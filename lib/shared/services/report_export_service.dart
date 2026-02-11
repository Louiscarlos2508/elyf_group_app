import 'package:intl/intl.dart';

/// Shared utility for exporting data to CSV format.
class ReportExportService {
  const ReportExportService();

  /// Exports a list of rows to a CSV string.
  /// 
  /// [headers] is the first row of the CSV.
  /// [rows] is a list of lists, where each inner list is a row.
  String exportToCsv({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    final buffer = StringBuffer();

    // Headers
    buffer.writeln(headers.map(_escapeCsvField).join(','));

    // Data rows
    for (final row in rows) {
      buffer.writeln(row.map((field) => _escapeCsvField(field.toString())).join(','));
    }

    return buffer.toString();
  }

  /// Generates a standardized filename for reports.
  String generateFilename({
    required String prefix,
    required String extension,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final dateSuffix = DateFormat('yyyyMMdd').format(now);
    
    if (startDate != null && endDate != null) {
      final startStr = DateFormat('yyyyMMdd').format(startDate);
      final endStr = DateFormat('yyyyMMdd').format(endDate);
      return '${prefix}_${startStr}_${endStr}_$dateSuffix.$extension';
    }
    
    return '${prefix}_$dateSuffix.$extension';
  }

  /// Escapes a CSV field value.
  String _escapeCsvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
