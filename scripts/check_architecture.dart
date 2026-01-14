#!/usr/bin/env dart
// Script to check architecture rules using dependency_validator

import 'dart:io';

void main(List<String> args) async {
  print('🔍 Checking architecture rules...\n');

  // Run dependency_validator
  final result = await Process.run('dart', [
    'run',
    'dependency_validator',
  ], runInShell: true);

  print(result.stdout);

  if (result.stderr.isNotEmpty) {
    print('⚠️  Warnings:');
    print(result.stderr);
  }

  if (result.exitCode != 0) {
    print('\n❌ Architecture validation failed!');
    print('Please fix the dependency violations above.');
    exit(1);
  } else {
    print('\n✅ Architecture validation passed!');
    exit(0);
  }
}
