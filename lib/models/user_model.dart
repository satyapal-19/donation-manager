import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String mobile;
  final String role;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.mobile,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final createdAtRaw = map['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : createdAtRaw is DateTime
            ? createdAtRaw
            : DateTime.now();

    return UserModel(
      uid: uid,
      name: (map['name'] ?? '') as String,
      mobile: (map['mobile'] ?? '') as String,
      role: (map['role'] ?? 'user') as String,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'mobile': mobile,
        'role': role,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
