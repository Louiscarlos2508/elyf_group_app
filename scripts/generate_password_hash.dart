#!/usr/bin/env dart

/// Script utilitaire pour générer le hash d'un mot de passe.
/// 
/// Usage:
///   dart scripts/generate_password_hash.dart <password>
/// 
/// Exemple:
///   dart scripts/generate_password_hash.dart admin123
/// 
/// Le hash généré peut être utilisé dans le fichier .env comme valeur
/// pour ADMIN_PASSWORD_HASH.

import 'dart:io';
import 'package:elyf_groupe_app/core/auth/utils/password_hasher.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart scripts/generate_password_hash.dart <password>');
    print('');
    print('Exemple:');
    print('  dart scripts/generate_password_hash.dart admin123');
    exit(1);
  }

  final password = args[0];
  final hash = PasswordHasher.hashPassword(password);

  print('');
  print('Password hash generated successfully!');
  print('');
  print('Password: $password');
  print('Hash: $hash');
  print('');
  print('Add this to your .env file:');
  print('ADMIN_PASSWORD_HASH=$hash');
  print('');
}

