import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/storage_service.dart';
import '../../models/advisor_model.dart';
import '../../models/category_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/advisor_service.dart';
import '../menu_pages/add_funds_screen.dart';
import '../user/login_screen.dart';
import 'live_session_screen.dart';
import 'video_call_screen.dart';
import 'voice_call_screen.dart';

class AdvisorDetailScreen extends StatefulWidget {
  final AdvisorDto? advisor;
  final String? advisorId;

  const AdvisorDetailScreen({
    Key? key,
    this.advisor,
    this.advisorId,
  })  : assert(advisor != null || advisorId != null, 'Either advisor or advisorId must be provided'),
        super(key: key);

  @override
  State<AdvisorDetailScreen> createState() => _AdvisorDetailScreenState();
}

class _AdvisorDetailScreenState extends State<AdvisorDetailScreen> {
  final AdvisorService _advisorService = AdvisorService();

  AdvisorDto? _advisor;
  bool _isLoadingAdvisor = true;
  String? _advisorError;

  int _freeMinutes = 0;
  List<AdvisorReviewDto> _reviews = [];
  bool _reviewsLoading = true;
  int _totalReviewsCount = 0;
  double _avgRating = 0.0;

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _advisor = widget.advisor;
    if (_advisor != null) {
      _isLoadingAdvisor = false;
      _avgRating = _advisor!.rating;
      _totalReviewsCount = _advisor!.reviewsCount;
    }
    _loadAllData();
  }

  String get _effectiveAdvisorId {
    return _advisor?.id ?? widget.advisorId ?? widget.advisor?.id ?? '';
  }

  Future<void> _loadAllData() async {
    final advisorId = _effectiveAdvisorId;
    if (advisorId.isEmpty) return;

    final userProv = Provider.of<UserProvider>(context, listen: false);
    final userId = userProv.user?.id;

    // 1. Fetch full advisor profile details from API
    _loadAdvisorProfile(advisorId, userId);

    // 2. Fetch free minutes discount from API
    _loadFreeMinutes(userId);

    // 3. Fetch reviews from API
    _loadAdvisorReviews(advisorId);
  }

  Future<void> _loadAdvisorProfile(String advisorId, String? userId) async {
    try {
      var updatedAdvisor = await _advisorService.getAdvisorById(advisorId, userId: userId);
      // Preserve existing valid category name or title from widget/previous state if updated profile has null
      final prevCat = _advisor?.categoryName ?? widget.advisor?.categoryName;
      if ((updatedAdvisor.categoryName == null || updatedAdvisor.categoryName!.isEmpty) &&
          prevCat != null && prevCat.isNotEmpty && !isGuidOrIdString(prevCat)) {
        updatedAdvisor = updatedAdvisor.copyWith(categoryName: prevCat);
      }
      if (mounted) {
        setState(() {
          _advisor = updatedAdvisor;
          _isLoadingAdvisor = false;
          _advisorError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAdvisor = false;
          if (_advisor == null) {
            _advisorError = "Failed to load advisor details: ${e.toString()}";
          }
        });
      }
    }
  }

  Future<void> _loadFreeMinutes(String? userId) async {
    try {
      final freeMins = await _advisorService.getUserFreeMinutes(userId);
      if (mounted) {
        setState(() {
          _freeMinutes = freeMins;
        });
      }
    } catch (_) {
      // Keep default 0
    }
  }

  Future<void> _loadAdvisorReviews(String advisorId) async {
    setState(() => _reviewsLoading = true);
    try {
      final result = await _advisorService.getAdvisorReviews(advisorId, pageNumber: 1, pageSize: 10);
      if (mounted) {
        final reviewList = (result['reviews'] as List<AdvisorReviewDto>?) ?? [];
        final count = (result['totalCount'] as int?) ?? reviewList.length;

        double computedAvg = 0.0;
        if (reviewList.isNotEmpty) {
          final sum = reviewList.fold<double>(0.0, (acc, r) => acc + r.rating);
          computedAvg = double.parse((sum / reviewList.length).toStringAsFixed(1));
        } else {
          computedAvg = _advisor?.rating ?? 0.0;
        }

        setState(() {
          _reviews = reviewList;
          _totalReviewsCount = count;
          _avgRating = computedAvg;
          _reviewsLoading = false;
          if (_advisor != null) {
            _advisor = _advisor!.copyWith(
              rating: computedAvg,
              reviewsCount: count,
            );
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reviews = [];
          _reviewsLoading = false;
        });
      }
    }
  }

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

  /// Handles clicking Chat, Call, Video, or Text Reading
  /// Follows exact web angular logic:
  /// 1. Check if user is logged in & token has not expired
  /// 2. Check if user is advisor (restricted)
  /// 3. Check if advisor is offline
  /// 4. Check session eligibility and balance via API (checkSessionEligibilty)
  Future<void> _handleAction(String mode) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userProv = Provider.of<UserProvider>(context, listen: false);

    // 1. Advisor role check
    if (userProv.isAdvisor) {
      _showAdvisorAccountDialog();
      return;
    }

    // 2. Authentication & Token Expiration Check (Matching Angular auth.isLoggedIn + token.exp)
    final token = await StorageService.getToken();
    if (!auth.isLoggedIn || token == null || token.isEmpty) {
      if (auth.isLoggedIn) {
        await auth.logout();
        userProv.clearUser();
      }
      _showSignInDialog(mode);
      return;
    }

    final adv = _advisor;
    if (adv == null) return;

    final targetId = (adv.loginId != null && adv.loginId!.isNotEmpty)
        ? adv.loginId!
        : ((adv.advisorId != null && adv.advisorId!.isNotEmpty) ? adv.advisorId! : adv.id);

    // 3. Offline check (Non-text sessions require advisor to be online)
    if (!adv.isOnline && mode.toLowerCase() != 'text reading') {
      _showAdvisorOfflineDialog(adv.name);
      return;
    }

    // 4. API checkSessionEligibilty (Balance & session validation matching Angular FundsService)
    _showEligibilityLoadingDialog();

    try {
      final eligibility = await _advisorService.checkSessionEligibility(targetId);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog

      // Check online status returned by API
      if (!eligibility.isOnline && mode.toLowerCase() != 'text reading') {
        _showAdvisorOfflineDialog(adv.name);
        return;
      }

      // Check balance status returned by API
      if (!eligibility.hasBalance) {
        _showLowBalanceDialog(mode, eligibility);
        return;
      }

      // Balance is valid & advisor is online -> Start session confirmation bottom sheet
      _showStartSessionSheet(mode, eligibility);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog

      if (e is ApiUnauthorizedException ||
          (e is ApiException && e.statusCode == 401) ||
          e.toString().contains('401') ||
          e.toString().toLowerCase().contains('unauthorized')) {
        await auth.logout();
        userProv.clearUser();
        _showSignInDialog(mode, isSessionExpired: true);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error checking session eligibility: ${e.toString()}")),
      );
    }
  }

  void _showEligibilityLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E5626))),
              SizedBox(height: 16),
              Text(
                "Checking session eligibility...",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdvisorAccountDialog() {
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E5626)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got It", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSignInDialog(String mode, {bool isSessionExpired = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isSessionExpired ? Icons.lock_clock_outlined : Icons.lock_outline_rounded,
              color: isSessionExpired ? Colors.orange : AppColors.accentGold,
            ),
            const SizedBox(width: 8),
            Text(isSessionExpired ? "Session Expired" : "Sign In Required"),
          ],
        ),
        content: Text(
          isSessionExpired
              ? "Your session has expired. Please sign in again to connect with ${_advisor?.name ?? 'this advisor'}."
              : "Please sign in or create an account to start a $mode session with ${_advisor?.name ?? 'this advisor'}.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E5626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              _loadAllData();
            },
            child: const Text("Sign In Now", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAdvisorOfflineDialog(String advisorName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_off_rounded, color: Colors.grey),
            SizedBox(width: 8),
            Text("Advisor Offline"),
          ],
        ),
        content: Text(
          "$advisorName is currently offline. Please try again when the advisor is online or send a text reading request.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E5626)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLowBalanceDialog(String mode, SessionEligibilityDto eligibility) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text("Low Balance"),
          ],
        ),
        content: Text(
          "Your current balance of \$${eligibility.userBalance.toStringAsFixed(2)} is insufficient to start a $mode session. Please add funds to your wallet to continue.",
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E5626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFundsScreen()),
              );
              _loadAllData();
            },
            child: const Text("Add Funds", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStartSessionSheet(String mode, SessionEligibilityDto eligibility) {
    final adv = _advisor!;
    final rate = eligibility.advisorFees > 0 ? eligibility.advisorFees : adv.pricePerMinute;
    bool isStarting = false;

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
                    adv.name.isNotEmpty ? adv.name[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Start $mode with ${adv.name}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
                      ),
                      Text(
                        adv.displayTitle,
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
            _buildBillingRow("Rate per Minute", "\$${rate.toStringAsFixed(2)} / min"),
            _buildBillingRow(
              "Free Minutes",
              eligibility.freeMinutes > 0 ? "${eligibility.freeMinutes} Minutes FREE" : "None Available",
            ),
            _buildBillingRow("Your Wallet Balance", "\$${eligibility.userBalance.toStringAsFixed(2)}"),
            if (eligibility.validSessionMinutes > 0)
              _buildBillingRow("Estimated Session Time", "~${eligibility.validSessionMinutes} mins"),
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
                  if (isStarting) return;
                  isStarting = true;
                  Navigator.pop(ctx);
                  final sessionProv = Provider.of<SessionProvider>(context, listen: false);
                  final user = Provider.of<UserProvider>(context, listen: false).user;
                  sessionProv.initiateSessionRequest(
                    clientId: user?.id ?? "",
                    clientName: user?.displayName ?? "User",
                    advisorId: adv.id,
                    advisorName: adv.name,
                    type: mode.toUpperCase().contains("VIDEO")
                        ? SessionType.video
                        : (mode.toUpperCase().contains("CALL") || mode.toUpperCase().contains("VOICE")
                            ? SessionType.call
                            : SessionType.chat),
                    ratePerMinute: rate,
                    freeMinutes: eligibility.freeMinutes,
                    userBalance: eligibility.userBalance,
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
    final adv = _advisor;
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
            } else if (sessionProv.sessionState == SessionState.declined) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(dialogCtx).pop();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.bgDarkCard,
                    title: Text(sessionProv.declineTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: Text(sessionProv.declineMessage, style: const TextStyle(color: AppColors.textPrimaryDark, height: 1.4)),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              });
            } else if (sessionProv.sessionState == SessionState.noBalance) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(dialogCtx).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddFundsScreen()),
                );
              });
            } else if (sessionProv.sessionState == SessionState.busy || sessionProv.sessionState == SessionState.anotherSession) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(sessionProv.sessionState == SessionState.busy
                        ? "Advisor is currently busy with another client."
                        : "You already have another active session in progress."),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              });
            } else if (sessionProv.sessionState == SessionState.cancelled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request was cancelled.")),
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
                        const SizedBox(
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
                            (adv != null && adv.name.isNotEmpty) ? adv.name[0].toUpperCase() : 'A',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Waiting for ${adv?.name ?? 'Advisor'}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Notification sent! Session will begin as soon as ${adv?.name ?? 'Advisor'} accepts your $mode request.",
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    // 60-second waiting badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: AppColors.accentGold, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Auto-cancels in ${sessionProv.waitingSecondsLeft}s",
                            style: const TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
    if (_isLoadingAdvisor && _advisor == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(title: const Text("Advisor Details")),
        body: const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E5626))),
        ),
      );
    }

    if (_advisorError != null && _advisor == null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(title: const Text("Advisor Details")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(_advisorError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAllData,
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final a = _advisor!;
    final statusColor = _getStatusColor(a.status);
    final userProv = Provider.of<UserProvider>(context);

    // Free minutes text matching Angular:
    // freeMinutes > 0 ? ('First ' + freeMinutes + ' minutes free') : 'No free minutes available'
    final freeMinsText = _freeMinutes > 0
        ? "First $_freeMinutes minutes free"
        : "No free minutes available";

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
      body: RefreshIndicator(
        color: const Color(0xFF2E5626),
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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

              // TOP PROFILE CARD (Dynamic from API)
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
                        // Avatar & Status Badge
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 90,
                                height: 105,
                                color: AppColors.primary.withOpacity(0.1),
                                child: (a.profilePhoto != null && a.profilePhoto!.isNotEmpty)
                                    ? Image.network(
                                        ApiEndpoints.resolveImageUrl(a.profilePhoto),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            a.name.isNotEmpty ? a.name[0].toUpperCase() : 'A',
                                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          a.name.isNotEmpty ? a.name[0].toUpperCase() : 'A',
                                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
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
                                  a.isOnline ? 'Online' : (a.isBusy ? 'Busy' : 'Offline'),
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Name, Title, Rating
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
                                a.displayTitle,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accentPurple),
                              ),
                              const SizedBox(height: 8),

                              // Stars & Rating (Synchronized with Reviews API as in Angular)
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(
                                      5,
                                      (index) {
                                        if (index < _avgRating.floor()) {
                                          return const Icon(Icons.star_rounded, color: AppColors.accentGoldDark, size: 18);
                                        } else if (index < _avgRating && (_avgRating - _avgRating.floor()) >= 0.5) {
                                          return const Icon(Icons.star_half_rounded, color: AppColors.accentGoldDark, size: 18);
                                        } else {
                                          return const Icon(Icons.star_outline_rounded, color: Colors.grey, size: 18);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${_avgRating.toStringAsFixed(1)} / 5.0 ($_totalReviewsCount reviews)",
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

                    // Expertise & Languages Grid (Completely from API)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Areas of Expertise
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Areas of Expertise",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                              ),
                              const SizedBox(height: 4),
                              if (a.specialitiesList.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: a.specialitiesList
                                      .map((s) => Padding(
                                            padding: const EdgeInsets.only(bottom: 2),
                                            child: Text("• $s", style: const TextStyle(fontSize: 12, color: AppColors.textPrimaryLight, height: 1.3)),
                                          ))
                                      .toList(),
                                )
                              else
                                const Text("• Not available", style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 60, color: AppColors.borderLight),
                        const SizedBox(width: 12),

                        // Languages
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Languages",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (a.language != null && a.language!.trim().isNotEmpty)
                                    ? "• ${a.language}"
                                    : "• Not available",
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimaryLight, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // PRICE CARD & ACTIONS (Web Angular Style)
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
                            const Text("Price", style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                if (a.offeredFee > 0 && a.offeredFee < a.fee) ...[
                                  Text(
                                    "\$${a.offeredFee.toStringAsFixed(2)}",
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ctaGreen),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "\$${a.fee.toStringAsFixed(2)}",
                                    style: const TextStyle(fontSize: 13, color: Colors.grey, decoration: TextDecoration.lineThrough),
                                  ),
                                ] else ...[
                                  Text(
                                    "\$${(a.fee > 0 ? a.fee : a.pricePerMinute).toStringAsFixed(2)}",
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ctaGreen),
                                  ),
                                ],
                                const Text(" / min", style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                              ],
                            ),
                          ],
                        ),

                        // Free Minutes Badge (Dynamic from API, exactly as in Web Angular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2E7D32)),
                          ),
                          child: Text(
                            freeMinsText,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.borderLight),
                    const SizedBox(height: 12),

                    // Action Buttons Grid (Filtered by commStyles matching Angular)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        // CALL BUTTON (Always displayed)
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 74) / 2,
                          height: 44,
                          child: _buildActionButton(
                            label: "CALL",
                            icon: Icons.phone_in_talk_rounded,
                            isPrimary: true,
                            onTap: () => _handleAction("CALL"),
                          ),
                        ),

                        // CHAT BUTTON (hasCommStyle(1))
                        if (a.hasCommStyle(1))
                          SizedBox(
                            width: (MediaQuery.of(context).size.width - 74) / 2,
                            height: 44,
                            child: _buildActionButton(
                              label: "CHAT",
                              icon: Icons.chat_bubble_rounded,
                              isPrimary: false,
                              onTap: () => _handleAction("CHAT"),
                            ),
                          ),

                        // VIDEO CALL BUTTON (hasCommStyle(2))
                        if (a.hasCommStyle(2))
                          SizedBox(
                            width: (MediaQuery.of(context).size.width - 74) / 2,
                            height: 44,
                            child: _buildActionButton(
                              label: "VIDEO CALL",
                              icon: Icons.videocam_rounded,
                              isPrimary: false,
                              onTap: () => _handleAction("VIDEO CALL"),
                            ),
                          ),

                        // TEXT READING BUTTON (hasCommStyle(4))
                        if (a.hasCommStyle(4))
                          SizedBox(
                            width: (MediaQuery.of(context).size.width - 74) / 2,
                            height: 44,
                            child: _buildActionButton(
                              label: "TEXT READING",
                              icon: Icons.mail_rounded,
                              isPrimary: false,
                              onTap: () => _handleAction("TEXT READING"),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ABOUT SECTION (From API: a.aboutMyServices or a.bio)
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
                      "About",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                    ),
                    const SizedBox(height: 4),
                    Container(width: 60, height: 2, color: const Color(0xFF2E5626)),
                    const SizedBox(height: 10),
                    Text(
                      a.cleanAbout.isNotEmpty ? a.cleanAbout : "No description available.",
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // EXPERIENCE & QUALIFICATIONS (From API: a.experienceAndQualifications)
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
                      "Experience & Qualifications",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                    ),
                    const SizedBox(height: 4),
                    Container(width: 60, height: 2, color: const Color(0xFF2E5626)),
                    const SizedBox(height: 10),
                    Text(
                      a.cleanExperience.isNotEmpty ? a.cleanExperience : "No details available.",
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // WHAT CLIENTS SAY / REVIEWS SECTION (Dynamic from api/Web/GetAdvisorReviews)
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

                    // Rating Summary Card (matching Angular Customers Reviews & Ratings)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Customers Reviews & Ratings",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${_avgRating.toStringAsFixed(1)} out of 5.0",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E5626)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Based on $_totalReviewsCount Reviews",
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_reviewsLoading) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E5626))),
                              SizedBox(height: 8),
                              Text("Loading reviews...", style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_reviews.isEmpty) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("No reviews available.", style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                        ),
                      ),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reviews.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.borderLight, height: 20),
                        itemBuilder: (ctx, index) {
                          final r = _reviews[index];
                          final formattedDate = r.createDate != null
                              ? DateFormat('MMM d, yyyy').format(r.createDate!)
                              : '';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    r.reviewerName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight),
                                  ),
                                  if (formattedDate.isNotEmpty)
                                    Text(formattedDate, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: List.generate(
                                  5,
                                  (starIndex) => Icon(
                                    starIndex < r.rating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: AppColors.accentGoldDark,
                                    size: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r.description ?? "No review text provided.",
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, height: 1.4),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
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
}
