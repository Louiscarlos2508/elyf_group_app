import 'dart:convert';

import 'package:intl/intl.dart';

import '../entities/audit_log.dart';

/// Service for exporting audit logs to various formats.
class AuditExportService {
  /// Exports audit logs to CSV format.
  ///
  /// Returns a CSV string with headers and data rows.
  String exportToCsv(List<AuditLog> logs) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // CSV Headers
    buffer.writeln(
      'ID,Date,Action,Type Entité,ID Entité,Utilisateur,'
      'Description,Module,Entreprise',
    );

    // Data rows
    for (final log in logs) {
      final row = [
        _escapeCsvField(log.id),
        dateFormat.format(log.timestamp),
        _escapeCsvField(_getActionLabel(log.action)),
        _escapeCsvField(log.entityType),
        _escapeCsvField(log.entityId),
        _escapeCsvField(log.userId),
        _escapeCsvField(log.description ?? ''),
        _escapeCsvField(log.moduleId ?? ''),
        _escapeCsvField(log.enterpriseId ?? ''),
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Exports audit logs to JSON format.
  ///
  /// Returns a formatted JSON string.
  String exportToJson(List<AuditLog> logs) {
    final data = logs.map((log) => log.toMap()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// Generates a filename for the export.
  ///
  /// Format: audit_logs_YYYY-MM-DD_HH-mm.{extension}
  String generateFilename(String extension) {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd_HH-mm');
    return 'audit_logs_${dateFormat.format(now)}.$extension';
  }

  /// Escapes a CSV field value.
  ///
  /// Wraps the value in quotes if it contains special characters.
  String _escapeCsvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Gets a human-readable label for an audit action.
  String _getActionLabel(AuditAction action) {
    switch (action) {
      case AuditAction.create:
        return 'Création';
      case AuditAction.update:
        return 'Modification';
      case AuditAction.delete:
        return 'Suppression';
      case AuditAction.assign:
        return 'Assignation';
      case AuditAction.unassign:
        return 'Désassignation';
      case AuditAction.activate:
        return 'Activation';
      case AuditAction.deactivate:
        return 'Désactivation';
      case AuditAction.permissionChange:
        return 'Changement de permissions';
      case AuditAction.roleChange:
        return 'Changement de rôle';
      case AuditAction.unknown:
        return 'Action inconnue';
    }
  }
}
