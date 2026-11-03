import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../models/advisor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/session_provider.dart';
import '../user/login_screen.dart';
import 'live_session_screen.dart';
import 'video_call_screen.dart';
import 'voice_call_screen.dart';

class AdvisorDetailScreen extends StatefulWidget {
  final AdvisorDto advisor;

  const AdvisorDetailScreen({Key? key, required this.advisor}) : super(key: key);

  @override
  State<AdvisorDetailScreen> createState() => _AdvisorDetailScreenState();
}

class _AdvisorDetailScreenState extends State<AdvisorDetailScreen> {
  bool _isFavorite = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return AppColors.onlineGreen;
      case 'busy':
        return AppColors.busyOrange;
      default:
        return AppColors.offlineGrey;
    }
  }

  void _startCommunication(String mode) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userProv = Provider.of<UserProvider>(context, listen: false);

    if (userProv.isAdvisor) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.accentGold),
              SizedBox(width: 8),
              Text("Advisor Account"),
            ],
          ),
          content: const Text(
            "Advisors cannot request readings or initiate chat/call sessions with other advisors. Please log in with a Customer account to connect.",
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Got It"),
            ),
          ],
        ),
      );
      return;
    }

    final user = userProv.user;

    if (!auth.isLoggedIn) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Sign In Required"),
          content: Text("Please sign in or create an account to start a $mode session with ${widget.advisor.name}."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text("Sign In Now"),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.bgDarkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 24,
                  child: Text(
                    widget.advisor.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Start $mode with ${widget.advisor.name}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
                      ),
                      Text(
                        widget.advisor.categoryName ?? "Psychic Guide",
                        style: const TextStyle(fontSize: 12, color: AppColors.accentGold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.borderDark),
            const SizedBox(height: 12),
            _buildBillingRow("Rate per Minute", "\$${widget.advisor.pricePerMinute.toStringAsFixed(2)} / min"),
            _buildBillingRow("Introductory Offer", "First 3 Minutes FREE"),
            _buildBillingRow("Your Wallet Balance", "\$${(user?.walletBalance ?? 25.0).toStringAsFixed(2)}"),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF369A23), Color(0xFF2E5626)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF369A23).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  final sessionProv = Provider.of<SessionProvider>(context, listen: false);
                  final user = Provider.of<UserProvider>(context, listen: false).user;
                  sessionProv.initiateSessionRequest(
                    clientId: user?.id ?? "",
                    clientName: (user?.displayName != null && user!.displayName.isNotEmpty)
                        ? user.displayName
                        : ((user?.fullName != null && user!.fullName.isNotEmpty) ? user.fullName : "User"),
                    advisorId: widget.advisor.id.toString(),
                    advisorName: widget.advisor.name,
                    type: mode.toUpperCase().contains("VIDEO")
                        ? SessionType.video
                        : (mode.toUpperCase().contains("CALL") || mode.toUpperCase().contains("VOICE")
                            ? SessionType.call
                            : SessionType.chat),
                    ratePerMinute: widget.advisor.pricePerMinute,
                  );
                  _showWaitingForAdvisorDialog(context, mode);
                },
                child: Text(
                  "START $mode NOW",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white, letterSpacing: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showWaitingForAdvisorDialog(BuildContext context, String mode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Consumer<SessionProvider>(
          builder: (context, sessionProv, child) {
            if (sessionProv.sessionState == SessionState.active) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(dialogCtx).pop();
                Widget targetScreen = const LiveSessionScreen(isAdvisorView: false);
                if (sessionProv.sessionType == SessionType.video) {
                  targetScreen = const VideoCallScreen(isAdvisorView: false);
                } else if (sessionProv.sessionType == SessionType.call) {
                  targetScreen = const VoiceCallScreen(isAdvisorView: false);
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => targetScreen),
                );
              });
            } else if (sessionProv.sessionState == SessionState.cancelled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request was declined or cancelled.")),
                );
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.bgDarkCard,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                          ),
                        ),
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            widget.advisor.name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Waiting for ${widget.advisor.name}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Notification sent! Session will begin as soon as ${widget.advisor.name} accepts your $mode request.",
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                      onPressed: () {
                        sessionProv.cancelSessionRequest();
                        Navigator.of(dialogCtx).pop();
                      },
                      child: const Text("Cancel Request", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBillingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.advisor;
    final statusColor = _getStatusColor(a.status);
    final userProv = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(a.name),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.red : AppColors.textPrimaryLight,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite ? "Added to favorites!" : "Removed from favorites"),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Advisor profile link copied!")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (userProv.isAdvisor) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Logged in as Advisor: Connecting with other advisors is disabled.",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Top Main Card (Matching Web App)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar & Status Dot
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 90,
                              height: 105,
                              color: AppColors.primary.withOpacity(0.1),
                              child: a.profilePhoto != null
                                  ? Image.network(
                                      '${ApiEndpoints.imageBaseUrl}${a.profilePhoto}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(a.name[0].toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ),
                                    )
                                  : Center(
                                      child: Text(a.name[0].toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Text(
                                a.status,
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Info Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a.categoryName ?? "Psychic Guide",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentPurple),
                            ),
                            const SizedBox(height: 8),

                            // Stars & Rating
                            Row(
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      index < a.rating.floor() ? Icons.star_rounded : Icons.star_half_rounded,
                                      color: AppColors.accentGoldDark,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${a.rating.toStringAsFixed(1)} (${a.reviewsCount})",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 12),

                  // Expertise & Languages Grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Areas of Expertise", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                            SizedBox(height: 4),
                            Text("• Clairvoyance\n• Love & Relationships\n• Career & Finance\n• Tarot Spreads", style: TextStyle(fontSize: 12, color: AppColors.textPrimaryLight, height: 1.4)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 60, color: AppColors.borderLight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Languages", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                            SizedBox(height: 4),
                            Text("• English\n• Spanish\n• French", style: TextStyle(fontSize: 12, color: AppColors.textPrimaryLight, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price & Actions Card (Web App Style Green CTAs)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Rate per minute", style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "\$${a.pricePerMinute.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ctaGreen),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "\$${(a.pricePerMinute + 1.0).toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 13, color: Colors.grey, decoration: TextDecoration.lineThrough),
                              ),
                              const Text(" / min", style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2E7D32)),
                        ),
                        child: const Text(
                          "FIRST 3 MIN FREE",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4 Web-Style Action Buttons Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.8,
                    children: [
                      // 1. CALL BUTTON (Green CTA)
                      _buildActionButton(
                        label: "CALL",
                        icon: Icons.phone_in_talk_rounded,
                        isPrimary: true,
                        onTap: () => _startCommunication("CALL"),
                      ),
                      // 2. CHAT BUTTON
                      _buildActionButton(
                        label: "CHAT",
                        icon: Icons.chat_bubble_rounded,
                        isPrimary: false,
                        onTap: () => _startCommunication("CHAT"),
                      ),
                      // 3. VIDEO CALL BUTTON
                      _buildActionButton(
                        label: "VIDEO CALL",
                        icon: Icons.videocam_rounded,
                        isPrimary: false,
                        onTap: () => _startCommunication("VIDEO CALL"),
                      ),
                      // 4. TEXT READING BUTTON
                      _buildActionButton(
                        label: "TEXT READING",
                        icon: Icons.mail_rounded,
                        isPrimary: false,
                        onTap: () => _startCommunication("TEXT READING"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "About My Services",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.bio ??
                        "Welcome to my psychic sanctuary. I am a gifted 3rd generation clairvoyant and master tarot guide with over 15 years of professional experience helping clients navigate love crossroads, soulmate connections, career choices, and spiritual alignment. My readings are compassionate, honest, and direct.",
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Experience Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Experience & Qualifications",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• 15+ Years of Professional Clairvoyant & Intuitive Reading\n• Certified Master Tarot Practitioner & Astrologer\n• Specialized in Relationship Dynamics, Soulmate Alignment & Life Purpose Guidance\n• Thousands of 5-Star Consultations Worldwide",
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimaryLight, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Client Testimonials Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What Clients Say",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 12),
                  _buildReviewTile("Sarah M.", 5.0, "Spot on prediction! Her guidance gave me total peace of mind regarding my career decision.", "2 days ago"),
                  const Divider(color: AppColors.borderLight),
                  _buildReviewTile("David K.", 5.0, "Incredible insight into my relationship. She saw things nobody else could know!", "1 week ago"),
                  const Divider(color: AppColors.borderLight),
                  _buildReviewTile("Emily R.", 5.0, "Warm, accurate, and deeply compassionate. I will definitely be calling back.", "2 weeks ago"),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF369A23), Color(0xFF2E5626)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF369A23).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.zero,
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 16, color: Colors.white),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2E5626).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E5626)),
      ),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: const Color(0xFF2E5626)),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2E5626)),
        ),
      ),
    );
  }

  Widget _buildReviewTile(String name, double rating, String text, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight)),
              Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: List.generate(
              5,
              (index) => const Icon(Icons.star_rounded, color: AppColors.accentGoldDark, size: 14),
            ),
          ),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, height: 1.4)),
        ],
      ),
    );
  }
}
