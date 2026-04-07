import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String name;
  final double amount;
  final String category;
  final DateTime date;
  final String? requestId;
  final String addedByUid;
  final String addedByName;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    this.requestId,
    required this.addedByUid,
    required this.addedByName,
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    final dateRaw = map['date'];
    final date = dateRaw is Timestamp
        ? dateRaw.toDate()
        : dateRaw is DateTime
            ? dateRaw
            : DateTime.now();

    final createdAtRaw = map['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : createdAtRaw is DateTime
            ? createdAtRaw
            : DateTime.now();

    final amountRaw = map['amount'];
    final amount = amountRaw is num ? amountRaw.toDouble() : 0.0;

    return ExpenseModel(
      id: id,
      name: (map['name'] ?? '') as String,
      amount: amount,
      category: (map['category'] ?? '') as String,
      date: date,
      requestId: map['requestId'] as String?,
      addedByUid: (map['addedByUid'] ?? '') as String,
      addedByName: (map['addedByName'] ?? '') as String,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
        'requestId': requestId,
        'addedByUid': addedByUid,
        'addedByName': addedByName,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

