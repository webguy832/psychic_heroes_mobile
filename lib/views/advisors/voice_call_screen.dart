import 'dart:math' as math;
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

class _VoiceCallScreenState extends State<VoiceCallScreen> with SingleTickerProviderStateMixin {
  bool _isChatOpen = false;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMsgCount = 0;
  bool _handledSessionEnd = false;
  double _speakerVolume = 100.0;
  late AnimationController _waveAnimController;

  @override
  void initState() {
    super.initState();
    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    _waveAnimController.dispose();
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
            content: Text("Voice Call has been ended by ${widget.isAdvisorView ? 'Client' : 'Advisor'} ($titleName). Redirecting..."),
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
              sessionTypeLabel: "Voice Call",
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
      backgroundColor: const Color(0xFF0D0B18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161226),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.accentGold, size: 20),
          onPressed: () => _confirmEndCall(context, sessionProv, titleName),
        ),
        titleSpacing: 0,
        title: Row(
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
            const Text("🎙", style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                "Audio Call · $titleName",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Elapsed Duration + Rate Tag (Web App Parity)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_rounded, size: 12, color: AppColors.accentGold),
                const SizedBox(width: 4),
                Text(
                  sessionProv.formattedTimer,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGold, fontFamily: 'monospace'),
                ),
                if (effectiveRate > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    "\$${effectiveRate.toStringAsFixed(2)}/m",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onlineGreen),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Participant Count Pill (Web App Parity)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.people_alt_rounded, size: 12, color: Colors.white70),
                SizedBox(width: 3),
                Text("2", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // End Call Top Button
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(Icons.call_end_rounded, color: AppColors.errorRed, size: 22),
              tooltip: "End Call",
              onPressed: () => _confirmEndCall(context, sessionProv, titleName),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Glow & Main Center Layout
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 0.9,
                  colors: [
                    Color(0xFF24143D),
                    Color(0xFF0F0B1E),
                    Color(0xFF080612),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // Free Minutes Banner if Over (Web App Parity)
                    if (sessionProv.showFreeFinishedNotice && !widget.isAdvisorView) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.6)),
                        ),
                        child: Row(
                          children: [
                            const Text("⏱️", style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Your free minutes are over. Now session time will be deducted from your balance.",
                                style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                              onPressed: () => sessionProv.dismissFreeFinishedNotice(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Top Metadata Badges (Free Time / Session Time / Billing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Free minutes badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Row(
                            children: [
                              const Text("Free: ", style: TextStyle(color: Colors.white70, fontSize: 11)),
                              Text(
                                freeMinutes > 0 ? "${freeMinutes}m" : "Over",
                                style: TextStyle(
                                  color: freeMinutes > 0 ? AppColors.onlineGreen : Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Billing / Grace Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: sessionProv.isChargingStarted ? AppColors.onlineGreen : AppColors.accentGold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                sessionProv.isChargingStarted
                                    ? "Billed: \$${sessionProv.currentSessionCost.toStringAsFixed(2)}"
                                    : "Grace: ${sessionProv.secondsUntilCharging}s left",
                                style: TextStyle(
                                  color: sessionProv.isChargingStarted ? AppColors.onlineGreen : AppColors.accentGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Central Pulsing Avatar Ring (Soundwave animation)
                    AnimatedBuilder(
                      animation: _waveAnimController,
                      builder: (context, child) {
                        final pulse = sessionProv.isMuted ? 0.0 : _waveAnimController.value;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring 2
                            Container(
                              width: 170 + (pulse * 24),
                              height: 170 + (pulse * 24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accentGold.withOpacity(0.04 + (pulse * 0.05)),
                                border: Border.all(
                                  color: AppColors.accentGold.withOpacity(0.15 + (pulse * 0.2)),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // Outer ring 1
                            Container(
                              width: 140 + (pulse * 14),
                              height: 140 + (pulse * 14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accentPurple.withOpacity(0.12 + (pulse * 0.1)),
                                border: Border.all(
                                  color: AppColors.onlineGreen.withOpacity(0.4 + (pulse * 0.3)),
                                  width: 2,
                                ),
                              ),
                            ),
                            // Main avatar circle
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: const Color(0xFF4C1D95),
                              child: Text(
                                titleName.isNotEmpty ? titleName[0].toUpperCase() : 'A',
                                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            // Speaking / Muted status tag on avatar
                            Positioned(
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: sessionProv.isMuted ? AppColors.errorRed : AppColors.onlineGreen,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  sessionProv.isMuted ? "MUTED" : "SPEAKING",
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Participant Title
                    Text(
                      titleName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),

                    const SizedBox(height: 6),

                    // HD Voice Connected Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.verified_rounded, color: AppColors.onlineGreen, size: 14),
                        SizedBox(width: 4),
                        Text(
                          "HD Voice Connected · Twilio Opus 48kHz",
                          style: TextStyle(fontSize: 12, color: AppColors.onlineGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Waveform Visualizer Simulation (Web App Parity) ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _waveAnimController,
                            builder: (context, _) {
                              final v = sessionProv.isMuted ? 0.0 : _waveAnimController.value;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(9, (index) {
                                  final double offset = math.sin((index + 1) * 0.8 + (v * math.pi));
                                  final double barHeight = sessionProv.isMuted ? 6.0 : (10.0 + (offset.abs() * 26.0));
                                  return Container(
                                    width: 4,
                                    height: barHeight,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    decoration: BoxDecoration(
                                      color: sessionProv.isMuted
                                          ? Colors.grey.withOpacity(0.4)
                                          : AppColors.accentGold.withOpacity(0.5 + (offset.abs() * 0.5)),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sessionProv.isMuted ? "Microphone muted" : "Microphone active",
                            style: TextStyle(
                              fontSize: 11,
                              color: sessionProv.isMuted ? Colors.white54 : AppColors.accentGold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Speaker Volume Slider (Web App Parity) ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _speakerVolume > 50
                                ? Icons.volume_up_rounded
                                : (_speakerVolume > 0 ? Icons.volume_down_rounded : Icons.volume_mute_rounded),
                            color: Colors.white70,
                            size: 18,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.accentGold,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: AppColors.accentGold,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: _speakerVolume,
                                min: 0,
                                max: 100,
                                onChanged: (val) {
                                  setState(() => _speakerVolume = val);
                                },
                              ),
                            ),
                          ),
                          Text(
                            "${_speakerVolume.round()}%",
                            style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Spacing for bottom controls bar
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Controls Bar (Web App Parity) ──
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161226).withOpacity(0.95),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Mute / Unmute Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: sessionProv.isMuted ? AppColors.errorRed.withOpacity(0.2) : Colors.white10,
                        radius: 22,
                        child: IconButton(
                          iconSize: 22,
                          icon: Icon(
                            sessionProv.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            color: sessionProv.isMuted ? AppColors.errorRed : AppColors.accentGold,
                          ),
                          onPressed: () => sessionProv.toggleMute(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sessionProv.isMuted ? "Unmute" : "Mute",
                        style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  // Speaker On / Off Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: sessionProv.isSpeakerOn ? AppColors.onlineGreen.withOpacity(0.2) : Colors.white10,
                        radius: 22,
                        child: IconButton(
                          iconSize: 22,
                          icon: Icon(
                            sessionProv.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            color: sessionProv.isSpeakerOn ? AppColors.onlineGreen : Colors.grey,
                          ),
                          onPressed: () => sessionProv.toggleSpeaker(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sessionProv.isSpeakerOn ? "Speaker" : "Earpiece",
                        style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  // In-Call Chat Drawer Toggle
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            backgroundColor: _isChatOpen ? AppColors.accentCyan.withOpacity(0.2) : Colors.white10,
                            radius: 22,
                            child: IconButton(
                              iconSize: 22,
                              icon: Icon(
                                _isChatOpen ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                                color: AppColors.accentCyan,
                              ),
                              onPressed: () {
                                setState(() => _isChatOpen = !_isChatOpen);
                                if (_isChatOpen) _scrollToBottom();
                              },
                            ),
                          ),
                          if (sessionProv.chatMessages.isNotEmpty && !_isChatOpen)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.accentGold,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "${sessionProv.chatMessages.length}",
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Chat",
                        style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  // End Call Button (Large Red)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.errorRed,
                        radius: 24,
                        child: IconButton(
                          icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 24),
                          onPressed: () => _confirmEndCall(context, sessionProv, titleName),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "End Call",
                        style: TextStyle(fontSize: 10, color: AppColors.errorRed, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Slide-up In-Call Chat Drawer (Web App Parity) ──
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
                          Row(
                            children: const [
                              Icon(Icons.chat_bubble_rounded, size: 16, color: AppColors.accentCyan),
                              SizedBox(width: 8),
                              Text("In-Call Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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

                    // Chat List
                    Expanded(
                      child: sessionProv.chatMessages.isEmpty
                          ? Center(
                              child: Text(
                                "No messages yet.\nType below to message during call.",
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

                    // Input Field
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
                                  hintText: "Message during call...",
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
        backgroundColor: const Color(0xFF161226),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("End Voice Call?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Call Duration: ${sessionProv.formattedTimer}\nEstimated Cost: \$${sessionProv.currentSessionCost.toStringAsFixed(2)}",
          style: const TextStyle(color: AppColors.textPrimaryDark),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
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
                    sessionTypeLabel: "Voice Call",
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
