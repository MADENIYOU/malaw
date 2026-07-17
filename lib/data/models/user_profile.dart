import 'enums.dart';

class UserProfile {
  final String id;
  final String nom;
  final String telephone;
  final UserRole role;

  const UserProfile({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.role,
  });

  String get initials {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  UserProfile copyWith({UserRole? role}) => UserProfile(
    id: id,
    nom: nom,
    telephone: telephone,
    role: role ?? this.role,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'nom': nom,
    'telephone': telephone,
    'role': role.name,
  };

  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
    id: map['id'] as String,
    nom: map['nom'] as String,
    telephone: map['telephone'] as String,
    role: UserRole.values.byName(map['role'] as String),
  );
}
