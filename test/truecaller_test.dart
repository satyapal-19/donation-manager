import 'package:flutter_test/flutter_test.dart';
import 'package:donation_manager/services/truecaller_service.dart';

void main() {
  group('TruecallerProfile Tests', () {
    test('displayName returns full name when first and last are provided', () {
      const profile = TruecallerProfile(
        phoneNumber: '9876543210',
        firstName: 'विठ्ठल',
        lastName: 'पाटील',
      );
      expect(profile.displayName, 'विठ्ठल पाटील');
      expect(profile.phoneNumber, '9876543210');
    });

    test('displayName returns first name when last name is empty', () {
      const profile = TruecallerProfile(
        phoneNumber: '9876543210',
        firstName: 'तुकाराम',
        lastName: '',
      );
      expect(profile.displayName, 'तुकाराम');
    });

    test('displayName returns default वारकरी when names are blank', () {
      const profile = TruecallerProfile(
        phoneNumber: '9876543210',
        firstName: '   ',
        lastName: '',
      );
      expect(profile.displayName, 'वारकरी');
    });
  });
}
