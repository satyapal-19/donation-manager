import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendOTP({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerify,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerify,
      verificationFailed: (FirebaseAuthException e) =>
          onError(e.message ?? e.code),
      codeSent: (String verificationId, int? resendToken) =>
          onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (String verificationId) {
        // We keep the last verificationId in the caller.
      },
    );
  }

  Future<UserCredential?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() ?? const {}, doc.id);
  }

  Future<bool> userExists(String uid) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    return doc.exists;
  }

  Future<void> createUserProfile(UserModel user) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: false));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

