import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_endpoints.dart';

enum SessionType { call, chat, video }
enum SessionState { idle, waitingForAdvisor, active, ended, cancelled }

class ChatMessageItem {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isAdvisor;

  ChatMessageItem({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isAdvisor,
  });
}

class SessionRequestItem {
  final String id;
  final String clientId;
  final String clientName;
  final String advisorId;
  final String advisorName;
  final SessionType type;
  final double ratePerMinute;
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
    required this.createdAt,
    this.isAccepted = false,
  });
}

class SessionProvider extends ChangeNotifier {
  bool _isAdvisorOnline = true;
  SessionState _sessionState = SessionState.idle;
  SessionType _sessionType = SessionType.chat;
  
  SessionRequestItem? _activeRequest;
  List<SessionRequestItem> _incomingRequests = [];
  List<ChatMessageItem> _chatMessages = [];
  
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isVideoOn = true;

  double _totalEarningsToday = 1420.50;
  int _completedSessionsToday = 14;

  bool get isAdvisorOnline => _isAdvisorOnline;
  SessionState get sessionState => _sessionState;
  SessionType get sessionType => _sessionType;
  SessionRequestItem? get activeRequest => _activeRequest;
  List<SessionRequestItem> get incomingRequests => _incomingRequests;
  List<ChatMessageItem> get chatMessages => _chatMessages;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isVideoOn => _isVideoOn;
  double get totalEarningsToday => _totalEarningsToday;
  int get completedSessionsToday => _completedSessionsToday;

  SessionProvider();

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  String get formattedTimer {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  /// Billed minutes calculated based on web app 45-second threshold rules:
  /// - < 45 seconds: 0 minutes billed (Free grace period / failed chat)
  /// - >= 45 seconds: 1 minute billed (starts charging at 45 sec)
  /// - >= 105 seconds (1m 45s): 2 minutes billed, and so on.
  int get billedMinutes {
    if (_elapsedSeconds < 45) return 0;
    return ((_elapsedSeconds - 45) ~/ 60) + 1;
  }

  /// Current session cost = billedMinutes * ratePerMinute
  double get currentSessionCost {
    final rate = _activeRequest?.ratePerMinute ?? 3.99;
    return (billedMinutes * rate);
  }

  /// Whether charging has started (after 45 seconds)
  bool get isChargingStarted => _elapsedSeconds >= 45;

  /// Remaining seconds in the 45-second free grace period
  int get secondsUntilCharging => _elapsedSeconds < 45 ? (45 - _elapsedSeconds) : 0;

  void toggleAdvisorOnline() {
    _isAdvisorOnline = !_isAdvisorOnline;
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

  // User initiates Chat/Call -> Status = waitingForAdvisor & Save Local
  void initiateSessionRequest({
    required String clientId,
    required String clientName,
    required String advisorId,
    required String advisorName,
    required SessionType type,
    double ratePerMinute = 3.99,
  }) async {
    final req = SessionRequestItem(
      id: "req_${DateTime.now().millisecondsSinceEpoch}",
      clientId: clientId,
      clientName: clientName,
      advisorId: advisorId,
      advisorName: advisorName,
      type: type,
      ratePerMinute: ratePerMinute,
      createdAt: DateTime.now(),
    );

    _activeRequest = req;
    _incomingRequests = [req];
    _sessionType = type;
    _sessionState = SessionState.waitingForAdvisor;
    
    _chatMessages = [
      ChatMessageItem(
        id: "msg_1",
        senderId: advisorId,
        senderName: advisorName,
        message: "Hello $clientName! Welcome to your live session. How can I guide you today?",
        timestamp: DateTime.now(),
        isAdvisor: true,
      )
    ];

    notifyListeners();

    final initialMsgMap = {
      'id': "msg_1",
      'senderId': advisorId,
      'senderName': advisorName,
      'message': "Hello $clientName! Welcome to your live session. How can I guide you today?",
      'timestamp': DateTime.now().toIso8601String(),
      'isAdvisor': true,
    };

    final sessionMap = {
      'id': req.id,
      'clientId': clientId,
      'clientName': clientName,
      'advisorId': advisorId,
      'advisorName': advisorName,
      'type': type == SessionType.video ? 'video' : (type == SessionType.call ? 'call' : 'chat'),
      'ratePerMinute': ratePerMinute,
      'status': 'PENDING',
      'messages': [initialMsgMap],
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_live_session', json.encode(sessionMap));
    } catch (_) {}
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

  // Advisor accepts the request -> Status = active
  void acceptSessionRequest(SessionRequestItem req) async {
    req.isAccepted = true;
    _activeRequest = req;
    _sessionState = SessionState.active;
    _incomingRequests.clear();
    _startSessionTimer();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('active_live_session');
      final sessionMap = {
        'id': req.id,
        'clientId': req.clientId,
        'clientName': req.clientName,
        'advisorId': req.advisorId,
        'advisorName': req.advisorName,
        'type': req.type == SessionType.video ? 'video' : (req.type == SessionType.call ? 'call' : 'chat'),
        'status': 'ACCEPTED',
      };
      if (localData != null && localData.isNotEmpty) {
        final existing = json.decode(localData);
        if (existing is Map && existing['messages'] != null) {
          sessionMap['messages'] = existing['messages'];
        }
      }
      await prefs.setString('active_live_session', json.encode(sessionMap));
    } catch (_) {}
  }

  // Advisor declines request
  void declineSessionRequest(SessionRequestItem req) async {
    _incomingRequests.clear();
    _activeRequest = null;
    _sessionState = SessionState.cancelled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_live_session', json.encode({'status': 'CANCELLED'}));
    } catch (_) {}
  }

  // User cancels request while waiting
  void cancelSessionRequest() async {
    _incomingRequests.clear();
    _activeRequest = null;
    _sessionState = SessionState.idle;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_live_session', json.encode({'status': 'CANCELLED'}));
    } catch (_) {}
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _elapsedSeconds = 0;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void sendChatMessage({
    required String senderId,
    required String senderName,
    required String message,
    required bool isAdvisor,
  }) async {
    final newMsg = ChatMessageItem(
      id: "msg_${DateTime.now().millisecondsSinceEpoch}",
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
      isAdvisor: isAdvisor,
    );

    _chatMessages.add(newMsg);
    notifyListeners();

    final msgMap = {
      'id': newMsg.id,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': newMsg.timestamp.toIso8601String(),
      'isAdvisor': isAdvisor,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('active_live_session');
      Map<String, dynamic> sessionMap = {};
      if (localData != null && localData.isNotEmpty) {
        sessionMap = json.decode(localData);
      }
      List msgs = sessionMap['messages'] ?? [];
      if (!msgs.any((m) => m['id'] == newMsg.id)) {
        msgs.add(msgMap);
      }
      sessionMap['messages'] = msgs;
      await prefs.setString('active_live_session', json.encode(sessionMap));
    } catch (_) {}
  }

  void endSession({String? endedBy}) async {
    _sessionTimer?.cancel();
    if (_activeRequest != null) {
      _totalEarningsToday += currentSessionCost;
      _completedSessionsToday++;
    }
    _sessionState = SessionState.ended;
    notifyListeners();

    final endPayload = {
      'status': 'ENDED',
      'endedBy': endedBy ?? 'Participant',
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_live_session', json.encode(endPayload));
    } catch (_) {}
  }

  void resetSession() async {
    _sessionTimer?.cancel();
    _sessionState = SessionState.idle;
    _activeRequest = null;
    _elapsedSeconds = 0;
    _chatMessages.clear();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_live_session');
    } catch (_) {}
  }
}
