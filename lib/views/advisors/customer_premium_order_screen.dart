import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/premium_service_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/premium_service.dart';
import '../menu_pages/add_funds_screen.dart';
import '../menu_pages/customer_premium_requests_screen.dart';
import '../user/login_screen.dart';

class CustomerPremiumOrderScreen extends StatefulWidget {
  final int serviceId;
  final PremiumServiceModel? initialService;
  final String? advisorName;
  final String? advisorPhoto;

  const CustomerPremiumOrderScreen({
    Key? key,
    required this.serviceId,
    this.initialService,
    this.advisorName,
    this.advisorPhoto,
  }) : super(key: key);

  @override
  State<CustomerPremiumOrderScreen> createState() => _CustomerPremiumOrderScreenState();
}

class _CustomerPremiumOrderScreenState extends State<CustomerPremiumOrderScreen> {
  final _premiumService = PremiumService();

  bool _isLoading = true;
  bool _isOrdering = false;
  String? _errorMessage;

  StartPremiumEligibilityModel? _eligibility;
  PremiumServiceModel? _service;
  Map<String, dynamic>? _advisorProfile;

  @override
  void initState() {
    super.initState();
    _service = widget.initialService;
    _loadServiceAndEligibility();
  }

  Future<void> _loadServiceAndEligibility() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch Eligibility & Pricing info
      final elig = await _premiumService.loadPremiumEligibility(widget.serviceId);
      _eligibility = elig;

      if (elig?.premiumService != null) {
        _service = elig!.premiumService;
      }
      if (elig?.advisorProfile != null) {
        _advisorProfile = elig!.advisorProfile;
      }

      // 2. If service details still null, load from details endpoint
      if (_service == null || _service!.serviceDescription == null) {
        final detailsData = await _premiumService.getServiceDetails(widget.serviceId);
        if (detailsData != null) {
          if (detailsData['service'] is Map<String, dynamic>) {
            _service = PremiumServiceModel.fromJson(detailsData['service'] as Map<String, dynamic>);
          }
          if (detailsData['advisor'] is Map<String, dynamic>) {
            _advisorProfile = detailsData['advisor'] as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      _errorMessage = "Failed to load service details. Please try again.";
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStartOrder() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    if (_eligibility?.noBalance == true) {
      _showInsufficientBalanceDialog();
      return;
    }

    if (_eligibility?.isRequestPending == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You already have an active pending order for this service."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Confirm Premium Order",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Service: ${_service?.title ?? 'Platinum Service'}",
              style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "Total Price: \$${(_eligibility?.totalPrice ?? _service?.price ?? 0.0).toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Duration: ${_service?.duration ?? 1} day delivery",
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              "The fee will be reserved from your wallet balance. You can exchange clarification messages with your advisor while the service is in progress.",
              style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm & Order", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isOrdering = true);

    try {
      final res = await _premiumService.startPremiumOrder(widget.serviceId);
      if (!mounted) return;

      // Update eligibility
      await _loadServiceAndEligibility();

      // Show completion dialog with navigation options
      _showOrderSuccessDialog(res['message']?.toString() ?? "Premium service request created successfully!");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error placing order: $e"),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  void _showInsufficientBalanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text("Insufficient Balance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your wallet does not have enough balance to place this premium order.",
              style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Service Price:", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                      Text("\$${(_eligibility?.totalPrice ?? _service?.price ?? 0.0).toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Current Balance:", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                      Text("\$${(_eligibility?.userBalance ?? 0.0).toStringAsFixed(2)}",
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_card_rounded, color: Colors.black, size: 16),
            label: const Text("Add Funds", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFundsScreen()),
              ).then((_) => _loadServiceAndEligibility());
            },
          ),
        ],
      ),
    );
  }

  void _showOrderSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDarkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Order Placed!",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your advisor has been notified and will review your request. You can track progress and send queries in My Premium Orders.",
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.textSecondaryDark),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text("Done & Return", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.black, size: 16),
            label: const Text("View My Orders", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CustomerPremiumRequestsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkHeader,
        title: const Text("Platinum Luxe Service", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
                          onPressed: _loadServiceAndEligibility,
                          child: const Text("Retry", style: TextStyle(color: Colors.black)),
                        )
                      ],
                    ),
                  ),
                )
              : _buildContent(),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildContent() {
    final title = _service?.title ?? "Premium Spiritual Service";
    final desc = _service?.serviceDescription ?? "";
    final howItWorks = _service?.howItWorks ?? "";
    final optimalFor = _service?.optimalFor ?? "";
    final checkList = _service?.checkList ?? "";
    final price = _eligibility?.totalPrice ?? _service?.price ?? 0.0;
    final duration = _service?.duration ?? 1;

    final advisorName = widget.advisorName ??
        _advisorProfile?['displayName'] ??
        _advisorProfile?['name'] ??
        _service?.advisorDisplayName ??
        "Spiritual Advisor";

    final advisorPhotoRaw = widget.advisorPhoto ??
        _advisorProfile?['profilePhoto'] ??
        _advisorProfile?['photo'] ??
        _service?.advisorPhoto;
    final advisorPhotoUrl = ApiEndpoints.resolveImageUrl(advisorPhotoRaw);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Advisor Mini Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgDarkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  backgroundImage: advisorPhotoUrl.isNotEmpty ? NetworkImage(advisorPhotoUrl) : null,
                  child: advisorPhotoUrl.isEmpty
                      ? Text(advisorName.isNotEmpty ? advisorName[0].toUpperCase() : 'A',
                          style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold))
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
                              advisorName,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: AppColors.accentGold, size: 16),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        "Verified Platinum Spiritual Master",
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.star, color: AppColors.accentGold, size: 14),
                      SizedBox(width: 4),
                      Text("5.0", style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Service Title Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2E1A47),
                  const Color(0xFF1E1035),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "LUXE SERVICE",
                        style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.accentGold, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          "$duration ${duration == 1 ? 'Day' : 'Days'} Delivery",
                          style: const TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "\$${price.toStringAsFixed(2)}",
                      style: const TextStyle(color: AppColors.accentGold, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "fixed one-time price",
                      style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Balance & Eligibility Summary Card
          if (_eligibility != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _eligibility!.noBalance ? Colors.amber.withOpacity(0.5) : AppColors.borderDark,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Your Current Balance:", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                      Text(
                        "\$${_eligibility!.userBalance.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: _eligibility!.noBalance ? Colors.amber : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Remaining after order:", style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                      Text(
                        "\$${_eligibility!.remainingBalance.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: _eligibility!.remainingBalance >= 0 ? AppColors.onlineGreen : AppColors.errorRed,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_eligibility!.noBalance) ...[
                    const Divider(color: AppColors.borderDark, height: 18),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Insufficient balance to place this order.",
                            style: TextStyle(color: Colors.amber, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddFundsScreen()),
                            ).then((_) => _loadServiceAndEligibility());
                          },
                          child: const Text("Recharge", style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                  if (_eligibility!.isRequestPending) ...[
                    const Divider(color: AppColors.borderDark, height: 18),
                    Row(
                      children: const [
                        Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You already have a pending order for this service.",
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Service Description
          if (desc.isNotEmpty) ...[
            _buildSectionHeader("Service Description", Icons.description_outlined),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Text(
                desc,
                style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // How It Works
          if (howItWorks.isNotEmpty) ...[
            _buildSectionHeader("How It Works", Icons.auto_awesome_outlined),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Text(
                howItWorks,
                style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Optimal For
          if (optimalFor.isNotEmpty) ...[
            _buildSectionHeader("Optimal For", Icons.star_border_rounded),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Text(
                optimalFor,
                style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Checklist / Preparation
          if (checkList.isNotEmpty) ...[
            _buildSectionHeader("Preparation Checklist", Icons.checklist_rounded),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Text(
                checkList,
                style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentGold, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    final isPending = _eligibility?.isRequestPending == true;
    final noBalance = _eligibility?.noBalance == true;
    final price = _eligibility?.totalPrice ?? _service?.price ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.bgDarkCard,
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: noBalance
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706), // Amber-600
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_card_rounded, color: Colors.white),
                      label: const Text(
                        "Add Funds to Proceed",
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddFundsScreen()),
                        ).then((_) => _loadServiceAndEligibility());
                      },
                    )
                  : isPending
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.receipt_long_rounded, color: AppColors.accentGold),
                          label: const Text(
                            "View Pending Order",
                            style: TextStyle(color: AppColors.accentGold, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CustomerPremiumRequestsScreen()),
                            );
                          },
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32), // Green-800
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _isOrdering
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.diamond_rounded, color: Colors.white),
                          label: Text(
                            _isOrdering ? "Placing Order..." : "Order Service - \$${price.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isOrdering ? null : _handleStartOrder,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
