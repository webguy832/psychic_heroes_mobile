import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/session_provider.dart';
import '../../providers/user_provider.dart';
import 'session_after_summary_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final bool isAdvisorView;

  const VideoCallScreen({
    Key? key,
    this.isAdvisorView = false,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> with SingleTickerProviderStateMixin {
  bool _isChatOpen = false;
  bool _isFrontCamera = true;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMsgCount = 0;
  bool _handledSessionEnd = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSessionChat();
    });
  }

  void _initSessionChat() async {
    if (!mounted) return;
    final sessionProv = Provider.of<SessionProvider>(context, listen: false);
    final activeReq = sessionProv.activeRequest;
    if (activeReq != null && !activeReq.id.startsWith("req_")) {
      try {
        if (widget.isAdvisorView) {
          final connId = sessionProv.connectionId.isNotEmpty ? sessionProv.connectionId : 'mobile';
          await sessionProv.signalR.connectAdvisorToChat(activeReq.advisorName, connId, activeReq.id);
        } else {
          await sessionProv.signalR.connectToChat(activeReq.clientName, activeReq.id);
        }
      } catch (_) {}
      await sessionProv.syncChatHistory(activeReq.id);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _checkAutoClose(SessionProvider sessionProv, String titleName) {
    if (sessionProv.sessionState == SessionState.ended && !_handledSessionEnd) {
      _handledSessionEnd = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Video Call has been ended by ${widget.isAdvisorView ? 'Client' : 'Advisor'} ($titleName). Redirecting..."),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
        final summaryCost = sessionProv.chatSummary?['chargedAmount'] ??
            sessionProv.chatSummary?['totalCharges'] ??
            sessionProv.chatSummary?['ChargedAmount'] ??
            sessionProv.chatSummary?['TotalCharges'];
        final finalCost = (summaryCost is num) ? summaryCost.toDouble() : sessionProv.currentSessionCost;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SessionAfterSummaryScreen(
              isAdvisorView: widget.isAdvisorView,
              participantName: titleName,
              formattedTime: sessionProv.formattedTimer,
              totalCost: finalCost,
              sessionTypeLabel: "Video Call",
              advisorId: sessionProv.activeRequest?.advisorId,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionProv = Provider.of<SessionProvider>(context);
    final user = Provider.of<UserProvider>(context).user;
    final activeReq = sessionProv.activeRequest;

    final titleName = widget.isAdvisorView
        ? (activeReq?.clientName ?? "Client")
        : (activeReq?.advisorName ?? "Advisor");

    _checkAutoClose(sessionProv, titleName);

    if (sessionProv.chatMessages.length != _lastMsgCount) {
      _lastMsgCount = sessionProv.chatMessages.length;
      if (_isChatOpen) _scrollToBottom();
    }

    final double effectiveRate = activeReq?.ratePerMinute ?? sessionProv.advisorBaseRate;
    final int freeMinutes = activeReq?.freeMinutes ?? (sessionProv.freeLeftSeconds ~/ 60);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main Full-Screen Video Canvas ──
            Positioned.fill(
              child: sessionProv.isVideoOn
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.9,
                          colors: [Color(0xFF1E1742), Color(0xFF0C0A1A), Colors.black],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Grid subtle pattern frame
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.accentCyan.withOpacity(0.15), width: 1.5),
                              ),
                            ),
                          ),

                          // Central Speaker Visualizer & Avatar
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) {
                                  final pulse = sessionProv.isMuted ? 0.0 : _pulseController.value;
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Active Speaker Glowing Ring
                                      Container(
                                        width: 140 + (pulse * 20),
                                        height: 140 + (pulse * 20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.accentCyan.withOpacity(0.08 + (pulse * 0.08)),
                                          border: Border.all(
                                            color: AppColors.accentCyan.withOpacity(0.3 + (pulse * 0.3)),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accentCyan.withOpacity(0.25 + (pulse * 0.2)),
                                              blurRadius: 24,
                                              spreadRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      CircleAvatar(
                                        radius: 54,
                                        backgroundColor: const Color(0xFF4C1D95),
                                        child: Text(
                                          titleName.isNotEmpty ? titleName[0].toUpperCase() : 'V',
                                          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.onlineGreen,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 18),

                              // Name & Live HD Stream tag
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: AppColors.onlineGreen, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "$titleName (Live HD Video)",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Twilio Video Encrypted Stream Badge (Web App Parity)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.hd_rounded, color: AppColors.accentCyan, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      "1080p HD · 60 FPS · WebRTC Opus/H.264",
                                      style: TextStyle(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Container(
                      color: const Color(0xFF0F172A),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 64),
                          SizedBox(height: 12),
                          Text("Camera Paused", style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Tap video camera icon below to resume live video feed", style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
            ),

            // ── Top Header Overlay (Title, Duration, Rate, Participants, End Call) ──
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.accentCyan, size: 18),
                      onPressed: () => _confirmEndVideoCall(context, sessionProv, titleName),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "📹 Video Call · $titleName",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: sessionProv.isChargingStarted ? AppColors.onlineGreen : AppColors.accentGold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sessionProv.isChargingStarted
                                    ? "Billed: \$${sessionProv.currentSessionCost.toStringAsFixed(2)}"
                                    : "Grace: ${sessionProv.secondsUntilCharging}s left",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: sessionProv.isChargingStarted ? AppColors.onlineGreen : AppColors.accentGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (freeMinutes > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  "• Free: ${freeMinutes}m",
                                  style: const TextStyle(fontSize: 10, color: AppColors.onlineGreen, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Duration Timer Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_rounded, size: 12, color: AppColors.accentGold),
                          const SizedBox(width: 4),
                          Text(
                            sessionProv.formattedTimer,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGold, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Participant Count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text("👥 2", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),

                    // End Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 12),
                      label: const Text("END", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
                      onPressed: () => _confirmEndVideoCall(context, sessionProv, titleName),
                    ),
                  ],
                ),
              ),
            ),

            // ── In-Call Free Minutes Over Toast Banner (Web App Parity) ──
            if (sessionProv.showFreeFinishedNotice && !widget.isAdvisorView)
              Positioned(
                top: 75,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text("⏱️", style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Your free minutes are over. Now session time will be deducted from your balance.",
                          style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.black, size: 16),
                        onPressed: () => sessionProv.dismissFreeFinishedNotice(),
                      ),
                    ],
                  ),
                ),
              ),

            // ── PIP Local Camera Viewport (Top Right) ──
            Positioned(
              top: 80,
              right: 14,
              child: Container(
                width: 95,
                height: 130,
                decoration: BoxDecoration(
                  color: sessionProv.isVideoOn ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sessionProv.isVideoOn ? AppColors.accentCyan : AppColors.errorRed.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (sessionProv.isVideoOn) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.accentGold, width: 1.5)),
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.accentPurple,
                              child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.displayName ?? "You",
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.videocam_rounded, color: AppColors.accentCyan, size: 10),
                              SizedBox(width: 2),
                              Text("Self Cam", style: TextStyle(color: AppColors.accentCyan, fontSize: 8, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            _isFrontCamera ? "FRONT" : "BACK",
                            style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ] else ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.videocam_off_rounded, color: AppColors.errorRed, size: 24),
                          SizedBox(height: 4),
                          Text("Cam Off", style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Floating Controls Bar (Bottom Center) ──
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Mute / Unmute Mic
                    IconButton(
                      iconSize: 26,
                      icon: Icon(
                        sessionProv.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: sessionProv.isMuted ? AppColors.errorRed : AppColors.accentGold,
                      ),
                      tooltip: sessionProv.isMuted ? "Unmute" : "Mute",
                      onPressed: () => sessionProv.toggleMute(),
                    ),

                    // Toggle Camera Video Feed
                    IconButton(
                      iconSize: 26,
                      icon: Icon(
                        sessionProv.isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        color: sessionProv.isVideoOn ? AppColors.accentCyan : Colors.grey,
                      ),
                      tooltip: sessionProv.isVideoOn ? "Stop Video" : "Start Video",
                      onPressed: () => sessionProv.toggleVideo(),
                    ),

                    // Flip Camera (Front / Back)
                    IconButton(
                      iconSize: 26,
                      icon: Icon(
                        _isFrontCamera ? Icons.flip_camera_android_rounded : Icons.cameraswitch_rounded,
                        color: Colors.white,
                      ),
                      tooltip: "Flip Camera",
                      onPressed: () {
                        setState(() => _isFrontCamera = !_isFrontCamera);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isFrontCamera ? "Switched to Front Camera" : "Switched to Back Camera"),
                            duration: const Duration(milliseconds: 800),
                          ),
                        );
                      },
                    ),

                    // In-Call Chat Drawer Toggle with unread badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          iconSize: 26,
                          icon: Icon(
                            _isChatOpen ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                            color: AppColors.accentCyan,
                          ),
                          tooltip: "Chat",
                          onPressed: () {
                            setState(() => _isChatOpen = !_isChatOpen);
                            if (_isChatOpen) _scrollToBottom();
                          },
                        ),
                        if (sessionProv.chatMessages.isNotEmpty && !_isChatOpen)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.accentGold,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${sessionProv.chatMessages.length}",
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // End Video Call Button
                    CircleAvatar(
                      backgroundColor: AppColors.errorRed,
                      radius: 22,
                      child: IconButton(
                        icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 20),
                        tooltip: "End Call",
                        onPressed: () => _confirmEndVideoCall(context, sessionProv, titleName),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── In-Call Chat Slide-up Sheet (Web App Parity) ──
            if (_isChatOpen)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.48,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF161226),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, -4)),
                    ],
                    border: Border(top: BorderSide(color: AppColors.accentCyan)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.chat_bubble_rounded, size: 16, color: AppColors.accentCyan),
                                SizedBox(width: 8),
                                Text("In-Call Messages", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 24),
                              onPressed: () => setState(() => _isChatOpen = false),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      Expanded(
                        child: sessionProv.chatMessages.isEmpty
                            ? Center(
                                child: Text(
                                  "No messages yet.\nType below to message during video call.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(12),
                                itemCount: sessionProv.chatMessages.length,
                                itemBuilder: (context, index) {
                                  final msg = sessionProv.chatMessages[index];
                                  final isMe = !msg.isOpponent;

                                  return Align(
                                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isMe ? AppColors.primaryLight : const Color(0xFF24143D),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg.senderName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isMe ? AppColors.accentGold : AppColors.accentCyan,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(msg.message, style: const TextStyle(fontSize: 13, color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: const Color(0xFF0D0B18),
                        child: SafeArea(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _msgController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: "Send message during video...",
                                    hintStyle: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1B4B),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                  ),
                                  onSubmitted: (_) => _sendMessage(sessionProv, user?.displayName ?? "User"),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.send_rounded, color: AppColors.accentGold),
                                onPressed: () => _sendMessage(sessionProv, user?.displayName ?? "User"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(SessionProvider sessionProv, String userName) {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    sessionProv.sendChatMessage(
      senderId: widget.isAdvisorView ? (sessionProv.activeRequest?.advisorId ?? "advisor") : (sessionProv.activeRequest?.clientId ?? "user"),
      senderName: widget.isAdvisorView ? (sessionProv.activeRequest?.advisorName ?? "Advisor") : userName,
      message: text,
      isAdvisor: widget.isAdvisorView,
    );

    _msgController.clear();
    _scrollToBottom();
  }

  void _confirmEndVideoCall(BuildContext context, SessionProvider sessionProv, String titleName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161226),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("End Video Call?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Video Call Duration: ${sessionProv.formattedTimer}\nEstimated Cost: \$${sessionProv.currentSessionCost.toStringAsFixed(2)}",
          style: const TextStyle(color: AppColors.textPrimaryDark),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text("End Video Call", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () async {
              final durationStr = sessionProv.formattedTimer;
              final costVal = sessionProv.currentSessionCost;
              Navigator.pop(ctx);
              await sessionProv.endSession();
              final summaryCost = sessionProv.chatSummary?['chargedAmount'] ??
                  sessionProv.chatSummary?['totalCharges'] ??
                  sessionProv.chatSummary?['ChargedAmount'] ??
                  sessionProv.chatSummary?['TotalCharges'];
              final finalCost = (summaryCost is num) ? summaryCost.toDouble() : costVal;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionAfterSummaryScreen(
                    isAdvisorView: widget.isAdvisorView,
                    participantName: titleName,
                    formattedTime: durationStr,
                    totalCost: finalCost,
                    sessionTypeLabel: "Video Call",
                    advisorId: sessionProv.activeRequest?.advisorId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
