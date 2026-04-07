import 'package:cloud_firestore/cloud_firestore.dart';

class MahaprasadModel {
  final String id;
  final DateTime date;
  final String menuText;
  final String? imageUrl;

  final String updatedByUid;
  final String updatedByName;
  final DateTime createdAt;

  const MahaprasadModel({
    required this.id,
    required this.date,
    required this.menuText,
    this.imageUrl,
    required this.updatedByUid,
    required this.updatedByName,
    required this.createdAt,
  });

  factory MahaprasadModel.fromMap(Map<String, dynamic> map, String id) {
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

    return MahaprasadModel(
      id: id,
      date: date,
      menuText: (map['menuText'] ?? '') as String,
      imageUrl: map['imageUrl'] as String?,
      updatedByUid: (map['updatedByUid'] ?? '') as String,
      updatedByName: (map['updatedByName'] ?? '') as String,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'menuText': menuText,
        'imageUrl': imageUrl,
        'updatedByUid': updatedByUid,
        'updatedByName': updatedByName,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

