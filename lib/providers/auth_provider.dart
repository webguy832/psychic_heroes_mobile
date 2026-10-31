import 'package:flutter/material.dart';
import '../core/utils/storage_service.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _checkInitialAuthStatus();
  }

  Future<void> _checkInitialAuthStatus() async {
    final token = await StorageService.getToken();
    _isLoggedIn = token != null && token.isNotEmpty;
    notifyListeners();
  }

  Future<LoginResponse> login(String emailOrPhone, String? password, {String? otp, bool forceLogin = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final req = LoginRequest(
        emailOrPhone: emailOrPhone,
        password: password,
        otp: otp,
        forceLogin: forceLogin,
      );
      final res = await _authService.login(req);

      if (res.success && res.token != null) {
        await StorageService.saveToken(res.token!);
        final inferredRole = res.userRole ?? (emailOrPhone.toLowerCase().contains('advisor') ? 'Advisor' : 'Customer');
        final userMap = {
          'id': res.userId ?? '1',
          'fullName': (res.userName != null && res.userName!.isNotEmpty) ? res.userName : (emailOrPhone.contains('@') ? emailOrPhone.split('@')[0] : emailOrPhone),
          'email': emailOrPhone.contains('@') ? emailOrPhone : '${emailOrPhone}@psychicheroes.com',
          'phoneNumber': emailOrPhone.contains('@') ? '' : emailOrPhone,
          'role': inferredRole,
          'walletBalance': 25.00,
        };
        await StorageService.saveUser(userMap);
        _isLoggedIn = true;
      } else if (!res.success && !res.isAlreadyLoggedIn) {
        _errorMessage = res.message ?? "Login failed. Please check credentials.";
      }
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<Map<String, dynamic>> sendMemberLeadOtp(String name, String email, String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final req = MemberLeadRequest(name: name, email: email, phoneNumber: phone);
      final res = await _authService.setMemberLead(req);
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<LoginResponse> signUpUsingVerification(
    String name,
    String email,
    String phone,
    String password,
    String verificationCode,
    String? verificationId,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final req = SignUpVerificationRequest(
        name: name,
        email: email,
        phoneNumber: phone,
        password: password,
        verificationCode: verificationCode,
        verificationId: verificationId,
      );
      final res = await _authService.signUpUsingVerificationCode(req);

      if (res.token != null) {
        await StorageService.saveToken(res.token!);
        final userMap = {
          'id': res.userId ?? '2',
          'fullName': name,
          'email': email,
          'phoneNumber': phone,
          'role': res.userRole ?? 'USER',
          'walletBalance': 25.00,
        };
        await StorageService.saveUser(userMap);
        _isLoggedIn = true;
      } else if (!res.success) {
        _errorMessage = res.message ?? "Sign up failed.";
      }
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<void> logout() async {
    await StorageService.clearSession();
    _isLoggedIn = false;
    notifyListeners();
  }
}
