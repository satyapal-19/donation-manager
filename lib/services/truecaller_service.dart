import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:truecaller_sdk/truecaller_sdk.dart';

class TruecallerProfile {
  final String phoneNumber;
  final String firstName;
  final String lastName;

  const TruecallerProfile({
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : 'वारकरी';
  }
}

class TruecallerService {
  static final TruecallerService _instance = TruecallerService._internal();
  factory TruecallerService() => _instance;
  TruecallerService._internal();

  static const String _tokenEndpoint =
      'https://oauth-account-noneu.truecaller.com/v1/token';
  static const String _userInfoEndpoint =
      'https://oauth-account-noneu.truecaller.com/v1/userinfo';

  StreamSubscription<TcSdkCallback>? _streamSubscription;
  Completer<TruecallerProfile>? _authCompleter;
  String? _currentCodeVerifier;
  String? _currentState;
  String? _clientId;
  bool _isInitialized = false;

  void initialize() {
    if (!Platform.isAndroid || _isInitialized) return;
    try {
      TcSdk.initializeSDK(sdkOption: TcSdkOptions.OPTION_VERIFY_ALL_USERS);
      _streamSubscription?.cancel();
      _streamSubscription = TcSdk.streamCallbackData.listen(
        _handleSdkCallback,
        onError: (err) {
          debugPrint('Truecaller stream error: $err');
          _completeWithError('Truecaller प्रमाणीकरण त्रुटी: $err');
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Truecaller initialize error: $e');
    }
  }

  Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      if (!_isInitialized) initialize();
      return await TcSdk.isOAuthFlowUsable;
    } catch (e) {
      debugPrint('Truecaller availability check failed: $e');
      return false;
    }
  }

  Future<TruecallerProfile> verifyUser({required String clientId}) async {
    if (!Platform.isAndroid) {
      throw Exception('Truecaller फक्त Android वर उपलब्ध आहे.');
    }
    if (clientId.isEmpty || clientId == 'YOUR_TRUECALLER_CLIENT_ID') {
      throw Exception(
        'Truecaller Client ID कॉन्फिगर केलेला नाही. कृपया AndroidManifest मध्ये Client ID टाका किंवा SMS OTP वापरा.',
      );
    }
    _clientId = clientId;

    if (!_isInitialized) initialize();

    final isUsable = await isAvailable();
    if (!isUsable) {
      throw Exception('आपल्या फोनवर Truecaller उपलब्ध किंवा सक्रिय नाही.');
    }

    // Cancel any previous pending request
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.completeError('नवीन विनंती सुरू झाली.');
    }
    _authCompleter = Completer<TruecallerProfile>();

    try {
      // 1. Generate CSRF State & PKCE Code Verifier / Challenge
      _currentState = _generateRandomString(32);
      TcSdk.setOAuthState(_currentState!);
      TcSdk.setOAuthScopes(['profile', 'phone', 'openid']);

      final codeVerifier = await TcSdk.generateRandomCodeVerifier;
      _currentCodeVerifier = codeVerifier;

      final codeChallenge = await TcSdk.generateCodeChallenge(codeVerifier);
      if (codeChallenge == null) {
        throw Exception('Code challenge तयार करता आले नाही.');
      }

      TcSdk.setCodeChallenge(codeChallenge);

      // 2. Trigger Truecaller 1-tap consent dialog
      TcSdk.getAuthorizationCode;

      // Return future awaiting callback + token exchange
      return await _authCompleter!.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception('Truecaller व्हेरिफिकेशन वेळ संपली (Timeout).');
        },
      );
    } catch (e) {
      _completeWithError(e.toString());
      rethrow;
    }
  }

  void _handleSdkCallback(TcSdkCallback callback) async {
    if (_authCompleter == null || _authCompleter!.isCompleted) return;

    switch (callback.result) {
      case TcSdkCallbackResult.success:
        final oauthData = callback.tcOAuthData;
        if (oauthData == null) {
          _completeWithError('Truecaller कडून डेटा मिळाला नाही.');
          return;
        }

        final authCode = oauthData.authorizationCode;
        if (authCode.isEmpty) {
          _completeWithError('प्रमाणीकरण कोड मिळाला नाही.');
          return;
        }

        try {
          final profile = await _fetchProfileWithAuthCode(
            authorizationCode: authCode,
            codeVerifier: _currentCodeVerifier ?? '',
          );
          _authCompleter?.complete(profile);
        } catch (e) {
          _completeWithError('प्रोफाईल माहिती मिळवण्यात अडचण आली: $e');
        }
        break;

      case TcSdkCallbackResult.failure:
        final err = callback.error;
        final message = err?.message ?? 'Truecaller प्रमाणीकरण अयशस्वी.';
        _completeWithError(message);
        break;

      case TcSdkCallbackResult.missedCallInitiated:
      case TcSdkCallbackResult.otpInitiated:
        // Other non-OAuth verification states
        break;
      default:
        break;
    }
  }

  Future<TruecallerProfile> _fetchProfileWithAuthCode({
    required String authorizationCode,
    required String codeVerifier,
  }) async {
    // 1. Exchange auth code for access token
    final tokenResponse = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'client_id': _clientId ?? '',
        'code': authorizationCode,
        'code_verifier': codeVerifier,
      },
    );

    if (tokenResponse.statusCode != 200) {
      throw Exception(
        'Token एक्सचेंज अयशस्वी (${tokenResponse.statusCode}): ${tokenResponse.body}',
      );
    }

    final tokenJson = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final accessToken = tokenJson['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Access token सापडला नाही.');
    }

    // 2. Fetch user profile from Truecaller userinfo endpoint
    final userinfoResponse = await http.get(
      Uri.parse(_userInfoEndpoint),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (userinfoResponse.statusCode != 200) {
      throw Exception(
        'Userinfo मिळवण्यात अडचण (${userinfoResponse.statusCode})',
      );
    }

    final userJson = jsonDecode(userinfoResponse.body) as Map<String, dynamic>;
    final phone = (userJson['phone_number'] ?? '') as String;
    final givenName = (userJson['given_name'] ?? '') as String;
    final familyName = (userJson['family_name'] ?? '') as String;

    if (phone.isEmpty) {
      throw Exception('Truecaller कडून मोबाईल नंबर मिळाला नाही.');
    }

    // Format phone: ensure standard 10-digit clean format
    String cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone.startsWith('+91')) {
      cleanPhone = cleanPhone.substring(3);
    }

    return TruecallerProfile(
      phoneNumber: cleanPhone,
      firstName: givenName,
      lastName: familyName,
    );
  }

  void _completeWithError(String message) {
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.completeError(message);
    }
  }

  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );
  }

  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _authCompleter = null;
  }
}
