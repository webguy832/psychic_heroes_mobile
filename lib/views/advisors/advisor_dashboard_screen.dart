import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/session_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import 'live_session_screen.dart';
import 'video_call_screen.dart';
import 'voice_call_screen.dart';

class AdvisorDashboardScreen extends StatefulWidget {
  const AdvisorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorDashboardScreen> createState() => _AdvisorDashboardScreenState();
}

class _AdvisorDashboardScreenState extends State<AdvisorDashboardScreen> {
  bool _isDialogShowing = false;

  void _checkAndShowIncomingRequestDialog(BuildContext context, SessionProvider sessionProv) {
    if (sessionProv.incomingRequests.isNotEmpty && !_isDialogShowing) {
      final req = sessionProv.incomingRequests.first;
      _isDialogShowing = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            return _IncomingRequestDialogModal(
              req: req,
              onAccept: () {
                _isDialogShowing = false;
                Navigator.of(dialogCtx).pop();
                sessionProv.acceptSessionRequest(req);
                Widget targetScreen = const LiveSessionScreen(isAdvisorView: true);
                if (req.type == SessionType.video) {
                  targetScreen = const VideoCallScreen(isAdvisorView: true);
                } else if (req.type == SessionType.call) {
                  targetScreen = const VoiceCallScreen(isAdvisorView: true);
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => targetScreen),
                );
              },
              onDecline: (r) {
                _isDialogShowing = false;
                Navigator.of(dialogCtx).pop();
                sessionProv.declineSessionRequest(r);
              },
            );
          },
        ).then((_) => _isDialogShowing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionProv = Provider.of<SessionProvider>(context);
    final user = Provider.of<UserProvider>(context).user;

    _checkAndShowIncomingRequestDialog(context, sessionProv);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 2,
        title: const Text(
          "Advisor Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          // Online / Offline Status Toggle
          Row(
            children: [
              Text(
                sessionProv.isAdvisorOnline ? "ONLINE" : "OFFLINE",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: sessionProv.isAdvisorOnline ? AppColors.onlineGreen : Colors.grey,
                ),
              ),
              Switch(
                value: sessionProv.isAdvisorOnline,
                activeColor: AppColors.onlineGreen,
                onChanged: (_) => sessionProv.toggleAdvisorOnline(),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Advisor Profile Header Card
            _buildProfileHeaderCard(sessionProv, user),

            const SizedBox(height: 16),

            // Incoming Call / Chat Request Section (Notification Banner)
            _buildIncomingRequestsSection(context, sessionProv),

            const SizedBox(height: 16),

            // Overview Metrics Grid
            const Text(
              "Earnings & Metrics Overview",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            _buildMetricsGrid(sessionProv),

            const SizedBox(height: 20),

            // Quick Actions Section
            const Text(
              "Advisor Quick Tools",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            _buildQuickToolsGrid(context, sessionProv),

            const SizedBox(height: 20),

            // Recent Sessions History
            const Text(
              "Recent Client Sessions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            _buildRecentSessionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(SessionProvider sessionProv, dynamic user) {
    final name = (user != null && user.displayName != null && user.displayName.isNotEmpty)
        ? user.displayName
        : (user?.screenName != null && user.screenName.isNotEmpty ? user.screenName : "Advisor");
    final initial = (name != null && name.isNotEmpty) ? name[0].toUpperCase() : 'A';
    final photo = user?.profilePhoto;
    final bio = (user?.userDescription != null && user.userDescription.isNotEmpty)
        ? user.userDescription
        : "Spiritual Psychic Advisor & Intuitive Guide";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.accentGold.withOpacity(0.2), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.bgDarkCard,
            backgroundImage: (photo != null && photo.isNotEmpty)
                ? NetworkImage(photo.startsWith('http') ? photo : 'https://psychicheroes.com/$photo')
                : null,
            child: (photo == null || photo.isEmpty)
                ? Text(
                    initial,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name ?? "Advisor",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 18),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimaryDark),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bgDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.star_rounded, color: AppColors.accentGold, size: 14),
                          SizedBox(width: 4),
                          Text("5.0 ★ Verified", style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestsSection(BuildContext context, SessionProvider sessionProv) {
    if (sessionProv.incomingRequests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgDarkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: const [
            Icon(Icons.notifications_active_outlined, color: AppColors.accentGold),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Waiting for incoming user chat & call requests...",
                style: TextStyle(fontSize: 12, color: AppColors.textPrimaryDark),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: sessionProv.incomingRequests.map((req) {
        final isCall = req.type == SessionType.call || req.type == SessionType.video;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgDarkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.onlineGreen, width: 1.5),
            boxShadow: [
              BoxShadow(color: AppColors.onlineGreen.withOpacity(0.2), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.onlineGreen,
                    radius: 16,
                    child: Icon(
                      isCall ? Icons.phone_in_talk_rounded : Icons.chat_rounded,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "INCOMING ${isCall ? 'CALL' : 'CHAT'} REQUEST",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.onlineGreen),
                        ),
                        Text(
                          req.clientName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "\$${req.ratePerMinute}/min",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.errorRed),
                        foregroundColor: AppColors.errorRed,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text("Decline"),
                      onPressed: () => sessionProv.declineSessionRequest(req),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.onlineGreen),
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
                      label: const Text("ACCEPT SESSION", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        sessionProv.acceptSessionRequest(req);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LiveSessionScreen(isAdvisorView: true)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricsGrid(SessionProvider sessionProv) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricCard("Today Earnings", "\$${sessionProv.totalEarningsToday.toStringAsFixed(2)}", Icons.account_balance_wallet_rounded, AppColors.onlineGreen),
        _buildMetricCard("Readings Done", "${sessionProv.completedSessionsToday}", Icons.auto_stories_rounded, AppColors.accentGold),
        _buildMetricCard("Rating", "5.0 ★", Icons.star_rounded, AppColors.accentCyan),
        _buildMetricCard("Response Rate", "98%", Icons.bolt_rounded, AppColors.primaryLight),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDarkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textPrimaryDark), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildQuickToolsGrid(BuildContext context, SessionProvider sessionProv) {
    return Column(
      children: [
        ListTile(
          tileColor: AppColors.bgDarkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: const Icon(Icons.call_outlined, color: AppColors.accentGold),
          title: const Text("Test Demo Call/Chat Join", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text("Trigger an incoming call request from client", style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 11)),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
            child: const Text("Simulate Request", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: () {
              final user = Provider.of<UserProvider>(context, listen: false).user;
              sessionProv.initiateSessionRequest(
                clientId: user?.id ?? "client",
                clientName: (user?.displayName != null && user!.displayName.isNotEmpty) ? user.displayName : "Client",
                advisorId: "advisor",
                advisorName: "Advisor",
                type: SessionType.call,
                ratePerMinute: 3.99,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSessionsList() {
    final userProv = Provider.of<UserProvider>(context);
    final history = userProv.readingHistory;

    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgDarkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          children: const [
            Icon(Icons.history_edu_rounded, color: AppColors.textSecondaryDark, size: 36),
            SizedBox(height: 8),
            Text("No Client Sessions Yet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 4),
            Text("Completed readings will be recorded here automatically.", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
          ],
        ),
      );
    }

    return Column(
      children: history.take(5).map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgDarkCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.bgDark,
                radius: 18,
                child: Icon(Icons.person_outline_rounded, color: AppColors.accentGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.advisorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    Text("${s.type} • ${s.duration}", style: const TextStyle(fontSize: 11, color: AppColors.textPrimaryDark)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("\$${s.cost.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onlineGreen)),
                  Text(s.date, style: const TextStyle(fontSize: 10, color: AppColors.textPrimaryDark)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Automatic Popup Dialog Component (Matching Web App IncomingRequestDialogComponent)
class _IncomingRequestDialogModal extends StatefulWidget {
  final SessionRequestItem req;
  final VoidCallback onAccept;
  final Function(SessionRequestItem) onDecline;

  const _IncomingRequestDialogModal({
    Key? key,
    required this.req,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  State<_IncomingRequestDialogModal> createState() => _IncomingRequestDialogModalState();
}

class _IncomingRequestDialogModalState extends State<_IncomingRequestDialogModal> {
  int _remainingSeconds = 15;
  Timer? _timer;
  String _selectedReason = "Busy";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        widget.onDecline(widget.req);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.req.type == SessionType.video;
    final isCall = widget.req.type == SessionType.call || isVideo;
    final serviceTitle = isVideo ? "Video Call" : (isCall ? "Voice Call" : "Chat Session");

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ringing Icon
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: _remainingSeconds / 15,
                    strokeWidth: 4,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.onlineGreen),
                    backgroundColor: Colors.black12,
                  ),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isVideo ? AppColors.accentCyan : (isCall ? AppColors.onlineGreen : AppColors.accentPurple),
                  child: Icon(
                    isVideo ? Icons.videocam_rounded : (isCall ? Icons.phone_in_talk_rounded : Icons.chat_rounded),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Header Title
            Text(
              "Incoming $serviceTitle Request",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 10),

            // Client & Service Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Client:", style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                      Text(widget.req.clientName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Service:", style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                      Text(serviceTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentPurple, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Rate:", style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                      Text("\$${widget.req.ratePerMinute.toStringAsFixed(2)} / min", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ctaGreen, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Auto expire countdown text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Auto-expire in $_remainingSeconds sec",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
              ),
            ),

            const SizedBox(height: 20),

            // Approve / Reject Buttons (Web App Style)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.ctaGreen, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => widget.onDecline(widget.req),
                    child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ctaGreen)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF369A23), Color(0xFF2E5626)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: widget.onAccept,
                      child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

