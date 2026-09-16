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

  Future<bool> isUtrAlreadyUsed(String utr) async {
    final cleaned = utr.trim();
    if (cleaned.isEmpty) return false;
    final snap = await _db
        .collection(AppConstants.donationsCollection)
        .where('utrNumber', isEqualTo: cleaned)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> addDonation(
    DonationModel donation, {
    File? proofImage,
  }) async {
    if (donation.utrNumber != null && donation.utrNumber!.trim().isNotEmpty) {
      final exists = await isUtrAlreadyUsed(donation.utrNumber!.trim());
      if (exists) {
        throw ArgumentError('हा UTR क्रमांक आधीच नोंदवला गेला आहे!');
      }
    }

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

  Future<void> verifyDonation({
    required String donationId,
    required String adminUid,
    required String adminName,
  }) async {
    await _db.collection(AppConstants.donationsCollection).doc(donationId).update({
      'paymentStatus': AppConstants.paymentStatusVerified,
      'verifiedByUid': adminUid,
      'verifiedByName': adminName,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
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
