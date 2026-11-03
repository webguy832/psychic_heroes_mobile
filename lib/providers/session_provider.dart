import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  Timer? _pollingTimer;
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

  SessionProvider() {
    _startPollingSessionState();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pollingTimer?.cancel();
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

  /// Current session cost based on 45-second charging logic
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

  void _syncMessagesFromList(List<dynamic>? rawList) {
    if (rawList == null) return;
    bool hasNew = false;
    for (var m in rawList) {
      if (m is Map) {
        final msgId = m['id']?.toString() ?? '';
        if (msgId.isNotEmpty && !_chatMessages.any((x) => x.id == msgId)) {
          DateTime ts = DateTime.now();
          if (m['timestamp'] != null) {
            try {
              ts = DateTime.parse(m['timestamp'].toString());
            } catch (_) {}
          }
          _chatMessages.add(ChatMessageItem(
            id: msgId,
            senderId: m['senderId']?.toString() ?? '',
            senderName: m['senderName']?.toString() ?? '',
            message: m['message']?.toString() ?? '',
            timestamp: ts,
            isAdvisor: m['isAdvisor'] == true,
          ));
          hasNew = true;
        }
      }
    }
    if (hasNew) {
      notifyListeners();
    }
  }

  void _startPollingSessionState() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
      // 1. Check local storage cache for instant cross-tab sync
      try {
        final prefs = await SharedPreferences.getInstance();
        final localData = prefs.getString('active_live_session');
        if (localData != null && localData.isNotEmpty) {
          final session = json.decode(localData);
          if (session['messages'] != null) {
            _syncMessagesFromList(session['messages']);
          }

          final status = session['status'];
          final reqId = session['id'] ?? 'req_1';
          final clientName = session['clientName'] ?? 'Client';
          final advisorName = session['advisorName'] ?? 'Advisor';
          final typeStr = (session['type'] ?? 'chat').toString().toLowerCase();
          final type = typeStr.contains('video')
              ? SessionType.video
              : (typeStr.contains('call') || typeStr.contains('voice') ? SessionType.call : SessionType.chat);

          final item = SessionRequestItem(
            id: reqId,
            clientId: session['clientId'] ?? 'client_1',
            clientName: clientName,
            advisorId: session['advisorId'] ?? '101',
            advisorName: advisorName,
            type: type,
            ratePerMinute: (session['ratePerMinute'] ?? 3.99).toDouble(),
            createdAt: DateTime.now(),
          );

          if (status == 'PENDING') {
            if (!_incomingRequests.any((r) => r.id == reqId)) {
              _incomingRequests = [item];
              _activeRequest = item;
              _sessionType = type;
              notifyListeners();
            }
          } else if (status == 'ACCEPTED') {
            if (_sessionState == SessionState.waitingForAdvisor || _sessionState == SessionState.idle) {
              _activeRequest = item;
              _sessionType = type;
              _sessionState = SessionState.active;
              _incomingRequests.clear();
              if (_chatMessages.isEmpty) {
                _chatMessages = [
                  ChatMessageItem(
                    id: "msg_1",
                    senderId: item.advisorId,
                    senderName: advisorName,
                    message: "Hello $clientName! Welcome to your live session. How can I guide you today?",
                    timestamp: DateTime.now(),
                    isAdvisor: true,
                  )
                ];
              }
              _startSessionTimer();
              notifyListeners();
            }
          } else if (status == 'CANCELLED') {
            if (_sessionState == SessionState.waitingForAdvisor || _sessionState == SessionState.active) {
              _sessionState = SessionState.cancelled;
              _incomingRequests.clear();
              notifyListeners();
            }
          } else if (status == 'ENDED') {
            if (_sessionState == SessionState.active || _sessionState == SessionState.waitingForAdvisor) {
              _sessionState = SessionState.ended;
              _sessionTimer?.cancel();
              _incomingRequests.clear();
              notifyListeners();
            }
          }
        }
      } catch (_) {}

      // 2. Poll API endpoint for remote cross-device sync
      try {
        final url = Uri.parse("/api/session-request");
        final res = await http.get(url).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final session = data['session'];

          if (session != null) {
            if (session['messages'] != null) {
              _syncMessagesFromList(session['messages']);
            }

            final status = session['status'];
            final reqId = session['id'] ?? 'req_1';
            final clientName = session['clientName'] ?? 'Client';
            final advisorName = session['advisorName'] ?? 'Advisor';
            final typeStr = (session['type'] ?? 'chat').toString().toLowerCase();
            final type = typeStr.contains('video')
                ? SessionType.video
                : (typeStr.contains('call') || typeStr.contains('voice') ? SessionType.call : SessionType.chat);

            final item = SessionRequestItem(
              id: reqId,
              clientId: session['clientId'] ?? 'client_1',
              clientName: clientName,
              advisorId: session['advisorId'] ?? '101',
              advisorName: advisorName,
              type: type,
              ratePerMinute: (session['ratePerMinute'] ?? 3.99).toDouble(),
              createdAt: DateTime.now(),
            );

            if (status == 'PENDING') {
              if (!_incomingRequests.any((r) => r.id == reqId)) {
                _incomingRequests = [item];
                _activeRequest = item;
                _sessionType = type;
                notifyListeners();
              }
            } else if (status == 'ACCEPTED') {
              if (_sessionState == SessionState.waitingForAdvisor || _sessionState == SessionState.idle) {
                _activeRequest = item;
                _sessionType = type;
                _sessionState = SessionState.active;
                _incomingRequests.clear();
                if (_chatMessages.isEmpty) {
                  _chatMessages = [
                    ChatMessageItem(
                      id: "msg_1",
                      senderId: item.advisorId,
                      senderName: advisorName,
                      message: "Hello $clientName! Welcome to your live session. How can I guide you today?",
                      timestamp: DateTime.now(),
                      isAdvisor: true,
                    )
                  ];
                }
                _startSessionTimer();
                notifyListeners();
              }
            } else if (status == 'CANCELLED') {
              if (_sessionState == SessionState.waitingForAdvisor || _sessionState == SessionState.active) {
                _sessionState = SessionState.cancelled;
                _incomingRequests.clear();
                notifyListeners();
              }
            } else if (status == 'ENDED') {
              if (_sessionState == SessionState.active || _sessionState == SessionState.waitingForAdvisor) {
                _sessionState = SessionState.ended;
                _sessionTimer?.cancel();
                _incomingRequests.clear();
                notifyListeners();
              }
            }
          } else {
            if (_sessionState == SessionState.active || _sessionState == SessionState.waitingForAdvisor) {
              _sessionState = SessionState.ended;
              _sessionTimer?.cancel();
              _incomingRequests.clear();
              notifyListeners();
            }
          }
        }
      } catch (_) {}

      // 3. Poll session messages endpoint
      try {
        final msgUrl = Uri.parse("/api/session-messages");
        final msgRes = await http.get(msgUrl).timeout(const Duration(seconds: 3));
        if (msgRes.statusCode == 200) {
          final msgData = json.decode(msgRes.body);
          if (msgData['messages'] != null) {
            _syncMessagesFromList(msgData['messages']);
          }
        }
      } catch (_) {}
    });
  }

  // User initiates Chat/Call -> Status = waitingForAdvisor & POST to API / Save Local
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

    try {
      final url = Uri.parse("/api/session-request");
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(sessionMap),
      );
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

  // Advisor accepts the request -> Status = active & POST to session-accept
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
      Map<String, dynamic> sessionMap = {
        'id': req.id,
        'clientName': req.clientName,
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

    try {
      final url = Uri.parse("/api/session-accept");
      await http.post(url);
    } catch (_) {}
  }

  // Advisor declines request -> POST to session-cancel
  void declineSessionRequest(SessionRequestItem req) async {
    _incomingRequests.clear();
    _activeRequest = null;
    _sessionState = SessionState.cancelled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_live_session', json.encode({'status': 'CANCELLED'}));
    } catch (_) {}

    try {
      final url = Uri.parse("/api/session-cancel");
      await http.post(url);
    } catch (_) {}
  }

  // User cancels request while waiting -> POST to session-cancel
  void cancelSessionRequest() async {
    _incomingRequests.clear();
    _activeRequest = null;
    _sessionState = SessionState.idle;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_live_session', json.encode({'status': 'CANCELLED'}));
    } catch (_) {}

    try {
      final url = Uri.parse("/api/session-cancel");
      await http.post(url);
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
    if (message.trim().isEmpty) return;

    final newMsg = ChatMessageItem(
      id: "msg_${DateTime.now().millisecondsSinceEpoch}",
      senderId: senderId,
      senderName: senderName,
      message: message.trim(),
      timestamp: DateTime.now(),
      isAdvisor: isAdvisor,
    );

    if (!_chatMessages.any((m) => m.id == newMsg.id)) {
      _chatMessages.add(newMsg);
      notifyListeners();
    }

    final msgMap = {
      'id': newMsg.id,
      'senderId': newMsg.senderId,
      'senderName': newMsg.senderName,
      'message': newMsg.message,
      'timestamp': newMsg.timestamp.toIso8601String(),
      'isAdvisor': newMsg.isAdvisor,
    };

    // 1. Save to SharedPreferences for instant cross-tab sync
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('active_live_session');
      Map<String, dynamic> sessionMap = {};
      if (localData != null && localData.isNotEmpty) {
        sessionMap = Map<String, dynamic>.from(json.decode(localData));
      }
      List<dynamic> msgs = sessionMap['messages'] is List ? List.from(sessionMap['messages']) : [];
      if (!msgs.any((m) => m is Map && m['id'] == newMsg.id)) {
        msgs.add(msgMap);
      }
      sessionMap['messages'] = msgs;
      await prefs.setString('active_live_session', json.encode(sessionMap));
    } catch (_) {}

    // 2. Post message to remote API for cross-device sync
    try {
      final url = Uri.parse("/api/session-messages");
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(msgMap),
      );
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

    try {
      final url = Uri.parse("/api/session-end");
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(endPayload),
      );
    } catch (_) {}

    try {
      final url = Uri.parse("/api/session-request");
      await http.delete(url);
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

    try {
      final url = Uri.parse("/api/session-request");
      await http.delete(url);
    } catch (_) {}
  }
}
