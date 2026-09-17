import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'services/other_services.dart';
import 'models/user_model.dart';
import 'preview/preview_app.dart';
import 'theme/app_theme.dart';
import 'utils/app_helpers.dart';
import 'utils/app_constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/home/main_navigation.dart';
import 'screens/admin/admin_panel_screen.dart';

const bool _previewMode = bool.fromEnvironment('PREVIEW_MODE');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_previewMode) {
    runApp(const DonationManagerPreviewApp());
    return;
  }

  var firebaseReady = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  if (firebaseReady) {
    try {
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  runApp(DonationManagerApp(firebaseReady: firebaseReady));
}

class DonationManagerApp extends StatelessWidget {
  final bool firebaseReady;
  const DonationManagerApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donation Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: AppHelpers.scaffoldMessengerKey,
      home: firebaseReady ? const AuthGate() : const _SetupRequiredScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final user = settings.arguments as UserModel?;
          if (user != null) {
            return MaterialPageRoute(
                builder: (_) => MainNavigation(user: user));
          }
        }
        if (settings.name == '/admin') {
          final user = settings.arguments as UserModel?;
          if (user != null) {
            return MaterialPageRoute(
                builder: (_) => AdminPanelScreen(user: user));
          }
        }
        return null;
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          final firebaseUser = snapshot.data!;
          final uid = firebaseUser.uid;
          // Live listen: new sign-ups see home as soon as `users/{uid}` is written.
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.usersCollection)
                .doc(uid)
                .snapshots(),
            builder: (context, docSnap) {
              if (docSnap.connectionState == ConnectionState.waiting &&
                  !docSnap.hasData) {
                return const _SplashScreen();
              }
              final doc = docSnap.data;
              if (doc != null && doc.exists) {
                final data = doc.data();
                if (data != null) {
                  final user = UserModel.fromMap(data, doc.id);
                  if (AppConstants.isDefaultAdmin(user.mobile) &&
                      data['role'] != 'admin') {
                    FirebaseFirestore.instance
                        .collection(AppConstants.usersCollection)
                        .doc(uid)
                        .update({'role': 'admin'}).catchError((_) {});
                  }
                  return _HomeShell(user: user);
                }
              }
              return CompleteProfileScreen(firebaseUser: firebaseUser);
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}

/// Subscribes FCM topic once per session; avoids calling [subscribeAdmin] on every StreamBuilder rebuild.
class _HomeShell extends StatefulWidget {
  final UserModel user;
  const _HomeShell({required this.user});

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  @override
  void initState() {
    super.initState();
    _maybeSubscribeAdmin(widget.user);
  }

  @override
  void didUpdateWidget(_HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.user.isAdmin && widget.user.isAdmin) {
      _maybeSubscribeAdmin(widget.user);
    }
  }

  void _maybeSubscribeAdmin(UserModel user) {
    if (!user.isAdmin) return;
    NotificationService()
        .subscribeAdmin()
        .catchError((error) => debugPrint('subscribeAdmin skipped: $error'));
  }

  @override
  Widget build(BuildContext context) => MainNavigation(user: widget.user);
}

class _SetupRequiredScreen extends StatelessWidget {
  const _SetupRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary, Color(0xFFFFB74D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volunteer_activism_rounded,
                    size: 72,
                    color: Colors.white,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Donation Manager',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Firebase is not configured for this build yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add the platform Firebase files from the README to unlock the full app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary, Color(0xFFFFB74D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.volunteer_activism_rounded,
                size: 72,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Donation Manager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Donations, expenses, and event coordination',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 40),
              SpinKitFadingCircle(color: Colors.white, size: 36),
            ],
          ),
        ),
      ),
    );
  }
}
