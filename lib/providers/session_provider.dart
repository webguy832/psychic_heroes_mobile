import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/utils/storage_service.dart';
import '../services/chat_service.dart';
import '../services/signalr_service.dart';

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
  double ratePerMinute;
  int freeMinutes;
  double userBalance;
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
  final SignalRService _signalR = SignalRService();
  final List<StreamSubscription> _signalRSubs = [];

  bool _isAdvisorOnline = true;
  SessionState _sessionState = SessionState.idle;
  SessionType _sessionType = SessionType.chat;

  SessionRequestItem? _activeRequest;
  List<SessionRequestItem> _incomingRequests = [];
  final Set<String> _handledRequestIds = {};
  List<ChatMessageItem> _chatMessages = [];

  // Active timers & safety nets
  Timer? _sessionTimer;
  Timer? _waitingTimer;
  Timer? _advisorIncomingRequestsTimer;
  String? _currentAdvisorProfileId;

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
  double _advisorBaseRate = 0.49;

  // Current user identifiers for message attribution & role
  String _currentUserId = '';
  String _currentUserName = '';
  bool _isCurrentUserAdvisor = false;

  // Getters
  bool get isCurrentUserAdvisor => _isCurrentUserAdvisor;
  bool get isAdvisorOnline => _isAdvisorOnline;
  bool get isAdvisorInActiveSession =>
      _isCurrentUserAdvisor &&
      (_sessionState == SessionState.active || _sessionState == SessionState.hold);
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
  double get advisorBaseRate => _advisorBaseRate;
  SignalRService get signalR => _signalR;
  String get connectionId => _signalR.connectionId;

  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isVideoOn => _isVideoOn;
  double get totalEarningsToday => _totalEarningsToday;
  int get completedSessionsToday => _completedSessionsToday;

  SessionProvider() {
    _initSignalRListeners();
  }

  void _initSignalRListeners() {
    // 1. Real-time incoming chat message push (Zero polling!)
    _signalRSubs.add(_signalR.messageReceivedStream.listen((msg) {
      _handleIncomingRealtimeMessage(msg);
    }));

    // 2. Real-time advisor acceptance push
    _signalRSubs.add(_signalR.advisorJoinedStream.listen((data) {
      _handleAdvisorJoined(data);
    }));

    _signalRSubs.add(_signalR.advisorConnectedStream.listen((data) {
      if (_sessionState == SessionState.waitingForAdvisor) {
        _handleAdvisorJoined(data);
      }
    }));

    // 3. Real-time incoming chat request for advisor
    _signalRSubs.add(_signalR.incomingRequestStream.listen((req) {
      _handleIncomingChatRequest(req);
    }));

    // 4. Real-time cancellation / decline / timeout
    _signalRSubs.add(_signalR.chatCancelledStream.listen((payload) {
      _handleRemoteChatCancelled(payload);
    }));

    // 5. Real-time session end
    _signalRSubs.add(_signalR.chatEndedStream.listen((payload) {
      _handleRemoteChatEnded(payload);
    }));

    // 6. Real-time hold / resume
    _signalRSubs.add(_signalR.chatHoldStream.listen((payload) {
      _sessionState = SessionState.hold;
      notifyListeners();
    }));

    _signalRSubs.add(_signalR.chatResumeStream.listen((payload) {
      _sessionState = SessionState.active;
      notifyListeners();
    }));
  }

  @override
  void dispose() {
    _stopAllTimers();
    for (var sub in _signalRSubs) {
      sub.cancel();
    }
    _signalRSubs.clear();
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
    final rate = _activeRequest?.ratePerMinute ?? _advisorBaseRate;
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
      _incomingRequests.clear();
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
    double ratePerMinute = 0.49,
    int freeMinutes = 0,
    double userBalance = 0.0,
  }) async {
    // Avoid duplicate initiation if already waiting or active
    if (_sessionState == SessionState.waitingForAdvisor || _sessionState == SessionState.active) {
      return;
    }

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
    _currentUserId = clientId;
    _currentUserName = clientName;
    _isCurrentUserAdvisor = false;

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

    // Join SignalR Chat Session group for instant real-time events (matching Angular startConnection parity)
    try {
      await _signalR.ensureConnected(
        userName: clientName,
        userId: clientId,
        isAdvisor: false,
        requestId: realRequestId,
      );
      await _signalR.connectToChat(clientName, realRequestId);

      // Register client connection info with backend so backend pushes customer.request.accepted directly
      if (_signalR.connectionId.isNotEmpty) {
        await _chatService.updateClientConnectionInfo(realRequestId, _signalR.connectionId);
      }
    } catch (e) {
      debugPrint("SignalR Connect / updateClientConnectionInfo error: $e");
    }

    // Safety fallback: Check status immediately after brief delay
    Future.delayed(const Duration(seconds: 3), () {
      if (_sessionState == SessionState.waitingForAdvisor) {
        _checkSessionStatusOnce(realRequestId);
      }
    });
  }

  void _checkSessionStatusOnce(String requestId) async {
    try {
      final details = await _chatService.getSessionDetails(requestId);
      if (details != null && _sessionState == SessionState.waitingForAdvisor) {
        final bool chatAccepted = details['chatAccepted'] == true ||
            details['ChatAccepted'] == true ||
            details['startOn'] != null ||
            details['StartOn'] != null;
        if (chatAccepted) {
          _handleAdvisorJoined({'name': _activeRequest?.advisorName ?? 'Advisor'});
        }
      }
    } catch (_) {}
  }

  void startDemoSession({
    required String advisorId,
    required String advisorName,
    String clientId = "client",
    String clientName = "Client",
    SessionType type = SessionType.chat,
    double ratePerMinute = 0.49,
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

      // Check session status every 2 seconds as a fallback safety net for network hiccups
      if (_waitingSecondsLeft % 2 == 0 && _sessionState == SessionState.waitingForAdvisor) {
        _checkSessionStatusOnce(requestId);
      }

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

  // ==========================================================
  // REAL-TIME SIGNALR EVENT HANDLERS & MESSAGE DELIVERY
  // ==========================================================
  void _handleAdvisorJoined(Map<String, dynamic> data) async {
    if (_sessionState == SessionState.waitingForAdvisor) {
      _waitingTimer?.cancel();
      _waitingTimer = null;
      _activeRequest?.isAccepted = true;
      _sessionState = SessionState.active;
      _startBillingTimer();

      // One-time load of initial chat history upon entering
      final reqId = _activeRequest?.id;
      if (reqId != null) {
        await _syncChatHistory(reqId);
      }

      notifyListeners();
    }
  }

  void _handleIncomingChatRequest(IncomingChatRequestRealtime req) {
    if (!_isAdvisorOnline) return;

    // Suppress incoming requests if advisor is currently in an active or on-hold session
    if (_sessionState == SessionState.active || _sessionState == SessionState.hold) return;

    // Avoid duplicate or already handled requests
    if (_handledRequestIds.contains(req.requestId)) return;
    if (_activeRequest?.id == req.requestId) return;
    if (_incomingRequests.any((r) => r.id == req.requestId)) return;

    final item = SessionRequestItem(
      id: req.requestId,
      clientId: req.clientId,
      clientName: req.clientName ?? 'Valued Client',
      advisorId: req.advisorId,
      advisorName: 'Advisor',
      type: req.requestType == 2
          ? SessionType.video
          : (req.requestType == 3 ? SessionType.call : SessionType.chat),
      ratePerMinute: _advisorBaseRate,
      createdAt: req.requestedAtUtc,
    );

    _incomingRequests.add(item);
    notifyListeners();
  }

  void _handleIncomingRealtimeMessage(RealtimeChatMessage msg) {
    if (msg.message.isEmpty || msg.message.startsWith('__TAROT_REQ__')) return;

    final cleanSender = msg.userName.trim().toLowerCase();

    // Check if sender is advisor
    final bool isFromAdvisor = cleanSender == 'advisor' ||
        cleanSender == (_activeRequest?.advisorName.trim().toLowerCase() ?? '') ||
        cleanSender == (_activeRequest?.advisorId.trim().toLowerCase() ?? '');

    // Is it an opponent message for the current viewer?
    final bool isOpponent = _isCurrentUserAdvisor ? !isFromAdvisor : isFromAdvisor;

    final localSentOn = msg.sentOn.toLocal();

    if (!isOpponent) {
      // Echo of our own message from server.
      // If not already in local list, add it
      final alreadyExists = _chatMessages.any((m) =>
          !m.isOpponent &&
          m.message.trim() == msg.message.trim() &&
          m.timestamp.difference(localSentOn).inSeconds.abs() < 25);
      if (!alreadyExists) {
        _chatMessages.add(ChatMessageItem(
          id: "sig_self_${DateTime.now().millisecondsSinceEpoch}",
          senderId: _currentUserId,
          senderName: _currentUserName,
          message: msg.message,
          timestamp: localSentOn,
          isAdvisor: _isCurrentUserAdvisor,
          isOpponent: false,
          messageType: msg.messageType,
        ));
        _chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        notifyListeners();
      }
      return;
    }

    // It is an OPPONENT message!
    final alreadyExists = _chatMessages.any((m) =>
        m.isOpponent &&
        m.message.trim() == msg.message.trim() &&
        m.timestamp.difference(localSentOn).inSeconds.abs() < 25);

    if (!alreadyExists) {
      _chatMessages.add(ChatMessageItem(
        id: "sig_opp_${DateTime.now().millisecondsSinceEpoch}",
        senderId: msg.userName,
        senderName: _isCurrentUserAdvisor
            ? (_activeRequest?.clientName ?? "Client")
            : (_activeRequest?.advisorName ?? "Advisor"),
        message: msg.message,
        timestamp: localSentOn,
        isAdvisor: !_isCurrentUserAdvisor,
        isOpponent: true,
        messageType: msg.messageType,
      ));
      _chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      notifyListeners();
    }
  }

  void _handleRemoteChatCancelled(dynamic payload) {
    final reqId = payload is Map
        ? (payload['requestId']?.toString() ?? payload['RequestId']?.toString() ?? payload['id']?.toString())
        : payload?.toString();
    if (reqId != null && reqId.isNotEmpty) {
      _handledRequestIds.add(reqId);
      _incomingRequests.removeWhere((r) => r.id == reqId);
    }
    // If cancellation is specifically for a different request, do not cancel the active request
    if (_activeRequest != null && reqId != null && reqId.isNotEmpty && _activeRequest!.id != reqId) {
      return;
    }
    if (_sessionState == SessionState.waitingForAdvisor ||
        (_activeRequest != null && (reqId == null || reqId.isEmpty || _activeRequest!.id == reqId))) {
      _waitingTimer?.cancel();
      _waitingTimer = null;
      _sessionState = SessionState.declined;
      _declineTitle = "Chat Cancelled";
      _declineMessage = "The session was cancelled or timed out.";
      notifyListeners();
    }
  }

  void _handleRemoteChatEnded(dynamic payload) {
    if (_activeRequest?.id != null) {
      _handledRequestIds.add(_activeRequest!.id);
    }
    if (_sessionState == SessionState.active || _sessionState == SessionState.hold) {
      _stopAllTimers();
      _sessionState = SessionState.ended;
      notifyListeners();
    }
  }

  /// Public method to trigger immediate chat history sync
  Future<void> syncChatHistory([String? reqId]) async {
    final effectiveId = reqId ?? _activeRequest?.id;
    if (effectiveId != null && !effectiveId.startsWith("req_")) {
      await _syncChatHistory(effectiveId);
    }
  }

  Future<void> _syncChatHistory(String requestId) async {
    try {
      final history = await _chatService.getChatHistory(requestId);
      if (history.isEmpty) return;

      bool changed = false;
      for (var h in history) {
        final text = h['message']?.toString() ?? '';
        if (text.isEmpty || text.startsWith('__TAROT_REQ__')) continue;
        final sentOnStr = h['sentOn']?.toString() ?? h['SentOn']?.toString();
        DateTime time = DateTime.now();
        if (sentOnStr != null) {
          time = (DateTime.tryParse(sentOnStr) ?? DateTime.now()).toLocal();
        }

        // Determine if message is from advisor using backend's IsOpponentAdvisor (or FromUser fallback)
        bool isFromAdvisor = false;
        if (h['isOpponentAdvisor'] is bool) {
          isFromAdvisor = h['isOpponentAdvisor'] as bool;
        } else if (h['IsOpponentAdvisor'] is bool) {
          isFromAdvisor = h['IsOpponentAdvisor'] as bool;
        } else {
          final from = (h['fromUser']?.toString() ?? h['FromUser']?.toString() ?? '').toLowerCase().trim();
          isFromAdvisor = from == 'advisor' ||
              from == (_activeRequest?.advisorName.toLowerCase().trim() ?? '') ||
              from == (_activeRequest?.advisorId.toLowerCase().trim() ?? '');
        }

        // Opponent status based on current viewer's role
        final bool isOpponent = _isCurrentUserAdvisor ? !isFromAdvisor : isFromAdvisor;

        final msgIdStr = h['messageId']?.toString() ?? h['MessageId']?.toString() ?? h['id']?.toString();

        final existingIndex = _chatMessages.indexWhere((m) {
          if (msgIdStr != null && m.id == "srv_$msgIdStr") return true;
          return m.message.trim() == text.trim() &&
              m.isOpponent == isOpponent &&
              m.timestamp.difference(time).inSeconds.abs() < 30;
        });

        if (existingIndex == -1) {
          _chatMessages.add(ChatMessageItem(
            id: msgIdStr != null ? "srv_$msgIdStr" : "srv_${DateTime.now().millisecondsSinceEpoch}",
            senderId: isOpponent
                ? (_isCurrentUserAdvisor ? (_activeRequest?.clientId ?? "client") : (_activeRequest?.advisorId ?? "advisor"))
                : _currentUserId,
            senderName: isOpponent
                ? (_isCurrentUserAdvisor ? (_activeRequest?.clientName ?? "Client") : (_activeRequest?.advisorName ?? "Advisor"))
                : _currentUserName,
            message: text,
            timestamp: time,
            isAdvisor: isFromAdvisor,
            isOpponent: isOpponent,
            messageType: (h['messageType'] is int) ? h['messageType'] : 1,
          ));
          changed = true;
        } else if (msgIdStr != null && _chatMessages[existingIndex].id != "srv_$msgIdStr") {
          // Upgrade local temporary message ID to server ID
          _chatMessages[existingIndex] = ChatMessageItem(
            id: "srv_$msgIdStr",
            senderId: _chatMessages[existingIndex].senderId,
            senderName: _chatMessages[existingIndex].senderName,
            message: _chatMessages[existingIndex].message,
            timestamp: time,
            isAdvisor: _chatMessages[existingIndex].isAdvisor,
            isOpponent: _chatMessages[existingIndex].isOpponent,
            messageType: _chatMessages[existingIndex].messageType,
          );
        }
      }
      if (changed) {
        _chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        notifyListeners();
      }
    } catch (_) {}
  }

  // Backward compatibility alias
  Future<void> _loadInitialChatHistory(String requestId) => _syncChatHistory(requestId);

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

      // Periodic 3s chat history sync safety net for both participants
      if (_elapsedSeconds % 3 == 0) {
        final reqId = _activeRequest?.id;
        if (reqId != null && !reqId.startsWith("req_")) {
          _syncChatHistory(reqId);
        }
      }

      // Parity with Angular advisor-chat.component.ts:
      // ADVISOR ONLY increments elapsed seconds. ADVISORS DO NOT DEDUCT WALLET BALANCE OR AUTO-HOLD!
      if (_isCurrentUserAdvisor) {
        notifyListeners();
        return;
      }

      final rate = _activeRequest?.ratePerMinute ?? _advisorBaseRate;
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
  // REAL-TIME CHAT MESSAGING (SIGNALR INSTANT PUSH)
  // ==========================================================
  Future<void> sendChatMessage({
    required String senderId,
    required String senderName,
    required String message,
    required bool isAdvisor,
    int messageType = 1,
  }) async {
    _currentUserId = senderId;
    _currentUserName = senderName;
    _isCurrentUserAdvisor = isAdvisor;

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
      // 1. Instant push to opponent over SignalR Hub (Zero polling latency!)
      try {
        await _signalR.sendChatMessage(
          message: message,
          requestId: reqId,
          fromUser: senderName,
          messageType: messageType,
        );
      } catch (e) {
        debugPrint("SignalR sendChatMessage error: $e");
      }

      // 2. Persist in backend DB
      try {
        await _chatService.sendChatMessage(
          requestId: reqId,
          message: message,
          senderId: senderId,
          messageType: messageType,
        );
      } catch (e) {
        debugPrint("ChatService sendChatMessage error: $e");
      }
    }
  }

  // ==========================================================
  // ADVISOR PRESENCE & ACTIONS (SIGNALR REAL-TIME PUSH + SAFETY NET POLL)
  // ==========================================================
  Future<void> startAdvisorPolling(String advisorProfileId, {String advisorName = 'Advisor', String userId = ''}) async {
    _currentUserId = userId.isNotEmpty ? userId : advisorProfileId;
    _currentUserName = advisorName;
    _isCurrentUserAdvisor = true;

    // Resolve advisor profile GUID if not passed properly (parity with Angular GetAdvisorProfileDetails)
    String effectiveProfileId = advisorProfileId;
    final savedProfileId = await StorageService.getAdvisorProfileId();
    if (savedProfileId != null && savedProfileId.isNotEmpty) {
      effectiveProfileId = savedProfileId;
    }
    try {
      final advDetails = await _chatService.getAdvisorProfileDetails();
      if (advDetails != null) {
        final pid = advDetails['id']?.toString() ??
            advDetails['Id']?.toString() ??
            advDetails['userProfile']?['id']?.toString() ??
            advDetails['userProfile']?['Id']?.toString();
        if (pid != null && pid.isNotEmpty) {
          effectiveProfileId = pid;
          await StorageService.saveAdvisorProfileId(pid);
        }

        // Extract base rate from advisor profile (OfferedFee or Fee)
        final rawOffered = advDetails['offeredFee'] ?? advDetails['OfferedFee'];
        final rawFee = advDetails['fee'] ?? advDetails['Fee'];
        double? parsedFee;
        if (rawOffered is num && rawOffered > 0) {
          parsedFee = rawOffered.toDouble();
        } else if (rawFee is num && rawFee > 0) {
          parsedFee = rawFee.toDouble();
        } else if (rawOffered != null) {
          final val = double.tryParse(rawOffered.toString());
          if (val != null && val > 0) parsedFee = val;
        }
        if (parsedFee == null && rawFee != null) {
          final val = double.tryParse(rawFee.toString());
          if (val != null && val > 0) parsedFee = val;
        }
        if (parsedFee != null && parsedFee > 0) {
          _advisorBaseRate = parsedFee;
        }
      }
    } catch (_) {}

    _currentAdvisorProfileId = effectiveProfileId;

    // 1. Connect to SignalR as Advisor with presence and registration
    try {
      await _signalR.ensureConnected(
        userName: advisorName,
        userId: _currentUserId,
        advisorProfileId: effectiveProfileId,
        isAdvisor: true,
      );
    } catch (e) {
      debugPrint("startAdvisorPolling SignalR error: $e");
    }

    // 2. Immediate check for any incoming requests
    await _pollAdvisorRequestsOnce(effectiveProfileId, advisorName);

    // 3. Fallback recurring polling safety net (every 3s while idle on dashboard)
    _advisorIncomingRequestsTimer?.cancel();
    _advisorIncomingRequestsTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_sessionState == SessionState.idle || _sessionState == SessionState.declined || _sessionState == SessionState.cancelled) {
        _pollAdvisorRequestsOnce(effectiveProfileId, advisorName);
      }
    });
  }

  Future<void> _pollAdvisorRequestsOnce(String advisorProfileId, String advisorName) async {
    if (!_isAdvisorOnline) return;
    if (_sessionState == SessionState.active || _sessionState == SessionState.hold) return;
    try {
      final requests = await _chatService.getChatRequests(advisorProfileId);
      if (_sessionState == SessionState.active || _sessionState == SessionState.hold) return;
      if (requests.isNotEmpty) {
        bool changed = false;
        for (var r in requests) {
          final id = r['requestId']?.toString() ?? r['RequestId']?.toString() ?? r['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          if (_handledRequestIds.contains(id)) continue;
          if (_activeRequest?.id == id) continue;
          if (_incomingRequests.any((existing) => existing.id == id)) continue;

          final clientName = r['clientName']?.toString() ??
              r['ClientName']?.toString() ??
              r['clientScreenName']?.toString() ??
              r['ClientScreenName']?.toString() ??
              r['customerName']?.toString() ??
              r['userName']?.toString() ??
              'Valued Client';
          final clientId = r['clientId']?.toString() ?? r['ClientId']?.toString() ?? '';
          final rateVal = r['ratePerMinute'] ?? r['RatePerMinute'];
          final double rate = (rateVal is num)
              ? rateVal.toDouble()
              : (double.tryParse(rateVal?.toString() ?? '') ?? _advisorBaseRate);
          final reqTypeVal = r['requestType'] ?? r['RequestType'] ?? 1;
          final int reqTypeInt = (reqTypeVal is num) ? reqTypeVal.toInt() : int.tryParse(reqTypeVal.toString()) ?? 1;

          _incomingRequests.add(SessionRequestItem(
            id: id,
            clientId: clientId,
            clientName: clientName,
            advisorId: advisorProfileId,
            advisorName: advisorName,
            type: reqTypeInt == 2 ? SessionType.video : (reqTypeInt == 3 ? SessionType.call : SessionType.chat),
            ratePerMinute: rate,
            createdAt: DateTime.now(),
          ));
          changed = true;
        }
        if (changed) {
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void stopAdvisorPolling() {
    _advisorIncomingRequestsTimer?.cancel();
    _advisorIncomingRequestsTimer = null;
  }

  Future<bool> acceptSessionRequest(SessionRequestItem req) async {
    _handledRequestIds.add(req.id);
    _advisorIncomingRequestsTimer?.cancel();
    _advisorIncomingRequestsTimer = null;
    _isCurrentUserAdvisor = true;
    _currentUserId = _currentAdvisorProfileId ?? req.advisorId;
    _currentUserName = req.advisorName;
    _activeRequest = req;
    _sessionType = req.type;
    _incomingRequests.removeWhere((r) => r.id == req.id);
    _incomingRequests.clear();
    _chatMessages.clear();
    _sessionState = SessionState.active;
    notifyListeners();

    // Ensure advisor SignalR connection is active with presence
    String connId = _signalR.connectionId;
    try {
      final ensured = await _signalR.ensureConnected(
        userName: req.advisorName,
        userId: _currentUserId,
        advisorProfileId: _currentAdvisorProfileId ?? req.advisorId,
        isAdvisor: true,
        requestId: req.id,
      );
      if (ensured.isNotEmpty) {
        connId = ensured;
      }
    } catch (_) {}

    if (connId.isEmpty && _signalR.connectionId.isNotEmpty) {
      connId = _signalR.connectionId;
    }
    if (connId.isEmpty) connId = 'mobile';

    final acceptResult = await _chatService.acceptChat(req.id, connectId: connId);
    req.isAccepted = true;

    // Dynamically update ratePerMinute and free minutes from backend AcceptChat response
    if (acceptResult.advisorFee != null && acceptResult.advisorFee! > 0) {
      req.ratePerMinute = acceptResult.advisorFee!;
      _advisorBaseRate = acceptResult.advisorFee!;
      if (_activeRequest?.id == req.id) {
        _activeRequest?.ratePerMinute = acceptResult.advisorFee!;
      }
    }
    if (acceptResult.freeMinutes != null && acceptResult.freeMinutes! > 0) {
      req.freeMinutes = acceptResult.freeMinutes!;
      _freeLeftSeconds = acceptResult.freeMinutes! * 60;
    }

    // Safety check: if rate is still missing or invalid, query SessionDetails
    if (req.ratePerMinute <= 0) {
      try {
        final sDetails = await _chatService.getSessionDetails(req.id);
        if (sDetails != null) {
          final feeVal = sDetails['advisorFee'] ?? sDetails['AdvisorFee'];
          if (feeVal is num && feeVal > 0) {
            req.ratePerMinute = feeVal.toDouble();
            _advisorBaseRate = feeVal.toDouble();
            if (_activeRequest?.id == req.id) {
              _activeRequest?.ratePerMinute = feeVal.toDouble();
            }
          }
        }
      } catch (_) {}
    }

    _startBillingTimer();

    // Connect advisor to SignalR chat session group & register advisor connection info (matching Angular parity)
    try {
      await _signalR.connectAdvisorToChat(req.advisorName, connId, req.id);
      final activeConn = _signalR.connectionId.isNotEmpty ? _signalR.connectionId : connId;
      if (activeConn.isNotEmpty && activeConn != 'mobile') {
        await _chatService.updateAdvisorConnectionInfo(req.id, activeConn);
      }
    } catch (e) {
      debugPrint("connectAdvisorToChat / updateAdvisorConnectionInfo error: $e");
    }

    // Load initial chat history
    await _loadInitialChatHistory(req.id);

    notifyListeners();
    return acceptResult.success;
  }

  Future<void> declineSessionRequest(SessionRequestItem req) async {
    _handledRequestIds.add(req.id);
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
    if (reqId != null) {
      _handledRequestIds.add(reqId);
    }
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
    if (reqId != null) {
      _handledRequestIds.add(reqId);
    }
    final totalSecs = _elapsedSeconds;
    _stopAllTimers();

    if (_activeRequest != null) {
      _totalEarningsToday += currentSessionCost;
      _completedSessionsToday++;
    }

    if (reqId != null && !reqId.startsWith("req_")) {
      // Notify over SignalR and settle billing
      _signalR.endChat(reqId, totalSecs);
      await _chatService.endChatSession(reqId, totalSecs, connectionId: _signalR.connectionId);
      _chatSummary = await _chatService.getSessionSummary(reqId);
      if (_chatSummary != null) {
        final finalCharge = _chatSummary!['chargedAmount'] ??
            _chatSummary!['ChargedAmount'] ??
            _chatSummary!['totalCharges'];
        if (finalCharge is num && _activeRequest != null) {
          _totalEarningsToday = _totalEarningsToday - currentSessionCost + finalCharge.toDouble();
        }
      }
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
    _advisorIncomingRequestsTimer?.cancel();
    _advisorIncomingRequestsTimer = null;
  }
}
