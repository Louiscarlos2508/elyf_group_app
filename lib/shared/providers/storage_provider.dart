import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/storage_service.dart';

/// Provider pour le service de stockage Firebase.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(storage: FirebaseStorage.instance);
});
