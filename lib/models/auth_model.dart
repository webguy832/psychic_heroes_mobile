class LoginRequest {
  final String emailOrPhone;
  final String? password;
  final String? otp;
  final bool forceLogin;

  LoginRequest({
    required this.emailOrPhone,
    this.password,
    this.otp,
    this.forceLogin = false,
  });

  Map<String, dynamic> toJson() => {
        'EmailOrPhone': emailOrPhone,
        'Password': password,
        'Otp': otp,
        'otp': otp,
        'ForceLogin': forceLogin,
        'force': forceLogin,
        'forceLogoutOthers': forceLogin,
      };
}

class MemberLeadRequest {
  final String name;
  final String email;
  final String phoneNumber;

  MemberLeadRequest({
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
      };
}

class SignUpVerificationRequest {
  final String name;
  final String email;
  final String phoneNumber;
  final String password;
  final String verificationCode;
  final String? verificationId;
  final String? referralCode;

  SignUpVerificationRequest({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.verificationCode,
    this.verificationId,
    this.referralCode,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'verificationCode': verificationCode,
        'verificationId': verificationId,
        'referralCode': referralCode,
      };
}

class LoginResponse {
  final bool success;
  final String? token;
  final String? message;
  final String? userRole;
  final String? userId;
  final String? userName;
  final bool isAlreadyLoggedIn;
  final bool requiresConfirmation;
  final Map<String, dynamic>? user;
  final dynamic data;

  LoginResponse({
    required this.success,
    this.token,
    this.message,
    this.userRole,
    this.userId,
    this.userName,
    this.isAlreadyLoggedIn = false,
    this.requiresConfirmation = false,
    this.user,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? (json['token'] != null),
      token: json['token'] ?? json['data']?['token'],
      message: json['message'],
      userRole: json['userRole'] ?? json['role'],
      userId: json['userId']?.toString() ?? json['id']?.toString(),
      userName: json['userName'] ?? json['name'],
      isAlreadyLoggedIn: json['isAlreadyLoggedIn'] ?? false,
      requiresConfirmation: json['requiresConfirmation'] ?? false,
      user: json['user'] ?? json['data']?['user'],
      data: json['data'],
    );
  }
}
