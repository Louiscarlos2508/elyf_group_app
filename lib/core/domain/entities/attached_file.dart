/// Représente un fichier joint (photo, PDF, etc.).
class AttachedFile {
  const AttachedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.size,
    this.uploadedAt,
  });

  final String id;
  final String name; // Nom du fichier
  final String path; // Chemin local ou URL (Firebase Storage)
  final AttachedFileType type; // Type de fichier
  final int? size; // Taille en bytes
  final DateTime? uploadedAt; // Date d'upload

  /// Vérifie si le fichier est une image
  bool get isImage => type == AttachedFileType.image;

  /// Vérifie si le fichier est un PDF
  bool get isPdf => type == AttachedFileType.pdf;

  /// Vérifie si le fichier est un document
  bool get isDocument => type == AttachedFileType.document;

  AttachedFile copyWith({
    String? id,
    String? name,
    String? path,
    AttachedFileType? type,
    int? size,
    DateTime? uploadedAt,
  }) {
    return AttachedFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}

/// Type de fichier joint.
enum AttachedFileType {
  image, // Photo/image
  pdf, // Document PDF
  document, // Autre document
}
