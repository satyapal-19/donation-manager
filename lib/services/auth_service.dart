import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendOTP({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerify,
    int? forceResendingToken,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
        verificationCompleted: onAutoVerify,
        verificationFailed: (FirebaseAuthException e) =>
            onError(mapFirebaseError(e)),
        codeSent: (String verificationId, int? resendToken) =>
            onCodeSent(verificationId, resendToken),
        codeAutoRetrievalTimeout: (String verificationId) {
          // We keep the last verificationId in the caller.
        },
      );
    } catch (e) {
      onError('OTP पाठवताना अडचण आली: $e');
    }
  }

  static String mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'कृपया वैध १० अंकी मोबाईल नंबर टाका.';
      case 'invalid-verification-code':
        return 'चुकीचा OTP टाकला आहे. कृपया तपासा.';
      case 'session-expired':
        return 'OTP ची मुदत संपली आहे. कृपया पुन्हा OTP मागवा.';
      case 'too-many-requests':
        return 'वारंवार प्रयत्न केल्यामुळे तात्पुरता ब्लॉक झाला आहे. कृपया काही वेळानंतर प्रयत्न करा.';
      case 'network-request-failed':
        return 'इंटरनेट कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';
      case 'app-not-authorized':
        return 'अॅप Firebase प्रमाणीकरणासाठी अधिकृत नाही (SHA-1 fingerprint आवश्यक आहे).';
      case 'quota-exceeded':
        return 'SMS मर्यादा संपली आहे. कृपया नंतर प्रयत्न करा.';
      case 'operation-not-allowed':
        return 'Firebase Console मध्ये Phone Authentication सुरू केलेले नाही.';
      default:
        return e.message ?? 'प्रमाणीकरण अयशस्वी झाले (${e.code}).';
    }
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

  Future<UserModel> signInWithTruecallerProfile({
    required String phoneNumber,
    required String name,
  }) async {
    final userCredential = await _auth.signInAnonymously();
    final uid = userCredential.user!.uid;

    final query = await _db
        .collection(AppConstants.usersCollection)
        .where('mobile', isEqualTo: phoneNumber)
        .limit(1)
        .get();

    UserModel userModel;
    if (query.docs.isNotEmpty) {
      final existingDoc = query.docs.first;
      final existingData = existingDoc.data();
      userModel = UserModel(
        uid: uid,
        name: (existingData['name'] as String?)?.isNotEmpty == true
            ? (existingData['name'] as String)
            : (name.isNotEmpty ? name : 'वारकरी'),
        mobile: phoneNumber,
        role: (existingData['role'] as String?) ?? 'user',
        createdAt: (existingData['createdAt'] is Timestamp)
            ? (existingData['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } else {
      userModel = UserModel(
        uid: uid,
        name: name.isNotEmpty ? name : 'वारकरी',
        mobile: phoneNumber,
        role: 'user',
        createdAt: DateTime.now(),
      );
    }

    await createUserProfile(userModel);
    return userModel;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

