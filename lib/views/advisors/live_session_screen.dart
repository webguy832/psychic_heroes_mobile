import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/session_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import 'session_after_summary_screen.dart';
import '../menu_pages/add_funds_screen.dart';

class LiveSessionScreen extends StatefulWidget {
  final bool isAdvisorView;

  const LiveSessionScreen({
    Key? key,
    this.isAdvisorView = false,
  }) : super(key: key);

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
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
    if (sessionProv.sessionState == SessionState.ended && !_handledSessionEnd) {
      _handledSessionEnd = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Session has been ended by ${widget.isAdvisorView ? 'Client' : 'Advisor'} ($titleName). Redirecting..."),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
        final summaryCost = sessionProv.chatSummary?['chargedAmount'] ??
            sessionProv.chatSummary?['totalCharges'] ??
            sessionProv.chatSummary?['ChargedAmount'];
        final finalCost = (summaryCost is num) ? summaryCost.toDouble() : sessionProv.currentSessionCost;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SessionAfterSummaryScreen(
              isAdvisorView: widget.isAdvisorView,
              participantName: titleName,
              formattedTime: sessionProv.formattedTimer,
              totalCost: finalCost,
              sessionTypeLabel: "Live Chat",
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
      _scrollToBottom();
    }

    final isVideo = sessionProv.sessionType == SessionType.video;
    final isCall = sessionProv.sessionType == SessionType.call || isVideo;
    final sessionLabel = isVideo
        ? "LIVE VIDEO CALL"
        : (sessionProv.sessionType == SessionType.call ? "LIVE VOICE CALL" : "LIVE CHAT SESSION");

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.accentGold),
          onPressed: () => _confirmEndSession(context, sessionProv),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isVideo ? AppColors.accentCyan : AppColors.accentGold,
              child: Text(
                titleName.isNotEmpty ? titleName[0].toUpperCase() : 'P',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.onlineGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sessionLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: isVideo ? AppColors.accentCyan : AppColors.onlineGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sessionProv.isChargingStarted
                            ? "• \$${(activeReq?.ratePerMinute ?? sessionProv.advisorBaseRate).toStringAsFixed(2)}/min (Billed: \$${sessionProv.currentSessionCost.toStringAsFixed(2)})"
                            : "• \$${(activeReq?.ratePerMinute ?? sessionProv.advisorBaseRate).toStringAsFixed(2)}/min (Grace: ${sessionProv.secondsUntilCharging}s left)",
                        style: TextStyle(
                          fontSize: 10,
                          color: sessionProv.isChargingStarted ? AppColors.onlineGreen : AppColors.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGold),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, size: 14, color: AppColors.accentGold),
                const SizedBox(width: 4),
                Text(
                  sessionProv.formattedTimer,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 14),
              label: Text(
                isCall ? "END CALL" : "END CHAT",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
              ),
              onPressed: () => _confirmEndSession(context, sessionProv),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Media Viewport: Video Call or Voice Call Header
          if (isVideo)
            _buildVideoCallViewport(sessionProv, titleName)
          else if (sessionProv.sessionType == SessionType.call)
            _buildVoiceCallHeader(sessionProv, titleName),

          // Active Free Minutes Notice Banner
          if (sessionProv.freeLeftSeconds > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1E3A2B),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.accentGold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Free Promotional Chat: ${(sessionProv.freeLeftSeconds ~/ 60) + 1}m remaining free",
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Free Minutes Finished Transition Notice
          if (sessionProv.showFreeFinishedNotice)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF3B2E1E),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Free minutes finished. Session continuing from main wallet.",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => sessionProv.dismissFreeFinishedNotice(),
                    child: const Text("DISMISS", style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Low Balance Warning Banner (<= 3 mins left)
          if (sessionProv.isLowBalanceWarning && !widget.isAdvisorView)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF4A1E1E),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Low Balance: Less than 3 minutes remaining.",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddFundsScreen()),
                      );
                    },
                    child: const Text("ADD FUNDS", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // On-Hold Notice Banner / Action
          if (sessionProv.sessionState == SessionState.hold)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF3B1E1E),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pause_circle_filled_rounded, color: AppColors.errorRed, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Session Paused: Wallet balance depleted.",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Session timer is paused. Add funds to immediately resume chatting with your advisor.",
                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaGreen),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddFundsScreen()),
                      );
                      sessionProv.resumeHeldSession(sessionProv.userBalance > 0 ? sessionProv.userBalance : 10.0);
                    },
                    child: const Text("ADD FUNDS & RESUME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: sessionProv.chatMessages.length,
              itemBuilder: (context, index) {
                final msg = sessionProv.chatMessages[index];
                final isMe = !msg.isOpponent;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primaryLight : AppColors.bgDarkCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: Border.all(
                        color: isMe ? AppColors.accentGold.withOpacity(0.4) : AppColors.borderDark,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.senderName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isMe ? AppColors.accentGold : AppColors.accentCyan,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.message,
                          style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 9, color: AppColors.textPrimaryDark),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick Response Suggestions (for Advisors)
          if (widget.isAdvisorView) _buildQuickReplies(sessionProv),

          // Chat Bottom Bar / Input Field
          _buildMessageInputField(context, sessionProv, user?.displayName ?? "User"),
        ],
      ),
    );
  }

  Widget _buildVideoCallViewport(SessionProvider sessionProv, String titleName) {
    return Container(
      height: 220,
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.accentCyan.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // Remote Participant Main Video Container
          Center(
            child: sessionProv.isVideoOn
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentCyan.withOpacity(0.15),
                          border: Border.all(color: AppColors.accentCyan, width: 2),
                          boxShadow: [
                            BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 16),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.accentPurple,
                          child: Text(
                            titleName.isNotEmpty ? titleName[0].toUpperCase() : 'V',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                            "$titleName (Live 1080p HD Video)",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 40),
                      SizedBox(height: 6),
                      Text("Camera Paused", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text("Tap video button below to unpause", style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
          ),

          // PIP Local Camera Thumbnail (Top Right)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: sessionProv.isVideoOn ? const Color(0xFF1E293B) : AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sessionProv.isVideoOn ? AppColors.accentCyan : AppColors.borderDark, width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (sessionProv.isVideoOn) ...[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.accentPurple,
                          child: Icon(Icons.person_rounded, color: Colors.white, size: 16),
                        ),
                        SizedBox(height: 4),
                        Text("Self Cam", style: TextStyle(color: AppColors.accentCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppColors.onlineGreen, shape: BoxShape.circle),
                      ),
                    ),
                  ] else ...[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.videocam_off_rounded, color: AppColors.errorRed, size: 20),
                        SizedBox(height: 2),
                        Text("Off", style: TextStyle(color: Colors.white70, fontSize: 9)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Embedded Video Controls Overlay Bar (Bottom)
          Positioned(
            bottom: 8,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      sessionProv.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: sessionProv.isMuted ? AppColors.errorRed : AppColors.accentGold,
                      size: 20,
                    ),
                    onPressed: () => sessionProv.toggleMute(),
                  ),
                  IconButton(
                    icon: Icon(
                      sessionProv.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: sessionProv.isSpeakerOn ? AppColors.onlineGreen : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => sessionProv.toggleSpeaker(),
                  ),
                  IconButton(
                    icon: Icon(
                      sessionProv.isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                      color: sessionProv.isVideoOn ? AppColors.accentCyan : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => sessionProv.toggleVideo(),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 14),
                    label: const Text("END", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                    onPressed: () => _confirmEndSession(context, sessionProv),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCallHeader(SessionProvider sessionProv, String titleName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        border: Border(bottom: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              sessionProv.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: sessionProv.isMuted ? AppColors.errorRed : AppColors.accentGold,
            ),
            onPressed: () => sessionProv.toggleMute(),
          ),
          IconButton(
            icon: Icon(
              sessionProv.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: sessionProv.isSpeakerOn ? AppColors.onlineGreen : Colors.grey,
            ),
            onPressed: () => sessionProv.toggleSpeaker(),
          ),
          IconButton(
            icon: Icon(
              sessionProv.isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              color: sessionProv.isVideoOn ? AppColors.accentCyan : Colors.grey,
            ),
            onPressed: () => sessionProv.toggleVideo(),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 18),
            label: const Text("END CALL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: () => _confirmEndSession(context, sessionProv),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(SessionProvider sessionProv) {
    final quickTexts = [
      "I see a positive energy shift ahead ✨",
      "Let's check your Tarot spread 🎴",
      "Your natal chart aligns with success 🌟",
      "Focus on inner peace and clarity ❤️",
    ];

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickTexts.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: AppColors.bgDarkCard,
              side: const BorderSide(color: AppColors.borderDark),
              label: Text(
                quickTexts[i],
                style: const TextStyle(fontSize: 11, color: AppColors.textPrimaryDark),
              ),
              onPressed: () {
                sessionProv.sendChatMessage(
                  senderId: sessionProv.activeRequest?.advisorId ?? "advisor",
                  senderName: sessionProv.activeRequest?.advisorName ?? "Advisor",
                  message: quickTexts[i],
                  isAdvisor: true,
                );
                _scrollToBottom();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInputField(BuildContext context, SessionProvider sessionProv, String userName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.bgDarkCard,
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  hintStyle: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.bgDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.borderDark),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(sessionProv, userName),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.accentGold,
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                onPressed: () => _sendMessage(sessionProv, userName),
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

  void _confirmEndSession(BuildContext context, SessionProvider sessionProv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        title: const Text("End Live Session?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Total Duration: ${sessionProv.formattedTimer}\nEstimated Cost: \$${sessionProv.currentSessionCost.toStringAsFixed(2)}",
          style: const TextStyle(color: AppColors.textPrimaryDark),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text("End Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () async {
              final activeReq = sessionProv.activeRequest;
              final titleName = widget.isAdvisorView
                  ? (activeReq?.clientName ?? "Client")
                  : (activeReq?.advisorName ?? "Advisor");
              final timeStr = sessionProv.formattedTimer;
              final costVal = sessionProv.currentSessionCost;
              Navigator.pop(ctx);
              await sessionProv.endSession();
              final summaryCost = sessionProv.chatSummary?['chargedAmount'] ??
                  sessionProv.chatSummary?['totalCharges'] ??
                  sessionProv.chatSummary?['ChargedAmount'];
              final finalCost = (summaryCost is num) ? summaryCost.toDouble() : costVal;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionAfterSummaryScreen(
                    isAdvisorView: widget.isAdvisorView,
                    participantName: titleName,
                    formattedTime: timeStr,
                    totalCost: finalCost,
                    sessionTypeLabel: "Live Chat",
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
