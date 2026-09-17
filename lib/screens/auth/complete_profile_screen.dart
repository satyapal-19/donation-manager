import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../utils/app_constants.dart';
import '../../widgets/common_widgets.dart';

class CompleteProfileScreen extends StatefulWidget {
  final User firebaseUser;

  const CompleteProfileScreen({super.key, required this.firebaseUser});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getMobileNumber() {
    final raw = widget.firebaseUser.phoneNumber ?? '';
    if (raw.startsWith('+91')) {
      return raw.substring(3);
    }
    return raw;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final name = _nameController.text.trim();
      final mobile = _getMobileNumber();

      final user = UserModel(
        uid: widget.firebaseUser.uid,
        name: name,
        mobile: mobile,
        role: AppConstants.isDefaultAdmin(mobile) ? 'admin' : 'user',
        createdAt: DateTime.now(),
      );

      await _authService.createUserProfile(user);
      AppHelpers.showToast('आपले स्वागत आहे, $name!');
      // AuthGate stream automatically navigates to home as soon as users/{uid} is created
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'प्रोफाइल तयार करताना अडचण आली: $e';
        });
      }
    }
  }

  Future<void> _changeAccount() async {
    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'दुसऱ्या नंबरने लॉगिन',
      message: 'आपण दुसऱ्या मोबाईल नंबरने लॉगिन करू इच्छिता का?',
    );
    if (confirm) {
      await _authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = _getMobileNumber();

    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary, Color(0xFFFFB74D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text('🚩', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'सप्ताह व्यवस्थापक',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'नोंदणी पूर्ण करा',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'आपले नाव सांगा',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'सप्ताह नियोजनासाठी आपले पूर्ण नाव आवश्यक आहे',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            // Verified phone pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.success.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    color: AppTheme.success,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'मोबाईल: +91 $mobile (OTP प्रमाणित)',
                                      style: const TextStyle(
                                        color: AppTheme.success,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'पूर्ण नाव *',
                                hintText: 'उदा. रामदास पाटील',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: AppTheme.primary,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'कृपया आपले नाव टाका';
                                }
                                if (v.trim().length < 2) {
                                  return 'नाव किमान २ अक्षरांचे असावे';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            GradientButton(
                              text: 'नोंदणी पूर्ण करा',
                              icon: Icons.check_circle_outline,
                              onPressed: _saveProfile,
                            ),
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: _changeAccount,
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('दुसऱ्या नंबरने लॉगिन करा'),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppTheme.error,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: AppTheme.error,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
