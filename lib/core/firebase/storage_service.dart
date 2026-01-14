import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Service pour gérer l'upload et le download de fichiers dans Firebase Storage.
///
/// Ce service gère :
/// - L'upload de fichiers avec organisation par entreprise/module
/// - Le download de fichiers
/// - La suppression de fichiers
/// - La gestion des métadonnées
class StorageService {
  StorageService({required this.storage});

  final FirebaseStorage storage;

  /// Construit le chemin de stockage avec enterpriseId et moduleId.
  ///
  /// Format : `enterprises/{enterpriseId}/modules/{moduleId}/files/{fileName}`
  /// Si moduleId est null : `enterprises/{enterpriseId}/files/{fileName}`
  String _buildStoragePath({
    required String fileName,
    required String enterpriseId,
    String? moduleId,
    String? subfolder,
  }) {
    final pathParts = <String>['enterprises', enterpriseId];

    if (moduleId != null && moduleId.isNotEmpty) {
      pathParts.addAll(['modules', moduleId]);
    }

    pathParts.add('files');

    if (subfolder != null && subfolder.isNotEmpty) {
      pathParts.add(subfolder);
    }

    pathParts.add(fileName);

    return pathParts.join('/');
  }

  /// Upload un fichier vers Firebase Storage.
  ///
  /// [file] : Le fichier à uploader (File ou Uint8List)
  /// [fileName] : Nom du fichier dans Storage
  /// [enterpriseId] : ID de l'entreprise
  /// [moduleId] : ID du module (optionnel)
  /// [subfolder] : Sous-dossier optionnel (ex: 'receipts', 'proofs')
  /// [contentType] : Type MIME du fichier (ex: 'image/jpeg', 'application/pdf')
  /// [metadata] : Métadonnées additionnelles
  Future<String> uploadFile({
    required dynamic file,
    required String fileName,
    required String enterpriseId,
    String? moduleId,
    String? subfolder,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final storagePath = _buildStoragePath(
        fileName: fileName,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        subfolder: subfolder,
      );

      final ref = storage.ref(storagePath);

      // Préparer les métadonnées
      final uploadMetadata = SettableMetadata(
        contentType: contentType,
        customMetadata: metadata,
      );

      UploadTask uploadTask;

      if (file is File) {
        // Upload depuis un fichier
        uploadTask = ref.putFile(file, uploadMetadata);
      } else if (file is List<int>) {
        // Upload depuis des bytes
        uploadTask = ref.putData(Uint8List.fromList(file), uploadMetadata);
      } else {
        throw ArgumentError('File must be File or List<int>');
      }

      // Suivre la progression
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress =
            taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        developer.log(
          'Upload progress: ${(progress * 100).toStringAsFixed(1)}%',
          name: 'storage.service',
        );
      });

      // Attendre la fin de l'upload
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      developer.log(
        'File uploaded successfully: $storagePath',
        name: 'storage.service',
      );

      return downloadUrl;
    } catch (e, stackTrace) {
      developer.log(
        'Error uploading file to Storage',
        name: 'storage.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Download un fichier depuis Firebase Storage.
  ///
  /// Retourne les bytes du fichier.
  Future<Uint8List> downloadFile({
    required String fileName,
    required String enterpriseId,
    String? moduleId,
    String? subfolder,
    int? maxSizeBytes,
  }) async {
    try {
      final storagePath = _buildStoragePath(
        fileName: fileName,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        subfolder: subfolder,
      );

      final ref = storage.ref(storagePath);

      Uint8List? data;
      if (maxSizeBytes != null) {
        data = await ref.getData(maxSizeBytes);
      } else {
        data = await ref.getData();
      }

      if (data == null) {
        throw Exception('Failed to download file: data is null');
      }

      return data;
    } catch (e, stackTrace) {
      developer.log(
        'Error downloading file from Storage',
        name: 'storage.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Download un fichier vers un fichier local.
  Future<File> downloadFileToLocal({
    required String fileName,
    required String enterpriseId,
    required File localFile,
    String? moduleId,
    String? subfolder,
  }) async {
    try {
      final storagePath = _buildStoragePath(
        fileName: fileName,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        subfolder: subfolder,
      );

      final ref = storage.ref(storagePath);
      await ref.writeToFile(localFile);

      developer.log(
        'File downloaded to: ${localFile.path}',
        name: 'storage.service',
      );

      return localFile;
    } catch (e, stackTrace) {
      developer.log(
        'Error downloading file to local',
        name: 'storage.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Récupère l'URL de téléchargement d'un fichier.
  Future<String> getDownloadUrl({
    required String fileName,
    required String enterpriseId,
    String? moduleId,
    String? subfolder,
  }) async {
    try {
      final storagePath = _buildStoragePath(
        fileName: fileName,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        subfolder: subfolder,
      );

      final ref = storage.ref(storagePath);
      return await ref.getDownloadURL();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting download URL',
        name: 'storage.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Supprime un fichier de Firebase Storage.
  Future<void> deleteFile({
    required String fileName,
    required String enterpriseId,
    String? moduleId,
    String? subfolder,
  }) async {
    try {
      final storagePath = _buildStoragePath(
        fileName: fileName,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        subfolder: subfolder,
      );

      final ref = storage.ref(storagePath);
      await ref.delete();

      developer.log('File deleted: $storagePath', name: 'storage.service');
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting file from Storage',
        name: 'storage.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Liste tous les fichiers d'un dossier.
  Future<List<Reference>> listFiles({
    required String enterpriseId,
    String? moduleId,
    String? subfolder,
    int? maxResults,
  }) async {
    try {
      final pathParts = <String>['enterprises', enterpriseId];

      if (moduleId != null && moduleId.isNotEmpty) {
        pathParts.addAll(['modules', moduleId]);
      }

      pathParts.add('files');

      if (subfolder != null && subfolder.isNotEmpty) {
        pathParts.add(subfolder);
      }

      final path = pathParts.join('/');
      final ref = storage.ref(path);

      final listOptions = maxResults != null
          ? ListOptions(maxResults: maxResults)
          : null;

      final listResult = await ref.list(listOptions);

      return listResult.items;
    } catch (e, stackTrace) {
      developer.log(
        'Error listing files',
        name: 'storage.service',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Récupère les métadonnées d'un fichier.
  Future<FullMetadata> getFileMetadata({
    required String fileName,
    required String enterpriseId,
    String? moduleId,
    String? subfolder,
  }) async {
    try {
      final storagePath = _buildStoragePath(
        fileName: fileName,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        subfolder: subfolder,
      );

      final ref = storage.ref(storagePath);
      return await ref.getMetadata();
    } catch (e, stackTrace) {
      developer.log(
        'Error getting file metadata',
        name: 'storage.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Met à jour les métadonnées d'un fichier.
  Future<void> updateFileMetadata({
    required String fileName,
    required String enterpriseId,
    String? moduleId,
    String? subfolder,
    Map<String, String>? customMetadata,
    String? contentType,
  }) async {
    try {
      final storagePath = _buildStoragePath(
        fileName: fileName,
        enterpriseId: enterpriseId,
        moduleId: moduleId,
        subfolder: subfolder,
      );

      final ref = storage.ref(storagePath);

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: customMetadata,
      );

      await ref.updateMetadata(metadata);

      developer.log(
        'File metadata updated: $storagePath',
        name: 'storage.service',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error updating file metadata',
        name: 'storage.service',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
