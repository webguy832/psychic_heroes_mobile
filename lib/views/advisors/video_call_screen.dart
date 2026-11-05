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

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isChatOpen = false;
  bool _isFrontCamera = true;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMsgCount = 0;
  bool _handledSessionEnd = false;

  @override
  void dispose() {
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
    if ((sessionProv.sessionState == SessionState.ended || sessionProv.sessionState == SessionState.idle) && !_handledSessionEnd) {
      _handledSessionEnd = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Video Call has been ended by ${widget.isAdvisorView ? 'Client' : 'Advisor'} ($titleName). Redirecting..."),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SessionAfterSummaryScreen(
              isAdvisorView: widget.isAdvisorView,
              participantName: titleName,
              formattedTime: sessionProv.formattedTimer,
              totalCost: sessionProv.currentSessionCost,
              sessionTypeLabel: "Video Call",
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Full-Bleed Remote Video Stream Viewport
            Positioned.fill(
              child: sessionProv.isVideoOn
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.85,
                          colors: [Color(0xFF1E1B4B), Colors.black],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Live Video Stream Grid Background Frame
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.accentCyan.withOpacity(0.2), width: 1.5),
                              ),
                            ),
                          ),

                          // Main Remote Video Stream Visual
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Active Speaker Glowing Ring
                                  Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.accentCyan.withOpacity(0.12),
                                      border: Border.all(color: AppColors.accentCyan.withOpacity(0.5), width: 2),
                                      boxShadow: [
                                        BoxShadow(color: AppColors.accentCyan.withOpacity(0.35), blurRadius: 24, spreadRadius: 4),
                                      ],
                                    ),
                                  ),
                                  CircleAvatar(
                                    radius: 56,
                                    backgroundColor: AppColors.accentPurple,
                                    child: Text(
                                      titleName.isNotEmpty ? titleName[0].toUpperCase() : 'V',
                                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: AppColors.onlineGreen, shape: BoxShape.circle),
                                      child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.onlineGreen, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text("$titleName (Live HD Video)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 1080p HD Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.accentCyan.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.hd_rounded, color: AppColors.accentCyan, size: 14),
                                    SizedBox(width: 4),
                                    Text("1080p HD • 60 FPS • Encrypted Stream", style: TextStyle(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.bold)),
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
                          Text("Tap video icon below to resume video feed", style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
            ),

            // Top Header Overlay Bar (Title, Status, Timer, End Call)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentCyan.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.accentCyan, size: 20),
                      onPressed: () => _confirmEndVideoCall(context, sessionProv, titleName),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titleName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                          Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.onlineGreen, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              const Text("LIVE VIDEO SESSION", style: TextStyle(fontSize: 9, color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              Text(
                                sessionProv.isChargingStarted
                                    ? "• \$${activeReq?.ratePerMinute ?? 3.99}/min (Billed: \$${sessionProv.currentSessionCost.toStringAsFixed(2)})"
                                    : "• \$${activeReq?.ratePerMinute ?? 3.99}/min (Grace: ${sessionProv.secondsUntilCharging}s left)",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: sessionProv.isChargingStarted ? AppColors.onlineGreen : AppColors.accentGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Timer Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accentGold)),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_rounded, size: 12, color: AppColors.accentGold),
                          const SizedBox(width: 4),
                          Text(sessionProv.formattedTimer, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 14),
                      label: const Text("END", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                      onPressed: () => _confirmEndVideoCall(context, sessionProv, titleName),
                    ),
                  ],
                ),
              ),
            ),

            // PIP Local Camera Window Overlay (Top Right)
            Positioned(
              top: 75,
              right: 14,
              child: Container(
                width: 95,
                height: 130,
                decoration: BoxDecoration(
                  color: sessionProv.isVideoOn ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sessionProv.isVideoOn ? AppColors.accentCyan : AppColors.errorRed.withOpacity(0.5), width: 1.5),
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

            // Floating Controls Bar Overlay (Bottom Center)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Mute Mic
                    IconButton(
                      iconSize: 26,
                      icon: Icon(
                        sessionProv.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: sessionProv.isMuted ? AppColors.errorRed : AppColors.accentGold,
                      ),
                      onPressed: () => sessionProv.toggleMute(),
                    ),
                    // Toggle Camera On/Off
                    IconButton(
                      iconSize: 26,
                      icon: Icon(
                        sessionProv.isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        color: sessionProv.isVideoOn ? AppColors.accentCyan : Colors.grey,
                      ),
                      onPressed: () => sessionProv.toggleVideo(),
                    ),
                    // Flip Camera (Front / Back)
                    IconButton(
                      iconSize: 26,
                      icon: Icon(
                        _isFrontCamera ? Icons.flip_camera_android_rounded : Icons.cameraswitch_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() => _isFrontCamera = !_isFrontCamera);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_isFrontCamera ? "Switched to Front Camera" : "Switched to Back Camera"), duration: const Duration(milliseconds: 800)),
                        );
                      },
                    ),
                    // In-Call Chat Drawer Toggle
                    IconButton(
                      iconSize: 26,
                      icon: Icon(
                        _isChatOpen ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                        color: AppColors.accentCyan,
                      ),
                      onPressed: () {
                        setState(() => _isChatOpen = !_isChatOpen);
                        if (_isChatOpen) _scrollToBottom();
                      },
                    ),
                    // End Video Call
                    CircleAvatar(
                      backgroundColor: AppColors.errorRed,
                      radius: 22,
                      child: IconButton(
                        icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 20),
                        onPressed: () => _confirmEndVideoCall(context, sessionProv, titleName),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // In-Call Chat Slide-up Sheet
            if (_isChatOpen)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.45,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bgDarkCard,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: AppColors.accentCyan)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("In-Call Messages", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                              onPressed: () => setState(() => _isChatOpen = false),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.borderDark, height: 1),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: sessionProv.chatMessages.length,
                          itemBuilder: (context, index) {
                            final msg = sessionProv.chatMessages[index];
                            final isMe = widget.isAdvisorView ? msg.isAdvisor : !msg.isAdvisor;

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isMe ? AppColors.primaryLight : AppColors.bgDark,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(msg.senderName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMe ? AppColors.accentGold : AppColors.accentCyan)),
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
                        color: AppColors.bgDark,
                        child: SafeArea(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _msgController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: "Send message...",
                                    hintStyle: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
                                    filled: true,
                                    fillColor: AppColors.bgDarkCard,
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
        backgroundColor: AppColors.bgDarkCard,
        title: const Text("End Video Call?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Video Call Duration: ${sessionProv.formattedTimer}\nEstimated Cost: \$${sessionProv.currentSessionCost.toStringAsFixed(2)}",
          style: const TextStyle(color: AppColors.textPrimaryDark),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionAfterSummaryScreen(
                    isAdvisorView: widget.isAdvisorView,
                    participantName: titleName,
                    formattedTime: durationStr,
                    totalCost: costVal,
                    sessionTypeLabel: "Video Call",
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
