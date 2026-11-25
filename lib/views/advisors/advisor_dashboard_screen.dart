import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../providers/session_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/advisor_service.dart';
import 'live_session_screen.dart';
import 'video_call_screen.dart';
import 'voice_call_screen.dart';
import 'advisor_text_readings_screen.dart';
import 'advisor_premium_requests_screen.dart';
import '../../core/services/audio_service.dart';

class AdvisorDashboardScreen extends StatefulWidget {
  const AdvisorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdvisorDashboardScreen> createState() => _AdvisorDashboardScreenState();
}

class _AdvisorDashboardScreenState extends State<AdvisorDashboardScreen> {
  final AdvisorService _advisorService = AdvisorService();
  bool _isDialogShowing = false;
  String? _currentShowingDialogRequestId;

  bool _isLoadingStats = true;
  Map<String, dynamic>? _advisorProfile;
  double _earningsToday = 0.0;
  int _totalSessions = 0;
  int _totalReviews = 0;
  double _rating = 0.0;
  int _missedOrCancelled = 0;
  int _pendingTextReadings = 0;
  List<Map<String, dynamic>> _recentBookings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      final sessionProv = Provider.of<SessionProvider>(context, listen: false);
      final user = userProv.user;
      if (user != null && user.id.isNotEmpty) {
        final profileId = await userProv.getOrFetchAdvisorProfileId();
        final effectiveId = (profileId != null && profileId.isNotEmpty) ? profileId : user.id;
        sessionProv.startAdvisorPolling(effectiveId, advisorName: user.displayName, userId: user.id);
        await _loadDashboardData(advisorProfileId: profileId);
      } else {
        if (mounted) setState(() => _isLoadingStats = false);
      }
    });
  }

  Future<void> _loadDashboardData({String? advisorProfileId, bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoadingStats = true);
    }
    try {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      final profileId = advisorProfileId ?? await userProv.getOrFetchAdvisorProfileId();

      final results = await Future.wait([
        _advisorService.getAdvisorDashboard(advisorProfileId: profileId),
        _advisorService.getAdvisorProfileDetails(),
        _advisorService.getAdvisorBookingsHistory(page: 1, pageSize: 10),
      ]);

      if (!mounted) return;

      final dashboard = results[0] as Map<String, dynamic>?;
      final profile = results[1] as Map<String, dynamic>?;
      final bookings = (results[2] as List<Map<String, dynamic>>?) ?? [];

      double earningsToday = _earningsToday;
      int totalSessions = _totalSessions;
      int totalReviews = _totalReviews;
      double rating = _rating;
      int missed = _missedOrCancelled;
      int pendingText = _pendingTextReadings;

      if (dashboard != null) {
        final quickStats = dashboard['quickStats'] as Map<String, dynamic>?;
        if (quickStats != null) {
          earningsToday = (quickStats['earningsToday'] as num?)?.toDouble() ?? 0.0;
          totalSessions = (quickStats['totalSessions'] as num?)?.toInt() ?? 0;
          totalReviews = (quickStats['totalReviews'] as num?)?.toInt() ?? 0;
          rating = (quickStats['rating'] as num?)?.toDouble() ?? 0.0;
        }
        final sessionsSummary = dashboard['sessionsSummary'] as Map<String, dynamic>?;
        if (sessionsSummary != null) {
          pendingText = (sessionsSummary['pendingTextReadings'] as num?)?.toInt() ?? 0;
          missed = (sessionsSummary['missedOrCancelled'] as num?)?.toInt() ?? 0;
        }
      }

      if (mounted) {
        final sessionProv = Provider.of<SessionProvider>(context, listen: false);
        sessionProv.syncAdvisorStats(
          earningsToday: earningsToday,
          completedSessions: totalSessions,
        );
        setState(() {
          _advisorProfile = profile;
          _earningsToday = earningsToday;
          _totalSessions = totalSessions;
          _totalReviews = totalReviews;
          _rating = rating;
          _missedOrCancelled = missed;
          _pendingTextReadings = pendingText;
          _recentBookings = bookings;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  void dispose() {
    try {
      Provider.of<SessionProvider>(context, listen: false).stopAdvisorPolling();
    } catch (_) {}
    super.dispose();
  }

  void _checkAndShowIncomingRequestDialog(BuildContext context, SessionProvider sessionProv) {
    // If this screen is NOT the topmost active route, NEVER show incoming request dialogs!
    // (Prevents dialogs popping up over LiveSessionScreen, VideoCallScreen, VoiceCallScreen, etc.)
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return;
    }

    // If advisor is currently in an active or on-hold session, NEVER show incoming request dialogs
    if (sessionProv.sessionState == SessionState.active ||
        sessionProv.sessionState == SessionState.hold ||
        sessionProv.activeRequest != null) {
      return;
    }

    if (sessionProv.incomingRequests.isEmpty || _isDialogShowing) {
      return;
    }

    final req = sessionProv.incomingRequests.first;
    if (_currentShowingDialogRequestId == req.id) {
      return;
    }

    _isDialogShowing = true;
    _currentShowingDialogRequestId = req.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = ModalRoute.of(context);
      if (!mounted ||
          (currentRoute != null && !currentRoute.isCurrent) ||
          sessionProv.sessionState == SessionState.active ||
          sessionProv.sessionState == SessionState.hold ||
          sessionProv.activeRequest != null) {
        _isDialogShowing = false;
        _currentShowingDialogRequestId = null;
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          return _IncomingRequestDialogModal(
            req: req,
            onAccept: () async {
              AudioService.stopRingtone();
              _isDialogShowing = false;
              _currentShowingDialogRequestId = null;
              if (Navigator.of(dialogCtx).canPop()) {
                Navigator.of(dialogCtx).pop();
              }
              Widget targetScreen = const LiveSessionScreen(isAdvisorView: true);
              if (req.type == SessionType.video) {
                targetScreen = const VideoCallScreen(isAdvisorView: true);
              } else if (req.type == SessionType.call) {
                targetScreen = const VoiceCallScreen(isAdvisorView: true);
              }

              final acceptFuture = sessionProv.acceptSessionRequest(req);

              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => targetScreen),
                ).then((_) {
                  _isDialogShowing = false;
                  _currentShowingDialogRequestId = null;
                });
              }
              await acceptFuture;
            },
            onDecline: (r) {
              AudioService.stopRingtone();
              _isDialogShowing = false;
              _currentShowingDialogRequestId = null;
              if (Navigator.of(dialogCtx).canPop()) {
                Navigator.of(dialogCtx).pop();
              }
              sessionProv.declineSessionRequest(r);
            },
          );
        },
      ).then((_) {
        AudioService.stopRingtone();
        if (mounted && sessionProv.sessionState != SessionState.active && sessionProv.sessionState != SessionState.hold) {
          _isDialogShowing = false;
          _currentShowingDialogRequestId = null;
        }
      });
    });
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
      body: RefreshIndicator(
        color: AppColors.accentGold,
        backgroundColor: AppColors.bgDarkCard,
        onRefresh: () => _loadDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }

  Widget _buildProfileHeaderCard(SessionProvider sessionProv, dynamic user) {
    final profileName = _advisorProfile?['displayName']?.toString();
    final name = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : ((user != null && user.displayName != null && user.displayName.isNotEmpty)
            ? user.displayName
            : (user?.screenName != null && user.screenName.isNotEmpty ? user.screenName : (user?.email ?? "Advisor")));
    final initial = (name != null && name.isNotEmpty) ? name[0].toUpperCase() : 'A';
    final rawPhoto = (_advisorProfile?['profileImage']?.toString().isNotEmpty == true)
        ? _advisorProfile!['profileImage'].toString()
        : user?.profilePhoto?.toString();
    final photoUrl = (rawPhoto != null && rawPhoto.isNotEmpty) ? ApiEndpoints.resolveImageUrl(rawPhoto) : '';
    final profileBio = (_advisorProfile?['briefDescription']?.toString().isNotEmpty == true)
        ? _advisorProfile!['briefDescription'].toString()
        : (_advisorProfile?['aboutMyServices']?.toString().isNotEmpty == true)
            ? _advisorProfile!['aboutMyServices'].toString()
            : (user?.userDescription != null && user.userDescription.isNotEmpty)
                ? user.userDescription.toString()
                : "";
    final isVerified = _advisorProfile?['emailVerified'] == true ||
        _advisorProfile?['profileStatus']?.toString().toLowerCase() == 'approved';
    final ratingLabel = _rating > 0 ? "${_rating.toStringAsFixed(1)} ★" : "No ratings yet";
    final reviewsSuffix = _totalReviews > 0 ? " ($_totalReviews)" : "";

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
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
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
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 18),
                    ],
                  ],
                ),
                if (profileBio.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profileBio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimaryDark),
                  ),
                ],
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
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _isLoadingStats
                                ? "Loading..."
                                : "$ratingLabel$reviewsSuffix${isVerified ? ' • Verified' : ''}",
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
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
                      onPressed: () async {
                        _isDialogShowing = true;
                        _currentShowingDialogRequestId = req.id;
                        Widget targetScreen = const LiveSessionScreen(isAdvisorView: true);
                        if (req.type == SessionType.video) {
                          targetScreen = const VideoCallScreen(isAdvisorView: true);
                        } else if (req.type == SessionType.call) {
                          targetScreen = const VoiceCallScreen(isAdvisorView: true);
                        }
                        final acceptFuture = sessionProv.acceptSessionRequest(req);
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => targetScreen),
                          ).then((_) {
                            _isDialogShowing = false;
                            _currentShowingDialogRequestId = null;
                          });
                        }
                        await acceptFuture;
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
    final totalAttempts = _totalSessions + _missedOrCancelled;
    final responseRateStr = totalAttempts > 0
        ? "${((_totalSessions / totalAttempts) * 100).round()}%"
        : "—";
    final ratingStr = _rating > 0 ? "${_rating.toStringAsFixed(1)} ★" : "—";

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricCard(
          "Today Earnings",
          _isLoadingStats ? "..." : "\$${sessionProv.totalEarningsToday.toStringAsFixed(2)}",
          Icons.account_balance_wallet_rounded,
          AppColors.onlineGreen,
        ),
        _buildMetricCard(
          "Readings Done",
          _isLoadingStats ? "..." : "${sessionProv.completedSessionsToday}",
          Icons.auto_stories_rounded,
          AppColors.accentGold,
        ),
        _buildMetricCard(
          "Rating",
          _isLoadingStats ? "..." : ratingStr,
          Icons.star_rounded,
          AppColors.accentCyan,
        ),
        _buildMetricCard(
          "Response Rate",
          _isLoadingStats ? "..." : responseRateStr,
          Icons.bolt_rounded,
          AppColors.primaryLight,
        ),
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
          leading: const Icon(Icons.mail_rounded, color: AppColors.accentGold),
          title: Row(
            children: [
              const Flexible(
                child: Text("Text Reading Requests", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              if (_pendingTextReadings > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB45309),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$_pendingTextReadings",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          subtitle: const Text("Manage pending customer text questions, clarifications & replies", style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 11)),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB45309)), // Amber-700
            child: const Text("View Requests", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdvisorTextReadingsScreen()),
              ).then((_) => _loadDashboardData(silent: true));
            },
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          tileColor: AppColors.bgDarkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: const Icon(Icons.diamond_rounded, color: AppColors.accentGold),
          title: const Text("Premium / Luxe Requests", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text("Accept and manage high-value platinum customer service orders", style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 11)),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)), // Green-800
            child: const Text("View Orders", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdvisorPremiumRequestsScreen()),
              ).then((_) => _loadDashboardData(silent: true));
            },
          ),
        ),
      ],
    );
  }

  String _mapRequestType(int? reqType) {
    switch (reqType) {
      case 1:
        return "Live Chat";
      case 2:
        return "Voice Call";
      case 3:
        return "Video Call";
      case 4:
        return "Text Reading";
      default:
        return "Reading";
    }
  }

  String _formatDuration(dynamic durationVal) {
    final mins = (durationVal is num) ? durationVal.toDouble() : (double.tryParse(durationVal?.toString() ?? '') ?? 0.0);
    if (mins <= 0) return "0m";
    final wholeMins = mins.floor();
    final secs = ((mins - wholeMins) * 60).round();
    if (wholeMins == 0) return "${secs}s";
    return secs > 0 ? "${wholeMins}m ${secs}s" : "${wholeMins}m";
  }

  String _formatRequestDate(dynamic dateVal) {
    if (dateVal == null) return "";
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return dateVal.toString();
    }
  }

  Widget _buildRecentSessionsList() {
    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
      );
    }

    if (_recentBookings.isEmpty) {
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
      children: _recentBookings.take(10).map((b) {
        final clientName = (b['clientDisplayName']?.toString().isNotEmpty == true)
            ? b['clientDisplayName'].toString()
            : "Client";
        final typeLabel = _mapRequestType((b['requestType'] as num?)?.toInt());
        final durationLabel = _formatDuration(b['duration']);
        final status = b['status']?.toString() ?? '';
        final amount = ((b['chargedAmount'] as num?) ?? (b['advisorFee'] as num?) ?? 0).toDouble();
        final dateStr = _formatRequestDate(b['requestOn']);

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
                    Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    Text(
                      "$typeLabel • $durationLabel${status.isNotEmpty ? ' • $status' : ''}",
                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimaryDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("\$${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onlineGreen)),
                  if (dateStr.isNotEmpty)
                    Text(dateStr, style: const TextStyle(fontSize: 10, color: AppColors.textPrimaryDark)),
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
  int _remainingSeconds = 60; // 60s parity with Angular expiresInSeconds || 60
  Timer? _timer;
  bool _actionTaken = false;
  String _selectedReason = "Busy";

  @override
  void initState() {
    super.initState();
    AudioService.playRingtone();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        _timer = null;
        return;
      }
      final sessionProv = Provider.of<SessionProvider>(context, listen: false);
      if (sessionProv.sessionState == SessionState.active ||
          sessionProv.sessionState == SessionState.hold ||
          sessionProv.activeRequest?.id == widget.req.id) {
        timer.cancel();
        _timer = null;
        _actionTaken = true;
        AudioService.stopRingtone();
        return;
      }
      if (_actionTaken) {
        timer.cancel();
        _timer = null;
        AudioService.stopRingtone();
        return;
      }
      if (_remainingSeconds > 1) {
        if (mounted) {
          setState(() => _remainingSeconds--);
        }
      } else {
        timer.cancel();
        _timer = null;
        AudioService.stopRingtone();
        if (!_actionTaken && mounted) {
          _actionTaken = true;
          widget.onDecline(widget.req);
        }
      }
    });
  }

  @override
  void dispose() {
    AudioService.stopRingtone();
    _timer?.cancel();
    _timer = null;
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
                    value: _remainingSeconds / 60,
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
                    onPressed: _actionTaken
                        ? null
                        : () {
                            _actionTaken = true;
                            AudioService.stopRingtone();
                            _timer?.cancel();
                            _timer = null;
                            widget.onDecline(widget.req);
                          },
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
                      onPressed: _actionTaken
                          ? null
                          : () {
                              _actionTaken = true;
                              AudioService.stopRingtone();
                              _timer?.cancel();
                              _timer = null;
                              widget.onAccept();
                            },
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

