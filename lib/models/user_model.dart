import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_constants.dart';

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

  bool get isAdmin => role == 'admin' || AppConstants.isDefaultAdmin(mobile);

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final createdAtRaw = map['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : createdAtRaw is DateTime
            ? createdAtRaw
            : DateTime.now();

    final mobile = (map['mobile'] ?? '') as String;
    final rawRole = (map['role'] ?? 'user') as String;
    final role = AppConstants.isDefaultAdmin(mobile) ? 'admin' : rawRole;

    return UserModel(
      uid: uid,
      name: (map['name'] ?? '') as String,
      mobile: mobile,
      role: role,
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
