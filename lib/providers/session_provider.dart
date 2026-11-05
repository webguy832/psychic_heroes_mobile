import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';

enum SessionType { call, chat, video }

enum SessionState {
  idle,
  waitingForAdvisor,
  active,
  hold,
  ended,
  cancelled,
  declined,
  noBalance,
  busy,
  anotherSession,
}

class ChatMessageItem {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isAdvisor;
  final bool isOpponent;
  final int messageType; // 1 = text, 2 = image, 4 = cancel/decline

  ChatMessageItem({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isAdvisor,
    this.isOpponent = false,
    this.messageType = 1,
  });
}

class SessionRequestItem {
  final String id; // requestId
  final String clientId;
  final String clientName;
  final String advisorId;
  final String advisorName;
  final SessionType type;
  final double ratePerMinute;
  final int freeMinutes;
  final double userBalance;
  final DateTime createdAt;
  bool isAccepted;

  SessionRequestItem({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.advisorId,
    required this.advisorName,
    required this.type,
    required this.ratePerMinute,
    this.freeMinutes = 0,
    this.userBalance = 0.0,
    required this.createdAt,
    this.isAccepted = false,
  });
}

class SessionProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  bool _isAdvisorOnline = true;
  SessionState _sessionState = SessionState.idle;
  SessionType _sessionType = SessionType.chat;

  SessionRequestItem? _activeRequest;
  List<SessionRequestItem> _incomingRequests = [];
  List<ChatMessageItem> _chatMessages = [];

  // Active timers
  Timer? _sessionTimer;
  Timer? _waitingTimer;
  Timer? _pollAcceptanceTimer;
  Timer? _chatMessagePollTimer;
  Timer? _advisorIncomingRequestsTimer;

  int _elapsedSeconds = 0;
  int _waitingSecondsLeft = 60;
  int _freeLeftSeconds = 0;
  double _userBalance = 0.0;
  bool _lowBalanceWarning = false;
  bool _showFreeFinishedNotice = false;
  String? _holdId;
  String _declineTitle = "Chat Declined";
  String _declineMessage = "The advisor is currently unavailable to accept your chat request.";
  Map<String, dynamic>? _chatSummary;

  // Media Controls
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isVideoOn = true;

  // Overview stats
  double _totalEarningsToday = 1420.50;
  int _completedSessionsToday = 14;

  // Getters
  bool get isAdvisorOnline => _isAdvisorOnline;
  SessionState get sessionState => _sessionState;
  SessionType get sessionType => _sessionType;
  SessionRequestItem? get activeRequest => _activeRequest;
  List<SessionRequestItem> get incomingRequests => _incomingRequests;
  List<ChatMessageItem> get chatMessages => _chatMessages;
  int get elapsedSeconds => _elapsedSeconds;
  int get waitingSecondsLeft => _waitingSecondsLeft;
  int get freeLeftSeconds => _freeLeftSeconds;
  double get userBalance => _userBalance;
  bool get isLowBalanceWarning => _lowBalanceWarning;
  bool get showFreeFinishedNotice => _showFreeFinishedNotice;
  String? get holdId => _holdId;
  String get declineTitle => _declineTitle;
  String get declineMessage => _declineMessage;
  Map<String, dynamic>? get chatSummary => _chatSummary;

  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isVideoOn => _isVideoOn;
  double get totalEarningsToday => _totalEarningsToday;
  int get completedSessionsToday => _completedSessionsToday;

  SessionProvider();

  @override
  void dispose() {
    _stopAllTimers();
    _advisorIncomingRequestsTimer?.cancel();
    super.dispose();
  }

  String get formattedTimer {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  /// 45-second threshold billing rule (parity with web_angular_2025):
  /// - < 45 seconds: 0 minutes billed
  /// - >= 45 seconds: 1 minute billed
  /// - >= 105 seconds (1m 45s): 2 minutes billed, etc.
  int get billedMinutes {
    if (_elapsedSeconds < 45) return 0;
    return ((_elapsedSeconds - 45) ~/ 60) + 1;
  }

  /// Cost calculation reflecting free promotional time vs paid minutes
  double get currentSessionCost {
    final rate = _activeRequest?.ratePerMinute ?? 3.99;
    if (_freeLeftSeconds > 0 && billedMinutes == 0) return 0.0;
    return billedMinutes * rate;
  }

  bool get isChargingStarted => _elapsedSeconds >= 45 && _freeLeftSeconds == 0;

  int get secondsUntilCharging {
    if (_freeLeftSeconds > 0) return _freeLeftSeconds;
    if (_elapsedSeconds < 45) return 45 - _elapsedSeconds;
    return 0;
  }

  void toggleAdvisorOnline() {
    _isAdvisorOnline = !_isAdvisorOnline;
    if (!_isAdvisorOnline) {
      stopAdvisorPolling();
    }
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoOn = !_isVideoOn;
    notifyListeners();
  }

  void dismissFreeFinishedNotice() {
    _showFreeFinishedNotice = false;
    notifyListeners();
  }

  void dismissLowBalanceWarning() {
    _lowBalanceWarning = false;
    notifyListeners();
  }

  // ==========================================================
  // INITIATE CHAT (CUSTOMER SIDE)
  // ==========================================================
  Future<void> initiateSessionRequest({
    required String clientId,
    required String clientName,
    required String advisorId,
    required String advisorName,
    required SessionType type,
    double ratePerMinute = 3.99,
    int freeMinutes = 0,
    double userBalance = 0.0,
  }) async {
    _stopAllTimers();
    _sessionType = type;
    _chatMessages.clear();
    _elapsedSeconds = 0;
    _freeLeftSeconds = freeMinutes * 60;
    _userBalance = userBalance;
    _lowBalanceWarning = false;
    _showFreeFinishedNotice = false;
    _holdId = null;
    _chatSummary = null;
    _declineTitle = "Chat Declined";
    _declineMessage = "The advisor is currently unavailable to accept your chat request.";

    _sessionState = SessionState.waitingForAdvisor;
    _waitingSecondsLeft = 60;
    notifyListeners();

    // Call ChatService.startChat(advisorId)
    final startResult = await _chatService.startChat(advisorId);

    if (startResult.noBalance) {
      _sessionState = SessionState.noBalance;
      notifyListeners();
      return;
    }

    if (startResult.isBusy) {
      _sessionState = SessionState.busy;
      notifyListeners();
      return;
    }

    if (startResult.isAnotherSession) {
      _sessionState = SessionState.anotherSession;
      notifyListeners();
      return;
    }

    if (!startResult.success || startResult.requestId == null || startResult.requestId!.isEmpty) {
      _sessionState = SessionState.declined;
      _declineTitle = "Unable to Start";
      _declineMessage = startResult.message ?? "The advisor is currently unavailable. Please try again later.";
      notifyListeners();
      return;
    }

    final realRequestId = startResult.requestId!;
    final effectiveRate = startResult.fees ?? ratePerMinute;

    final req = SessionRequestItem(
      id: realRequestId,
      clientId: clientId,
      clientName: clientName,
      advisorId: advisorId,
      advisorName: advisorName,
      type: type,
      ratePerMinute: effectiveRate,
      freeMinutes: freeMinutes,
      userBalance: userBalance,
      createdAt: DateTime.now(),
    );

    _activeRequest = req;
    notifyListeners();

    // 60-second waiting countdown (parity with Angular 60s rule)
    _startWaitingCountdown(realRequestId);

    // Poll for advisor acceptance every 2s
    _startPollingAdvisorAcceptance(realRequestId);
  }

  void startDemoSession({
    required String advisorId,
    required String advisorName,
    String clientId = "client",
    String clientName = "Client",
    SessionType type = SessionType.chat,
    double ratePerMinute = 3.99,
  }) {
    initiateSessionRequest(
      clientId: clientId,
      clientName: clientName,
      advisorId: advisorId,
      advisorName: advisorName,
      type: type,
      ratePerMinute: ratePerMinute,
    );
  }

  void _startWaitingCountdown(String requestId) {
    _waitingTimer?.cancel();
    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _waitingSecondsLeft--;
      notifyListeners();

      if (_waitingSecondsLeft <= 0) {
        _waitingTimer?.cancel();
        _waitingTimer = null;
        if (_sessionState == SessionState.waitingForAdvisor) {
          _chatService.cancelChat(requestId);
          _stopAllTimers();
          _sessionState = SessionState.declined;
          _declineTitle = "Missed Request";
          _declineMessage = "Missed Request: The advisor was unavailable and did not respond in time. Your request has been cancelled and no charges have been deducted from your wallet.";
          notifyListeners();
        }
      }
    });
  }

  void _startPollingAdvisorAcceptance(String requestId) {
    _pollAcceptanceTimer?.cancel();
    _pollAcceptanceTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_sessionState != SessionState.waitingForAdvisor) {
        timer.cancel();
        return;
      }

      // 1. Check SessionDetails from backend API
      final details = await _chatService.getSessionDetails(requestId);
      if (details != null) {
        final bool chatAccepted = details['chatAccepted'] == true || details['ChatAccepted'] == true;
        final int? status = details['status'] is int
            ? details['status']
            : (details['Status'] is int ? details['Status'] : null);

        if (status == 2 || status == 3 || details['isTimeout'] == true || details['IsTimeout'] == true) {
          timer.cancel();
          _waitingTimer?.cancel();
          _sessionState = SessionState.declined;
          _declineTitle = "Chat Declined";
          _declineMessage = "The advisor is currently unavailable to accept your chat request.";
          notifyListeners();
          return;
        }

        if (chatAccepted) {
          timer.cancel();
          _waitingTimer?.cancel();
          _activeRequest?.isAccepted = true;
          _sessionState = SessionState.active;
          _startBillingTimer();
          _startChatMessagesPolling(requestId);
          notifyListeners();
          return;
        }
      }

      // 2. Also check chat history for messages / decline
      final history = await _chatService.getChatHistory(requestId);
      if (history.isNotEmpty) {
        final hasDeclined = history.any((m) =>
            m['messageType'] == 4 ||
            m['MessageType'] == 4 ||
            m['message'] == 'DECLINED' ||
            m['message'] == 'CANCELLED');

        if (hasDeclined) {
          timer.cancel();
          _waitingTimer?.cancel();
          _sessionState = SessionState.declined;
          _declineTitle = "Chat Declined";
          _declineMessage = "The advisor declined the chat request.";
          notifyListeners();
          return;
        }

        // If history contains messages, advisor has accepted
        timer.cancel();
        _waitingTimer?.cancel();
        _activeRequest?.isAccepted = true;
        _sessionState = SessionState.active;
        _startBillingTimer();
        _startChatMessagesPolling(requestId);
        notifyListeners();
      }
    });
  }

  // ==========================================================
  // BILLING & TIMER LOGIC (45-SECOND RULE & FREE MINS PARITY)
  // ==========================================================
  void _startBillingTimer() {
    _sessionTimer?.cancel();
    _elapsedSeconds = 0;
    bool fundOverTriggered = false;

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionState != SessionState.active) return;
      _elapsedSeconds++;

      final rate = _activeRequest?.ratePerMinute ?? 3.99;
      const deductAtSecond = 45;

      // 1) Free wallet deduction at 45s, 105s, etc.
      if (_freeLeftSeconds > 0) {
        if ((_elapsedSeconds - deductAtSecond) % 60 == 0) {
          _freeLeftSeconds -= 60;
          if (_freeLeftSeconds < 0) _freeLeftSeconds = 0;

          if (_freeLeftSeconds == 0) {
            if (_userBalance > 0) {
              _showFreeFinishedNotice = true;
              final reqId = _activeRequest?.id;
              if (reqId != null) {
                _chatService.registerFreeFinishedAck(reqId);
              }
            } else {
              if (!fundOverTriggered) {
                fundOverTriggered = true;
                _putChatOnHold();
              }
            }
          }
        }
        notifyListeners();
        return;
      }

      // 2) Paid wallet deduction at 45s, 105s, etc.
      if ((_elapsedSeconds - deductAtSecond) % 60 == 0) {
        _userBalance -= rate;
        if (_userBalance < 0) _userBalance = 0;
      }

      // Low balance warning (3 mins / 180 seconds left)
      final secondsLeft = rate > 0 ? (_userBalance / rate) * 60 : 0;
      if (secondsLeft <= 180 && _userBalance > 0 && !_lowBalanceWarning) {
        _lowBalanceWarning = true;
      }

      // Funds exhausted -> Auto-hold session
      if (_userBalance <= 0 && !fundOverTriggered) {
        fundOverTriggered = true;
        _userBalance = 0;
        _putChatOnHold();
      }

      notifyListeners();
    });
  }

  void _putChatOnHold() async {
    _sessionState = SessionState.hold;
    _showFreeFinishedNotice = false;
    _lowBalanceWarning = false;
    notifyListeners();

    final reqId = _activeRequest?.id;
    if (reqId != null) {
      final elapsedMins = (_elapsedSeconds / 60).ceil();
      final holdId = await _chatService.holdChat(reqId, elapsedMins);
      _holdId = holdId;
      notifyListeners();
    }
  }

  Future<bool> resumeHeldSession(double newBalance) async {
    if (_holdId == null) {
      _sessionState = SessionState.active;
      _userBalance = newBalance;
      notifyListeners();
      return true;
    }

    final success = await _chatService.resumeChat(_holdId!);
    if (success) {
      _sessionState = SessionState.active;
      _userBalance = newBalance;
      _holdId = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  // ==========================================================
  // REAL-TIME CHAT MESSAGING
  // ==========================================================
  Future<void> sendChatMessage({
    required String senderId,
    required String senderName,
    required String message,
    required bool isAdvisor,
    int messageType = 1,
  }) async {
    final newMsg = ChatMessageItem(
      id: "msg_${DateTime.now().millisecondsSinceEpoch}",
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
      isAdvisor: isAdvisor,
      isOpponent: false,
      messageType: messageType,
    );

    _chatMessages.add(newMsg);
    notifyListeners();

    final reqId = _activeRequest?.id;
    if (reqId != null && !reqId.startsWith("req_")) {
      await _chatService.sendChatMessage(
        requestId: reqId,
        message: message,
        senderId: senderId,
        messageType: messageType,
      );
    }
  }

  void _startChatMessagesPolling(String requestId) {
    _chatMessagePollTimer?.cancel();
    _chatMessagePollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_sessionState != SessionState.active && _sessionState != SessionState.hold) {
        timer.cancel();
        return;
      }

      final history = await _chatService.getChatHistory(requestId);
      if (history.isNotEmpty) {
        // Detect if ended or cancelled remotely
        final isDead = history.any((m) =>
            m['messageType'] == 4 ||
            m['MessageType'] == 4 ||
            m['message'] == 'CANCELLED' ||
            m['message'] == 'DECLINED' ||
            m['message'] == 'Ended' ||
            m['message'] == 'ChatEnded');

        if (isDead) {
          timer.cancel();
          _stopAllTimers();
          _sessionState = SessionState.ended;
          notifyListeners();
          return;
        }

        // Merge incoming messages
        bool hasNew = false;
        for (var h in history) {
          final text = h['message']?.toString() ?? '';
          if (text.isEmpty || text.startsWith('__TAROT_REQ__')) continue;
          final sentOnStr = h['sentOn']?.toString() ?? h['SentOn']?.toString();
          DateTime time = DateTime.now();
          if (sentOnStr != null) {
            time = DateTime.tryParse(sentOnStr) ?? DateTime.now();
          }
          final fromUser = h['fromUser']?.toString() ?? h['FromUser']?.toString() ?? '';
          final bool isAdvisorMsg = fromUser.toLowerCase() == 'advisor' ||
              fromUser == _activeRequest?.advisorId ||
              fromUser == _activeRequest?.advisorName;

          final exists = _chatMessages.any((m) =>
              m.message == text &&
              (m.timestamp.difference(time).inSeconds.abs() < 5 || m.senderId == fromUser));

          if (!exists) {
            _chatMessages.add(ChatMessageItem(
              id: "srv_${h['id'] ?? DateTime.now().millisecondsSinceEpoch}",
              senderId: fromUser,
              senderName: isAdvisorMsg
                  ? (_activeRequest?.advisorName ?? "Advisor")
                  : (_activeRequest?.clientName ?? "Client"),
              message: text,
              timestamp: time,
              isAdvisor: isAdvisorMsg,
              isOpponent: true,
              messageType: (h['messageType'] is int) ? h['messageType'] : 1,
            ));
            hasNew = true;
          }
        }

        if (hasNew) {
          notifyListeners();
        }
      }
    });
  }

  // ==========================================================
  // ADVISOR INCOMING REQUEST POLLING & ACTIONS
  // ==========================================================
  void startAdvisorPolling(String advisorProfileId) {
    _advisorIncomingRequestsTimer?.cancel();
    _advisorIncomingRequestsTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!_isAdvisorOnline) return;
      final requests = await _chatService.getChatRequests(advisorProfileId);
      if (requests.isNotEmpty) {
        final List<SessionRequestItem> mapped = [];
        for (var r in requests) {
          final id = r['requestId']?.toString() ?? r['RequestId']?.toString() ?? '';
          if (id.isEmpty) continue;
          final clientName = r['clientName']?.toString() ?? r['ClientName']?.toString() ?? 'Valued Client';
          final clientId = r['clientId']?.toString() ?? r['ClientId']?.toString() ?? '';
          final rateVal = r['ratePerMinute'] ?? r['RatePerMinute'] ?? 3.99;
          final double rate = (rateVal is num) ? rateVal.toDouble() : double.tryParse(rateVal.toString()) ?? 3.99;
          final reqTypeInt = r['requestType'] ?? r['RequestType'] ?? 1;

          mapped.add(SessionRequestItem(
            id: id,
            clientId: clientId,
            clientName: clientName,
            advisorId: advisorProfileId,
            advisorName: 'Advisor',
            type: reqTypeInt == 2 ? SessionType.video : (reqTypeInt == 3 ? SessionType.call : SessionType.chat),
            ratePerMinute: rate,
            createdAt: DateTime.now(),
          ));
        }

        if (mapped.isNotEmpty) {
          _incomingRequests = mapped;
          notifyListeners();
        }
      } else {
        if (_incomingRequests.isNotEmpty) {
          _incomingRequests.clear();
          notifyListeners();
        }
      }
    });
  }

  void stopAdvisorPolling() {
    _advisorIncomingRequestsTimer?.cancel();
    _advisorIncomingRequestsTimer = null;
  }

  Future<bool> acceptSessionRequest(SessionRequestItem req) async {
    final success = await _chatService.acceptChat(req.id);
    req.isAccepted = true;
    _activeRequest = req;
    _incomingRequests.clear();
    _sessionState = SessionState.active;
    _startBillingTimer();
    _startChatMessagesPolling(req.id);
    notifyListeners();
    return success;
  }

  Future<void> declineSessionRequest(SessionRequestItem req) async {
    _incomingRequests.removeWhere((r) => r.id == req.id);
    await _chatService.cancelChat(req.id);
    if (_activeRequest?.id == req.id) {
      _activeRequest = null;
      _sessionState = SessionState.cancelled;
    }
    notifyListeners();
  }

  Future<void> cancelSessionRequest() async {
    final reqId = _activeRequest?.id;
    _stopAllTimers();
    if (reqId != null && !reqId.startsWith("req_")) {
      await _chatService.cancelChat(reqId);
    }
    _incomingRequests.clear();
    _activeRequest = null;
    _sessionState = SessionState.idle;
    notifyListeners();
  }

  Future<void> endSession({String? endedBy}) async {
    final reqId = _activeRequest?.id;
    final totalSecs = _elapsedSeconds;
    _stopAllTimers();

    if (_activeRequest != null) {
      _totalEarningsToday += currentSessionCost;
      _completedSessionsToday++;
    }

    if (reqId != null && !reqId.startsWith("req_")) {
      await _chatService.endChatSession(reqId, totalSecs);
      _chatSummary = await _chatService.getSessionSummary(reqId);
    }

    _sessionState = SessionState.ended;
    notifyListeners();
  }

  void resetSession() {
    _stopAllTimers();
    _sessionState = SessionState.idle;
    _activeRequest = null;
    _elapsedSeconds = 0;
    _waitingSecondsLeft = 60;
    _freeLeftSeconds = 0;
    _userBalance = 0.0;
    _lowBalanceWarning = false;
    _showFreeFinishedNotice = false;
    _holdId = null;
    _chatMessages.clear();
    _chatSummary = null;
    notifyListeners();
  }

  void _stopAllTimers() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _waitingTimer?.cancel();
    _waitingTimer = null;
    _pollAcceptanceTimer?.cancel();
    _pollAcceptanceTimer = null;
    _chatMessagePollTimer?.cancel();
    _chatMessagePollTimer = null;
  }
}
