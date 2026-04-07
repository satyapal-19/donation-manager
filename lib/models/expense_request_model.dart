import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/app_constants.dart';

class ExpenseRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String name;
  final double amount;
  final String category;
  final String description;
  final String status;
  final DateTime timestamp;
  final String? imageUrl;

  final String? approvedByName;
  final DateTime? resolvedAt;
  final String? rejectionReason;

  const ExpenseRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.name,
    required this.amount,
    required this.category,
    required this.description,
    required this.status,
    required this.timestamp,
    this.imageUrl,
    this.approvedByName,
    this.resolvedAt,
    this.rejectionReason,
  });

  bool get isPending => status == AppConstants.statusPending;
  bool get isApproved => status == AppConstants.statusApproved;
  bool get isRejected => status == AppConstants.statusRejected;

  factory ExpenseRequestModel.fromMap(Map<String, dynamic> map, String id) {
    final timestampRaw = map['timestamp'];
    final timestamp = timestampRaw is Timestamp
        ? timestampRaw.toDate()
        : timestampRaw is DateTime
            ? timestampRaw
            : DateTime.now();

    final amountRaw = map['amount'];
    final amount = amountRaw is num ? amountRaw.toDouble() : 0.0;

    return ExpenseRequestModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      userName: (map['userName'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      amount: amount,
      category: (map['category'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      status: (map['status'] ?? AppConstants.statusPending) as String,
      timestamp: timestamp,
      imageUrl: map['imageUrl'] as String?,
      approvedByName: map['approvedByName'] as String?,
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'name': name,
        'amount': amount,
        'category': category,
        'description': description,
        'status': status,
        'timestamp': Timestamp.fromDate(timestamp),
        'imageUrl': imageUrl,
        'approvedByName': approvedByName,
        'resolvedAt': resolvedAt == null ? null : Timestamp.fromDate(resolvedAt!),
        'rejectionReason': rejectionReason,
      };
}

