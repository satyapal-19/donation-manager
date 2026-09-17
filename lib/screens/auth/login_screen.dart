import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/truecaller_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../utils/app_constants.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _truecallerService = TruecallerService();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  bool _isTruecallerLoading = false;
  bool _isTruecallerAvailable = false;
  String _verificationId = '';
  int? _resendToken;
  String? _error;

  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _checkTruecaller();
  }

  Future<void> _checkTruecaller() async {
    final available = await _truecallerService.isAvailable();
    if (mounted) {
      setState(() => _isTruecallerAvailable = available);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _truecallerService.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOTP({bool isResend = false}) async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _error = 'कृपया वैध १० अंकी मोबाईल नंबर टाका');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _authService.sendOTP(
      phoneNumber: '+91$phone',
      forceResendingToken: isResend ? _resendToken : null,
      onCodeSent: (id, resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = id;
          _resendToken = resendToken;
          _otpSent = true;
          _isLoading = false;
          _error = null;
        });
        _startResendTimer();
        AppHelpers.showToast(
          isResend ? 'नवीन OTP पाठवला गेला ✓' : 'OTP पाठवला गेला ✓',
        );
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = err;
        });
      },
      onAutoVerify: (credential) => _signInWithCredential(credential),
    );
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'कृपया ६ अंकी OTP टाका');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = AuthService.mapFirebaseError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'OTP तपासताना त्रुटी आली: $e';
      });
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      if (result.user != null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = null;
        });
        AppHelpers.showToast('मोबाईल नंबर प्रमाणित झाला ✓');
        // AuthGate will now automatically route to Home or CompleteProfileScreen!
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = AuthService.mapFirebaseError(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'लॉगिन पूर्ण झाले नाही: $e';
        });
      }
    }
  }

  Future<void> _loginWithTruecaller() async {
    if (!Platform.isAndroid) {
      AppHelpers.showToast('Truecaller फक्त Android फोनवर उपलब्ध आहे.');
      return;
    }

    setState(() {
      _isTruecallerLoading = true;
      _error = null;
    });

    try {
      if (!_isTruecallerAvailable) {
        final available = await _truecallerService.isAvailable();
        if (mounted) setState(() => _isTruecallerAvailable = available);
        if (!available) {
          throw Exception(
            'आपल्या फोनवर Truecaller ॲप उपलब्ध किंवा सक्रिय नाही. कृपया खालील SMS OTP पर्याय वापरा.',
          );
        }
      }

      final profile = await _truecallerService.verifyUser(
        clientId: AppConstants.truecallerClientId,
      );

      if (!mounted) return;
      AppHelpers.showToast('Truecaller पडताळणी यशस्वी ✓');

      final userModel = await _authService.signInWithTruecallerProfile(
        phoneNumber: profile.phoneNumber,
        name: profile.displayName,
      );

      if (!mounted) return;
      AppHelpers.showToast('स्वागत आहे, ${userModel.name}!');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _error = msg;
      });
      AppHelpers.showToast(msg);
    } finally {
      if (mounted) {
        setState(() => _isTruecallerLoading = false);
      }
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 36),
                    _buildCard(),
                  ],
                ),
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
          width: 88,
          height: 88,
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
            _otpSent ? 'OTP टाका' : 'लॉगिन करा',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _otpSent
                ? '+91 ${_phoneController.text} वर पाठवलेला ६-अंकी OTP टाका'
                : 'आपल्या मोबाईल नंबरवर OTP मागवून सुरक्षित लॉगिन करा',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!_otpSent) ...[
            _buildTruecallerButton(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'किंवा मोबाईल OTP द्वारे',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'मोबाईल नंबर *',
                hintText: '9876543210',
                prefixText: '+91  ',
                prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primary),
                counterText: '',
              ),
              onFieldSubmitted: (_) => _sendOTP(),
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'OTP पाठवा',
              icon: Icons.sms_outlined,
              onPressed: () => _sendOTP(),
            ),
          ] else ...[
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                labelText: '६-अंकी OTP *',
                counterText: '',
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primary),
              ),
              onFieldSubmitted: (_) => _verifyOTP(),
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'पुष्टी करा व लॉगिन करा',
              icon: Icons.verified_outlined,
              onPressed: _verifyOTP,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _resendTimer?.cancel();
                    setState(() {
                      _otpSent = false;
                      _otpController.clear();
                      _error = null;
                    });
                  },
                  child: const Text('नंबर बदला'),
                ),
                TextButton(
                  onPressed: _resendCountdown > 0
                      ? null
                      : () => _sendOTP(isResend: true),
                  child: Text(
                    _resendCountdown > 0
                        ? 'पुन्हा पाठवा (${_resendCountdown}s)'
                        : 'पुन्हा OTP पाठवा',
                    style: TextStyle(
                      color: _resendCountdown > 0
                          ? Colors.grey
                          : AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTruecallerButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0087FF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0087FF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isTruecallerLoading || _isLoading ? null : _loginWithTruecaller,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            child: _isTruecallerLoading
                ? const Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_in_talk,
                          color: Color(0xFF0087FF),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isTruecallerAvailable
                            ? 'Truecaller ने १-क्लिक लॉगिन'
                            : 'Truecaller ने लॉगिन (मोफत)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
