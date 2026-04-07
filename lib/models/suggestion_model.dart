import 'package:cloud_firestore/cloud_firestore.dart';

class SuggestionModel {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  const SuggestionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory SuggestionModel.fromMap(Map<String, dynamic> map, String id) {
    final createdAtRaw = map['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : createdAtRaw is DateTime
            ? createdAtRaw
            : DateTime.now();

    return SuggestionModel(
      id: id,
      userId: (map['userId'] ?? '') as String,
      userName: (map['userName'] ?? '') as String,
      text: (map['text'] ?? '') as String,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

