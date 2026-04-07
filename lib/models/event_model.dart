import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final int dayNumber;
  final String time;
  final String title;
  final String maharajName;
  final String maharajLocation;
  final String? maharajPhotoUrl;
  final String? description;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.dayNumber,
    required this.time,
    required this.title,
    required this.maharajName,
    required this.maharajLocation,
    required this.maharajPhotoUrl,
    required this.description,
    required this.createdAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    final createdAtRaw = map['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : createdAtRaw is DateTime
            ? createdAtRaw
            : DateTime.now();

    final dayRaw = map['dayNumber'];
    final dayNumber = dayRaw is int
        ? dayRaw
        : dayRaw is num
            ? dayRaw.toInt()
            : 1;

    return EventModel(
      id: id,
      dayNumber: dayNumber,
      time: (map['time'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      maharajName: (map['maharajName'] ?? '') as String,
      maharajLocation: (map['maharajLocation'] ?? '') as String,
      maharajPhotoUrl: map['maharajPhotoUrl'] as String?,
      description: map['description'] as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'dayNumber': dayNumber,
        'time': time,
        'title': title,
        'maharajName': maharajName,
        'maharajLocation': maharajLocation,
        'maharajPhotoUrl': maharajPhotoUrl,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

