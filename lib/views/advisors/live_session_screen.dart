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
            backgroundColor: const Color(0xFF4F46E5),
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
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FF),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4338CA), // Deep Indigo
                Color(0xFF4F46E5), // Indigo
                Color(0xFF6366F1), // Vibrant Indigo
                Color(0xFF818CF8), // Soft Light Indigo
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x404338CA),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => _confirmEndSession(context, sessionProv),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  titleName.isNotEmpty ? titleName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 9),
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
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "LIVE CHAT",
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFFD1FAE5),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sessionProv.isChargingStarted
                              ? "• \$${(activeReq?.ratePerMinute ?? sessionProv.advisorBaseRate).toStringAsFixed(2)}/min"
                              : "• Grace: ${sessionProv.secondsUntilCharging}s left",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withOpacity(0.9),
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
          // Frosted Glass Timer Badge (Matching Web App)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  sessionProv.formattedTimer,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // End Chat Button (Matching Web App Style)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close_rounded, color: Colors.white, size: 13),
                  SizedBox(width: 3),
                  Text(
                    "End",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                  ),
                ],
              ),
              onPressed: () => _confirmEndSession(context, sessionProv),
            ),
          ),
        ],
      ),
      body: Container(
        // Web App Soft Pastel Gradient Background (#eef2ff -> #e0e7ff -> #ede9fe -> #f0f4ff)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEEF2FF), // soft indigo
              Color(0xFFE0E7FF), // light periwinkle
              Color(0xFFEDE9FE), // lavender
              Color(0xFFEEF2FF), // soft airy white/blue
              Color(0xFFF0F4FF),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Active Free Minutes Notice Banner
            if (sessionProv.freeLeftSeconds > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  border: Border(bottom: BorderSide(color: Color(0xFFA7F3D0))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFF059669), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Free Promotional Chat: ${(sessionProv.freeLeftSeconds ~/ 60) + 1}m remaining free",
                        style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 12),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBEB),
                  border: Border(bottom: BorderSide(color: Color(0xFFFDE68A))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Free minutes finished. Session continuing from main wallet.",
                        style: TextStyle(color: Color(0xFF92400E), fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => sessionProv.dismissFreeFinishedNotice(),
                      child: const Text("DISMISS", style: TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Low Balance Warning Banner (<= 3 mins left)
            if (sessionProv.isLowBalanceWarning && !widget.isAdvisorView)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F2),
                  border: Border(bottom: BorderSide(color: Color(0xFFFECDD3))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Low Balance: Less than 3 minutes remaining.",
                        style: TextStyle(color: Color(0xFF9F1239), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  border: Border(bottom: BorderSide(color: Color(0xFFFCA5A5))),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pause_circle_filled_rounded, color: Color(0xFFDC2626), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Session Paused: Wallet balance depleted.",
                            style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Session timer is paused. Add funds to immediately resume chatting with your advisor.",
                      style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
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
              child: sessionProv.chatMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF6366F1), size: 36),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Connected to Live Chat",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Say hello to begin your session!",
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: sessionProv.chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = sessionProv.chatMessages[index];
                        final isMe = !msg.isOpponent;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: isMe
                                ? BoxDecoration(
                                    // Sent Bubble: Vibrant Indigo Gradient matching Web App
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(4),
                                      bottomLeft: Radius.circular(18),
                                      bottomRight: Radius.circular(18),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  )
                                : BoxDecoration(
                                    // Received Bubble: Crisp White Card matching Web App
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(18),
                                      bottomLeft: Radius.circular(18),
                                      bottomRight: Radius.circular(18),
                                    ),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isMe) ...[
                                  Text(
                                    msg.senderName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                ],
                                Text(
                                  msg.message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isMe ? Colors.white : const Color(0xFF1E293B),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${msg.timestamp.toLocal().hour}:${msg.timestamp.toLocal().minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe ? Colors.white.withOpacity(0.7) : const Color(0xFF94A3B8),
                                  ),
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

            // Chat Bottom Bar / Input Field (Clean White Card matching Web App)
            _buildMessageInputField(context, sessionProv, user?.displayName ?? "User"),
          ],
        ),
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
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withOpacity(0.04),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              label: Text(
                quickTexts[i],
                style: const TextStyle(fontSize: 11, color: Color(0xFF4338CA), fontWeight: FontWeight.w500),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Type your message...",
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendMessage(sessionProv, userName),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("End Live Session?", style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        content: Text(
          "Total Duration: ${sessionProv.formattedTimer}\nEstimated Cost: \$${sessionProv.currentSessionCost.toStringAsFixed(2)}",
          style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
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
