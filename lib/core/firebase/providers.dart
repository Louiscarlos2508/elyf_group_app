import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'messaging_service.dart';

/// Provider for Firebase Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for a secondary Firebase Auth instance for administrative tasks
/// to avoid logging out the current admin during user creation.
final managementFirebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  // Not using FutureProvider here to simplify usage in other providers.
  // Initialization should be done in bootstrap or handled synchronously if already initialized.
  try {
    return FirebaseAuth.instanceFor(app: Firebase.app('ManagementApp'));
  } catch (e) {
    // If not initialized, it will throw. We should ideally initialize it in bootstrap.
    // For now, return default instance as fallback, but this is what we want to avoid.
    return FirebaseAuth.instance;
  }
});

/// Provider for Firebase Messaging instance
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

/// Provider for Messaging service
final messagingServiceProvider = Provider<MessagingService>((ref) {
  final messaging = ref.watch(firebaseMessagingProvider);
  return MessagingService(messaging: messaging);
});
