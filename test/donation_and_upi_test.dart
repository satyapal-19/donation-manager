import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:donation_manager/models/donation_model.dart';
import 'package:donation_manager/widgets/upi_qr_dialog.dart';

void main() {
  group('DonationModel Tests', () {
    test('serializes and deserializes donorPhone correctly', () {
      final now = DateTime(2026, 9, 15, 10, 0);
      final donation = DonationModel(
        id: 'don-123',
        donorName: 'Santosh Shinde',
        village: 'चिंचोली-भोसे',
        amount: 2100,
        type: 'रोख',
        purpose: 'धर्मकार्य',
        proofImageUrl: null,
        addedByUid: 'uid-admin',
        addedByName: 'Admin',
        createdAt: now,
        itemDescription: null,
        donorPhone: '9876543210',
      );

      final map = donation.toMap();
      expect(map['donorName'], 'Santosh Shinde');
      expect(map['village'], 'चिंचोली-भोसे');
      expect(map['amount'], 2100.0);
      expect(map['donorPhone'], '9876543210');

      final fromMap = DonationModel.fromMap(map, 'don-123');
      expect(fromMap.id, 'don-123');
      expect(fromMap.donorName, 'Santosh Shinde');
      expect(fromMap.donorPhone, '9876543210');
      expect(fromMap.amount, 2100);
    });

    test('backward compatibility when donorPhone is missing', () {
      final map = {
        'donorName': 'Tukaram Maharaj',
        'village': 'देहू',
        'amount': 5001,
        'type': 'ऑनलाइन',
        'purpose': 'महाप्रसाद',
        'proofImageUrl': null,
        'addedByUid': 'uid-1',
        'addedByName': 'User',
        'createdAt': DateTime(2026, 9, 15),
      };

      final fromMap = DonationModel.fromMap(map, 'don-456');
      expect(fromMap.donorPhone, isNull);
      expect(fromMap.donorName, 'Tukaram Maharaj');
    });

    test('copyWith updates donorPhone properly', () {
      final donation = DonationModel(
        id: 'don-1',
        donorName: 'Namdev',
        village: 'पंढरपूर',
        amount: 1001,
        type: 'रोख',
        purpose: 'भजने',
        proofImageUrl: null,
        addedByUid: 'uid-1',
        addedByName: 'Admin',
        createdAt: DateTime(2026, 9, 15),
        itemDescription: null,
      );

      expect(donation.donorPhone, isNull);
      final updated = donation.copyWith(donorPhone: '9988776655');
      expect(updated.donorPhone, '9988776655');
      expect(updated.donorName, 'Namdev');
    });

    test('serializes and deserializes utrNumber and paymentStatus correctly', () {
      final now = DateTime(2026, 9, 15, 12, 0);
      final donation = DonationModel(
        id: 'don-upi-1',
        donorName: 'Dnyaneshwar',
        village: 'आळंदी',
        amount: 5001,
        type: 'ऑनलाइन',
        purpose: 'महाप्रसाद',
        proofImageUrl: null,
        addedByUid: 'uid-user-1',
        addedByName: 'Devotee',
        createdAt: now,
        itemDescription: null,
        donorPhone: '9822001122',
        utrNumber: '425109876543',
        paymentStatus: 'pending',
      );

      expect(donation.isVerified, isFalse);

      final map = donation.toMap();
      expect(map['utrNumber'], '425109876543');
      expect(map['paymentStatus'], 'pending');

      final fromMap = DonationModel.fromMap(map, 'don-upi-1');
      expect(fromMap.utrNumber, '425109876543');
      expect(fromMap.paymentStatus, 'pending');
      expect(fromMap.isVerified, isFalse);

      final verified = fromMap.copyWith(
        paymentStatus: 'verified',
        verifiedByUid: 'admin-1',
        verifiedByName: 'Admin Ji',
        verifiedAt: DateTime.now(),
      );
      expect(verified.isVerified, isTrue);
      expect(verified.verifiedByName, 'Admin Ji');
    });

    test('validates 12-digit numeric regex for UTR', () {
      final validRegex = RegExp(r'^\d{12}$');
      expect(validRegex.hasMatch('425109876543'), isTrue);
      expect(validRegex.hasMatch('42510987654'), isFalse); // 11 digits
      expect(validRegex.hasMatch('4251098765432'), isFalse); // 13 digits
      expect(validRegex.hasMatch('42510987ABCD'), isFalse); // non-numeric
    });
  });

  group('UpiQrDialog Widget Tests', () {
    testWidgets('renders UPI QR dialog with preset chips and payee name',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpiQrDialog(
              upiId: 'saptah@upi',
              payeeName: 'अखंड हरिनाम सप्ताह समिती',
              initialAmount: 501,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('UPI QR कोडद्वारे देणगी'), findsOneWidget);
      expect(find.text('अखंड हरिनाम सप्ताह समिती'), findsOneWidget);
      expect(find.text('saptah@upi'), findsOneWidget);
      expect(find.text('₹101'), findsOneWidget);
      expect(find.text('₹501'), findsOneWidget);
      expect(find.text('₹1001'), findsOneWidget);
    });
  });
}
