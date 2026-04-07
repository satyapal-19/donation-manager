import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'services/auth_service.dart';
import 'services/other_services.dart';
import 'models/user_model.dart';
import 'theme/app_theme.dart';
import 'utils/app_helpers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_navigation.dart';
import 'screens/admin/admin_panel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
    firebaseReady = true;
  } catch (e) {
    print('Firebase init failed: $e');
  }

  if (firebaseReady) {
    try {
      await NotificationService().initialize();
    } catch (e) {
      print('Notification init failed: $e');
    }
  }

  runApp(SaptahManagerApp(firebaseReady: firebaseReady));
}

class SaptahManagerApp extends StatelessWidget {
  final bool firebaseReady;
  const SaptahManagerApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'सप्ताह व्यवस्थापक',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: AppHelpers.scaffoldMessengerKey,
      home: firebaseReady ? const AuthGate() : const LoginScreen(),
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
          return FutureBuilder<UserModel?>(
            future: AuthService().getUserProfile(snapshot.data!.uid),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const _SplashScreen();
              }
              if (userSnap.hasData && userSnap.data != null) {
                final user = userSnap.data!;
                // Subscribe to admin topic if admin
                if (user.isAdmin) {
                  NotificationService().subscribeAdmin();
                }
                return MainNavigation(user: user);
              }
              return const LoginScreen();
            },
          );
        }
        return const LoginScreen();
      },
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
              Text('🙏', style: TextStyle(fontSize: 72)),
              SizedBox(height: 20),
              Text(
                'सप्ताह व्यवस्थापक',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'अखंड हरिनाम सप्ताह',
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
