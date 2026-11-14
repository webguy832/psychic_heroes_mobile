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
  void initState() {
    super.initState();
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
    if ((sessionProv.sessionState == SessionState.ended ||
         sessionProv.sessionState == SessionState.declined ||
         sessionProv.sessionState == SessionState.cancelled) && !_handledSessionEnd) {
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
              advisorId: activeReq?.advisorId,
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

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.accentGold),
          onPressed: () => _confirmEndSession(context, sessionProv),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.accentGold,
              child: Text(
                titleName.isNotEmpty ? titleName[0].toUpperCase() : 'P',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titleName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.onlineGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "LIVE CHAT",
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.onlineGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sessionProv.isChargingStarted
                              ? "• \$${(activeReq?.ratePerMinute ?? sessionProv.advisorBaseRate).toStringAsFixed(2)}/min (Billed: \$${sessionProv.currentSessionCost.toStringAsFixed(2)})"
                              : "• \$${(activeReq?.ratePerMinute ?? sessionProv.advisorBaseRate).toStringAsFixed(2)}/min (Grace: ${sessionProv.secondsUntilCharging}s)",
                          style: TextStyle(
                            fontSize: 9,
                            color: sessionProv.isChargingStarted ? AppColors.onlineGreen : AppColors.accentGold,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGold),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_rounded, size: 13, color: AppColors.accentGold),
                const SizedBox(width: 4),
                Text(
                  sessionProv.formattedTimer,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
              label: const Text(
                "END CHAT",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
              ),
              onPressed: () => _confirmEndSession(context, sessionProv),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
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
                          "${msg.timestamp.toLocal().hour}:${msg.timestamp.toLocal().minute.toString().padLeft(2, '0')}",
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
                    advisorId: activeReq?.advisorId,
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
