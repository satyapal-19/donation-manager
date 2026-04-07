import 'package:cloud_firestore/cloud_firestore.dart';

class IssueModel {
  final String id;
  final String userId;
  final String userName;
  final String donationName;
  final String description;
  final String status; // open / resolved
  final DateTime createdAt;

  const IssueModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.donationName,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory IssueModel.fromMap(Map<String, dynamic> map, String id) {
    final createdAtRaw = map['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : createdAtRaw is DateTime
            ? createdAtRaw
            : DateTime.now();

    return IssueModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      userName: (map['userName'] ?? '') as String,
      donationName: (map['donationName'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      status: (map['status'] ?? 'open') as String,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'donationName': donationName,
        'description': description,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

