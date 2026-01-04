// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? department;
  final String role; // "admin" or "user"
  final String? photoUrl;
  final DateTime joinedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.department,
    this.role = 'user',
    this.photoUrl,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'department': department,
        'role': role,
        'photoUrl': photoUrl,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      department: map['department'],
      role: map['role'] ?? 'user',
      photoUrl: map['photoUrl'],
      joinedAt: map.containsKey('joinedAt')
          ? DateTime.tryParse(map['joinedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
