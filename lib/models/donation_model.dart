import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String id;
  final String donorName;
  final String village;
  final double amount;
  final String type;
  final String purpose;
  final String? proofImageUrl;
  final String addedByUid;
  final String addedByName;
  final DateTime createdAt;
  final String? itemDescription;

  const DonationModel({
    required this.id,
    required this.donorName,
    required this.village,
    required this.amount,
    required this.type,
    required this.purpose,
    required this.proofImageUrl,
    required this.addedByUid,
    required this.addedByName,
    required this.createdAt,
    required this.itemDescription,
  });

  DonationModel copyWith({
    String? id,
    String? donorName,
    String? village,
    double? amount,
    String? type,
    String? purpose,
    String? proofImageUrl,
    String? addedByUid,
    String? addedByName,
    DateTime? createdAt,
    String? itemDescription,
  }) {
    return DonationModel(
      id: id ?? this.id,
      donorName: donorName ?? this.donorName,
      village: village ?? this.village,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      purpose: purpose ?? this.purpose,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      addedByUid: addedByUid ?? this.addedByUid,
      addedByName: addedByName ?? this.addedByName,
      createdAt: createdAt ?? this.createdAt,
      itemDescription: itemDescription ?? this.itemDescription,
    );
  }

  factory DonationModel.fromMap(Map<String, dynamic> map, String id) {
    final createdAtRaw = map['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : createdAtRaw is DateTime
            ? createdAtRaw
            : DateTime.now();

    final amountRaw = map['amount'];
    final amount = amountRaw is num ? amountRaw.toDouble() : 0.0;

    return DonationModel(
      id: id,
      donorName: (map['donorName'] ?? '') as String,
      village: (map['village'] ?? '') as String,
      amount: amount,
      type: (map['type'] ?? '') as String,
      purpose: (map['purpose'] ?? '') as String,
      proofImageUrl: map['proofImageUrl'] as String?,
      addedByUid: (map['addedByUid'] ?? '') as String,
      addedByName: (map['addedByName'] ?? '') as String,
      createdAt: createdAt,
      itemDescription: map['itemDescription'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'donorName': donorName,
        'village': village,
        'amount': amount,
        'type': type,
        'purpose': purpose,
        'proofImageUrl': proofImageUrl,
        'addedByUid': addedByUid,
        'addedByName': addedByName,
        'createdAt': Timestamp.fromDate(createdAt),
        'itemDescription': itemDescription,
      };
}

