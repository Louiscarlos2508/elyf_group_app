import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Représente un utilisateur du système avec toutes ses informations.
class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.email,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Identifiant unique de l'utilisateur (Firebase Auth UID en production)
  final String id;

  /// Prénom de l'utilisateur
  final String firstName;

  /// Nom de famille de l'utilisateur
  final String lastName;

  /// Nom d'utilisateur (unique)
  final String username;

  /// Email de l'utilisateur (optionnel)
  final String? email;

  /// Téléphone de l'utilisateur (optionnel)
  final String? phone;

  /// Indique si l'utilisateur est actif
  final bool isActive;

  /// Date de création du compte
  final DateTime? createdAt;

  /// Date de dernière mise à jour
  final DateTime? updatedAt;

  /// Nom complet de l'utilisateur
  String get fullName => '$firstName $lastName';

  /// Crée une copie avec des champs modifiés
  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'phone': phone,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Crée depuis un Map Firestore
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      username: map['username'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, fullName: $fullName, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Convertit un timestamp Firestore (Timestamp ou String) en DateTime
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (timestamp is String) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }
}
