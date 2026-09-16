import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:donation_manager/services/auth_service.dart';
import 'package:donation_manager/models/user_model.dart';

void main() {
  group('AuthService Error Mapping Tests', () {
    test('maps invalid-verification-code to Marathi user message', () {
      final ex = FirebaseAuthException(code: 'invalid-verification-code');
      final msg = AuthService.mapFirebaseError(ex);
      expect(msg, contains('चुकीचा OTP'));
    });

    test('maps session-expired to Marathi user message', () {
      final ex = FirebaseAuthException(code: 'session-expired');
      final msg = AuthService.mapFirebaseError(ex);
      expect(msg, contains('मुदत संपली'));
    });

    test('maps too-many-requests to Marathi user message', () {
      final ex = FirebaseAuthException(code: 'too-many-requests');
      final msg = AuthService.mapFirebaseError(ex);
      expect(msg, contains('तात्पुरता ब्लॉक'));
    });

    test('maps network-request-failed to Marathi user message', () {
      final ex = FirebaseAuthException(code: 'network-request-failed');
      final msg = AuthService.mapFirebaseError(ex);
      expect(msg, contains('इंटरनेट कनेक्शन'));
    });

    test('maps app-not-authorized to SHA-1 requirement message', () {
      final ex = FirebaseAuthException(code: 'app-not-authorized');
      final msg = AuthService.mapFirebaseError(ex);
      expect(msg, contains('SHA-1'));
    });
  });

  group('UserModel and Role Tests', () {
    test('creates regular devotee user correctly', () {
      final user = UserModel(
        uid: 'user-77',
        name: 'विठ्ठल भक्त',
        mobile: '9876543210',
        role: 'user',
        createdAt: DateTime(2026, 9, 15),
      );

      expect(user.isAdmin, isFalse);
      expect(user.mobile, '9876543210');
      final map = user.toMap();
      expect(map['role'], 'user');
      expect(map['name'], 'विठ्ठल भक्त');
    });

    test('creates committee admin user correctly', () {
      final admin = UserModel(
        uid: 'admin-1',
        name: 'सप्ताह अध्यक्ष',
        mobile: '9822334455',
        role: 'admin',
        createdAt: DateTime(2026, 9, 15),
      );

      expect(admin.isAdmin, isTrue);
      final fromMap = UserModel.fromMap(admin.toMap(), 'admin-1');
      expect(fromMap.isAdmin, isTrue);
      expect(fromMap.name, 'सप्ताह अध्यक्ष');
    });
  });
}
