import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/session_provider.dart';
import '../../providers/user_provider.dart';
import 'session_after_summary_screen.dart';

class VoiceCallScreen extends StatefulWidget {
  final bool isAdvisorView;

  const VoiceCallScreen({
    Key? key,
    this.isAdvisorView = false,
  }) : super(key: key);

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _isChatOpen = false;
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
            content: Text("Voice Call has been ended by ${widget.isAdvisorView ? 'Client' : 'Advisor'} ($titleName). Redirecting..."),
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
              sessionTypeLabel: "Voice Call",
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
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.accentGold),
          onPressed: () => _confirmEndCall(context, sessionProv, titleName),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              "VOICE CALL IN PROGRESS",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onlineGreen),
            ),
          ],
        ),
        actions: [
          // Timer Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.only(right: 8),
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
              label: const Text("END CALL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
              onPressed: () => _confirmEndCall(context, sessionProv, titleName),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Voice Call Center Visualizer
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Animated Pulsing Avatar Box
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentGold.withOpacity(0.08),
                        border: Border.all(color: AppColors.accentGold.withOpacity(0.3), width: 1.5),
                      ),
                    ),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentPurple.withOpacity(0.2),
                        border: Border.all(color: AppColors.onlineGreen, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.accentPurple,
                        child: Text(
                          titleName.isNotEmpty ? titleName[0].toUpperCase() : 'A',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                titleName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),

              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppColors.onlineGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sessionProv.isChargingStarted
                        ? "HD Voice Connected • \$${activeReq?.ratePerMinute ?? 3.99}/min (Billed: \$${sessionProv.currentSessionCost.toStringAsFixed(2)})"
                        : "HD Voice Connected • \$${activeReq?.ratePerMinute ?? 3.99}/min (Grace: ${sessionProv.secondsUntilCharging}s left)",
                    style: TextStyle(
                      fontSize: 13,
                      color: sessionProv.isChargingStarted ? AppColors.onlineGreen : AppColors.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Audio Controls Floating Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgDarkCard,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.borderDark),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Mute Toggle
                    IconButton(
                      iconSize: 28,
                      icon: Icon(
                        sessionProv.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: sessionProv.isMuted ? AppColors.errorRed : AppColors.accentGold,
                      ),
                      onPressed: () => sessionProv.toggleMute(),
                    ),
                    // Speaker Toggle
                    IconButton(
                      iconSize: 28,
                      icon: Icon(
                        sessionProv.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        color: sessionProv.isSpeakerOn ? AppColors.onlineGreen : Colors.grey,
                      ),
                      onPressed: () => sessionProv.toggleSpeaker(),
                    ),
                    // In-call Chat Drawer Toggle
                    IconButton(
                      iconSize: 28,
                      icon: Icon(
                        _isChatOpen ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                        color: AppColors.accentCyan,
                      ),
                      onPressed: () {
                        setState(() => _isChatOpen = !_isChatOpen);
                        if (_isChatOpen) _scrollToBottom();
                      },
                    ),
                    // End Call
                    CircleAvatar(
                      backgroundColor: AppColors.errorRed,
                      radius: 24,
                      child: IconButton(
                        icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 22),
                        onPressed: () => _confirmEndCall(context, sessionProv, titleName),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Slide-up In-Call Chat Drawer
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
                  border: Border(top: BorderSide(color: AppColors.borderGold)),
                ),
                child: Column(
                  children: [
                    // Drawer Handle Bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("In-Call Text Messages", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                            onPressed: () => setState(() => _isChatOpen = false),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AppColors.borderDark, height: 1),

                    // Chat List
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

                    // Input Field
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
                                  hintText: "Send message during call...",
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

  void _confirmEndCall(BuildContext context, SessionProvider sessionProv, String titleName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        title: const Text("End Voice Call?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Call Duration: ${sessionProv.formattedTimer}\nEstimated Cost: \$${sessionProv.currentSessionCost.toStringAsFixed(2)}",
          style: const TextStyle(color: AppColors.textPrimaryDark),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text("End Call", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    sessionTypeLabel: "Voice Call",
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
