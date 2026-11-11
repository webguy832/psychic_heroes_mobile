import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';

class AcceptChatResult {
  final bool success;
  final double? advisorFee;
  final double? advisorOriginalFees;
  final int? freeMinutes;
  final int? complimentaryMins;
  final int? validSessionMinutes;
  final Map<String, dynamic>? data;

  AcceptChatResult({
    required this.success,
    this.advisorFee,
    this.advisorOriginalFees,
    this.freeMinutes,
    this.complimentaryMins,
    this.validSessionMinutes,
    this.data,
  });
}

class StartChatResult {
  final bool success;
  final String? requestId;
  final double? fees;
  final bool noBalance;
  final bool isBusy;
  final bool isAnotherSession;
  final String? message;

  StartChatResult({
    required this.success,
    this.requestId,
    this.fees,
    this.noBalance = false,
    this.isBusy = false,
    this.isAnotherSession = false,
    this.message,
  });

  factory StartChatResult.fromJson(Map<String, dynamic> json) {
    final reqId = json['requestId']?.toString() ?? json['RequestId']?.toString();
    final bool noBal = json['noBalance'] == true || json['NoBalance'] == true;
    final bool busy = json['isBusy'] == true || json['IsBusy'] == true;
    final bool another = json['isAnotherSession'] == true || json['IsAnotherSession'] == true;
    final rawFee = json['fees'] ?? json['Fees'];
    final double? fee = (rawFee is num) ? rawFee.toDouble() : double.tryParse(rawFee?.toString() ?? '');

    final bool ok = reqId != null &&
        reqId.isNotEmpty &&
        reqId != '00000000-0000-0000-0000-000000000000' &&
        !noBal &&
        !busy &&
        !another;

    return StartChatResult(
      success: ok,
      requestId: reqId,
      fees: fee,
      noBalance: noBal,
      isBusy: busy,
      isAnotherSession: another,
      message: json['message']?.toString() ?? json['Message']?.toString(),
    );
  }
}

class ChatService {
  /// Initiates a chat request from Customer to Advisor via api/Chat/StartChat
  Future<StartChatResult> startChat(String advisorId) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.startChat,
        body: {'advisorId': advisorId},
        requiresAuth: true,
      );

      if (response is Map<String, dynamic>) {
        return StartChatResult.fromJson(response);
      }
      return StartChatResult(success: false, message: "Unexpected response from server");
    } catch (e) {
      return StartChatResult(success: false, message: e.toString());
    }
  }

  /// Advisor accepts a chat request via api/Chat/AcceptChat
  Future<AcceptChatResult> acceptChat(String requestId, {String connectId = 'mobile'}) async {
    try {
      final endpoint = "${ApiEndpoints.acceptChat}?requestId=$requestId&connectId=$connectId";
      final response = await ApiClient.post(
        endpoint,
        requiresAuth: true,
      );
      if (response is Map) {
        final bool ok = response['status'] == 'success' ||
            response['isSuccess'] == true ||
            response['success'] == true;
        final data = response['data'] is Map ? response['data'] as Map : null;
        double? fee;
        double? originalFee;
        int? freeMins;
        int? compMins;
        int? validMins;

        if (data != null) {
          final rawFee = data['advisorFee'] ??
              data['AdvisorFee'] ??
              data['advisorProfile']?['offeredFee'] ??
              data['advisorProfile']?['fee'];
          if (rawFee is num) {
            fee = rawFee.toDouble();
          } else if (rawFee != null) {
            fee = double.tryParse(rawFee.toString());
          }

          final rawOrig = data['advisorOriginalFees'] ??
              data['AdvisorOriginalFees'] ??
              data['advisorProfile']?['fee'];
          if (rawOrig is num) {
            originalFee = rawOrig.toDouble();
          } else if (rawOrig != null) {
            originalFee = double.tryParse(rawOrig.toString());
          }

          final rawFree = data['freeMinutes'] ?? data['FreeMinutes'];
          if (rawFree is num) freeMins = rawFree.toInt();

          final rawComp = data['complimentaryMins'] ?? data['ComplimentaryMins'];
          if (rawComp is num) compMins = rawComp.toInt();

          final rawValid = data['validSessionMinutes'] ?? data['ValidSessionMinutes'];
          if (rawValid is num) validMins = rawValid.toInt();
        }

        return AcceptChatResult(
          success: ok,
          advisorFee: fee,
          advisorOriginalFees: originalFee,
          freeMinutes: freeMins,
          complimentaryMins: compMins,
          validSessionMinutes: validMins,
          data: data != null ? Map<String, dynamic>.from(data) : null,
        );
      }
      return AcceptChatResult(success: true);
    } catch (_) {
      return AcceptChatResult(success: false);
    }
  }

  /// Cancels an active or waiting chat request via api/Chat/CancelChat
  Future<bool> cancelChat(String requestId) async {
    try {
      await ApiClient.post(
        ApiEndpoints.cancelChat,
        body: {'requestId': requestId},
        requiresAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Places a chat session on hold when balance finishes via api/Chat/hold
  Future<String?> holdChat(String requestId, int elapsedMinutes) async {
    try {
      final response = await ApiClient.post(
        ApiEndpoints.holdChat,
        body: {
          'ChatRequestId': requestId,
          'HoldDurationMinutes': elapsedMinutes > 0 ? elapsedMinutes : 1,
        },
        requiresAuth: true,
      );
      if (response is Map) {
        return response['holdId']?.toString() ?? response['HoldId']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Resumes a held chat session after funds recharge via api/Chat/resume-chat
  Future<bool> resumeChat(String holdId) async {
    try {
      final endpoint = "${ApiEndpoints.resumeChat}?holdId=$holdId";
      await ApiClient.post(
        endpoint,
        requiresAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ends a chat session and settles billing via api/Chat/end-session
  Future<bool> endChatSession(String requestId, int totalSeconds, {String connectionId = 'mobile'}) async {
    try {
      await ApiClient.post(
        ApiEndpoints.endChatSession,
        body: {
          'connectionId': connectionId,
          'requestId': requestId,
          'totalTime': totalSeconds,
        },
        requiresAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches real-time chat history for an ongoing or completed session via api/Chat/NewSessionChatHistory
  Future<List<Map<String, dynamic>>> getChatHistory(String requestId) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.getChatHistory,
        requiresAuth: true,
        queryParams: {'requestId': requestId},
      );
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Adds a new chat message to history via api/Chat/AddChatHistory
  Future<bool> sendChatMessage({
    required String requestId,
    required String message,
    required String senderId,
    int messageType = 1,
  }) async {
    try {
      await ApiClient.post(
        ApiEndpoints.addChatHistory,
        body: {
          'chatRequestId': requestId,
          'messageType': messageType,
          'fromUser': senderId,
          'message': message,
          'sentOn': DateTime.now().toUtc().toIso8601String(),
        },
        requiresAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches pending chat requests for an advisor via api/Chat/GetChatRequests
  Future<List<Map<String, dynamic>>> getChatRequests(String advisorId) async {
    try {
      final endpoint = "${ApiEndpoints.getChatRequests}?advisorId=$advisorId";
      final response = await ApiClient.post(
        endpoint,
        requiresAuth: true,
      );
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Registers user acknowledgement when free promotional minutes end via api/PaidSessionConfirmation
  Future<bool> registerFreeFinishedAck(String requestId, {String remarks = 'user closed'}) async {
    try {
      await ApiClient.post(
        ApiEndpoints.paidSessionConfirmation,
        body: {
          'requestType': 1,
          'requestId': requestId,
          'remarks': remarks,
        },
        requiresAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches session details (accepted status, duration, etc.) via api/Chat/SessionDetails
  Future<Map<String, dynamic>?> getSessionDetails(String requestId) async {
    try {
      final endpoint = "${ApiEndpoints.sessionDetails}?requestId=$requestId";
      final response = await ApiClient.get(endpoint, requiresAuth: true);
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches final session summary & billed minutes via api/VoiceCall/summary/{requestId}
  Future<Map<String, dynamic>?> getSessionSummary(String requestId) async {
    try {
      final endpoint = "${ApiEndpoints.sessionSummary}/$requestId";
      final response = await ApiClient.get(endpoint, requiresAuth: true);
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Updates client SignalR connection ID via api/Chat/UpdateClientConInfo (matching Angular parity)
  Future<bool> updateClientConnectionInfo(String requestId, String connectionId) async {
    try {
      await ApiClient.post(
        ApiEndpoints.updateClientConInfo,
        body: {
          'requestId': requestId,
          'connectionId': connectionId,
        },
        requiresAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Updates advisor SignalR connection ID via api/Chat/UpdateAdvisorConInfo (matching Angular parity)
  Future<bool> updateAdvisorConnectionInfo(String requestId, String connectionId) async {
    try {
      await ApiClient.post(
        ApiEndpoints.updateAdvisorConInfo,
        body: {
          'requestId': requestId,
          'connectionId': connectionId,
        },
        requiresAuth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches advisor's own profile details (including Guid profile ID) via api/advisor/GetAdvisorProfileDetails
  Future<Map<String, dynamic>?> getAdvisorProfileDetails() async {
    try {
      final response = await ApiClient.get("api/advisor/GetAdvisorProfileDetails", requiresAuth: true);
      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
