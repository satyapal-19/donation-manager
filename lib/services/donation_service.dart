import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/donation_model.dart';
import '../utils/app_constants.dart';

class DonationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<DonationModel>> streamAllDonations() {
    return _db
        .collection(AppConstants.donationsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DonationModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<DonationModel>> streamUserDonations(String userId) {
    return _db
        .collection(AppConstants.donationsCollection)
        .where('addedByUid', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DonationModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> addDonation(
    DonationModel donation, {
    File? proofImage,
  }) async {
    final docRef = _db.collection(AppConstants.donationsCollection).doc();
    final donationId = docRef.id;

    String? proofImageUrl = donation.proofImageUrl;
    if (proofImage != null) {
      final fileName = proofImage.path.split(Platform.pathSeparator).last;
      final ref =
          _storage.ref().child('donation_proofs/${donationId}_$fileName');
      await ref.putFile(proofImage);
      proofImageUrl = await ref.getDownloadURL();
    }

    final finalDonation = donation.copyWith(
      id: donationId,
      proofImageUrl: proofImageUrl,
      createdAt: donation.createdAt,
    );

    await docRef.set(finalDonation.toMap());
  }

  Future<void> updateDonation(
    DonationModel donation, {
    File? newProofImage,
  }) async {
    if (donation.id.isEmpty) {
      throw ArgumentError('Donation id is missing.');
    }

    String? proofImageUrl = donation.proofImageUrl;
    if (newProofImage != null) {
      final fileName = newProofImage.path.split(Platform.pathSeparator).last;
      final ref =
          _storage.ref().child('donation_proofs/${donation.id}_$fileName');
      await ref.putFile(newProofImage);
      proofImageUrl = await ref.getDownloadURL();
    }

    final finalDonation = donation.copyWith(proofImageUrl: proofImageUrl);
    await _db
        .collection(AppConstants.donationsCollection)
        .doc(donation.id)
        .set(finalDonation.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteDonation(String donationId) async {
    await _db
        .collection(AppConstants.donationsCollection)
        .doc(donationId)
        .delete();
  }
}
