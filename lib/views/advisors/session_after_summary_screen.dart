import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/session_provider.dart';

class SessionAfterSummaryScreen extends StatefulWidget {
  final bool isAdvisorView;
  final String participantName;
  final String formattedTime;
  final double totalCost;
  final String sessionTypeLabel;
  final bool isLiveSessionEnd;

  const SessionAfterSummaryScreen({
    Key? key,
    required this.isAdvisorView,
    required this.participantName,
    required this.formattedTime,
    required this.totalCost,
    required this.sessionTypeLabel,
    this.isLiveSessionEnd = true,
  }) : super(key: key);

  @override
  State<SessionAfterSummaryScreen> createState() => _SessionAfterSummaryScreenState();
}

class _SessionAfterSummaryScreenState extends State<SessionAfterSummaryScreen> {
  int _selectedRating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _reviewSubmitted = false;
  int _redirectSeconds = 10;
  Timer? _redirectTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLiveSessionEnd) {
      _startRedirectTimer();
    }
  }

  void _startRedirectTimer() {
    _redirectTimer?.cancel();
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        _redirectTimer = null;
        return;
      }
      if (_redirectSeconds > 1) {
        setState(() => _redirectSeconds--);
      } else {
        timer.cancel();
        _redirectTimer = null;
        _returnToDashboardOrHome();
      }
    });
  }

  void _returnToDashboardOrHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _redirectTimer?.cancel();
    _redirectTimer = null;
    final sessionProv = Provider.of<SessionProvider>(context, listen: false);
    sessionProv.resetSession();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _redirectTimer = null;
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionProv = Provider.of<SessionProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkCard,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Session Summary",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: _returnToDashboardOrHome,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Top Status Icon & Completion Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGold, width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.accentGold.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGold, size: 54),
            ),
            const SizedBox(height: 16),

            Text(
              "Session Ended",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              "Your ${widget.sessionTypeLabel} with ${widget.participantName} has ended.",
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryDark),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Session Receipt Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  _buildSummaryRow("Service Type", widget.sessionTypeLabel, icon: Icons.psychology_rounded),
                  const Divider(color: AppColors.borderDark, height: 24),
                  _buildSummaryRow("Participant", widget.participantName, icon: Icons.person_rounded),
                  const Divider(color: AppColors.borderDark, height: 24),
                  _buildSummaryRow("Total Duration", widget.formattedTime, icon: Icons.timer_rounded, valueColor: AppColors.accentGold),
                  const Divider(color: AppColors.borderDark, height: 24),
                  _buildSummaryRow("Total Charges", widget.totalCost == 0 ? "FREE (\$0.00)" : "\$${widget.totalCost.toStringAsFixed(2)}", icon: Icons.payments_rounded, valueColor: AppColors.onlineGreen),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rating & Review Section (For Customers)
            if (!widget.isAdvisorView) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgDarkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderGold.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Rate Your Experience",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "How satisfied were you with ${widget.participantName}?",
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimaryDark),
                    ),
                    const SizedBox(height: 16),

                    // 5-Star Selection Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          iconSize: 36,
                          icon: Icon(
                            star <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: AppColors.accentGold,
                          ),
                          onPressed: () => setState(() => _selectedRating = star),
                        );
                      }),
                    ),

                    const SizedBox(height: 12),

                    // Optional Review Field
                    if (!_reviewSubmitted) ...[
                      TextField(
                        controller: _reviewController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 3,
                        onChanged: (text) {
                          // Pause auto-redirect if customer is actively typing a review
                          if (text.trim().isNotEmpty && _redirectTimer != null) {
                            _redirectTimer?.cancel();
                            _redirectTimer = null;
                            if (mounted) setState(() => _redirectSeconds = 0);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Write your review or feedback (optional)...",
                          hintStyle: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.bgDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGold,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              _reviewSubmitted = true;
                              _redirectSeconds = 3;
                            });
                            _startRedirectTimer();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Thank you! Your review has been submitted.")),
                            );
                          },
                          child: const Text("Submit Review", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.onlineGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.onlineGreen),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 18),
                            SizedBox(width: 8),
                            Text("Review Submitted Successfully!", style: TextStyle(color: AppColors.onlineGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Auto Redirect Countdown Notice (Matching Angular Web App Parity)
            if (widget.isLiveSessionEnd && _redirectSeconds > 0) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGold.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isAdvisorView
                          ? "Redirecting to dashboard in $_redirectSeconds seconds..."
                          : "Redirecting to home in $_redirectSeconds seconds...",
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Back to Dashboard / Home Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(
                  widget.isAdvisorView ? Icons.dashboard_rounded : Icons.home_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  widget.isAdvisorView ? "Go To Dashboard" : "Return to Home",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: _returnToDashboardOrHome,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required IconData icon, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.accentGold),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13)),
          ],
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valueColor ?? Colors.white),
        ),
      ],
    );
  }
}
