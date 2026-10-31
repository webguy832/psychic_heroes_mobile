class ApiEndpoints {
  // Base Backend API URL (Relative same-origin for web, or direct host)
  static const String baseUrl = "";
  static const String imageBaseUrl = "http://139.84.168.3:82/";

  // Auth Endpoints (Exact matching web_angular_2025)
  static const String login = "api/auth/login";
  static const String setMemberLead = "api/auth/SetMemberLead";
  static const String signUpUsingVerificationCode = "api/auth/SignUpUsingVerificationCode";
  static const String phoneVerifySignIn = "api/auth/PhoneVerifyRequestSignIn";
  static const String sendOtp = "api/auth/send-otp";
  static const String forgotPassword = "api/auth/forgot-password";
  static const String resetPassword = "api/auth/reset-password";

  // Web & Home Endpoints
  static const String homeSliders = "api/Web/SliderHome";
  static const String psychicCategories = "api/Web/GetPsychicCategories";
  static const String homeAdvisors = "api/Web/GetHomeAdvisor";
  static const String advisorDetail = "api/advisor";

  // User Endpoints
  static const String userProfile = "api/User/GetUserProfile";
  static const String editProfile = "api/User/EditProfile";
  static const String userBalance = "api/User/GetBalanceInQuery";
  static const String userNotifications = "api/User/notifications";
  static const String pendingNotifications = "api/User/pending-Notifications";
  static String markNotificationRead(int id) => "api/User/notifications/$id/read";
  static const String readAllNotifications = "api/User/notifications/read-all";
  
  // Billing Endpoints
  static const String getBillingAddresses = "api/UserBillingAddress/GetAllByUser";
  static const String createBillingAddress = "api/UserBillingAddress";
  static String updateBillingAddress(int id) => "api/UserBillingAddress/$id";

  // Packages & Payment Endpoints (Exact matching web_angular_2025)
  static const String getAllPackages = "api/web/GetAllPackages";
  static const String userStatus = "api/user/status";
  static const String getCountries = "api/common/GetCountries";
  static const String createPaymentIntent = "api/payment/create";
  static const String confirmPayment = "api/payment/confirm";
  static const String validateCoupon = "api/coupon/validate";
}
