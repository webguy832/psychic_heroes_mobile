import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants/api_endpoints.dart';
import '../core/utils/storage_service.dart';

enum SignalRConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class IncomingChatRequestRealtime {
  final String requestId;
  final int requestType;
  final String clientId;
  final String advisorId;
  final String? clientName;
  final DateTime requestedAtUtc;
  final int expiresInSeconds;

  IncomingChatRequestRealtime({
    required this.requestId,
    required this.requestType,
    required this.clientId,
    required this.advisorId,
    this.clientName,
    required this.requestedAtUtc,
    this.expiresInSeconds = 60,
  });

  factory IncomingChatRequestRealtime.fromJson(Map<String, dynamic> json) {
    return IncomingChatRequestRealtime(
      requestId: json['requestId']?.toString() ??
          json['RequestId']?.toString() ??
          json['id']?.toString() ??
          json['Id']?.toString() ??
          json['sessionId']?.toString() ??
          json['SessionId']?.toString() ??
          json['CallRequestId']?.toString() ??
          '',
      requestType: (json['requestType'] is num)
          ? (json['requestType'] as num).toInt()
          : ((json['RequestType'] is num) ? (json['RequestType'] as num).toInt() : 1),
      clientId: json['clientId']?.toString() ??
          json['ClientId']?.toString() ??
          json['fromUser']?.toString() ??
          '',
      advisorId: json['advisorId']?.toString() ??
          json['AdvisorId']?.toString() ??
          json['advisorProfileId']?.toString() ??
          json['AdvisorProfileId']?.toString() ??
          '',
      clientName: json['clientName']?.toString() ??
          json['ClientName']?.toString() ??
          json['CustomerName']?.toString() ??
          json['clientScreenName']?.toString() ??
          json['ClientScreenName']?.toString() ??
          json['customerName']?.toString() ??
          json['userName']?.toString(),
      requestedAtUtc: DateTime.tryParse(json['requestedAtUtc']?.toString() ?? json['RequestedAtUtc']?.toString() ?? '') ?? DateTime.now(),
      expiresInSeconds: json['expiresInSeconds'] ?? json['ExpiresInSeconds'] ?? json['TimeoutSeconds'] ?? 60,
    );
  }
}

class RealtimeChatMessage {
  final String userName;
  final String? toUserName;
  final String? connectionId;
  final String message;
  final int messageType;
  final DateTime sentOn;

  RealtimeChatMessage({
    required this.userName,
    this.toUserName,
    this.connectionId,
    required this.message,
    this.messageType = 1,
    required this.sentOn,
  });

  factory RealtimeChatMessage.fromJson(Map<String, dynamic> json) {
    return RealtimeChatMessage(
      userName: json['userName']?.toString() ?? json['UserName']?.toString() ?? '',
      toUserName: json['toUserName']?.toString() ?? json['ToUserName']?.toString(),
      connectionId: json['connectionId']?.toString() ?? json['ConnectionId']?.toString(),
      message: json['message']?.toString() ?? json['Message']?.toString() ?? '',
      messageType: json['msgType'] ?? json['MsgType'] ?? json['messageType'] ?? 1,
      sentOn: DateTime.tryParse(json['sentOn']?.toString() ?? json['SentOn']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Advanced SignalR Hub Service with full protocol parity to Web Angular (@microsoft/signalr)
class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  static const String _recordSeparator = '\u001e';

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  SignalRConnectionState _state = SignalRConnectionState.disconnected;
  String _connectionId = '';
  String _buffer = '';
  int _invocationCounter = 0;
  final Map<String, Completer<dynamic>> _pendingInvocations = {};

  // Presence & session tracking for automatic re-registration after disconnect
  String _savedUserName = '';
  String _savedUserId = '';
  String _savedAdvisorProfileId = '';
  bool _savedIsAdvisor = false;
  String _savedRequestId = '';

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  // Stream Controllers for Real-time Push Events
  final StreamController<SignalRConnectionState> _stateController = StreamController.broadcast();
  final StreamController<RealtimeChatMessage> _messageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _advisorJoinedController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _advisorConnectedController = StreamController.broadcast();
  final StreamController<IncomingChatRequestRealtime> _incomingRequestController = StreamController.broadcast();
  final StreamController<dynamic> _chatCancelledController = StreamController.broadcast();
  final StreamController<dynamic> _chatEndedController = StreamController.broadcast();
  final StreamController<dynamic> _chatHoldController = StreamController.broadcast();
  final StreamController<dynamic> _chatResumeController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _advisorStatusController = StreamController.broadcast();

  // Public Getters
  SignalRConnectionState get state => _state;
  bool get isConnected => _state == SignalRConnectionState.connected;
  String get connectionId => _connectionId;

  Stream<SignalRConnectionState> get stateStream => _stateController.stream;
  Stream<RealtimeChatMessage> get messageReceivedStream => _messageController.stream;
  Stream<Map<String, dynamic>> get advisorJoinedStream => _advisorJoinedController.stream;
  Stream<Map<String, dynamic>> get advisorConnectedStream => _advisorConnectedController.stream;
  Stream<IncomingChatRequestRealtime> get incomingRequestStream => _incomingRequestController.stream;
  Stream<dynamic> get chatCancelledStream => _chatCancelledController.stream;
  Stream<dynamic> get chatEndedStream => _chatEndedController.stream;
  Stream<dynamic> get chatHoldStream => _chatHoldController.stream;
  Stream<dynamic> get chatResumeStream => _chatResumeController.stream;
  Stream<Map<String, dynamic>> get advisorStatusStream => _advisorStatusController.stream;

  /// Ensures SignalR connection is active and user presence is registered (Matching Angular ensureConnected)
  Future<String> ensureConnected({
    required String userName,
    required String userId,
    String advisorProfileId = '',
    bool isAdvisor = false,
    String requestId = '',
  }) async {
    _savedUserName = userName.isNotEmpty ? userName : 'User';
    _savedUserId = userId;
    _savedAdvisorProfileId = advisorProfileId;
    _savedIsAdvisor = isAdvisor;
    if (requestId.isNotEmpty) {
      _savedRequestId = requestId;
    }

    if (_state == SignalRConnectionState.connected && _channel != null) {
      await _registerPresenceInternal();
      if (_savedRequestId.isNotEmpty) {
        if (!_savedIsAdvisor) {
          await connectToChat(_savedUserName, _savedRequestId);
        } else {
          final connId = _connectionId.isNotEmpty ? _connectionId : 'mobile';
          await connectAdvisorToChat(_savedUserName, connId, _savedRequestId);
        }
      }
      return _connectionId;
    }

    if (_state == SignalRConnectionState.connecting) {
      // Wait for existing connecting attempt
      var count = 0;
      while (_state == SignalRConnectionState.connecting && count < 30) {
        await Future.delayed(const Duration(milliseconds: 200));
        count++;
      }
      if (_state == SignalRConnectionState.connected) {
        return _connectionId;
      }
    }

    return await _connect();
  }

  Future<String> _connect() async {
    _setState(SignalRConnectionState.connecting);
    _buffer = '';

    try {
      final token = await StorageService.getToken();
      final negotiateUrl = "${ApiEndpoints.baseUrl}api/chathub/negotiate?negotiateVersion=1";

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final negResp = await http.post(Uri.parse(negotiateUrl), headers: headers);
      if (negResp.statusCode != 200) {
        throw Exception("SignalR negotiate failed with status ${negResp.statusCode}: ${negResp.body}");
      }

      final negJson = jsonDecode(negResp.body) as Map<String, dynamic>;
      final connectionToken = negJson['connectionToken'] ?? negJson['connectionId'];
      if (connectionToken == null || connectionToken.toString().isEmpty) {
        throw Exception("SignalR negotiate returned no connectionToken");
      }

      // Store Connection ID immediately from negotiate response
      _connectionId = negJson['connectionId']?.toString() ?? connectionToken.toString();

      final baseUri = Uri.parse(ApiEndpoints.baseUrl);
      final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
      final wsAuthority = baseUri.authority;
      final wsUrl = "$wsScheme://$wsAuthority/api/chathub?id=${Uri.encodeComponent(connectionToken.toString())}${token != null ? '&access_token=${Uri.encodeComponent(token)}' : ''}";

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      final handshakeCompleter = Completer<void>();

      _channelSub = _channel!.stream.listen(
        (data) {
          _handleRawIncomingData(data.toString(), handshakeCompleter);
        },
        onError: (err) {
          debugPrint("SignalR WebSocket Error: $err");
          _handleDisconnect();
        },
        onDone: () {
          debugPrint("SignalR WebSocket Closed.");
          _handleDisconnect();
        },
      );

      // Send SignalR JSON handshake protocol
      _channel!.sink.add('{"protocol":"json","version":1}$_recordSeparator');

      // Await handshake with 10s timeout
      await handshakeCompleter.future.timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception("SignalR Handshake timed out");
      });

      _setState(SignalRConnectionState.connected);

      // Start ping heartbeat
      _startHeartbeat();

      // Register presence and roles
      await _registerPresenceInternal();

      if (_savedRequestId.isNotEmpty) {
        if (!_savedIsAdvisor) {
          await connectToChat(_savedUserName, _savedRequestId);
        } else {
          final connId = _connectionId.isNotEmpty ? _connectionId : 'mobile';
          await connectAdvisorToChat(_savedUserName, connId, _savedRequestId);
        }
      }

      return _connectionId;
    } catch (e) {
      debugPrint("SignalR Connect failed: $e");
      _handleDisconnect();
      rethrow;
    }
  }

  void _handleRawIncomingData(String rawData, Completer<void> handshakeCompleter) {
    _buffer += rawData;
    while (_buffer.contains(_recordSeparator)) {
      final index = _buffer.indexOf(_recordSeparator);
      final messageStr = _buffer.substring(0, index).trim();
      _buffer = _buffer.substring(index + 1);

      if (messageStr.isEmpty) continue;

      if (!handshakeCompleter.isCompleted) {
        // First message is handshake response: {}
        if (messageStr == '{}' || messageStr.contains('"error":null') || !messageStr.contains('"error":')) {
          handshakeCompleter.complete();
        } else {
          handshakeCompleter.completeError(Exception("SignalR Handshake error: $messageStr"));
        }
        continue;
      }

      _parseSignalRMessage(messageStr);
    }
  }

  void _parseSignalRMessage(String messageStr) {
    try {
      final json = jsonDecode(messageStr);
      if (json is! Map<String, dynamic>) return;

      final type = json['type'] as int?;

      // Type 6: Ping keepalive from server
      if (type == 6) {
        _channel?.sink.add('{"type":6}$_recordSeparator');
        return;
      }

      // Type 3: Invocation result
      if (type == 3) {
        final invId = json['invocationId']?.toString();
        if (invId != null && _pendingInvocations.containsKey(invId)) {
          final completer = _pendingInvocations.remove(invId)!;
          if (json.containsKey('error') && json['error'] != null) {
            completer.completeError(Exception(json['error']));
          } else {
            completer.complete(json['result']);
          }
        }
        return;
      }

      // Type 1: Server invocation / broadcast event
      if (type == 1) {
        final target = json['target']?.toString();
        final args = (json['arguments'] as List?) ?? [];

        _dispatchHubEvent(target, args);
      }
    } catch (e) {
      debugPrint("Error parsing SignalR message: $e");
    }
  }

  void _dispatchHubEvent(String? target, List<dynamic> args) {
    if (target == null) return;

    switch (target) {
      case 'connected':
        if (args.isNotEmpty) {
          _connectionId = args[0]?.toString() ?? '';
          debugPrint("SignalR Connected with Connection ID: $_connectionId");
        }
        break;

      case 'privateMsgRecivied':
        if (args.isNotEmpty && args[0] is Map) {
          final msg = RealtimeChatMessage.fromJson(args[0] as Map<String, dynamic>);
          _messageController.add(msg);
        }
        break;

      case 'customer.request.accepted':
      case 'advisorJoined':
        String connId = '';
        String name = 'Advisor';
        if (args.isNotEmpty) {
          if (args[0] is Map) {
            final m = args[0] as Map;
            connId = m['advisorConnectionId']?.toString() ?? m['clientConnectionId']?.toString() ?? '';
            name = m['advisorName']?.toString() ?? 'Advisor';
          } else {
            connId = args[0]?.toString() ?? '';
            if (args.length >= 2) {
              name = args[1]?.toString() ?? 'Advisor';
            }
          }
        }
        _advisorJoinedController.add({
          'connectionId': connId,
          'name': name,
          if (args.isNotEmpty && args[0] is Map) ...(args[0] as Map).cast<String, dynamic>(),
        });
        break;

      case 'advisor.request.accepted.confirm':
      case 'advisorConnected':
        String connId = '';
        String name = 'Advisor';
        if (args.isNotEmpty) {
          if (args[0] is Map) {
            final m = args[0] as Map;
            connId = m['connectionId']?.toString() ?? '';
            name = m['name']?.toString() ?? 'Advisor';
          } else {
            connId = args[0]?.toString() ?? '';
            if (args.length >= 2) {
              name = args[1]?.toString() ?? 'Advisor';
            }
          }
        }
        if (connId.isNotEmpty) {
          _connectionId = connId;
        }
        _advisorConnectedController.add({
          'connectionId': connId,
          'name': name,
          if (args.isNotEmpty && args[0] is Map) ...(args[0] as Map).cast<String, dynamic>(),
        });
        break;

      case 'advisor.request.incoming':
      case 'incomingSession':
      case 'incomingVideoSession':
      case 'IncomingCallRequest':
      case 'incomingCallRequest':
      case 'notificationChat':
      case 'notification':
        if (args.isNotEmpty && args[0] is Map) {
          final req = IncomingChatRequestRealtime.fromJson(args[0] as Map<String, dynamic>);
          _incomingRequestController.add(req);
        }
        break;

      case 'ChatCancelled':
      case 'customer.request.timeout':
      case 'advisor.request.timeout':
        _chatCancelledController.add(args.isNotEmpty ? args[0] : null);
        break;

      case 'chatEndedByOther':
      case 'chatEnded':
        _chatEndedController.add(args.isNotEmpty ? args[0] : null);
        break;

      case 'chatOnHold':
        _chatHoldController.add(args.isNotEmpty ? args[0] : null);
        break;

      case 'chatOnResume':
        _chatResumeController.add(args.isNotEmpty ? args[0] : null);
        break;

      case 'AdvisorStatusChanged':
        if (args.isNotEmpty && args[0] is Map) {
          _advisorStatusController.add(args[0] as Map<String, dynamic>);
        }
        break;

      default:
        debugPrint("Unhandled SignalR event: $target");
        break;
    }
  }

  Future<void> _registerPresenceInternal() async {
    if (_savedUserId.isEmpty) return;

    try {
      await invoke('RegisterPresence', [
        _savedUserId,
        _savedUserName,
        _savedIsAdvisor,
        _savedAdvisorProfileId.isNotEmpty ? _savedAdvisorProfileId : null,
      ]);

      if (_savedIsAdvisor) {
        if (_savedAdvisorProfileId.isNotEmpty) {
          await invoke('RegisterAdvisor', [_savedAdvisorProfileId]);
        }
        if (_savedUserId.isNotEmpty && _savedUserId != _savedAdvisorProfileId) {
          await invoke('RegisterAdvisor', [_savedUserId]);
        }
      } else {
        await invoke('RegisterCustomer', [_savedUserId]);
      }
      debugPrint("SignalR presence registered successfully for $_savedUserName (isAdvisor: $_savedIsAdvisor, advisorProfileId: $_savedAdvisorProfileId)");
    } catch (e) {
      debugPrint("RegisterPresence error: $e");
    }
  }

  /// Invoke a method on the SignalR Hub with arguments
  Future<dynamic> invoke(String method, List<dynamic> args) async {
    if (_state != SignalRConnectionState.connected || _channel == null) {
      throw Exception("SignalR is not connected (current state: $_state)");
    }

    final invocationId = (++_invocationCounter).toString();
    final completer = Completer<dynamic>();
    _pendingInvocations[invocationId] = completer;

    final payload = jsonEncode({
      'type': 1,
      'invocationId': invocationId,
      'target': method,
      'arguments': args,
    }) + _recordSeparator;

    _channel!.sink.add(payload);

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _pendingInvocations.remove(invocationId);
        throw Exception("SignalR invoke('$method') timed out");
      },
    );
  }

  /// Connect Customer to Chat Session Group
  Future<void> connectToChat(String userName, String requestId) async {
    _savedRequestId = requestId;
    await invoke('Connect', [userName, requestId]);
  }

  /// Connect Advisor to Chat Session Group
  Future<void> connectAdvisorToChat(String userName, String connectTo, String requestId) async {
    _savedRequestId = requestId;
    await invoke('ConnectAdvisor', [userName, connectTo, requestId]);
  }

  /// Send chat message in real-time over SignalR (triggers instant push to opponent)
  Future<void> sendChatMessage({
    required String message,
    required String requestId,
    required String fromUser,
    int messageType = 1,
  }) async {
    final payload = {
      'Message': message,
      'MsgType': messageType,
      'RequestId': requestId,
      'fromUser': fromUser,
    };
    await invoke('SendMessageToUser', [payload]);
  }

  /// End chat session notification over SignalR
  Future<void> endChat(String requestId, int totalTime) async {
    try {
      await invoke('EndChat', [requestId, totalTime]);
    } catch (_) {}
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_state == SignalRConnectionState.connected && _channel != null) {
        _channel!.sink.add('{"type":6}$_recordSeparator');
      }
    });
  }

  void _handleDisconnect() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_state != SignalRConnectionState.disconnected && !_isDisposed) {
      _setState(SignalRConnectionState.reconnecting);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () async {
      if (_isDisposed) return;
      if (_savedUserId.isNotEmpty) {
        debugPrint("SignalR attempting auto-reconnect...");
        try {
          await ensureConnected(
            userName: _savedUserName,
            userId: _savedUserId,
            advisorProfileId: _savedAdvisorProfileId,
            isAdvisor: _savedIsAdvisor,
            requestId: _savedRequestId,
          );
        } catch (_) {
          _scheduleReconnect();
        }
      }
    });
  }

  void _setState(SignalRConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  void disconnect() {
    _savedRequestId = '';
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _channelSub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setState(SignalRConnectionState.disconnected);
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _stateController.close();
    _messageController.close();
    _advisorJoinedController.close();
    _advisorConnectedController.close();
    _incomingRequestController.close();
    _chatCancelledController.close();
    _chatEndedController.close();
    _chatHoldController.close();
    _chatResumeController.close();
    _advisorStatusController.close();
  }
}

