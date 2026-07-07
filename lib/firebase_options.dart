// ╔══════════════════════════════════════════════════════════╗
// ║         firebase_options.dart - AUTO GENERATED          ║
// ║  Run: flutterfire configure  (after Firebase setup)      ║
// ╚══════════════════════════════════════════════════════════╝
//
// Steps to generate this file:
//   1. Install FlutterFire CLI:
//        dart pub global activate flutterfire_cli
//   2. Login to Firebase:
//        firebase login
//   3. Configure project:
//        flutterfire configure
//   This will create this file automatically.
//
// PLACEHOLDER - replace with your actual firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  
  // ⚠️  REPLACE THESE VALUES with your actual Firebase project config

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.yourorg.saptahmanager',
  );
}
