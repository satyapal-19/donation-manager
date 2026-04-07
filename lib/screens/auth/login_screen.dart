import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();

  bool _otpSent = false;
  bool _showNameInput = false;
  bool _isLoading = false;
  String _verificationId = '';
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _error = 'कृपया १० अंकी मोबाईल नंबर टाका');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    await _authService.sendOTP(
      phoneNumber: '+91$phone',
      onCodeSent: (id) {
        setState(() {
          _verificationId = id;
          _otpSent = true;
          _isLoading = false;
        });
        AppHelpers.showToast('OTP पाठवले गेले');
      },
      onError: (e) {
        setState(() { _isLoading = false; _error = e; });
      },
      onAutoVerify: (credential) => _signInWithCredential(credential),
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _error = 'कृपया ६ अंकी OTP टाका');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _authService.verifyOTP(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      if (result?.user != null) {
        await _checkUserExists(result!.user!);
      }
    } catch (e) {
      setState(() { _isLoading = false; _error = 'चुकीचा OTP. पुन्हा प्रयत्न करा.'; });
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      if (result.user != null) await _checkUserExists(result.user!);
    } catch (_) {}
  }

  Future<void> _checkUserExists(User user) async {
    final exists = await _authService.userExists(user.uid);
    if (exists) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() { _isLoading = false; _showNameInput = true; });
    }
  }

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'कृपया आपले नाव टाका');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final phone = _phoneController.text.trim();
      final user = UserModel(
        uid: uid,
        name: name,
        mobile: phone,
        role: 'user',
        createdAt: DateTime.now(),
      );
      await _authService.createUserProfile(user);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() { _isLoading = false; _error = 'प्रोफाइल तयार करताना चूक झाली'; });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Center(
            child: Text('🙏', style: TextStyle(fontSize: 44)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'सप्ताह व्यवस्थापक',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'अखंड हरिनाम सप्ताह',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          'हनुमान मंदिर, चिंचोली-भोसे',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _showNameInput
                ? 'आपले नाव सांगा'
                : _otpSent
                    ? 'OTP टाका'
                    : 'लॉगिन करा',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _showNameInput
                ? 'नोंदणीसाठी आपले पूर्ण नाव टाका'
                : _otpSent
                    ? '+91${_phoneController.text} वर OTP पाठवला आहे'
                    : 'मोबाईल नंबरने लॉगिन करा',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (_showNameInput) ...[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'पूर्ण नाव *',
                prefixIcon: Icon(Icons.person_outline, color: AppTheme.primary),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'प्रोफाइल सेव करा',
              icon: Icons.save_outlined,
              onPressed: _createProfile,
            ),
          ] else if (!_otpSent) ...[
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'मोबाईल नंबर *',
                prefixText: '+91  ',
                prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primary),
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'OTP पाठवा',
              icon: Icons.sms_outlined,
              onPressed: _sendOTP,
            ),
          ] else ...[
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'OTP',
                counterText: '',
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'पुष्टी करा',
              icon: Icons.verified_outlined,
              onPressed: _verifyOTP,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() { _otpSent = false; _otpController.clear(); }),
              child: const Text('मोबाईल नंबर बदला'),
            ),
          ],
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
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
