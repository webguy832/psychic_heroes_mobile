import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../models/auth_model.dart';

class AuthService {
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await ApiClient.post(
      ApiEndpoints.login,
      body: request.toJson(),
      requiresAuth: false,
    );
    if (response is Map<String, dynamic>) {
      return LoginResponse.fromJson(response);
    }
    return LoginResponse(success: true, data: response);
  }

  Future<Map<String, dynamic>> setMemberLead(MemberLeadRequest request) async {
    final response = await ApiClient.post(
      ApiEndpoints.setMemberLead,
      body: request.toJson(),
      requiresAuth: false,
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }

  Future<LoginResponse> signUpUsingVerificationCode(SignUpVerificationRequest request) async {
    final response = await ApiClient.post(
      ApiEndpoints.signUpUsingVerificationCode,
      body: request.toJson(),
      requiresAuth: false,
    );
    if (response is Map<String, dynamic>) {
      return LoginResponse.fromJson(response);
    }
    return LoginResponse(success: true, data: response);
  }

  Future<void> sendOtp(String phoneNumber) async {
    await ApiClient.post(
      ApiEndpoints.sendOtp,
      body: {'phoneNumber': phoneNumber},
      requiresAuth: false,
    );
  }

  Future<void> forgotPassword(String email) async {
    await ApiClient.post(
      ApiEndpoints.forgotPassword,
      body: {'email': email},
      requiresAuth: false,
    );
  }
}
