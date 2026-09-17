class AppConstants {
  // Firestore collections
  static const String usersCollection = 'users';
  static const String donationsCollection = 'donations';
  static const String expensesCollection = 'expenses';
  static const String expenseRequestsCollection = 'expense_requests';
  static const String eventsCollection = 'events';
  static const String mahaprasadCollection = 'mahaprasad';
  static const String notificationsCollection = 'notifications';
  static const String suggestionsCollection = 'suggestions';
  static const String issuesCollection = 'issues';

  // Expense request statuses
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // Payment statuses (for Online UPI donations)
  static const String paymentStatusVerified = 'verified';
  static const String paymentStatusPending = 'pending';

  // UPI Payment Configuration
  static const String defaultUpiId = 'saptah.samiti@upi';
  static const String defaultPayeeName = 'श्री अखंड हरिनाम सप्ताह समिती';

  // Truecaller OAuth Client ID
  static const String truecallerClientId =
      '0maklxa_aunyk-dy0m18ik7xtt4sbnpe7wobjsntoxy';

  // Super Admin Phone Numbers (Automatically granted full admin rights)
  static const List<String> adminPhones = [
    '9511675503',
    '9922538900',
    '9999999999',
  ];

  static bool isDefaultAdmin(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final last10 = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
    return adminPhones.contains(last10);
  }

  // Saptah (8 days)
  static const List<String> saptahDays = [
    'दिवस १',
    'दिवस २',
    'दिवस ३',
    'दिवस ४',
    'दिवस ५',
    'दिवस ६',
    'दिवस ७',
    'दिवस ८',
  ];

  // Dashboard "आजचे कार्यक्रम" will read events only for this day number.
  // Update this value daily during the Saptah.
  static const int currentSaptahDay = 7;

  // Dropdowns
  static const List<String> eventTypes = [
    'काकडा',
    'हरिपाठ',
    'ज्ञानेश्वरी पारायण',
    'सार्थ तुकाराम गाथा',
    'भोजन आणि विश्रांती',
    'एकनाथी भावार्थ रामायण',
    'कीर्तन हरिजागर',
    'भारुड',
    'शोभायात्रा',
  ];

  static const List<String> donationTypes = [
    'रोख',
    'ऑनलाइन',
    'वस्तू',
  ];

  static const List<String> donationPurposes = [
    'सामान्य',
    'धर्मकार्य',
    'भजने',
    'महाप्रसाद',
    'विशेष',
  ];

  static const List<String> expenseCategories = [
    'अन्नदान',
    'प्रवास',
    'साधने',
    'इतर',
  ];
}

