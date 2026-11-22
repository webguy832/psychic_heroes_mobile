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

  // Voice Call Endpoints (Real .NET 8 backend parity)
  static const String createVoiceSession = "api/VoiceCall/create-session";
  static const String acceptVoiceCall = "api/VoiceCall/accept";
  static const String rejectVoiceCall = "api/VoiceCall/reject";
  static const String endVoiceCall = "api/VoiceCall/end";
  static const String voiceSummary = "api/VoiceCall/summary";
  static const String pendingVoiceCall = "api/VoiceCall/pending";

  // Video Call Endpoints (Real .NET 8 backend parity)
  static const String createVideoSession = "api/Video/create-session";
  static const String acceptVideoCall = "api/Video/accept";
  static const String rejectVideoCall = "api/Video/reject";
  static const String endVideoCall = "api/Video/end";
  static const String videoSummary = "api/Video/summary";
  static const String pendingVideoCall = "api/Video/pending";

  // Twilio Audio & Video Token Endpoints
  static const String getAudioToken = "api/twilio/get-audio-token";
  static const String getVideoToken = "api/twilio/get-token";
  static const String getVideoRoomToken = "api/Video/token";

  // User Endpoints
  static const String userProfile = "api/User/GetUserProfile";
  static const String editProfile = "api/User/EditProfile";
  static const String userBalance = "api/User/GetBalanceInQuery";
  static const String userNotifications = "api/User/notifications";
  static const String pendingNotifications = "api/User/pending-Notifications";
  static String markNotificationRead(int id) => "api/User/notifications/$id/read";
  static const String readAllNotifications = "api/User/notifications/read-all";
  static const String advisorNotifications = "api/advisor/dashboard/notifications";
  static String markAdvisorNotificationRead(int id) => "api/advisor/dashboard/notifications/$id/read";
  static const String readAllAdvisorNotifications = "api/advisor/dashboard/notifications/read-all";
  
  // Billing Endpoints
  static const String getBillingAddresses = "api/UserBillingAddress/GetAllByUser";
  static const String createBillingAddress = "api/UserBillingAddress";
  static String updateBillingAddress(int id) => "api/UserBillingAddress/$id";

  // Wallet & Session Endpoints
  static const String walletSummary = "api/dashboard/wallet/summary";
  static const String walletTransactions = "api/dashboard/wallet/transactions";
  static const String readingHistory = "api/customer/history";

  // Advisor Wallet & History Endpoints (Exact matching web_angular_2025 & .NET 8 backend)
  static const String advisorBookingsHistory = "api/advisor/dashboard/bookings/history";
  static const String advisorEarningsHistory = "api/advisor/dashboard/earnings/history";
  static const String advisorWalletSummary = "api/advisor/wallet/summary";
  static const String advisorWalletTransactions = "api/advisor/wallet/transactions";
  static const String advisorWithdrawalsHistory = "api/advisor/dashboard/withdrawals/history";

  // Packages & Payment Endpoints (Exact matching web_angular_2025)
  static const String getAllPackages = "api/web/GetAllPackages";
  static const String userStatus = "api/user/status";
  static const String getCountries = "api/admin/dashboard/GetAllCountries";
  static const String createPaymentIntent = "api/payment/create";
  static const String confirmPayment = "api/payment/confirm";
  static const String validateCoupon = "api/coupon/validate";

  // Text Reading Endpoints (Exact matching web_angular_2025 & .NET 8 backend)
  static const String textReadingRequest = "api/User/TextReadingRequest";
  static String uploadTextReadingFile(int id) => "api/User/text-reading/$id/upload";
  static const String customerTextReadings = "api/User/GetCustomerTextReadings";
  static const String getServiceMessages = "api/User/GetServiceMessages";
  static const String requestAdditionalMessage = "api/User/RequestAdditioanlMessage";
  static const String submitTextReading = "api/User/SubmitTextReading";
  static const String advisorTextReadings = "api/Advisor/GetAdvisorTextReadings";
  static const String pendingAdvisorTextReadings = "api/Advisor/GetPendingAdvisorTextReadings";
  static const String getTextReadingById = "api/Advisor/GetTextReadingById";

  // Platinum / Premium Service Endpoints (Exact matching web_angular_2025 & .NET 8 backend)
  static const String premiumCategory = "api/PlatinumService/GetPremiumCategory";
  static const String premiumLuxeCategories = "api/PlatinumService/luxe-categories";
  static const String premiumDetails = "api/PlatinumService/details";
  static const String loadPremium = "api/PlatinumService/loadpremium";
  static const String startPremium = "api/PlatinumService/StartPremium";
  static const String premiumRequests = "api/PlatinumService/GetPremiumRequests";
  static const String premiumRequestDetail = "api/PlatinumService/premium-request-detail";
  static const String acceptPremiumRequest = "api/PlatinumService/accept";
  static const String markCompletedPremiumRequest = "api/PlatinumService/mark-completed";
  static const String cancelPremiumRequest = "api/PlatinumService/cancel";
  static const String myPremiumServices = "api/PlatinumService/GetMyServices";
  static const String discountPercentage = "api/PlatinumService/GetDiscountPercentage";

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
