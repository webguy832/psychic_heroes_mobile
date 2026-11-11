class ApiEndpoints {
  // Base Backend API URL strictly pointing to https://psychicheroes.online/ (matching web_angular_2025)
  static const String baseUrl = "https://psychicheroes.online/";
  static const String directBackendUrl = "https://psychicheroes.online/";
  static const String imageBaseUrl = "https://psychicheroes.online/";
  static const String bannerBaseUrl = "https://psychicheroes.online/Content/Psychic/images/banners/";

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
  static const String advisorReviews = "api/Web/GetAdvisorReviews";
  static const String userFreeMinutes = "api/web/GetUserFreeMinutes";
  static const String checkSessionEligibility = "api/user/checkSessionEligibilty";

  // Chat & Communication Endpoints (Exact matching web_angular_2025 & .NET 8 backend)
  static const String startChat = "api/Chat/StartChat";
  static const String acceptChat = "api/Chat/AcceptChat";
  static const String cancelChat = "api/Chat/CancelChat";
  static const String holdChat = "api/Chat/hold";
  static const String resumeChat = "api/Chat/resume-chat";
  static const String endChatSession = "api/Chat/end-session";
  static const String getChatHistory = "api/Chat/NewSessionChatHistory";
  static const String addChatHistory = "api/Chat/AddChatHistory";
  static const String getChatRequests = "api/Chat/GetChatRequests";
  static const String paidSessionConfirmation = "api/PaidSessionConfirmation";
  static const String sessionSummary = "api/VoiceCall/summary";
  static const String sessionDetails = "api/Chat/SessionDetails";
  static const String updateClientConInfo = "api/Chat/UpdateClientConInfo";
  static const String updateAdvisorConInfo = "api/Chat/UpdateAdvisorConInfo";

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

  // Wallet & Session Endpoints
  static const String walletTransactions = "api/wallet/transactions";
  static const String readingHistory = "api/customer/history";

  // Packages & Payment Endpoints (Exact matching web_angular_2025)
  static const String getAllPackages = "api/web/GetAllPackages";
  static const String userStatus = "api/user/status";
  static const String getCountries = "api/common/GetCountries";
  static const String createPaymentIntent = "api/payment/create";
  static const String confirmPayment = "api/payment/confirm";
  static const String validateCoupon = "api/coupon/validate";

  /// Resolves image URLs for advisor photos, static banners, and uploads matching Angular web app
  static String resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('assets/') || trimmed.startsWith('/assets/')) return trimmed;

    final clean = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    if (clean.startsWith('Content/') || clean.startsWith('images/')) {
      return '$baseUrl$clean';
    }

    final fileName = clean.contains('/') ? clean.substring(clean.lastIndexOf('/') + 1) : clean;
    return '${baseUrl}api/Web/download/$fileName';
  }
}
